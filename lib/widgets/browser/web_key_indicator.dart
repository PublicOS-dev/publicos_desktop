import 'package:flutter/material.dart';
import 'package:publicos_core/publicos_core.dart'; // PublicOS, PublicOSKeychain
import 'package:publicos_web3_bridge/publicos_web3_bridge.dart'
    show ConnectGate, WalletKey;

import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/router.dart'; // AppStateNotifier
import 'package:publicos_desktop/widgets/browser/chain_picker_sheet.dart';
import 'package:publicos_desktop/widgets/chain_icon.dart';
import 'package:publicos_desktop/data/chain_registry.dart';
import 'package:publicos_desktop/widgets/browser/site_keys_sheet.dart';

/// The web-key indicator — the VISIBLE CONSEQUENCE OF A GRANT.
///
/// Ported from publicos_client `components/browser/web_key_indicator.dart`.
/// Same semantics, verbatim where it could be: it is a pure
/// function of grant state and exists on screen ONLY when the displayed page
/// holds a grant ([connected], driven by the host from the bridge's connect
/// events). No grant → nothing in the cluster.
///
/// **Why it shows no name:** permission is a SET of keys,
/// so there is no single name to print: showing the first would claim a site
/// sees one key when it may see three. The glyph answers the only question the
/// chrome should: *is this site connected?* Which keys, and whether to change
/// them, is one tap away.
///
/// **Still an indicator, not a verdict.** It states connectedness, never
/// whether a key is linked to an account. That judgement is left out on
/// purpose; the signature consumer adjudicates. Do not add it here.
///
/// ── DESKTOP DELTAS, and why each one is forced ──────────────────────────────
///
/// 1. **It lives in the deck's button cluster, not an address bar.** Desktop
///    has no address bar; the cluster is where per-tab actions live
///    (profile QR/share, channel follow, chat gear), so it is the
///    same slot in a different chrome.
/// 2. **Every colour is passed in, none are read from tokens.** The client's
///    glyph sits on a dark app bar and can hold `starkWhite` outright. This one
///    sits on the browsed contact's own colour swatch and, once the
///    banner docks, on their photograph — so it takes [accent] from
///    `_DeckPalette`/`_GlassPill` like every other glyph up there. A fixed
///    light-on-dark token would vanish on a pale swatch.
/// 3. **No `HapticFeedback`** on tap — desktop.
/// 4. **Tap opens the SITE's keys**, not the keychain dialog. Permission is
///    per-site, and the keychain carries delete/export/rename, which must
///    never sit one mis-click from a permission checkbox. [foreground] is
///    therefore unused by the glyph-only chip and kept only so the deck's call
///    site does not have to change shape.
class WebKeyIndicator extends StatefulWidget {
  /// Whether the displayed page holds any grant. The host (`browser.dart`)
  /// drives this from the webview's connect events. false → the widget renders
  /// nothing.
  final bool connected;
  final Uri? origin;
  final Color accent;
  final Color foreground;

  /// The address the page sees first (`accounts[0]`), from the gate's
  /// `onActiveAccountChanged`. The chip shows that key's emoji, so the icon
  /// says WHICH key a site is using, not just that one is. Null → the plain
  /// key glyph.
  final String? activeAddress;

  /// The host's grants revision. The chip re-reads its counts when this
  /// moves, which covers the case [activeAddress] cannot: a key added to or
  /// removed from the site while `accounts[0]` stays the same.
  final int grantsRevision;

  /// The picker changed this site's permission or active key; the host bumps
  /// its grants revision so the running page is re-evaluated.
  final VoidCallback? onGrantsChanged;

  /// The chain THIS TAB is on, `0x`-prefixed — from the page's own
  /// `ChainRegistry` via the host. Drives the corner badge; null hides it.
  final String? chainId;

  /// The user picked another chain from the badge. The host owns what happens
  /// next (switch the tab's registry, reload the page) because the registry
  /// belongs to the webview, not to the address bar.
  final ValueChanged<String>? onChainSelected;

  const WebKeyIndicator({
    super.key,
    required this.connected,
    required this.accent,
    required this.foreground,
    this.origin,
    this.activeAddress,
    this.grantsRevision = 0,
    this.onGrantsChanged,
    this.chainId,
    this.onChainSelected,
  });

  @override
  State<WebKeyIndicator> createState() => _WebKeyIndicatorState();
}

class _WebKeyIndicatorState extends State<WebKeyIndicator> {
  bool _busy = false;

  /// Emoji and display name of [WebKeyIndicator.activeAddress], plus how many
  /// keys this site can see — the chip reads `[emoji] name · N visible`
  /// (desktop only: the deck has room for the answer, the mobile
  /// chip does not). Resolved when the address, origin or grants revision
  /// changes — never per build, since [_availableKeys] reads every key's
  /// secure-storage entry.
  String? _activeEmoji;
  String? _activeName;
  int _visibleCount = 0;

