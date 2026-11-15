// PORTED VERBATIM from publicos_client, with only mechanical import
// rewrites (components/->widgets/, pages/->screens/,
// glass_theme->glass_tokens, chain_icon, and
// explorer/chip_bar.dart -> widgets/explorer_chip.dart).
// Presentation is deliberately duplicated between the two clients; the
// LOGIC behind these sheets is not -- it lives in publicos_web3_bridge and
// is shared.
//
// Still a bottom sheet, exactly as on mobile. Re-shelling it as a
// desktop dialog is a presentation change to make deliberately, not on
// the way past.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:publicos_web3_bridge/publicos_web3_bridge.dart'
    show ConnectDecision, WalletKey;

import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/widgets/chain_icon.dart';
import 'package:publicos_desktop/widgets/explorer_chip.dart';
import 'package:publicos_desktop/data/chain_registry.dart';
import 'package:publicos_desktop/l10n/app_localizations.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';
import 'package:publicos_desktop/utils/glass_sheet_dialog.dart';

/// Which keys a site may see — the per-site permission surface.
///
/// ── WHY THIS IS ITS OWN SCREEN ───────────────────────────────────────────────
/// Permission is a per-site SET of keys. The
/// keychain sheet already lists every key, so hosting the checkboxes there
/// looks free — and it is the one thing this must not do: the keychain carries
/// **delete, export and rename**, and a site-scoped permission surface cannot
/// put "delete key" one mis-tap away from a checkbox. Same row look, different
/// screen, no destructive verbs anywhere on it.
///
/// ── TWO SHAPES, ONE PICKER ───────────────────────────────────────────────────
/// [SiteKeyPicker] is the rows. [SiteKeysSheet] wraps them for the address-bar
/// indicator's tap. The connect prompt embeds the same rows, so what the user
/// checks at connect time and what they change later are literally the same
/// widget and cannot drift apart.
///
/// ── UNCHECK-ALL IS A DISCONNECT ──────────────────────────────────────────────
/// The empty set is a real answer, not a refusal: it revokes every row, emits
/// `accountsChanged []` and puts the indicator out. That is why the confirm
/// button relabels itself rather than disabling — a disabled button would make
/// the disconnect gesture unreachable and force a separate "revoke" verb.
class SiteKeyPicker extends StatelessWidget {
  /// Every key the user holds, in the order they should be listed. A pinned
  /// view (the wallet manager) supplies exactly one.
  final List<WalletKey> keys;

  /// The checked set, lowercased. Owned by the caller so the confirm button can
  /// read it too.
  final Set<String> selected;

  /// The row the site sees FIRST — its active key: the explicit per-site
  /// choice if visible, else the global preferred key if visible, else the
  /// first visible row. Resolved by the host so the green glyph follows
  /// every tap live.
  final String? active;

  /// A key the site named that it does not hold yet (a signature request for a
  /// key we have but have not granted). Called out on its row so the sheet can
  /// say why it appeared.
  final String? requested;

  /// Display name for the session key, whose label is `null` or `'session'`.
  final String sessionKeyName;

  /// Flip a row's visibility — the eye glyph, or the row itself.
  final ValueChanged<String> onToggle;

  /// Make a row the active key — the key glyph. The host also makes it
  /// visible: an active key that is not visible is unconstructible.
  final ValueChanged<String>? onActive;

  /// The key glyph is a CHOICE BETWEEN rows, so one row earns none — it is
  /// the active key by definition.
  bool get _showActive => onActive != null && keys.length > 1;

  const SiteKeyPicker({
    super.key,
    required this.keys,
    required this.selected,
    required this.onToggle,
    required this.sessionKeyName,
    this.active,
    this.requested,
    this.onActive,
  });

  static String shortAddress(String a) =>
      a.length < 12 ? a : '${a.substring(0, 6)}…${a.substring(a.length - 4)}';

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final l10n = context.l10n;

