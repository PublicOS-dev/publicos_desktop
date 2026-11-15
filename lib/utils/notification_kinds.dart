import 'package:publicos_core/publicos_core.dart';
import 'package:publicos_desktop/data/chain_registry.dart';
import 'package:publicos_desktop/l10n/app_localizations.dart';

/// Resolves an address to a human label, or null when it isn't known.
typedef AddrLabel = String? Function(String addrHex);

/// Notification taxonomy for the on-chain activity feed.
///
/// Pure functions (no widget / no service) shared by the notifications screen
/// (the list) and the explorer app-bar bell (the unread count), so the badge
/// can never disagree with what the list shows. Filtering, the 24h throttle,
/// and the per-type toggles all live here.
///
/// Policy: this client surfaces only
/// PROFILE record edits (avatar/banner/bio/cards/links) + tab edits, plus the
/// discrete life events (vouch/citizenship/rent/eviction/name/display-name).
/// SETTINGS/CUSTOM/SYSTEM records, profile.color, profile.status, router rss,
/// and the bonus-name grant are deliberately never shown — other clients may
/// choose differently, which is why this is client-side, not in Core.
enum NotifKind {
  // Profile-edit kinds — throttled (per actor, one per 24h).
  avatar,
  banner,
  bio,
  profile, // cards + social links + any other PROFILE key
  tabs,
  // Discrete life events — not throttled, each is meaningful on its own.
  vouched,
  citizenized,
  domainPaid,
  evicted,
  nameChanged,
  displayName,
  // Wallet transfers (PublicOSWalletActivity) — never throttled. Money is not
  // a profile edit: two payments of the same size from the same sender are two
  // separate facts, and collapsing them would hide one.
  transferIn,
  transferOut,
  transferSelf,
  // Social events: a reply, a comment, a mention, a
  // reaction or a follow request on any registered SSP, delivered by the
  // account's HOME SSP (a push on the phone, the 15-min inbox pull, the
  // desktop's 10-min sweep). Never throttled: each is its own fact, and the
  // home already dedups by notification id.
  comment,
  reply,
  mention,
  reaction,
  followRequest,
  followApproved,
}

/// The edit kinds that collapse under the 24h-per-actor throttle. Life events
/// and transfers are excluded — a vouch, an eviction, or a payment is always
/// worth its own row.
const Set<NotifKind> _throttledKinds = {
  NotifKind.avatar,
  NotifKind.banner,
  NotifKind.bio,
  NotifKind.profile,
  NotifKind.tabs,
};

/// The wallet-transfer kinds — grouped in the prefs sheet, and the kinds whose
/// tap opens the Wallet tab rather than a profile.
const Set<NotifKind> kWalletKinds = {
  NotifKind.transferIn,
  NotifKind.transferOut,
  NotifKind.transferSelf,
};

/// The social kinds — grouped in the prefs sheet under their own master row,
/// and the kinds whose tap opens the POST (`item_url`) rather than a profile.
const Set<NotifKind> kSocialKinds = {
  NotifKind.comment,
  NotifKind.reply,
  NotifKind.mention,
  NotifKind.reaction,
  NotifKind.followRequest,
  NotifKind.followApproved,
};

/// NotifKind ↔ the wire spelling (`SocialNotificationKind`, the home's
/// `kinds` filter on the official target, the `social_<kind>` row slug).
const Map<NotifKind, String> kSocialWire = {
  NotifKind.comment: SocialNotificationKind.comment,
  NotifKind.reply: SocialNotificationKind.reply,
  NotifKind.mention: SocialNotificationKind.mention,
  NotifKind.reaction: SocialNotificationKind.reaction,
  NotifKind.followRequest: SocialNotificationKind.followRequest,
  NotifKind.followApproved: SocialNotificationKind.followApproved,
};

NotifKind? socialKindOf(String wire) {
  for (final e in kSocialWire.entries) {
    if (e.value == wire) return e.key;
  }
  return null;
}

/// The `kinds` map the home keeps on the official target: which social kinds
/// this account wants pushed. The per-kind toggles write it; the home then
/// never pushes a kind the device would drop (iOS can't drop a push).
Map<String, bool> socialKindsMap(Set<NotifKind> enabled) => {
      for (final k in kSocialKinds) kSocialWire[k]!: enabled.contains(k),
    };

/// A social row's post permalink, and the item inside it (the post itself, or
/// `<post>#comment-<uid>`), as the hosting server wrote them.
String socialPostUrl(ActivityEvent e) => '${e.data['post_url'] ?? ''}';
String socialItemUrl(ActivityEvent e) => '${e.data['item_url'] ?? ''}';

/// True when the item is a comment (a reaction on a comment says "your
/// comment").
bool socialItemIsComment(ActivityEvent e) =>
    socialItemUrl(e).contains('#comment-');