  @override
  void initState() {
    super.initState();
    _refreshChip();
  }

  @override
  void didUpdateWidget(covariant WebKeyIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeAddress != widget.activeAddress ||
        oldWidget.origin != widget.origin ||
        oldWidget.connected != widget.connected ||
        oldWidget.grantsRevision != widget.grantsRevision) {
      _refreshChip();
    }
  }

  Future<void> _refreshChip() async {
    final wanted = widget.activeAddress?.toLowerCase();
    final origin = widget.origin;
    if (wanted == null || origin == null || !widget.connected) {
      if (mounted && (_activeEmoji != null || _visibleCount != 0)) {
        setState(() {
          _activeEmoji = null;
          _activeName = null;
          _visibleCount = 0;
        });
      }
      return;
    }
    try {
      final keys = await _availableKeys();
      final match = keys.where((k) => k.address.toLowerCase() == wanted);
      final key = match.isEmpty ? null : match.first;
      final visible = await PublicOS.database.listGrantsForOrigin(
        origin: ConnectGate.originKey(origin),
        session: _sessionScope,
      );
      if (!mounted) return;
      // The session key's label is `null`/`'session'` on the wire; it shows as
      // the account's display name, exactly as the picker rows spell it.
      final name = key == null
          ? null
          : (key.isSessionKey
              ? (AppStateNotifier.currentMyContact?.displayName ??
                  context.l10n.connectRequestSheetSessionKey)
              : key.label);
      final emoji = key == null ? null : (key.emoji ?? '🔑');
      if (emoji != _activeEmoji ||
          name != _activeName ||
          visible.length != _visibleCount) {
        setState(() {
          _activeEmoji = emoji;
          _activeName = name;
          _visibleCount = visible.length;
        });
      }
    } catch (e) {
      debugPrint('[web3] could not resolve the active key chip: $e');
    }
  }

  String? get _userAddress =>
      AppStateNotifier.currentMyContact?.publicosAddress?.eip55With0x;

  String get _sessionScope =>
      (PublicOS.sessionBlockchainAddress ?? '').toLowerCase();

  /// Open the site's key permissions.
  ///
  /// Reads and writes through Core directly rather than through the running
  /// `ConnectGate`: the gate lives inside the webview's state and this widget
  /// sits in the deck above it. The two agree because they share the one
  /// authority that matters — the grant rows, keyed by [ConnectGate.originKey]
  /// — and the host tells the webview to re-read after this returns.
  Future<void> _openPicker() async {
    final origin = widget.origin;
    final scope = _sessionScope;
    if (origin == null || scope.isEmpty || _busy) return;

    setState(() => _busy = true);
    try {
      final originKey = ConnectGate.originKey(origin);
      final granted = await PublicOS.database
          .listGrantsForOrigin(origin: originKey, session: scope);
      final keys = await _availableKeys();
      final preferred = await _preferredAddress();
      final activeBefore = await PublicOS.database
          .siteActiveKey(origin: originKey, session: scope);
      if (!mounted) return;

      final result = await SiteKeysSheet.show(
        context: context,
        origin: originKey,
        keys: keys,
        alreadyGranted: granted.map((e) => e.toLowerCase()).toSet(),
        preferred: preferred,
        activeKey: activeBefore,
        sessionKeyName: AppStateNotifier.currentMyContact?.displayName ??
            context.l10n.connectRequestSheetSessionKey,
        currentChainId: widget.chainId,
      );
      // null is a dismissal and changes nothing. An EMPTY visible set is the
      // disconnect gesture and must still be applied.
      if (result == null) return;
      final decision = result.decision;

      final want = decision.visible.map((e) => e.toLowerCase()).toSet();
      final have = granted.map((e) => e.toLowerCase()).toSet();
      final byAddress = {for (final k in keys) k.address: k};

      for (final eoa in want.difference(have)) {
        await PublicOS.database.grantSite(
          origin: originKey,
          session: scope,
          eoa: eoa,
          keyLabel: byAddress[eoa]?.label,
        );
      }
      for (final eoa in have.difference(want)) {
        await PublicOS.database
            .revokeSite(origin: originKey, session: scope, eoa: eoa);
      }
      // The site's active choice rides on a grant row, so it is written AFTER
      // the grants and only inside the visible set.
      final active = decision.activeKey?.toLowerCase();
      if (active != null && want.contains(active)) {
        await PublicOS.database
            .setSiteActiveKey(origin: originKey, session: scope, eoa: active);
      } else {
        await PublicOS.database
            .clearSiteActiveKey(origin: originKey, session: scope);
      }
      final grantsChanged =
          want.length != have.length || !want.containsAll(have);
      if (grantsChanged || active != activeBefore?.toLowerCase()) {
        widget.onGrantsChanged?.call();
      }
      // The chain LAST, because switching reloads the page: doing it before
      // the grant writes above would race a fresh injection against
      // half-written permissions.
      final chainId = result.chainId;
      if (chainId != null) widget.onChainSelected?.call(chainId);
      await _refreshChip();
    } catch (e) {
      debugPrint('[web3] site keys picker failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Session key first (it is not in `fetchKeys`), then the keychain. Same order
  /// the bridge's own binding builds, and it decides `accounts[0]` when no
  /// preference applies.
  Future<List<WalletKey>> _availableKeys() async {
    final session = PublicOS.sessionBlockchainAddress;
    final keys = <WalletKey>[
      if (session != null && session.isNotEmpty)
        WalletKey(label: 'session', address: session),
    ];
    final user = _userAddress;
    if (user == null) return keys;
    for (final k in await PublicOSKeychain.fetchKeys(user)) {
      final address = (k['address'] ?? '') as String;
      if (address.isEmpty || address == 'Unknown') continue;
      keys.add(WalletKey(
        label: k['label'] as String,
        address: address,
        emoji: k['emoji'] as String?,
      ));
    }
    return keys;
  }

  Future<String?> _preferredAddress() async {
    final user = _userAddress;
    if (user == null) return PublicOS.sessionBlockchainAddress?.toLowerCase();
    final addr = await PublicOSKeychain.getWebSelectedAddress(user);
    return (addr == null || addr.isEmpty) ? null : addr.toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.connected) return const SizedBox.shrink();

    final chainId = chainIdFromHex(widget.chainId);

    return Tooltip(
      message: context.l10n.webKeyIndicatorTooltip,
      waitDuration: const Duration(milliseconds: 400),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _openPicker,
          child: Padding(
            padding: EdgeInsets.symmetric(
                horizontal: _activeName == null ? 0 : 6, vertical: 0),
            child: SizedBox(
              height: 28,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: _activeName == null ? 28 : 18,
                    child: _activeEmoji != null
                        ? Center(
                            child: Text(_activeEmoji!,
                                style:
                                    const TextStyle(fontSize: 15, height: 1)))
                        : Icon(Icons.key_outlined,
                            size: 16, color: widget.accent),
                  ),
                  if (_activeName != null) ...[
                    const SizedBox(width: 5),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 120),
                      child: Text(
                        _activeName!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'SpaceGrotesk',
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: widget.accent,
                        ),
                      ),
                    ),
                    // Only worth saying when there is a choice behind the
                    // active key — one visible key needs no count.
                    if (_visibleCount > 1) ...[
                      const SizedBox(width: 5),
                      Text(
                        '·',
                        style: TextStyle(
                            fontSize: 11, color: widget.foreground),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        context.l10n.desktopWebKeyVisibleCount(_visibleCount),
                        style: TextStyle(
                          fontFamily: 'SpaceGrotesk',
                          fontSize: 11,
                          color: widget.foreground,
                        ),
                      ),
                    ],
                  ],
                  // The chain mark sits at the very END of the cluster, after
                  // the name and the visible count — desktop has the width for
                  // a row, so the chip reads left-to-right as *who signs* then
                  // *where*: [key] name · N visible · [chain]. Mobile keeps the
                  // corner badge instead; a 28px chip has no room for a fourth
                  // element.
                  //
                  // ⚠ Informational — it does NOT open a picker. Chain
                  // selection lives in the Connected-keys sheet this whole chip
                  // opens, so the cluster keeps exactly one click target.
                  if (chainId != null) ...[
                    const SizedBox(width: 6),
                    // The dot only earns its place between two things; with no
                    // name resolved the cluster is just [key] [chain].
                    if (_activeName != null) ...[
                      Text('·',
                          style: TextStyle(
                              fontSize: 11, color: widget.foreground)),
                      const SizedBox(width: 6),
                    ],
                    NftChainIcon(chain: chainId, size: 14),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// ⚠ **PARKED, deliberately not deleted.** The standalone
  /// network sheet is not fired from anywhere — chain selection lives
  /// in the Connected-keys sheet. Kept whole, with its call site
  /// commented, in case the cluster ever wants its own picker back
  /// (`chain_picker_sheet.dart` is likewise kept and still compiles).
  // ignore: unused_element
  Future<void> _openChainPicker() async {
    if (_busy) return;
    final picked = await ChainPickerSheet.show(
      context: context,
      currentChainId: widget.chainId,
    );
    // null = dismissed, or the chain it was already on.
    if (picked != null) widget.onChainSelected?.call(picked);
  }
}
