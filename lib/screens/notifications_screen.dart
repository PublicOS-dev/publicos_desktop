import 'dart:async';

import 'package:flutter/material.dart';
import 'package:publicos_core/publicos_core.dart';

import 'package:publicos_desktop/widgets/glass_contact_icon.dart';
import 'package:publicos_desktop/widgets/notification_prefs_sheet.dart';
import 'package:publicos_desktop/widgets/phigital_loading_widget.dart';
import 'package:publicos_desktop/widgets/system_app_scaffold.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/router_helpers.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';
import 'package:publicos_desktop/utils/notification_kinds.dart';
import 'package:publicos_desktop/utils/social_notifs.dart';
import 'package:publicos_desktop/utils/post_links.dart';
import 'package:publicos_desktop/utils/channel_links.dart';
import 'package:publicos_desktop/utils/own_wallets.dart';
import 'package:publicos_desktop/widgets/wallet/wallet_avatar.dart';
import 'package:publicos_desktop/widgets/wallet/transfer_detail_sheet.dart';

/// On-chain activity feed — a newest-top list of [ActivityEvent]s polled by
/// `PublicOSActivity`, filtered + throttled + toggled through
/// `notification_kinds.dart` so this screen and the app-bar bell badge agree.
/// Pushed from the bell, not a bottom-nav tab. Marks everything read on open.
class NotificationsScreen extends StatefulWidget {
  /// DESKTOP DELTA: render as a dialog BODY instead of a full page, a dialog
  /// that grows taller with the list. Everything above this line — polling,
  /// filtering, throttling, mark-read, row taps — is untouched; only the shell
  /// changes. In this mode the widget owns a slim header (so `_openPrefs`
  /// stays where its state is) and shrink-wraps its list so the host dialog
  /// can size itself to the content.
  final bool asDialogBody;

