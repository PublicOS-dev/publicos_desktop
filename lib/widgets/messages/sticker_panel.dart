import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:publicos_core/publicos_core.dart';

import 'package:publicos_desktop/widgets/phigital_loading_widget.dart';
import 'package:publicos_desktop/widgets/sticker_icon.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';

/// The composer's sticker gallery — a 4-column grid of the user's saved
/// stickers, rendered as an inline panel occupying the keyboard's space.
///
/// **Not a bottom sheet.** It's an ordinary child of `MessageInput`'s Column,
/// so it grows the input bar upward exactly the way the attach-options row
/// does, and `chat_screen`'s `SizeChangedLayoutNotifier` re-pins the
/// conversation for free. Nothing is shadowed; messages stay readable above.
/// The host owns the mutual exclusion with the keyboard.
///
/// **Tap** sends immediately (the panel stays open, so a run of stickers lands
/// as one horizontal stack). **Long-press** opens a menu at the finger:
/// add a description, or delete.
///
/// Bytes are fetched per tile, never for the whole library at once — a
/// 200-sticker gallery selected whole would be ~20 MB of `Uint8List` resident.
/// See `SavedStickerMeta` in PublicOS_Core.
class StickerPanel extends StatefulWidget {
  /// Matches the keyboard's height so the swap is visually a no-op.
  final double height;

  /// Send this sticker now.
  final ValueChanged<AttachmentContent> onSend;

  /// Stage this sticker in the compose preview so the user can caption it
  /// before sending. A captioned sticker renders in a bubble, by design.
  final ValueChanged<AttachmentContent> onAddDescription;

  const StickerPanel({
    super.key,
    required this.height,
    required this.onSend,
    required this.onAddDescription,
  });

  @override
  State<StickerPanel> createState() => _StickerPanelState();
}

class _StickerPanelState extends State<StickerPanel> {
  List<SavedStickerMeta>? _stickers;