const Duration kNotifThrottleWindow = Duration(hours: 24);

/// Settings key for a kind's on/off toggle (UI-layer concern; uses Core's
/// generic getSetting/setSetting, mirrors video_overlay_muted). Default ON.
String notifPrefKey(NotifKind k) => 'notif_kind_${k.name}';

/// RecordType enum ordinals (mirror of contracts/libraries/Record.sol).
const int _kRecordTypeProfile = 0;
const int _kRecordTypeRouter = 2;

/// A displayable notification: the underlying event plus its resolved kind.
class NotifItem {
  final ActivityEvent event;
  final NotifKind kind;
  const NotifItem(this.event, this.kind);

  bool get isRead => event.isRead;
}

/// Maps an [ActivityEvent] to its [NotifKind], or null if this client never
/// shows it (the filter). The `key` string is the precise profile-field
/// discriminator; `recordType`/`customType` gate tabs vs the rest.
NotifKind? kindOf(ActivityEvent e) {
  if (ActivityEventType.isSocial(e.eventType)) {
    return socialKindOf(ActivityEventType.socialKind(e.eventType));
  }
  switch (e.eventType) {
    case ActivityEventType.vouched:
      return NotifKind.vouched;
    case ActivityEventType.citizenized:
      return NotifKind.citizenized;
    // Hidden by product decision: "paid rent"
    // isn't shown. Kept (Core also stops sweeping it) so it's a 1-line re-enable;
    // NotifKind.domainPaid + its copy/toggle stay dormant. Falls to default null.
    // case ActivityEventType.domainPaid:
    //   return NotifKind.domainPaid;
    case ActivityEventType.evicted:
      return NotifKind.evicted;
    case ActivityEventType.nameChanged:
      return NotifKind.nameChanged;
    // Hidden by product decision: a front-door
    // changeName already fires NameChanged; DisplayNameSet is the storage-layer
    // twin (+ account creation / root rename), so it's redundant/odd. Kept (Core
    // also stops sweeping it); NotifKind.displayName + copy stay dormant → null.
    // case ActivityEventType.displayNameSet:
    //   return NotifKind.displayName;
    case ActivityEventType.recordSet:
      return _recordKind(e);
    // Wallet transfers — swept by PublicOSWalletActivity into the same table.
    case ActivityEventType.transferIn:
      return NotifKind.transferIn;
    case ActivityEventType.transferOut:
      return NotifKind.transferOut;
    case ActivityEventType.transferSelf:
      return NotifKind.transferSelf;
    // bonusNameChangeGranted + anything unknown → hidden.
    default:
      return null;
  }
}

/// Resolve the token behind a transfer event and format its raw amount —
/// "5 OX", "12.5 USDC".
///
/// The registry (`kChainRegistry`) is the single source of `decimals`, which is
/// load-bearing: a raw amount is meaningless without it, and hardcoding 18
/// would silently mis-render a 6-decimal token by 10^12. OX's registry entry
/// carries a **null address** (the chain mints it, so the address resolves at
/// runtime from the ModuleRegistry) — hence the address lookup falls back to
/// the chain's default token rather than failing.
String transferAmountText(ActivityEvent e) {
  final chainId = _asInt(e.data['chainId']) ?? kOxChainId;
  final tokenAddr = e.data['token'] as String?;
  final raw = BigInt.tryParse('${e.data['rawAmount'] ?? ''}') ?? BigInt.zero;

  final chain = chainById(chainId);
  final token = (tokenAddr != null ? tokenForAddress(chainId, tokenAddr) : null) ??
      chain?.defaultToken;
  if (token == null) return raw.toString();

  return PublicOSWallets.formatTokenAmount(
    raw,
    token.decimals,
    symbol: token.symbol,
  );
}

/// The user's own wallet this transfer concerns (Core stamps it into `data`).
/// Falls back to the direction-implied side if an older row predates the field.
String transferWalletAddress(ActivityEvent e) {
  final w = e.data['wallet'] as String?;
  if (w != null && w.isNotEmpty) return w;
  return e.eventType == ActivityEventType.transferIn
      ? (e.target ?? e.actor)
      : e.actor;
}

/// The OTHER end's **PublicOS account** — reverse-resolved by Core at sweep time
/// from the wallet address (a main Safe, or a linked EOA). Null when the other
/// end isn't a PublicOS account at all: a bare EOA, a contract, or `address(0)`
/// on a mint/burn.
///
/// **This is the icon gate.** No account ⇒ no avatar, show the bare address.
/// Always null for a self-transfer (both ends are the user's).
String? transferCounterpartyAccount(ActivityEvent e) {
  final a = e.data['counterpartyAccount'] as String?;
  return (a != null && a.isNotEmpty) ? a : null;
}