  const NotificationsScreen({super.key, this.asDialogBody = false});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _loading = true;
  List<ActivityEvent> _raw = []; // unfiltered, newest-first (for re-toggling)
  List<NotifItem> _items = []; // filtered + throttled + toggled display list
  Map<String, Contact> _byAddr = {}; // lowercased ACCOUNT eip55 -> Contact
  Map<String, OwnWallet> _wallets = {}; // lowercased WALLET eip55 -> own wallet
  Map<String, Contact> _cpByWallet = {}; // counterparty WALLET eip55 -> Contact
  String? _selfLower;
  // (txHash:logIndex) keys unread at open — used to draw the teal left-edge on
  // this session's new rows even after markAllRead resets the badge.
  Set<String> _unreadAtOpen = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Local first, network after. Phase 1 paints from the device
  /// DB only — stored rows + stored contacts — and drops the loader. Phase 2
  /// then pulls the home inbox, resolves own wallets + unknown counterparties
  /// (chain calls), and marks read; each step repaints when it lands, and the
  /// home read marker is fire-and-forget. None of it may run before the first
  /// paint: a slow RPC/SSP would keep the loader up over a full list.
  Future<void> _load() async {
    _selfLower = PublicOS.sessionBlockchainAddress?.toLowerCase();

    // ── Phase 1: local only ────────────────────────────────────────────────
    try {
      final raw = await PublicOSActivity.getStored(limit: 200);
      final enabled = await loadEnabledNotifKinds();
      final items = buildNotifications(raw, enabled);
      // Snapshot the unread set BEFORE marking read, for the left-edge accent.
      final unread = _unreadKeys(items);
      // Resolve display names / avatars from the stored contacts.
      final contacts = await PublicOSContacts.getStoredContacts();
      final map = <String, Contact>{};
      for (final c in contacts) {
        final a = c.publicosAddress?.eip55With0x.toLowerCase();
        if (a != null) map[a] = c;
      }
      if (!mounted) return;
      setState(() {
        _raw = raw;
        _items = items;
        _byAddr = map;
        _unreadAtOpen = unread;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }

    // ── Phase 2: network, each step best-effort ────────────────────────────
    // Opening the bell pulls the home inbox, so the list is current. New rows
    // join the list (and the unread accent) without a loader.
    try {
      if (await pullSocialInboxNow() > 0) {
        final raw = await PublicOSActivity.getStored(limit: 200);
        final items = buildNotifications(raw, await loadEnabledNotifKinds());
        if (!mounted) return;
        setState(() {
          _raw = raw;
          _items = items;
          _unreadAtOpen = {..._unreadAtOpen, ..._unreadKeys(items)};
        });
      }
    } catch (_) {}

    // Wallet rows name WALLETS, not accounts — a Safe address is never a
    // contact address, so it can never appear in `_byAddr`. Resolve the user's
    // own wallets ("main", the org's name, the key's label) separately, with
    // their emoji/colour so the row draws the Wallet tab's exact mark.
    try {
      final wallets = <String, OwnWallet>{};
      final me = PublicOS.myPublicosAddress;
      if (me != null) {
        for (final w
            in await loadOwnReceivingWallets(EthereumAddress.fromHex(me))) {
          wallets[w.address.toLowerCase()] = w;
        }
      }
      if (mounted) setState(() => _wallets = wallets);
    } catch (_) {}

    try {
      final cp = await _resolveCounterparties(_items, _byAddr);
      if (mounted) setState(() => _cpByWallet = cp);
    } catch (_) {}

    try {
      await PublicOSActivity.markAllRead();
    } catch (_) {}
    // Social rows: the read marker at the HOME
    // SSP too, forward only, so every app of this account agrees. Best
    // effort and NOT awaited: offline just leaves the server marker behind.
    var maxSeq = 0;
    for (final e in _raw) {
      if (!ActivityEventType.isSocial(e.eventType)) continue;
      final seq = e.data['seq'];
      if (seq is num && seq > maxSeq) maxSeq = seq.toInt();
    }
    if (maxSeq > 0) {
      unawaited(PublicOSPush.markNotificationsRead(maxSeq).catchError((_) {}));
    }
  }

  static Set<String> _unreadKeys(List<NotifItem> items) => {
        for (final it in items)
          if (!it.isRead) '${it.event.txHash}:${it.event.logIndex}',
      };

  /// Build `counterparty WALLET address -> Contact` for the transfer rows.
  ///
  /// Core already did the expensive half — the on-chain **wallet → account**
  /// reverse lookup — once, at sweep time, and stamped the account into the
  /// row. Here we only close the loop account → Contact.
  ///
  /// Most counterparties are already contacts, so that's a free local hit. For
  /// an account we've never stored, we `fetchContact` — **4-7 chain calls**, so
  /// this must stay where it is: on **screen open** (a user action), bounded by
  /// the number of *distinct unknown* counterparties on screen, and never on
  /// the 30-second poll or in the background popup worker.
  Future<Map<String, Contact>> _resolveCounterparties(
    List<NotifItem> items,
    Map<String, Contact> known,
  ) async {
    // wallet -> account, for the transfer rows that have a resolved account.
    final walletToAccount = <String, String>{};
    for (final it in items) {
      if (!kWalletKinds.contains(it.kind)) continue;
      final wallet = transferCounterpartyWallet(it.event);
      final account = transferCounterpartyAccount(it.event);
      if (wallet == null || account == null) continue; // no account ⇒ no icon
      walletToAccount[wallet.toLowerCase()] = account;
    }
    if (walletToAccount.isEmpty) return const {};

    final out = <String, Contact>{};
    final fetched = <String, Contact?>{};
    for (final entry in walletToAccount.entries) {
      final accountLower = entry.value.toLowerCase();

      final local = known[accountLower];
      if (local != null) {
        out[entry.key] = local;
        continue;
      }
      // Not a contact of ours — fetch once per distinct account.
      if (!fetched.containsKey(accountLower)) {
        try {
          fetched[accountLower] =
              await PublicOSContacts.fetchContact(EthereumAddress.fromHex(entry.value));
        } catch (_) {
          fetched[accountLower] = null;
        }
      }
      final c = fetched[accountLower];
      if (c != null) out[entry.key] = c;
    }
    return out;
  }

  /// One of the user's OWN wallets by address, or null if it isn't theirs.
  OwnWallet? _ownWallet(String addrHex) => _wallets[addrHex.toLowerCase()];

  /// A label for one of the user's OWN wallets ("main", the org's name, the
  /// key's label), or null if the address isn't one of theirs.
  String? _walletName(String addrHex) => _ownWallet(addrHex)?.name;

  /// The counterparty's Contact, keyed by their **wallet** address.
  ///
  /// The map is built in [_load] off the `counterpartyAccount` Core reverse-
  /// resolved at sweep time. A Safe
  /// address is *never* a contact address, so looking the wallet up directly in
  /// the contacts map always misses. The wallet→account hop happens once,
  /// on chain, at persist time — and this map closes the loop.
  ///
  /// Null when the other end isn't a PublicOS account (bare EOA, contract, or
  /// `address(0)` on a mint) — which is exactly the "no icon" case.
  Contact? _counterpartyContact(ActivityEvent e) {
    final w = transferCounterpartyWallet(e);
    return w == null ? null : _cpByWallet[w.toLowerCase()];
  }

  /// A display name for a counterparty **by wallet address** — the resolver
  /// shape `notifSentence` expects. Null when we can't resolve one.
  ///
  /// Deliberately null-not-hex: the copy switches template ("alice sent 5 OX to
  /// main" vs "Received 5 OX in main") rather than printing a raw address
  /// mid-sentence.
  String? _counterpartyNameByWallet(String walletHex) {
    final c = _cpByWallet[walletHex.toLowerCase()];
    final n = c?.publicosDisplayName ?? c?.displayName;
    return (n != null && n.trim().isNotEmpty) ? n.trim() : null;
  }

  /// The user's own wallet mark for a transfer row — identical to the Wallet
  /// tab's. Falls back to a neutral tile if the wallet has since been removed
  /// (e.g. the keychain key was toggled out of the wallet after the event).
  Widget _ownWalletMark(ActivityEvent e, double size) {
    final w = _ownWallet(transferWalletAddress(e));
    return WalletAvatar(
      contact: w?.contact,
      emoji: w?.emoji,
      colorValue: w?.colorValue,
      size: size,
    );
  }

  Future<void> _openTransfer(ActivityEvent e) async {
    await showTransferDetailSheet(
      context,
      event: e,
      ownWallet: _ownWallet(transferWalletAddress(e)),
      counterparty: _counterpartyContact(e),
    );
  }

  /// Re-read the per-type toggles and re-filter the already-loaded events.
  /// Does NOT re-mark read, so this session's teal accents survive.
  Future<void> _openPrefs() async {
    await showNotificationPrefsSheet(context);
    if (!mounted) return;
    final enabled = await loadEnabledNotifKinds();
    if (!mounted) return;
    setState(() {
      _items = buildNotifications(_raw, enabled);
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    if (widget.asDialogBody) {
      // mainAxisSize.min is what makes the host dialog grow with the list.
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _dialogHeader(tokens),
          Flexible(child: _content(context, null, tokens)),
        ],
      );
    }
    return SystemAppScaffold(
      title: context.l10n.notificationsScreenTitle,
      icon: Icons.notifications_rounded,
      pinHeader: true,
      actions: [
        IconButton(
          tooltip: context.l10n.notificationsScreenTypesTooltip,
          icon: Icon(Icons.tune_rounded, size: 20, color: tokens.starkWhite),
          onPressed: _openPrefs,
        ),
      ],
      builder: (context, scrollController, tokens) =>
          _content(context, scrollController, tokens),
    );
  }

  /// Slim header for the dialog shell — bell + title + the same prefs action
  /// the page keeps in its AppBar, plus a close.
  Widget _dialogHeader(GlassTokens tokens) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 10, 10),
      child: Row(
        children: [
          Icon(Icons.notifications_rounded,
              size: 18, color: tokens.connectedAccent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              context.l10n.notificationsScreenTitle,
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: tokens.starkWhite,
              ),
            ),
          ),
          IconButton(
            tooltip: context.l10n.notificationsScreenTypesTooltip,
            icon: Icon(Icons.tune_rounded, size: 18, color: tokens.textDim),
            onPressed: _openPrefs,
          ),
          IconButton(
            tooltip: 'Close',
            icon: Icon(Icons.close_rounded, size: 18, color: tokens.textDim),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ],
      ),
    );
  }

  /// The list itself — identical in both shells. [scrollController] is null in
  /// dialog mode, which is also the signal to shrink-wrap.
  Widget _content(
      BuildContext context, ScrollController? scrollController, GlassTokens tokens) {
    final dialog = scrollController == null;
    {
        if (_loading) {
          return SizedBox(
            height: dialog ? 120 : null,
            child: const Center(
              child: PhigitalLoadingWidget(size: 28, showShadows: false),
            ),
          );
        }
        if (_items.isEmpty) {
          return SizedBox(
            height: dialog ? 160 : null,
            child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_off_outlined,
                      size: 40, color: tokens.textDim),
                  const SizedBox(height: 12),
                  Text(
                    context.l10n.notificationsScreenNoActivity,
                    style: TextStyle(color: tokens.textDim, fontSize: 14),
                  ),
                ],
              ),
            ),
          ));
        }
        return ListView.separated(
          controller: scrollController,
          // Dialog mode sizes to content so the frame can grow with the list;
          // it still scrolls once the frame hits its max height.
          shrinkWrap: dialog,
          padding: dialog
              ? const EdgeInsets.only(bottom: 8)
              : EdgeInsets.only(
                  top: kToolbarHeight + MediaQuery.of(context).padding.top + 8,
                  bottom: 24,
                ),
          itemCount: _items.length,
          separatorBuilder: (_, __) =>
              Divider(height: 1, color: tokens.borderSubtle),
          itemBuilder: (_, i) {
            final item = _items[i];
            final e = item.event;
            final isWallet = kWalletKinds.contains(item.kind);
            final primary = _primaryAddr(e);
            return _NotifRow(
              event: e,
              tokens: tokens,
              // The SUBJECT of a money row is the user's own wallet, so that's
              // the big mark — the very same one the Wallet tab draws for it.
              // Contract-event rows keep the actor's avatar.
              leading: isWallet
                  ? _ownWalletMark(e, 34)
                  : GlassContactIcon(
                      contact: _byAddr[primary.toLowerCase()],
                      address: primary,
                      size: 34,
                    ),
              spans: _describe(item, tokens),
              unread: _unreadAtOpen.contains('${e.txHash}:${e.logIndex}'),
              // A transfer opens its receipt. Its addresses are WALLETS (Safes /
              // EOAs), not accounts, so there is no profile to route to.
              onTap: isWallet
                  ? () => _openTransfer(e)
                  : kSocialKinds.contains(item.kind)
                      ? () => _openSocial(item)
                      : () => AppNav.toProfile(context, primary),
            );
          },
        );
    }
  }

  /// A social row opens its post (`item_url`, the comment anchor rides
  /// along); a follow request or approval has no post and opens the actor's
  /// profile, which is also the fallback when the post can't be fetched
  /// (gone, private to the reader, server down).
  Future<void> _openSocial(NotifItem item) async {
    final e = item.event;
    final url = socialItemUrl(e);
    // A follow request opens the owner's settings on its request queue,
    // an approval the channel's feed; both carry the CHANNEL as item_url.
    final bool ok;
    if (item.kind == NotifKind.followRequest) {
      ok = await openChannelRequestsFromUrl(context, url);
    } else if (item.kind == NotifKind.followApproved) {
      ok = await openChannelFeedFromUrl(context, url);
    } else {
      ok = await openPostFromUrl(context, url);
    }
    if (ok || !mounted) return;
    AppNav.toProfile(context, e.actor);
  }

  // --- copy + resolution -----------------------------------------------------

  bool _isSelf(String addrHex) => addrHex.toLowerCase() == _selfLower;

  String _name(String addrHex) {
    if (_isSelf(addrHex)) return context.l10n.notificationsScreenYou;
    final c = _byAddr[addrHex.toLowerCase()];
    final n = c?.publicosDisplayName ?? c?.displayName;
    if (n != null && n.trim().isNotEmpty) return n.trim();
    return addrHex.length > 10
        ? '${addrHex.substring(0, 6)}…${addrHex.substring(addrHex.length - 4)}'
        : addrHex;
  }

  /// The address whose avatar/profile the row points at: the "other party" for
  /// a vouch the user gave, the actor otherwise.
  String _primaryAddr(ActivityEvent e) {
    if (e.eventType == ActivityEventType.vouched &&
        _isSelf(e.actor) &&
        e.target != null) {
      return e.target!;
    }
    return e.actor;
  }

  /// Builds the row sentence as styled spans (subject names bolded), switching
  /// on the resolved [NotifKind] so profile edits read per-field.
  List<InlineSpan> _describe(NotifItem item, GlassTokens tokens) {
    final e = item.event;
    final bold = TextStyle(
        color: tokens.starkWhite, fontWeight: FontWeight.w600, fontSize: 13);
    TextSpan b(String s) => TextSpan(text: s, style: bold);
    TextSpan t(String s) => TextSpan(text: s);

    // Generic "<subject> <verb>" / "You <verb>" builder for the simple kinds.
    List<InlineSpan> simple(String youCopy, String theyCopy) =>
        _isSelf(e.actor)
            ? [t(youCopy)]
            : [b(_name(e.actor)), t(theyCopy)];

    final l10n = context.l10n;
    switch (item.kind) {
      case NotifKind.avatar:
        return simple(l10n.notificationsScreenYouUpdatedAvatar,
            l10n.notificationsScreenTheyUpdatedAvatar);
      case NotifKind.banner:
        return simple(l10n.notificationsScreenYouUpdatedBanner,
            l10n.notificationsScreenTheyUpdatedBanner);
      case NotifKind.bio:
        return simple(l10n.notificationsScreenYouUpdatedBio,
            l10n.notificationsScreenTheyUpdatedBio);
      case NotifKind.profile:
        return simple(l10n.notificationsScreenYouUpdatedProfile,
            l10n.notificationsScreenTheyUpdatedProfile);
      case NotifKind.tabs:
        return simple(l10n.notificationsScreenYouUpdatedTabs,
            l10n.notificationsScreenTheyUpdatedTabs);
      case NotifKind.vouched:
        final target = e.target ?? e.actor;
        if (_isSelf(target)) {
          return [
            b(_name(e.actor)),
            t(l10n.notificationsScreenVouchedForYou)
          ];
        }
        if (_isSelf(e.actor)) {
          return [t(l10n.notificationsScreenYouVouchedFor), b(_name(target))];
        }
        return [
          b(_name(e.actor)),
          t(l10n.notificationsScreenVouchedFor),
          b(_name(target))
        ];
      case NotifKind.citizenized:
        return _isSelf(e.actor)
            ? [
                t(l10n.notificationsScreenYoureNowA),
                b(l10n.notificationsScreenCitizen),
                t(' 🎉'),
              ]
            : [
                b(_name(e.actor)),
                t(l10n.notificationsScreenIsNowCitizen),
              ];
      case NotifKind.domainPaid:
        final m = int.tryParse('${e.data['months'] ?? ''}') ?? 0;
        final label = l10n.notificationsScreenMonths(m);
        return simple(l10n.notificationsScreenYouPaidRent(label),
            l10n.notificationsScreenTheyPaidRent(label));
      case NotifKind.evicted:
        return simple(l10n.notificationsScreenYourAccountEvicted,
            l10n.notificationsScreenWasEvicted);
      case NotifKind.nameChanged:
        final n = '${e.data['newName'] ?? ''}'.trim();
        if (_isSelf(e.actor)) {
          return [
            t(n.isEmpty
                ? l10n.notificationsScreenYouChangedName
                : l10n.notificationsScreenYoureNowHandle(n))
          ];
        }
        return [
          b(_name(e.actor)),
          t(n.isEmpty
              ? l10n.notificationsScreenChangedTheirName
              : l10n.notificationsScreenIsNowHandle(n))
        ];
      case NotifKind.displayName:
        final n = '${e.data['newName'] ?? ''}'.trim();
        if (_isSelf(e.actor)) {
          return [
            t(n.isEmpty
                ? l10n.notificationsScreenYouChangedDisplayName
                : l10n.notificationsScreenYouChangedDisplayNameTo(n))
          ];
        }
        return [
          b(_name(e.actor)),
          t(n.isEmpty
              ? l10n.notificationsScreenChangedDisplayName
              : l10n.notificationsScreenChangedDisplayNameTo(n))
        ];

      // Wallet transfers. The AMOUNT is the subject here — it's what the user
      // scans the row for — so it takes the bold, not a name.
      case NotifKind.transferIn:
      case NotifKind.transferOut:
      case NotifKind.transferSelf:
        return _describeTransfer(item, b, t);

      // Social rows: the actor, bold, then the
      // verb. The actor is never the user (rule 1 at the hosting server), so
      // there is no "You" form. Twin of notifSentence's six sentences.
      case NotifKind.comment:
        return [b(_name(e.actor)), t(l10n.notificationsScreenCommented)];
      case NotifKind.reply:
        return [b(_name(e.actor)), t(l10n.notificationsScreenReplied)];
      case NotifKind.mention:
        return [b(_name(e.actor)), t(l10n.notificationsScreenMentioned)];
      case NotifKind.reaction:
        return [
          b(_name(e.actor)),
          t(socialItemIsComment(e)
              ? l10n.notificationsScreenReactedComment
              : l10n.notificationsScreenReactedPost),
        ];
      case NotifKind.followRequest:
        return [b(_name(e.actor)), t(l10n.notificationsScreenFollowRequested)];
      case NotifKind.followApproved:
        return [b(_name(e.actor)), t(l10n.notificationsScreenFollowApproved)];
    }
  }

  /// Transfer rows.
  ///
  /// Unlike the other kinds — which hand-assemble spans from per-fragment l10n
  /// keys — these reuse [notifSentence], the SAME localized builder the OS
  /// popup uses, then decorate the finished sentence: **bold the amount**, and
  /// splice a **mini avatar** in front of the counterparty's name.
  ///
  /// Decorating the finished sentence (rather than hand-assembling spans) is
  /// what makes it survive a locale that reorders the clause — the ES sentence
  /// puts the wallet before the amount, which hand-assembled spans would
  /// silently get wrong. It also guarantees the in-app row and the OS popup
  /// read verbatim identically.
  List<InlineSpan> _describeTransfer(
    NotifItem item,
    TextSpan Function(String) b,
    TextSpan Function(String) t,
  ) {
    final e = item.event;
    final sentence = notifSentence(
      item,
      context.l10n,
      isSelf: _isSelf,
      nameOf: _name,
      walletNameOf: _walletName,
      counterpartyNameOf: _counterpartyNameByWallet,
    );

    // Two decorations, applied to whatever the localized sentence turned out to
    // be: the amount (always present) and the counterparty's name (only when
    // they're a PublicOS account — otherwise there IS no name in the sentence).
    final amount = transferAmountText(e);
    final contact = _counterpartyContact(e);
    final cpName = contact == null
        ? null
        : (contact.publicosDisplayName ?? contact.displayName).trim();

    final marks = <_Mark>[
      _Mark(amount, bold: true),
      if (cpName != null && cpName.isNotEmpty)
        _Mark(cpName, bold: true, avatar: contact),
    ];
    return _decorate(sentence, marks, b, t);
  }

  /// Splice [marks] into [sentence], preserving the sentence's own word order.
  /// A mark carrying an avatar gets a 16px [GlassContactIcon] as a `WidgetSpan`
  /// immediately before it — the same inline-avatar pattern as
  /// `group_event_line.dart::_person`, including its rule: **no contact, no
  /// icon** (never fall back to an address-derived identicon, which would imply
  /// an identity we haven't verified).
  List<InlineSpan> _decorate(
    String sentence,
    List<_Mark> marks,
    TextSpan Function(String) b,
    TextSpan Function(String) t,
  ) {
    // Locate each mark in the sentence; drop any that isn't there.
    final hits = <({int start, _Mark mark})>[];
    for (final m in marks) {
      final i = sentence.indexOf(m.text);
      if (i >= 0) hits.add((start: i, mark: m));
    }
    if (hits.isEmpty) return [t(sentence)];
    hits.sort((x, y) => x.start.compareTo(y.start));

    final out = <InlineSpan>[];
    var cursor = 0;
    for (final h in hits) {
      if (h.start < cursor) continue; // overlapping match — skip
      if (h.start > cursor) out.add(t(sentence.substring(cursor, h.start)));
      if (h.mark.avatar != null) {
        out.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.only(right: 4),
            child: GlassContactIcon(contact: h.mark.avatar, size: 16),
          ),
        ));
      }
      out.add(h.mark.bold ? b(h.mark.text) : t(h.mark.text));
      cursor = h.start + h.mark.text.length;
    }
    if (cursor < sentence.length) out.add(t(sentence.substring(cursor)));
    return out;
  }
}

