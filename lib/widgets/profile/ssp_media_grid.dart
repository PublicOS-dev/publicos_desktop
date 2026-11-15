import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:publicos_core/publicos_core.dart';
import 'package:publicos_desktop/widgets/phigital_loading_widget.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';
import 'package:zero_cached_image/zero_cached_image.dart';

/// Grid of the user's already-uploaded images on their active SSP — the
/// "your uploads" library of the profile-image sheet's Image pane.
///
/// Read-only over [PublicOSSsp.listMedia] (the same signed listing the SSP
/// management page uses), filtered to `image/*`. Tapping a tile bubbles the
/// picked [MediaFile] — the host adopts `file.url` as its selection. No
/// delete affordance here: the library is managed from the SSP management
/// page, and selecting a pre-existing file must never entangle it with the
/// host's session-upload cleanup.
///
/// Renders nothing when no SSP is configured — the host's no-server banner
/// (from [ProfileImagePicker]) already covers that state.
class SspMediaGrid extends StatefulWidget {
  /// URL of the currently-selected file, to highlight its tile.
  final String? selectedUrl;

  /// Tap → adopt `file.url` (host mirrors it into its URL field).
  final void Function(MediaFile file) onSelect;

  final bool enabled;

  /// Tiles shown before the uploads (the card sheet puts None and Upload here).
  /// When given, the grid renders even without an SSP, showing just these.
  final List<Widget> leading;

  /// When set, the grid is a fixed-height box this many rows tall and the rest
  /// scroll inside it. Null keeps the default: every row laid out, no scroll.
  final int? visibleRows;

  const SspMediaGrid({
    super.key,
    this.selectedUrl,
    required this.onSelect,
    this.enabled = true,
    this.leading = const [],
    this.visibleRows,
  });

  @override
  State<SspMediaGrid> createState() => SspMediaGridState();
}

class SspMediaGridState extends State<SspMediaGrid> {
  bool _loading = true;
  bool _error = false;
  bool _noServer = false;
  List<MediaFile> _files = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Host calls this after a fresh upload so the new file appears in the
  /// grid (server returns newest-first).
  Future<void> reload() => _load();

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = false;
      _noServer = false;
    });
    try {
      final url = await PublicOSSsp.getActiveFeedServerUrl();
      if (!mounted) return;
      if (url == null) {
        setState(() {
          _noServer = true;
          _loading = false;
        });
        return;
      }
      final resp = await PublicOSSsp.listMedia();
      if (!mounted) return;
      if (!resp.success || resp.data == null) {
        setState(() {
          _error = true;
          _loading = false;
        });
        return;
      }
      setState(() {
        _files = resp.data!.files
            .where((f) => f.contentType.startsWith('image/'))
            .toList();
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = true;
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);

    if (widget.leading.isNotEmpty) {
      // Host tiles first, then the library. With no SSP or an empty library
      // the host tiles still show; a failed listing adds its note underneath.
      final tiles = <Widget>[
        ...widget.leading,
        if (_loading)
          const Center(
              child: PhigitalLoadingWidget(size: 18, showShadows: false))
        else if (!_noServer && !_error)
          ..._files.map((f) => _fileTile(tokens, f)),
      ];
      final grid = _grid(tiles);
      if (!_error) return grid;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          grid,
          const SizedBox(height: 8),
          _note(tokens, context.l10n.editProfileImageSheetUploadsError),
        ],
      );
    }

    if (_noServer) return const SizedBox.shrink();
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child:
            Center(child: PhigitalLoadingWidget(size: 24, showShadows: false)),
      );
    }
    if (_error) {
      return _note(tokens, context.l10n.editProfileImageSheetUploadsError);
    }
    if (_files.isEmpty) {
      return _note(tokens, context.l10n.editProfileImageSheetUploadsEmpty);
    }

    return _grid(_files.map((f) => _fileTile(tokens, f)).toList());
  }

  static const int _columns = 3;
  static const double _gap = 8;

  Widget _grid(List<Widget> tiles) {
    const delegate = SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: _columns,
      crossAxisSpacing: _gap,
      mainAxisSpacing: _gap,
    );
    final rows = widget.visibleRows;
    if (rows == null) {
      return GridView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: delegate,
        children: tiles,
      );
    }
    // Square tiles, so the box height follows from the width: at most [rows]
    // rows show and the rest scroll inside.
    return LayoutBuilder(
      builder: (context, constraints) {
        final tile =
            (constraints.maxWidth - _gap * (_columns - 1)) / _columns;
        final shown =
            math.max(1, math.min(rows, (tiles.length / _columns).ceil()));
        return SizedBox(
          height: shown * tile + (shown - 1) * _gap,
          child: GridView(
            primary: false,
            padding: EdgeInsets.zero,
            gridDelegate: delegate,
            children: tiles,
          ),
        );
      },
    );
  }

  Widget _fileTile(GlassTokens tokens, MediaFile f) {
    final selected = widget.selectedUrl == f.url;
    return GestureDetector(
      onTap: widget.enabled
          ? () {
              HapticFeedback.lightImpact();
              widget.onSelect(f);
            }
          : null,
      child: _MediaTile(tokens: tokens, file: f, selected: selected),
    );
  }

  Widget _note(GlassTokens tokens, String text) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: tokens.glassFill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: tokens.borderSubtle),
        ),
        child: Text(
          text,
          style: TextStyle(
              fontFamily: 'SpaceGrotesk', fontSize: 12.5, color: tokens.textDim),
        ),
      );
}