/// The other end's raw WALLET address (not its account). Null for a self-move.
String? transferCounterpartyWallet(ActivityEvent e) {
  switch (e.eventType) {
    case ActivityEventType.transferIn:
      return e.actor; // from
    case ActivityEventType.transferOut:
      return e.target; // to
    default:
      return null; // transferSelf — both ends are the user's own
  }
}

String shortAddr(String hex) =>
    hex.length <= 10 ? hex : '${hex.substring(0, 6)}…${hex.substring(hex.length - 4)}';

NotifKind? _recordKind(ActivityEvent e) {
  final rt = _asInt(e.data['recordType']);
  final key = (e.data['key'] as String? ?? '').toLowerCase();
  final custom = (e.data['customType'] as String? ?? '').toLowerCase();

  // ROUTER: only tabs surface; rss (and anything else) is hidden.
  if (rt == _kRecordTypeRouter) {
    return custom == 'tab' ? NotifKind.tabs : null;
  }
  // Everything else must be PROFILE; SETTINGS/CUSTOM/SYSTEM are hidden.
  if (rt != _kRecordTypeProfile) return null;

  switch (key) {
    case 'profile.avatar':
      return NotifKind.avatar;
    case 'profile.banner':
      return NotifKind.banner;
    case 'profile.bio':
      return NotifKind.bio;
    case 'profile.color': // deliberately excluded
    case 'profile.status': // no status feature
      return null;
    default:
      // cards (card.*), social links (com.twitter, url, email, ...), and any
      // other profile key collapse into the generic "updated their profile".
      return NotifKind.profile;
  }
}

int? _asInt(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse('$v');
}

/// Turn the raw, newest-first stored events into the display list: drop hidden
/// kinds, drop toggled-off kinds, then collapse throttled kinds to one per
/// (actor, kind) per [kNotifThrottleWindow]. Input MUST be newest-first
/// (PublicOSActivity.getStored already returns that), so the kept row of a
/// burst is the most recent.
List<NotifItem> buildNotifications(
  List<ActivityEvent> events,
  Set<NotifKind> enabled,
) {
  final out = <NotifItem>[];
  final lastKeptMs = <String, int>{}; // "actor|kind" -> ts of last kept row
  for (final e in events) {
    final kind = kindOf(e);
    if (kind == null) continue;
    if (!enabled.contains(kind)) continue;

    if (_throttledKinds.contains(kind)) {
      final bucket = '${e.actor.toLowerCase()}|${kind.name}';
      final prev = lastKeptMs[bucket];
      if (prev != null &&
          (prev - e.timestamp).abs() <= kNotifThrottleWindow.inMilliseconds) {
        continue; // within 24h of a kept row of the same (actor, kind)
      }
      lastKeptMs[bucket] = e.timestamp;
    }
    out.add(NotifItem(e, kind));
  }
  return out;
}

/// Unread count over an already-built display list (drives the bell badge).
int unreadNotifCount(List<NotifItem> items) =>
    items.where((i) => !i.isRead).length;

/// Reads every kind's toggle from the settings extension (default ON when the
/// key is absent, except reactions: OFF by default). One DB read per kind —
/// cheap, contact-scoped data.
Future<Set<NotifKind>> loadEnabledNotifKinds() async {
  final enabled = <NotifKind>{};
  for (final k in NotifKind.values) {
    var on = k != NotifKind.reaction;
    try {
      final rec = await PublicOSSettings.getSetting(notifPrefKey(k));
      if (rec != null) on = rec.value != 'false';
    } catch (_) {
      // best-effort: a failed read defaults the kind ON.
    }
    if (on) enabled.add(k);
  }
  return enabled;
}