/// A substring of the sentence to decorate — bolded, and optionally preceded by
/// an inline avatar.
class _Mark {
  final String text;
  final bool bold;
  final Contact? avatar;
  const _Mark(this.text, {this.bold = false, this.avatar});
}

class _NotifRow extends StatelessWidget {
  final ActivityEvent event;
  final GlassTokens tokens;

  /// The row's identity mark. For a contract-event row this is the actor's
  /// contact avatar; for a **wallet-transfer** row it is the user's OWN wallet
  /// — the mark the Wallet tab shows for it — because the wallet, not the
  /// counterparty, is the subject of the notification.
  final Widget leading;

  final List<InlineSpan> spans;
  final bool unread;
  final VoidCallback onTap;

  const _NotifRow({
    required this.event,
    required this.tokens,
    required this.leading,
    required this.spans,
    required this.unread,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: unread ? tokens.connectedAccent.withValues(alpha: 0.04) : null,
          border: Border(
            left: BorderSide(
              color: unread ? tokens.connectedAccent : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(13, 12, 16, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            leading,
            const SizedBox(width: 12),
            Expanded(
              child: Text.rich(
                TextSpan(
                  style: TextStyle(
                      color: tokens.textDim, fontSize: 13, height: 1.35),
                  children: spans,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              _relTime(event.timestamp, context),
              style: TextStyle(
                color: tokens.textDim,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _relTime(int ms, BuildContext context) {
    if (ms <= 0) return '';
    final d = DateTime.now()
        .difference(DateTime.fromMillisecondsSinceEpoch(ms));
    if (d.inMinutes < 1) return context.l10n.notificationsScreenRelTimeNow;
    if (d.inMinutes < 60) return '${d.inMinutes}m';
    if (d.inHours < 24) return '${d.inHours}h';
    if (d.inDays < 7) return '${d.inDays}d';
    return '${(d.inDays / 7).floor()}w';
  }
}