class _MediaTile extends StatelessWidget {
  final GlassTokens tokens;
  final MediaFile file;
  final bool selected;

  const _MediaTile({
    required this.tokens,
    required this.file,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    final accent = tokens.connectedAccent;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: selected ? accent : tokens.borderSubtle,
          width: selected ? 2 : 1,
        ),
        boxShadow: selected
            ? [BoxShadow(color: accent.withValues(alpha: 0.25), blurRadius: 10)]
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ZeroCachedImage(
            imageUrl: file.url,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(
              color: tokens.glassFill,
              child: const Center(
                  child: PhigitalLoadingWidget(size: 18, showShadows: false)),
            ),
            errorWidget: (_, __, ___) => Container(
              color: tokens.glassFill,
              child: Center(
                child: Icon(Icons.broken_image_outlined,
                    size: 20,
                    color: tokens.fallbackAccent.withValues(alpha: 0.7)),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              color: Colors.black.withValues(alpha: 0.55),
              child: Text(
                file.originalFilename.isNotEmpty
                    ? file.originalFilename
                    : file.filename,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 9,
                  color: Colors.white70,
                ),
              ),
            ),
          ),
          if (selected)
            Positioned(
              top: 5,
              right: 5,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
                child:
                    const Icon(Icons.check_rounded, size: 12, color: Colors.black),
              ),
            ),
        ],
      ),
    );
  }
}


/// A host tile drawn like an upload tile (same radius, border and selected
/// ring), for the non-file entries a host puts in [SspMediaGrid.leading].
class SspMediaGridActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback? onTap;

  const SspMediaGridActionTile({
    super.key,
    required this.icon,
    required this.label,
    this.selected = false,
    this.enabled = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final accent = tokens.connectedAccent;
    return GestureDetector(
      onTap: enabled && onTap != null
          ? () {
              HapticFeedback.lightImpact();
              onTap!();
            }
          : null,
      child: Opacity(
        opacity: enabled ? 1 : 0.4,
        child: Container(
          decoration: BoxDecoration(
            color: tokens.glassFill,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? accent : tokens.borderSubtle,
              width: selected ? 2 : 1,
            ),
            boxShadow: selected
                ? [BoxShadow(color: accent.withValues(alpha: 0.25), blurRadius: 10)]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 22, color: tokens.textDim),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: tokens.textDim,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