/// Plain-text sentence for an OS notification body (the background chain
/// worker in main.dart::runChainNotificationSync). [isSelf]/[nameOf] resolve
/// the actor/target to "You" or a display name (caller wires them to the
/// contact cache).
///
/// Localized: the headless background isolate (main.dart) loads
/// [AppLocalizations] via `delegate.load(locale)` and passes it in — there is
/// no `BuildContext` in the popup worker.
///
/// IMPORTANT: keep the phrasing in sync with
/// notifications_screen.dart::_describe — the styled-span twin for the in-app
/// feed (still English; localize it from these same `notif*` keys as a
/// follow-up). This is the plain-string twin for OS popups.
String notifSentence(
  NotifItem item,
  AppLocalizations l10n, {
  required bool Function(String addrHex) isSelf,
  required String Function(String addrHex) nameOf,
  AddrLabel? walletNameOf,
  AddrLabel? counterpartyNameOf,
}) {
  final e = item.event;
  final you = isSelf(e.actor);
  final actor = nameOf(e.actor);

  // Wallet transfers name WALLETS, not accounts — a Safe address is not a
  // contact address, so `nameOf` (the contact resolver) can't label them.
  // The caller passes resolvers built from its own-wallet list.
  if (kWalletKinds.contains(item.kind)) {
    final amount = transferAmountText(e);
    String wallet(String hex) => walletNameOf?.call(hex) ?? shortAddr(hex);
    final from = e.actor;
    final to = e.target ?? e.actor;

    switch (item.kind) {
      case NotifKind.transferIn:
        final sender = counterpartyNameOf?.call(from);
        return sender != null
            ? l10n.notifTransferInFrom(sender, amount, wallet(to))
            : l10n.notifTransferIn(amount, wallet(to));
      case NotifKind.transferOut:
        final recipient = counterpartyNameOf?.call(to);
        return recipient != null
            ? l10n.notifTransferOutTo(amount, wallet(from), recipient)
            : l10n.notifTransferOut(amount, wallet(from));
      case NotifKind.transferSelf:
        return l10n.notifTransferSelf(amount, wallet(from), wallet(to));
      default:
        break; // unreachable — kWalletKinds is exactly the three above
    }
  }

  switch (item.kind) {
    case NotifKind.avatar:
      return you ? l10n.notifAvatarYou : l10n.notifAvatarThey(actor);
    case NotifKind.banner:
      return you ? l10n.notifBannerYou : l10n.notifBannerThey(actor);
    case NotifKind.bio:
      return you ? l10n.notifBioYou : l10n.notifBioThey(actor);
    case NotifKind.profile:
      return you ? l10n.notifProfileYou : l10n.notifProfileThey(actor);
    case NotifKind.tabs:
      return you ? l10n.notifTabsYou : l10n.notifTabsThey(actor);
    case NotifKind.vouched:
      final target = e.target ?? e.actor;
      if (isSelf(target)) return l10n.notifVouchedYou(actor);
      if (you) return l10n.notifVouchedByYou(nameOf(target));
      return l10n.notifVouchedOther(actor, nameOf(target));
    case NotifKind.citizenized:
      return you ? l10n.notifCitizenYou : l10n.notifCitizenThey(actor);
    case NotifKind.domainPaid:
      final m = int.tryParse('${e.data['months'] ?? ''}') ?? 0;
      return you ? l10n.notifRentYou(m) : l10n.notifRentThey(actor, m);
    case NotifKind.evicted:
      return you ? l10n.notifEvictedYou : l10n.notifEvictedThey(actor);
    case NotifKind.nameChanged:
      final n = '${e.data['newName'] ?? ''}'.trim();
      if (you) {
        return n.isEmpty ? l10n.notifNameChangedYou : l10n.notifNameNowYou(n);
      }
      return n.isEmpty
          ? l10n.notifNameChangedThey(actor)
          : l10n.notifNameNowThey(actor, n);
    case NotifKind.displayName:
      final n = '${e.data['newName'] ?? ''}'.trim();
      if (you) {
        return n.isEmpty
            ? l10n.notifDisplayChangedYou
            : l10n.notifDisplayToYou(n);
      }
      return n.isEmpty
          ? l10n.notifDisplayChangedThey(actor)
          : l10n.notifDisplayToThey(actor, n);
    // Handled by the kWalletKinds branch above; listed only to keep the switch
    // exhaustive over NotifKind.
    case NotifKind.transferIn:
    case NotifKind.transferOut:
    case NotifKind.transferSelf:
      return transferAmountText(e);
    // Social events: the sentence is the app's, nothing textual rides the
    // wire. The actor is never the user (rule 1 at the hosting
    // server), so there is no "You" form.
    case NotifKind.comment:
      return l10n.notifComment(actor);
    case NotifKind.reply:
      return l10n.notifReply(actor);
    case NotifKind.mention:
      return l10n.notifMention(actor);
    case NotifKind.reaction:
      return socialItemIsComment(e)
          ? l10n.notifReactionComment(actor)
          : l10n.notifReactionPost(actor);
    case NotifKind.followRequest:
      return l10n.notifFollowRequest(actor);
    case NotifKind.followApproved:
      return l10n.notifFollowApproved(actor);
  }
}

/// Persists a single kind's toggle. Best-effort (mirrors video_controls_pill).
Future<void> setNotifKindEnabled(NotifKind k, bool enabled) async {
  try {
    final rec = Record.asSettings(
      key: notifPrefKey(k),
      value: enabled.toString(),
      isSystem: true,
      isExpired: false,
      expiration: DateTime.now().add(const Duration(days: 3650)),
    );
    await PublicOSSettings.setSetting(notifPrefKey(k), rec);
  } catch (_) {
    // swallow — the in-session toggle still applied.
  }
}