    if (keys.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Text(
          l10n.siteKeysSheetEmpty,
          style: TextStyle(fontSize: 12.5, color: tokens.textDim),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final k in keys)
          _row(
            context,
            tokens,
            walletKey: k,
            name: k.isSessionKey ? sessionKeyName : k.label!,
            checked: selected.contains(k.address),
          ),
      ],
    );
  }

  /// A keychain row, not a checkbox list.
  ///
  /// Deliberately the same shape the keychain sheet uses — emoji tile, name,
  /// address — because these are the SAME keys, and a second visual language
  /// for them would make the two screens feel unrelated. What differs is the
  /// two controls on the right, and they answer the two different questions
  /// this screen exists for: the globe is *which key do sites see first*
  /// (global), the checkbox is *may THIS site see it* (per site).
  Widget _row(
    BuildContext context,
    GlassTokens tokens, {
    required WalletKey walletKey,
    required String name,
    required bool checked,
  }) {
    final l10n = context.l10n;
    final isActive = checked && active != null && walletKey.address == active;
    final isRequested = requested != null && walletKey.address == requested;

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onToggle(walletKey.address);
      },
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Row(
          children: [
            // Emoji tile, same construction as the keychain's (44 there, 36
            // here — this is a list inside a sheet, not the sheet itself).
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: tokens.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(walletKey.emoji ?? '🔑',
                    style: const TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      fontSize: 13.5,
                      fontWeight: checked ? FontWeight.w700 : FontWeight.w600,
                      color: checked ? tokens.starkWhite : tokens.textDim,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    shortAddress(walletKey.address),
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10.5,
                      color: tokens.textDim.withValues(alpha: 0.75),
                    ),
                  ),
                  if (isRequested) ...[
                    const SizedBox(height: 2),
                    Text(
                      l10n.siteKeysSheetRequested,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: tokens.connectedAccent,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // The web-key pointer, drawn exactly as the keychain draws it:
            // filled globe when this is the one, outlined otherwise. Green is
            // the ONLY thing that says "preferred" (there is no text tag),
            // and the keychain's toggle is not the only way to move it.
            // Two on/off glyphs, no checkbox: the KEY
            // is "active on this site" (green when on), the EYE is "visible
            // to this site". Interlocked by the host — see the sheet state.
            if (_showActive) ...[
              Tooltip(
                message: l10n.siteKeysSheetActive,
                child: InkResponse(
                  radius: 20,
                  onTap: isActive
                      ? null
                      : () {
                          HapticFeedback.selectionClick();
                          onActive!(walletKey.address);
                        },
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      isActive ? Icons.key_rounded : Icons.key_outlined,
                      size: 18,
                      color: isActive
                          ? tokens.connectedAccent
                          : tokens.textDim.withValues(alpha: 0.45),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 2),
            ],
            Tooltip(
              message: l10n.siteKeysSheetVisible,
              child: InkResponse(
                radius: 20,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onToggle(walletKey.address);
                },
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    checked
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_outlined,
                    size: 18,
                    color: checked
                        ? tokens.starkWhite
                        : tokens.textDim.withValues(alpha: 0.45),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The standalone picker, raised by the address-bar key indicator.
///
/// Returns the approved set, or `null` if the user dismissed — and those are
/// NOT the same: an empty set disconnects, `null` changes nothing. A scrim tap
/// is a dismissal, which is safe here because dismissing can only ever leave
/// permission as it was.
/// What [SiteKeysSheet] hands back on Save: the key decision, and the chain the
/// user moved this tab to.
///
/// The two travel together because they are one gesture — the sheet has a single
/// Cancel/Save pair, so a dismissal must leave both the grants and the chain
/// exactly as they were. Keeping the chain out of [ConnectDecision] is
/// deliberate: that type belongs to the bridge and describes *permission*, which
/// a chain is not.
class SiteKeysResult {
  final ConnectDecision decision;

  /// The chain to move this tab to, or null to leave it where it is.
  final String? chainId;

  const SiteKeysResult({required this.decision, this.chainId});
}

class SiteKeysSheet extends StatefulWidget {
  final String origin;
  final List<WalletKey> keys;
  final Set<String> alreadyGranted;

  /// The GLOBAL preferred key — the fallback head when the site has no
  /// active key of its own. Display only; nothing here writes it.
  final String? preferred;

  /// The site's own active key, if it has chosen one.
  final String? activeKey;
  final String sessionKeyName;

  /// The chain this tab currently reads on, `0x`-prefixed. Null hides the
  /// network strip entirely — a surface with no chain in hand (a pinned wallet
  /// manager) shows keys only.
  final String? currentChainId;

  const SiteKeysSheet({
    super.key,
    required this.origin,
    required this.keys,
    required this.alreadyGranted,
    required this.sessionKeyName,
    this.preferred,
    this.activeKey,
    this.currentChainId,
  });

  /// `null` = dismissed (nothing changes). Otherwise the visible set (empty =
  /// disconnect) plus the site's explicit active choice, or null for "follow
  /// the preferred key".
  static Future<SiteKeysResult?> show({
    required BuildContext context,
    required String origin,
    required List<WalletKey> keys,
    required Set<String> alreadyGranted,
    required String sessionKeyName,
    String? preferred,
    String? activeKey,
    String? currentChainId,
  }) {
    return showGlassSheetDialog<SiteKeysResult>(
      context: context,
      width: DialogWidth.m,
      builder: (_) => SiteKeysSheet(
        origin: origin,
        keys: keys,
        alreadyGranted: alreadyGranted,
        sessionKeyName: sessionKeyName,
        preferred: preferred,
        activeKey: activeKey,
        currentChainId: currentChainId,
      ),
    );
  }

  @override
  State<SiteKeysSheet> createState() => _SiteKeysSheetState();
}

class _SiteKeysSheetState extends State<SiteKeysSheet> {
  late final Set<String> _selected = {...widget.alreadyGranted};

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

  /// **Which chain this tab reads on.** The address-bar chain badge is purely
  /// informational; this is the one place the chain changes. Horizontally
  /// scrollable because the list is long and growing, and it must not push
  /// the key rows off the sheet.
  ///
  /// Applied on **Save**, not on tap: the chain rides the same Cancel/Save
  /// gesture as the keys, so Cancel still means *nothing changed*. Tapping the
  /// chain it is already on clears the pick rather than re-selecting it.
  String? _pickedChainId;

  String? get _effectiveChainId => _pickedChainId ?? widget.currentChainId;

  Widget _chainStrip(GlassTokens tokens, AppLocalizations l10n) {
    final currentId = chainIdFromHex(_effectiveChainId);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.signatureRequestSheetLabelNetwork.toUpperCase(),
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            fontWeight: FontWeight.w800,
            fontSize: 10,
            letterSpacing: 1.2,
            color: tokens.textDim,
          ),
        ),
        const SizedBox(height: 6),
        ExplorerChipBar(
          height: 40,
          padding: EdgeInsets.zero,
          fadeColor: tokens.surfaceDeep,
          children: [
            for (final chain in kChainRegistry) ...[
              if (chain != kChainRegistry.first) const SizedBox(width: 8),
              ExplorerChip(
                label: chain.name,
                // The chain's own mark, LEADING. It replaced a generic
                // `Icons.lan_outlined` that sat on every chip saying "network"
                // to a list already headed NETWORK — the same word nine times,
                // while the one glyph that actually distinguished the rows was
                // exiled to the trailing edge.
                leading: NftChainIcon(chain: chain.chainId, size: 15),
                active: chain.chainId == currentId,
                onTap: () => setState(() {
                  // Re-picking the current chain is "never mind".
                  _pickedChainId =
                      chain.chainId == chainIdFromHex(widget.currentChainId)
                          ? null
                          : chainIdToHex(chain.chainId);
                }),
              ),
            ],
          ],
        ),
      ],
    );
  }

  /// The bottom guides — the sheet's entire explanation, one glyph plus a few
  /// words each, sitting under the rows whose glyphs they name.
  Widget _legend(GlassTokens tokens, AppLocalizations l10n) {
    Widget item(IconData icon, String text) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: tokens.textDim),
            const SizedBox(width: 4),
            Text(
              text,
              style: TextStyle(fontSize: 11, color: tokens.textDim),
            ),
          ],
        );

    // Wrap, not Row: three items do not fit one line in Spanish on a narrow
    // phone, and a legend that overflows is worse than one that wraps.
    return Wrap(
      spacing: 14,
      runSpacing: 6,
      children: [
        item(Icons.visibility_rounded, l10n.siteKeysSheetLegendVisible),
        item(Icons.key_rounded, l10n.siteKeysSheetLegendActive),
        item(Icons.link_off_rounded, l10n.siteKeysSheetLegendDisconnect),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final l10n = context.l10n;
    final disconnecting = _selected.isEmpty && widget.alreadyGranted.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: tokens.surfaceDeep,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
                  child: Icon(Icons.key_outlined,
                      color: tokens.starkWhite, size: 19),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.siteKeysSheetTitle,
                        style: TextStyle(
                          fontFamily: 'SpaceGrotesk',
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: tokens.starkWhite,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.origin,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11.5,
                          color: tokens.textDim,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // No rule under the header: the tone step from the sheet to the
          // key-rows panel below carries the separation on its own.
          const SizedBox(height: 2),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // The rows come FIRST, with no preamble: the bottom legend
                  // explains the two glyphs in a few words, next to the
                  // glyphs it describes.
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: tokens.glassFill,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SiteKeyPicker(
                      keys: widget.keys,
                      selected: _selected,
                      active: _effectiveActive,
                      sessionKeyName: widget.sessionKeyName,
                      onToggle: _toggle,
                      onActive: _setActive,
                    ),
                  ),
                  if (widget.currentChainId != null) ...[
                    const SizedBox(height: 14),
                    _chainStrip(tokens, l10n),
                  ],
                  const SizedBox(height: 12),
                  _legend(tokens, l10n),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            // No rule above the buttons either — the footer is padding and
            // the buttons carry their own weight.
            decoration: const BoxDecoration(),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: tokens.textDim,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        // Borderless: Cancel is the quiet half of the pair,
                        // and dim text on the sheet says that without a ring.
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
                      // Never disabled on the empty set: that IS the disconnect
                      // gesture, and disabling it would make disconnecting
                      // unreachable from the one screen that owns permission.
                      onPressed: () => Navigator.pop(
                        context,
                        SiteKeysResult(
                          decision: _decision,
                          chainId: _pickedChainId,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        // A tone step up instead of a ring — with the border
                        // gone the fill is what makes Save the primary.
                        backgroundColor: tokens.surfaceElevated,
                        foregroundColor: disconnecting
                            ? tokens.fallbackAccent
                            : tokens.starkWhite,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: Icon(
                        disconnecting
                            ? Icons.link_off_rounded
                            : Icons.check_rounded,
                        size: 16,
                      ),
                      label: Text(
                        disconnecting
                            ? l10n.siteKeysSheetActionDisconnect
                            : l10n.siteKeysSheetActionSave,
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
    );
  }
}
