import 'package:flutter/material.dart';
import 'package:publicos_core/publicos_core.dart';

import 'package:publicos_desktop/theme/glass_tokens.dart';
import 'package:publicos_desktop/utils/glass_sheet_dialog.dart';
import 'package:publicos_desktop/utils/notification_kinds.dart';

/// Per-type notification toggles. A Pattern-C picker/list sheet — pure rows,
/// no form, no primary action button. Body owns its own glass chrome +
/// SafeArea; `showPhigitalBottomSheet` is bypassed.
///
/// Persists each [NotifKind] via the settings extension (default ON). Toggles
/// are written immediately on change; the caller should re-read prefs after
/// this future completes (the sheet can be dismissed by scrim/drag, so there's
/// no reliable pop result to thread back).
Future<void> showNotificationPrefsSheet(BuildContext context) {
  return showGlassSheetDialog<void>(
    context: context,
    width: DialogWidth.l,
    builder: (_) => const _NotificationPrefsSheet(),
  );
}

/// Display grouping. Order within each group matches the taxonomy.
class _KindRow {
  final NotifKind kind;
  final String label;
  final String subtitle;
  const _KindRow(this.kind, this.label, this.subtitle);
}

const List<_KindRow> _profileGroup = [
  _KindRow(NotifKind.avatar, 'Avatar', 'When someone changes their avatar'),
  _KindRow(NotifKind.banner, 'Banner', 'When someone changes their banner'),
  _KindRow(NotifKind.bio, 'Bio', 'When someone updates their bio'),
  _KindRow(NotifKind.profile, 'Profile & cards',
      'Cards, links and other profile edits'),
  _KindRow(NotifKind.tabs, 'Tabs', 'When someone updates their tabs'),
];

const List<_KindRow> _networkGroup = [
  _KindRow(NotifKind.vouched, 'Vouches', 'When someone vouches'),
  _KindRow(NotifKind.citizenized, 'New citizens', 'When a private contact becomes a citizen'),
  // Hidden by product decision: "Rent paid" isn't surfaced. Kept (commented)
  // so the toggle returns with one uncomment.
  // _KindRow(NotifKind.domainPaid, 'Rent paid', 'When a contact pays their rent'),
  _KindRow(NotifKind.evicted, 'Evictions', 'When an account is evicted'),
  _KindRow(NotifKind.nameChanged, 'Name changes', 'When someone changes their name'),
  // Hidden by product decision: "Display names"
  // is the storage-layer twin of "Name changes" (a front-door rename fires both).
  // Kept (commented) so the toggle returns with one uncomment.
  // _KindRow(NotifKind.displayName, 'Display names',
  //     'When someone changes their display name'),
];

/// Token transfers touching the user's own wallets — their personal main Safe,
/// each org main Safe they belong to, and every keychain key toggled "show in
/// wallet". Never throttled: two payments are two facts.
const List<_KindRow> _walletGroup = [
  _KindRow(NotifKind.transferIn, 'Money received',
      'When funds arrive in one of your wallets'),
  _KindRow(NotifKind.transferOut, 'Money sent',
      'When funds leave one of your wallets'),
  _KindRow(NotifKind.transferSelf, 'Between your wallets',
      'When you move funds between your own wallets'),
];

/// Social events from any registered SSP, delivered by the account's home.
/// Reactions are OFF by default.
/// The toggles also write the `kinds` filter on the official push target at
/// the home, so a kind switched off here is never pushed to the phone.
const List<_KindRow> _socialGroup = [
  _KindRow(NotifKind.comment, 'Comments', 'When someone comments on your post'),
  _KindRow(NotifKind.reply, 'Replies', 'When someone replies to your comment'),
  _KindRow(NotifKind.mention, 'Mentions', 'When someone mentions you'),
  _KindRow(NotifKind.reaction, 'Reactions',
      'When someone reacts to your post or comment'),
  _KindRow(NotifKind.followRequest, 'Follow requests',
      'When someone asks to follow a private channel'),
  _KindRow(NotifKind.followApproved, 'Approved requests',
      'When a channel owner lets you in'),
];

class _NotificationPrefsSheet extends StatefulWidget {
  const _NotificationPrefsSheet();

  @override
  State<_NotificationPrefsSheet> createState() =>
      _NotificationPrefsSheetState();
}