  /// Memoized per-sticker byte fetches. Keyed by row id so a rebuild never
  /// re-hits the database for a tile that already resolved.
  final Map<int, Future<Uint8List?>> _bytes = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final stickers = await PublicOSStickers.listStickers();
    if (!mounted) return;
    setState(() {
      _stickers = stickers;
      _bytes.removeWhere((id, _) => !stickers.any((s) => s.id == id));
    });
  }

  Future<Uint8List?> _bytesFor(SavedStickerMeta meta) =>
      _bytes.putIfAbsent(meta.id, () => PublicOSStickers.getStickerData(meta.id));

  /// Resolve a tile back into a sendable attachment. Null when the row was
  /// deleted underneath us.
  Future<AttachmentContent?> _attachmentFor(SavedStickerMeta meta) =>
      PublicOSStickers.toAttachment(meta);

  Future<void> _handleTap(SavedStickerMeta meta) async {
    final attachment = await _attachmentFor(meta);
    if (attachment == null || !mounted) return;
    widget.onSend(attachment);
  }

  Future<void> _handleAddDescription(SavedStickerMeta meta) async {
    final attachment = await _attachmentFor(meta);
    if (attachment == null || !mounted) return;
    widget.onAddDescription(attachment);
  }

  Future<void> _handleDelete(SavedStickerMeta meta) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        constraints: const BoxConstraints(minWidth: DialogWidth.min, maxWidth: DialogWidth.s),
        title: Text(l10n.stickerPanelDeleteTitle),
        content: Text(l10n.stickerPanelDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(ctx.l10n.dlgCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(ctx.l10n.stickerPanelDeleteConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await PublicOSStickers.deleteSticker(meta.id);
    _bytes.remove(meta.id);
    await _load();
  }

  /// Glass menu anchored at the finger — same language as the message
  /// long-press reaction bar, scaled down to two rows.
  void _showTileMenu(SavedStickerMeta meta, Offset globalPosition) {
    final tokens = GlassTokens.of(context);
    final l10n = context.l10n;
    final media = MediaQuery.of(context);
    final screen = media.size;

    const menuWidth = 208.0;
    const rowHeight = 48.0;
    const menuHeight = rowHeight * 2 + 8;
    const edge = 12.0;
    const fingerGap = 12.0;

    // Lift the menu fully above the finger, then clamp into the safe area.
    final top = (globalPosition.dy - menuHeight - fingerGap)
        .clamp(media.padding.top + edge, screen.height - menuHeight - edge);
    final left = (globalPosition.dx - menuWidth / 2)
        .clamp(edge, screen.width - menuWidth - edge);

    showGeneralDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.05),
      barrierDismissible: true,
      barrierLabel: l10n.stickerPanelDismissMenu,
      transitionDuration: const Duration(milliseconds: 120),
      transitionBuilder: (context, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
          reverseCurve: Curves.easeIn,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.04),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
      pageBuilder: (dialogContext, _, __) => Stack(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(dialogContext),
            behavior: HitTestBehavior.opaque,
            child: const SizedBox.expand(),
          ),
          Positioned(
            top: top,
            left: left,
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: menuWidth,
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: tokens.background,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: tokens.borderSubtle, width: 1),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _menuRow(
                      tokens: tokens,
                      icon: Icons.notes_rounded,
                      label: l10n.stickerPanelAddDescription,
                      color: tokens.starkWhite,
                      onTap: () {
                        Navigator.pop(dialogContext);
                        _handleAddDescription(meta);
                      },
                    ),
                    _menuRow(
                      tokens: tokens,
                      icon: Icons.delete_outline_rounded,
                      label: l10n.stickerPanelDelete,
                      color: Colors.red.shade300,
                      onTap: () {
                        Navigator.pop(dialogContext);
                        _handleDelete(meta);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuRow({
    required GlassTokens tokens,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: SizedBox(
        height: 48,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final stickers = _stickers;

    return SizedBox(
      height: widget.height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tokens.background,
          border: Border(top: BorderSide(color: tokens.borderSubtle, width: 1)),
        ),
        child: stickers == null
            ? const Center(child: PhigitalLoadingWidget(size: 24, showShadows: false))
            : stickers.isEmpty
                ? _buildEmptyState(tokens)
                : GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 1,
                    ),
                    itemCount: stickers.length,
                    itemBuilder: (context, i) {
                      final meta = stickers[i];
                      return _StickerTile(
                        key: ValueKey(meta.id),
                        bytes: _bytesFor(meta),
                        onTap: () => _handleTap(meta),
                        onLongPress: (pos) => _showTileMenu(meta, pos),
                      );
                    },
                  ),
      ),
    );
  }

  Widget _buildEmptyState(GlassTokens tokens) {
    // Deliberately explains the acquisition path: on Windows/Web there is no
    // keyboard sticker tray, so receiving one and holding it is the ONLY way
    // to get a first sticker.
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StickerIcon(size: 40, color: tokens.textDim),
            const SizedBox(height: 14),
            Text(
              context.l10n.stickerPanelEmptyTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: tokens.starkWhite,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              context.l10n.stickerPanelEmptyBody,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontSize: 12,
                height: 1.4,
                color: tokens.textDim,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One gallery cell. Renders the sticker on transparency (no bubble, no fill) —
/// the alpha is the shape, same as in the conversation.
class _StickerTile extends StatelessWidget {
  final Future<Uint8List?> bytes;
  final VoidCallback onTap;
  final ValueChanged<Offset> onLongPress;

  const _StickerTile({
    super.key,
    required this.bytes,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPressStart: (details) => onLongPress(details.globalPosition),
      behavior: HitTestBehavior.opaque,
      child: FutureBuilder<Uint8List?>(
        future: bytes,
        builder: (context, snapshot) {
          final data = snapshot.data;
          if (data == null) return const SizedBox.shrink();
          return Image.memory(
            data,
            fit: BoxFit.contain,
            // Animated GIF/WebP stickers animate natively here, exactly as
            // they do in the message list.
            gaplessPlayback: true,
          );
        },
      ),
    );
  }
}
