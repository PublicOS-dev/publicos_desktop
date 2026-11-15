// Ported verbatim from publicos_client, with only the three mechanical
// import rewrites (components/->widgets/, pages/->screens/,
// glass_theme->glass_tokens).
// Presentation is deliberately duplicated between the two clients; the
// LOGIC behind these sheets is not -- it lives in publicos_web3_bridge and
// is shared.
//
// Still a bottom sheet, exactly as on mobile. Re-shelling it as a
// desktop dialog is a presentation change to make deliberately, not on
// the way past.
import 'package:flutter/material.dart';
import 'package:publicos_web3_bridge/publicos_web3_bridge.dart'
    show ConnectDecision, WalletKey;

import 'package:publicos_desktop/widgets/browser/site_keys_sheet.dart';
import 'package:publicos_desktop/widgets/chain_icon.dart';
import 'package:publicos_desktop/data/chain_registry.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';
import 'package:publicos_desktop/utils/glass_sheet_dialog.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';

/// The browser connect prompt — the door a page must pass through before it is
/// handed any of the user's addresses.
///
/// A deliberate SIBLING of [SignatureRequestSheet], not a new species: same
/// glass-dark bottom sheet, same origin line, same network pill, same
/// approve/reject shape. It states the cost of the action before it is
/// committed and NOTHING more — it does not
/// adjudicate whether a key is linked to an account (the indicator gives no
/// such verdict on purpose; the signature consumer decides).
///
/// ── IT ANSWERS WITH A SET ───────────────────────────────────────────────────
/// Permission is per-site and per-key, so the answer is `Set<String>?`, not a
/// bool: the checked addresses, or `null` for refusal. The keys are listed by
/// [SiteKeyPicker], the same rows the indicator's own sheet shows, so "what I approved" and
/// "what I can change later" are one widget and cannot drift.
///
/// Note the empty set is NOT refusal: it is a legitimate "connect nothing",
/// which `ConnectGate.setGrants` applies as a disconnect. Only `null` throws
/// 4001. Cancel and scrim-dismiss both answer `null`.
///
/// The one behavioural difference from the signature sheet: here CANCEL is the
/// safe default, so a scrim tap is allowed and counts as Cancel. A signature
/// sheet disables that because an accidental dismissal must never APPROVE; a
/// connect dismissal only ever REJECTS, which is safe.
class ConnectRequestSheet extends StatefulWidget {
  /// `scheme://host[:port]` of the requesting page (`ConnectGate.originKey`).
  final String origin;

  /// Browser's current chain (hex, e.g. `0x1189`) — drives the network pill.
  final String? currentChainId;

  /// Every key the user could offer, in the order to list them. A pinned view
  /// (the wallet manager) supplies exactly one, so there is nothing to choose.
  final List<WalletKey> keys;

  /// What this site already holds. Non-empty means the sheet was raised by
  /// `wallet_requestPermissions` or by a signature naming an ungranted key —
  /// not a first connect — and the boxes open already checked.
  final Set<String> alreadyGranted;

  /// The GLOBAL preferred key — the fallback head when the site has no
  /// active key of its own. Display only; nothing here writes it.
  final String? preferred;

  /// A key the site named but does not hold yet. Pre-checked, and called out on
  /// its row so the user can see why the sheet appeared.
  final String? requested;

  /// Display name for the session key (whose label is `null` / `'session'`).
  final String sessionKeyName;

  /// The site's own active key, if it already chose one.
  final String? activeKey;

  const ConnectRequestSheet({
    super.key,
    required this.origin,
    required this.keys,
    required this.sessionKeyName,
    this.alreadyGranted = const {},
    this.currentChainId,
    this.preferred,
    this.requested,
    this.activeKey,
  });

  /// PublicOS mainnet (4489 = 0x1189). External chains get an amber pill.
  static const _publicOSChainId = '0x1189';

  /// Show the connect sheet.
  ///
  /// Returns the approved SET, or `null` if the user cancelled or dismissed by
  /// tapping the scrim (both mean "do not change anything, and tell the page
  /// no"). An empty set is a different answer — see the class doc.
  static Future<ConnectDecision?> show({
    required BuildContext context,
    required String origin,
    required List<WalletKey> keys,
    required String sessionKeyName,
    Set<String> alreadyGranted = const {},
    String? currentChainId,
    String? preferred,
    String? requested,
    String? activeKey,
  }) {
    return showGlassSheetDialog<ConnectDecision>(
      context: context,
      width: DialogWidth.m,
      // Scrim tap ≡ Cancel ≡ reject (4001). Safe because dismissal only ever
      // says "no" — unlike a signature sheet, there is no accidental "yes".
      barrierDismissible: true,
      builder: (_) => ConnectRequestSheet(
        origin: origin,
        keys: keys,
        sessionKeyName: sessionKeyName,
        alreadyGranted: alreadyGranted,
        currentChainId: currentChainId,
        preferred: preferred,
        requested: requested,
        activeKey: activeKey,
      ),
    );
  }

  @override
  State<ConnectRequestSheet> createState() => _ConnectRequestSheetState();
}

class _ConnectRequestSheetState extends State<ConnectRequestSheet> {
  /// The checked set. Opens on what the site already holds, plus the key it
  /// explicitly asked for — the two reasons a box should start ticked.
  late final Set<String> _selected = {
    ...widget.alreadyGranted,
    if (widget.requested != null) widget.requested!,
  };

  /// Local, so the green globe follows the tap rather than waiting for a
  /// rebuild from above.
  /// The site's EXPLICIT active choice. Cleared when its row is turned off,
  /// so a stale choice can never outlive visibility.
  late String? _active = widget.activeKey;