class _NotificationPrefsSheetState extends State<_NotificationPrefsSheet> {
  Set<NotifKind> _enabled = {};
  bool _chainOn = false; // master switch — background on-chain popups
  bool _socialOn = true; // master switch — social events from the home SSP
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final enabled = await loadEnabledNotifKinds();
    final chainOn = await PublicOSSettings.getChainNotifications();
    final socialOn = await PublicOSSettings.getSocialNotifications();
    if (!mounted) return;
    setState(() {
      _enabled = enabled;
      _chainOn = chainOn;
      _socialOn = socialOn;
      _loading = false;
    });
  }

  /// Social master toggle: gates the inbox pull (the shared worker's social
  /// half) and flips `enabled` on the official target at the home, so the
  /// home stops pushing at the source. Best effort on the server half.
  Future<void> _toggleSocial(bool on) async {
    setState(() => _socialOn = on);
    await PublicOSSettings.setSocialNotifications(on);
    try {
      await PublicOSPush.putNotifTarget(enabled: on, registerDevice: false);
    } catch (_) {
      // Offline or no home yet: the local switch still applies; the next boot
      // registration carries the flag.
    }
  }

  /// Master toggle — registers/cancels the background sweep (and seeds the
  /// cursor on enable). Same flag as the Settings → Chain notifications row.
  Future<void> _toggleChain(bool on) async {
    setState(() => _chainOn = on);
    await PublicOSSettings.setChainNotifications(on);
  }

  Future<void> _toggle(NotifKind k, bool on) async {
    setState(() {
      if (on) {
        _enabled.add(k);
      } else {
        _enabled.remove(k);
      }
    });
    await setNotifKindEnabled(k, on);
    if (kSocialKinds.contains(k)) {
      try {
        await PublicOSPush.putNotifTarget(
          kinds: {kSocialWire[k]!: on},
          registerDevice: false,
        );
      } catch (_) {
        // Same as the master row: local filter applies now, the server
        // filter at the next boot registration.
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final maxHeight = MediaQuery.of(context).size.height * 0.7;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: tokens.background,
        borderRadius: BorderRadius.circular(20),
        border: Border(top: BorderSide(color: tokens.borderSubtle)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(
                children: [
                  Icon(Icons.tune_rounded,
                      size: 18, color: tokens.connectedAccent),
                  const SizedBox(width: 10),
                  Text(
                    'Notification types',
                    style: TextStyle(
                      color: tokens.starkWhite,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            if (_loading)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: tokens.connectedAccent,
                  ),
                ),
              )
            else
              Flexible(
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 12),
                  shrinkWrap: true,
                  children: [
                    _masterRow(
                      tokens,
                      icon: Icons.forum_outlined,
                      title: 'Social notifications',
                      subtitle:
                          'Replies, comments, mentions and follow requests from any server',
                      value: _socialOn,
                      onChanged: _toggleSocial,
                    ),
                    _groupHeader(tokens, 'Social activity'),
                    for (final r in _socialGroup) _row(tokens, r),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                      child: Divider(height: 1, color: tokens.borderSubtle),
                    ),
                    _masterRow(
                      tokens,
                      icon: Icons.hub_outlined,
                      title: 'Chain notifications',
                      subtitle:
                          'Get notified of on-chain events while the app is closed',
                      value: _chainOn,
                      onChanged: _toggleChain,
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                      child: Divider(height: 1, color: tokens.borderSubtle),
                    ),
                    _groupHeader(tokens, 'Profile activity'),
                    for (final r in _profileGroup) _row(tokens, r),
                    _groupHeader(tokens, 'Network activity'),
                    for (final r in _networkGroup) _row(tokens, r),
                    _groupHeader(tokens, 'Wallet activity'),
                    for (final r in _walletGroup) _row(tokens, r),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _masterRow(
    GlassTokens tokens, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: tokens.connectedAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: tokens.starkWhite,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(color: tokens.textDim, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: tokens.connectedAccent,
          ),
        ],
      ),
    );
  }

  Widget _groupHeader(GlassTokens tokens, String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: tokens.textDim,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _row(GlassTokens tokens, _KindRow r) {
    final on = _enabled.contains(r.kind);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.label,
                  style: TextStyle(
                    color: tokens.starkWhite,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  r.subtitle,
                  style: TextStyle(color: tokens.textDim, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: on,
            onChanged: (v) => _toggle(r.kind, v),
            activeThumbColor: tokens.connectedAccent,
          ),
        ],
      ),
    );
  }
}