  /// What the site will see first, given the rows as they stand: the explicit
  /// choice if visible, else the preferred key if visible, else the first
  /// visible row in keychain order. Same rule as the bridge's
  /// `ConnectGate.activeAccount`, evaluated live so the glyph follows taps.
  String? get _effectiveActive {
    final a = _active;
    if (a != null && _selected.contains(a)) return a;
    final p = widget.preferred;
    if (p != null && _selected.contains(p)) return p;
    for (final k in widget.keys) {
      if (_selected.contains(k.address)) return k.address;
    }
    return null;
  }

  void _toggle(String address) => setState(() {
        if (!_selected.remove(address)) {
          _selected.add(address);
        } else if (_active == address) {
          _active = null; // the interlock: not visible → not active
        }
      });

  /// One tap: visible AND active.
  void _setActive(String address) => setState(() {
        _selected.add(address);
        _active = address;
      });

  ConnectDecision get _decision => ConnectDecision(
        visible: {..._selected},
        activeKey: _selected.contains(_active) ? _active : null,
      );

  /// Names the chain from the app's one registry.
  String _chainName(BuildContext context, String? hexChainId) {
    final name = chainNameForHex(hexChainId);
    if (name != null) return name;
    return hexChainId == null
        ? context.l10n.signatureRequestSheetChainUnknown
        : context.l10n.signatureRequestSheetChainNamed(hexChainId);
  }

  TextStyle _label(GlassTokens t) => TextStyle(
        fontFamily: 'SpaceGrotesk',
        fontWeight: FontWeight.w800,
        fontSize: 10,
        letterSpacing: 1.2,
        color: t.textDim,
      );

  Widget _networkPill(BuildContext context, GlassTokens tokens) {
    final isPublicOS = widget.currentChainId == ConnectRequestSheet._publicOSChainId;
    final accent = isPublicOS ? tokens.connectedAccent : tokens.fallbackAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        // The 12% tint carries the chain state on its own (borderless).
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // The chain's brand mark, not a coloured dot. The signature sheet has
          // always shown the real mark here; this pill showed a 6px circle, so
          // the two sheets described the same chain differently. Unmapped ids
          // fall back to the generic Ethereum diamond inside NftChainIcon.
          NftChainIcon(chain: chainIdFromHex(widget.currentChainId), size: 14),
          const SizedBox(width: 6),
          Text(
            _chainName(context, widget.currentChainId),
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final l10n = context.l10n;
    // Uncheck-everything on a first connect is just "no". On a re-ask
    // (`wallet_requestPermissions`, or the site naming an ungranted key) it is
    // the disconnect gesture, so the button says so.
    final disconnecting =
        _selected.isEmpty && widget.alreadyGranted.isNotEmpty;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: tokens.surfaceDeep,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: tokens.glassFill,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.link_rounded,
                        color: tokens.connectedAccent, size: 19),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.connectRequestSheetTitle,
                      style: TextStyle(
                        fontFamily: 'SpaceGrotesk',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: tokens.starkWhite,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            // Body
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ORIGIN
                  Text(l10n.connectRequestSheetOrigin, style: _label(tokens)),
                  const SizedBox(height: 6),
                  Text(
                    widget.origin,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: tokens.starkWhite,
                    ),
                  ),
                  const SizedBox(height: 18),
                  // NETWORK
                  Text(l10n.connectRequestSheetNetwork, style: _label(tokens)),
                  const SizedBox(height: 6),
                  _networkPill(context, tokens),
                  const SizedBox(height: 18),
                  // SHARING — the key by name + the literal EOA it hands over
                  Text(l10n.connectRequestSheetSharing, style: _label(tokens)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: tokens.glassFill,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    // The picker IS the offer now. There is no "the key on
                    // offer" row above it any more: with permission being a
                    // set, a single headline key would be a lie about what is
                    // being granted, and it is what let a page ask for key A
                    // while the sheet quietly offered key B.
                    child: SiteKeyPicker(
                      keys: widget.keys,
                      selected: _selected,
                      active: _effectiveActive,
                      requested: widget.requested,
                      sessionKeyName: widget.sessionKeyName,
                      onToggle: _toggle,
                      onActive: _setActive,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // The honest scope
                  Text(
                    l10n.connectRequestSheetScope,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.5,
                      color: tokens.textDim,
                    ),
                  ),
                ],
              ),
            ),
            // Actions
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              // No rule above the buttons (borderless).
              decoration: const BoxDecoration(),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: tokens.starkWhite,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          side: BorderSide.none,
                        ),
                        child: Text(l10n.connectRequestSheetActionCancel,
                            style: const TextStyle(
                                fontFamily: 'SpaceGrotesk',
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.5,
                                fontSize: 12)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        // Never disabled on an empty selection: on a re-ask
                        // that IS the disconnect, and disabling it would make
                        // the gesture unreachable. On a first connect an empty
                        // approve is a harmless no-op grant of nothing.
                        onPressed: () => Navigator.pop(context, _decision),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: tokens.glassFill,
                          foregroundColor: tokens.starkWhite,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide.none,
                          ),
                        ),
                        icon: Icon(
                            disconnecting
                                ? Icons.link_off_rounded
                                : Icons.link_rounded,
                            size: 16),
                        label: Text(
                          disconnecting
                              ? l10n.siteKeysSheetActionDisconnect
                              : l10n.connectRequestSheetActionConnect,
                          style: const TextStyle(
                            fontFamily: 'SpaceGrotesk',
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
