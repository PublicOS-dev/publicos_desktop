import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// DESKTOP DELTA: gal (save-to-gallery) has no Windows support, so a picture
// is saved through a file_picker save dialog in `_downloadFile`, same as
// media_overlay.
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:publicos_core/publicos_core.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zero_cached_image/zero_cached_image.dart';

import 'package:publicos_desktop/widgets/explorer_chip.dart';
import 'package:publicos_desktop/widgets/phigital_loading_widget.dart';
import 'package:publicos_desktop/widgets/system_app_scaffold.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/widgets/error/error_l10n.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';
import 'package:publicos_desktop/widgets/image_overlay.dart';

/// The file library of one feed server: the public media library and the
/// private one, as ONE list. Reached from Manage Server → Media →
/// "Manage files", pushed via [CupertinoPageRoute]. A twin of the client's
/// page (`publicos_client/lib/pages/manage_files_page.dart`); the one
/// difference is how a picture is saved (search DESKTOP DELTA).
///
/// A list that builds every row at once is unusable on a full library. Three
/// rules keep this one cheap, and they are the reason the screen exists:
///   1. The list is LAZY ([SliverList.builder]): only the rows on screen
///      exist, and their images are released when they scroll away.
///   2. Image thumbnails decode at thumbnail size, never at full resolution.
///   3. A video row shows the server's poster (`<video url>/poster`) and
///      NOTHING else. No poster → an icon. This screen never downloads a
///      video to cut a frame from it.
///
/// The server's list endpoints are unpaged and return metadata only, so the
/// whole list is fetched once and search, filters and sorting run here.
class ManageFilesPage extends StatefulWidget {
  final String serverUrl;

  const ManageFilesPage({super.key, required this.serverUrl});

  @override
  State<ManageFilesPage> createState() => _ManageFilesPageState();
}

enum _FileKind { image, video, audio, other }

enum _FileSort { newest, oldest, largest, smallest, name }

class _ManageFilesPageState extends State<ManageFilesPage> {
  /// Logical size of a row's thumbnail box.
  static const double _thumbSize = 40;

  bool _loading = true;
  String? _error;

  /// Every file on the server (public + private), in server order.
  List<_FileRow> _all = const [];

  /// [_all] after search + filters + sort. Recomputed only when one of those
  /// inputs changes ([_applyFilters]), never in build.
  List<_FileRow> _visible = const [];
  int _visibleBytes = 0;
  Map<_FileKind, int> _kindCounts = const {};
  int _privateCount = 0;

  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  _FileKind? _kind; // null = every type
  bool? _private; // null = public and private
  _FileSort _sort = _FileSort.newest;

  // Selection. A selected row is always a VISIBLE row: changing the search or
  // a filter drops what it hides, so a bulk delete never removes a file the
  // user cannot see.
  bool _selecting = false;
  final Set<String> _selected = {};
  bool _bulkDeleting = false;
  int _bulkDone = 0;
  int _bulkTotal = 0;

  /// Rows with a download or a delete in flight.
  final Set<String> _busy = {};

  /// The scaffold's scroll controller, kept so a new sort or filter can
  /// return the list to the top.
  ScrollController? _scroll;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchChanged);
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Load ────────────────────────────────────────────────────────────────

  Future<void> _load({bool silent = false}) async {
    if (!silent && mounted) setState(() => _loading = true);
    try {
      final results = await Future.wait<dynamic>([
        PublicOSSsp.listMedia(serverAddress: widget.serverUrl),
        PublicOSSsp.listPedia(serverAddress: widget.serverUrl),
      ]);
      if (!mounted) return;
      final mediaResp =
          results[0] as FeedServerApiResponse<MediaListResponse>;
      final pediaResp =
          results[1] as FeedServerApiResponse<PediaListResponse>;
      final media = mediaResp.success ? mediaResp.data : null;
      if (media == null) {
        final l10n = context.l10n;
        setState(() {
          _loading = false;
          _error = mediaResp.error?['message']?.toString() ??
              l10n.manageFilesPageLoadFailed;
        });
        return;
      }
      // A server with no private library still lists its public files.
      final pedia = pediaResp.success ? pediaResp.data : null;
      final rows = <_FileRow>[
        for (final f in media.files)
          _FileRow.from(
            url: f.url,
            name:
                f.originalFilename.isNotEmpty ? f.originalFilename : f.filename,
            contentType: f.contentType,
            fileSize: f.fileSize,
            createdAt: f.createdAt,
            isPrivate: false,
            mediaId: f.id,
          ),
        for (final f in pedia?.files ?? const <PediaFile>[])
          _FileRow.from(
            url: f.url,
            name: f.originalFilename,
            contentType: f.contentType,
            fileSize: f.fileSize,
            createdAt: f.createdAt,
            isPrivate: true,
            pediaId: f.id,
          ),
      ];
      setState(() {
        _setRows(rows);
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      final l10n = context.l10n;
      setState(() {
        _loading = false;
        _error =
            localizedError(l10n, e, fallback: l10n.manageFilesPageLoadFailed);
      });
    }
  }

  /// Replaces the file list. Call inside `setState`.
  void _setRows(List<_FileRow> rows) {
    final counts = <_FileKind, int>{};
    var private = 0;
    for (final r in rows) {
      counts[r.kind] = (counts[r.kind] ?? 0) + 1;
      if (r.isPrivate) private++;
    }
    _all = rows;
    _kindCounts = counts;
    _privateCount = private;
    // Nothing private left → a "Private" filter would show an empty list
    // with no chip to turn it off.
    if (private == 0) _private = null;
    _applyFilters();
  }

  // ── Search, filters, sort ───────────────────────────────────────────────

  void _onSearchChanged() {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q == _query) return;
    _query = q;
    _refilter();
  }

  /// Rebuilds [_visible] from [_all]. Call inside `setState`.
  void _applyFilters() {
    final out = <_FileRow>[];
    var bytes = 0;
    for (final r in _all) {
      if (_kind != null && r.kind != _kind) continue;
      if (_private != null && r.isPrivate != _private) continue;
      if (_query.isNotEmpty && !r.nameLower.contains(_query)) continue;
      out.add(r);
      bytes += r.fileSize;
    }
    switch (_sort) {
      case _FileSort.newest:
        out.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case _FileSort.oldest:
        out.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      case _FileSort.largest:
        out.sort((a, b) => b.fileSize.compareTo(a.fileSize));
      case _FileSort.smallest:
        out.sort((a, b) => a.fileSize.compareTo(b.fileSize));
      case _FileSort.name:
        out.sort((a, b) => a.nameLower.compareTo(b.nameLower));
    }
    _visible = out;
    _visibleBytes = bytes;
    if (_selected.isNotEmpty) {
      _selected.retainAll({for (final r in out) r.key});
    }
  }

  /// Re-runs the filters after the user changed one, and returns the list to
  /// the top (the row that was on screen is likely gone or elsewhere).
  void _refilter() {
    if (!mounted) return;
    setState(_applyFilters);
    final s = _scroll;
    if (s != null && s.hasClients) s.jumpTo(0);
  }

  void _setKind(_FileKind? kind) {
    if (_kind == kind) return;
    _kind = kind;
    _refilter();
  }

  /// Public / Private are toggles: tapping the active one clears it.
  void _toggleVisibility(bool private) {
    _private = _private == private ? null : private;
    _refilter();
  }

  void _setSort(_FileSort sort) {
    if (_sort == sort) return;
    _sort = sort;
    _refilter();
  }

  String _sortLabel(_FileSort s) {
    final l10n = context.l10n;
    switch (s) {
      case _FileSort.newest:
        return l10n.manageFilesPageSortNewest;
      case _FileSort.oldest:
        return l10n.manageFilesPageSortOldest;
      case _FileSort.largest:
        return l10n.manageFilesPageSortLargest;
      case _FileSort.smallest:
        return l10n.manageFilesPageSortSmallest;
      case _FileSort.name:
        return l10n.manageFilesPageSortName;
    }
  }

  // ── Selection ───────────────────────────────────────────────────────────

  void _enterSelection([_FileRow? first]) {
    if (_bulkDeleting) return;
    HapticFeedback.selectionClick();
    setState(() {
      _selecting = true;
      if (first != null) _selected.add(first.key);
    });
  }

  void _exitSelection() {
    if (_bulkDeleting) return;
    setState(() {
      _selecting = false;
      _selected.clear();
    });
  }

  void _toggleSelected(_FileRow row) {
    setState(() {
      if (!_selected.remove(row.key)) _selected.add(row.key);
    });
  }

  /// Selects every row the current search and filters show; clears the
  /// selection when they are all selected already.
  void _toggleSelectAll() {
    setState(() {
      if (_selected.length == _visible.length) {
        _selected.clear();
      } else {
        _selected
          ..clear()
          ..addAll(_visible.map((r) => r.key));
      }
    });
  }

  // ── Row actions ─────────────────────────────────────────────────────────

  Future<void> _previewFile(_FileRow row) async {
    if (row.kind == _FileKind.image) {
      // Private images preview fine: ImageOverlay renders through the cached
      // image stack, whose fetch hooks answer the server's envelope challenge
      // and decrypt the sealed response (main.dart wiring).
      Navigator.of(context).push(PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.transparent,
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, animation, secondaryAnimation) => ImageOverlay(
          imageUrl: row.url,
          heroTag: 'manage_files_${row.key}',
          onClose: () => Navigator.pop(context),
        ),
        transitionsBuilder: (context, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ));
    } else if (!row.isPrivate && _isKnownNonImageMime(row.mime)) {
      // Browser preview is public-only: the OS browser can't sign envelopes,
      // so a private URL would just render its 401 challenge.
      await _openInBrowser(row.url);
    }
    // Unknown MIME: no preview action; the button isn't rendered.
  }

  Future<void> _downloadFile(_FileRow row) async {
    if (_busy.contains(row.key)) return;
    if (row.kind == _FileKind.image) {
      final l10n = context.l10n;
      setState(() => _busy.add(row.key));
      try {
        final Uint8List bytes;
        if (row.isPrivate) {
          // Sealed fetch: envelope + decrypt via Core; a plain GET would 401.
          final plain = await PublicOSSsp.fetchPediaBytes(row.url);
          if (plain == null) {
            _snack(l10n.manageServerPageDownloadFailed);
            return;
          }
          bytes = plain;
        } else {
          final response = await http.get(Uri.parse(row.url));
          if (response.statusCode != 200) {
            _snack(
                l10n.manageServerPageDownloadFailedHttp(response.statusCode));
            return;
          }
          bytes = response.bodyBytes;
        }
        // DESKTOP DELTA: native save dialog instead of the gallery.
        final name = row.name;
        final dot = name.lastIndexOf('.');
        final ext = (dot > 0 && dot < name.length - 1)
            ? name.substring(dot + 1).toLowerCase()
            : null;
        final path = await FilePicker.platform.saveFile(
          dialogTitle: 'Save media',
          fileName: name,
          type: ext == null ? FileType.any : FileType.custom,
          allowedExtensions: ext == null ? null : [ext],
        );
        if (path == null) return; // user cancelled, not an error
        await File(path).writeAsBytes(bytes, flush: true);
        _snack(l10n.manageServerPageSavedToGallery);
      } catch (e) {
        _snack(localizedError(l10n, e,
            fallback: l10n.manageServerPageDownloadFailed));
      } finally {
        if (mounted) setState(() => _busy.remove(row.key));
      }
    } else if (!row.isPrivate) {
      // Non-image: hand off to the OS browser. Browser handles the save.
      await _openInBrowser(row.url);
    }
    // Private non-image: no download affordance (browser can't sign).
  }

  Future<void> _copyFileUrl(_FileRow row) async {
    final l10n = context.l10n;
    await Clipboard.setData(ClipboardData(text: row.url));
    _snack(l10n.manageServerPageCopied(row.url));
  }

  Future<FeedServerApiResponse<dynamic>> _deleteOnServer(_FileRow row) {
    return row.isPrivate
        ? PublicOSSsp.deletePedia(row.pediaId!, serverAddress: widget.serverUrl)
        : PublicOSSsp.deleteMedia(row.mediaId!, serverAddress: widget.serverUrl);
  }

  Future<void> _deleteFile(_FileRow row) async {
    if (_busy.contains(row.key)) return;
    final name = row.name;
    final l10n = context.l10n;
    final confirm = await _confirm(
      title: l10n.manageServerPageDeleteFileTitle,
      body: l10n.manageServerPageDeleteFileBody(name),
    );
    if (confirm != true || !mounted) return;
    setState(() => _busy.add(row.key));
    try {
      final response = await _deleteOnServer(row);
      if (!mounted) return;
      if (response.success) {
        // The row leaves the list here; no second fetch of the whole library.
        setState(() => _removeRows({row.key}));
        _snack(l10n.manageServerPageDeletedNamed(name));
      } else {
        _snack(response.error?['message']?.toString() ??
            l10n.manageServerPageDeleteFailed);
      }
    } catch (e) {
      _snack(localizedError(l10n, e,
          fallback: l10n.manageServerPageDeleteFailed));
    } finally {
      if (mounted) setState(() => _busy.remove(row.key));
    }
  }

  /// Deletes every selected file, one request at a time, after ONE confirm.
  /// Leaving the screen stops the run after the request in flight.
  Future<void> _deleteSelected() async {
    if (_bulkDeleting || _selected.isEmpty) return;
    final l10n = context.l10n;
    final targets = [
      for (final r in _visible)
        if (_selected.contains(r.key)) r,
    ];
    final confirm = await _confirm(
      title: l10n.manageFilesPageDeleteManyTitle,
      body: l10n.manageFilesPageDeleteManyBody(targets.length),
    );
    if (confirm != true || !mounted) return;
    setState(() {
      _bulkDeleting = true;
      _bulkDone = 0;
      _bulkTotal = targets.length;
    });
    final deleted = <String>{};
    var failed = 0;
    for (final row in targets) {
      if (!mounted) return;
      try {
        final response = await _deleteOnServer(row);
        if (response.success) {
          deleted.add(row.key);
        } else {
          failed++;
        }
      } catch (_) {
        failed++;
      }
      if (mounted) setState(() => _bulkDone++);
    }
    if (!mounted) return;
    setState(() {
      _bulkDeleting = false;
      _removeRows(deleted);
      // Failed rows stay selected so the user can see them and retry.
      if (failed == 0) {
        _selecting = false;
        _selected.clear();
      }
    });
    _snack(failed == 0
        ? l10n.manageFilesPageDeletedCount(deleted.length)
        : l10n.manageFilesPageDeletedPartial(deleted.length, failed));
  }

  /// Drops deleted rows from the local list. Call inside `setState`.
  void _removeRows(Set<String> keys) {
    if (keys.isEmpty) return;
    _setRows([
      for (final r in _all)
        if (!keys.contains(r.key)) r,
    ]);
  }

  // ── Misc helpers ────────────────────────────────────────────────────────

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _openInBrowser(String url) async {
    final l10n = context.l10n;
    try {
      final uri = Uri.parse(url);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      _snack(localizedError(l10n, e,
          fallback: l10n.manageServerPageCouldNotOpen));
    }
  }

  /// Every confirm on this screen is a delete.
  Future<bool?> _confirm({required String title, required String body}) {
    final tokens = GlassTokens.of(context);
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        constraints: const BoxConstraints(
            minWidth: DialogWidth.min, maxWidth: DialogWidth.s),
        backgroundColor: tokens.surfaceDeep,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: tokens.borderSubtle),
        ),
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.dlgCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: Text(context.l10n.manageServerPageDelete),
          ),
        ],
      ),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final pageTokens = GlassTokens.of(context);
    // System back leaves selection mode first, the page second.
    return PopScope(
      canPop: !_selecting,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _exitSelection();
      },
      child: SystemAppScaffold(
        title: l10n.manageFilesPageTitle,
        icon: Icons.perm_media_outlined,
        pinHeader: true,
        actions: [
          if (_all.isNotEmpty)
            IconButton(
              tooltip: _selecting ? l10n.dlgCancel : l10n.manageFilesPageSelect,
              icon: Icon(
                _selecting ? Icons.close_rounded : Icons.checklist_rounded,
                size: 20,
              ),
              color: pageTokens.starkWhite,
              onPressed: _selecting ? _exitSelection : _enterSelection,
            ),
        ],
        builder: (context, scrollController, tokens) {
          _scroll = scrollController;
          // The scaffold's body runs behind its app bar; the fixed controls
          // start below it.
          final topInset = MediaQuery.paddingOf(context).top + kToolbarHeight;
          return Stack(
            children: [
              Column(
                children: [
                  SizedBox(height: topInset),
                  _buildControls(tokens),
                  Expanded(
                    child: AbsorbPointer(
                      absorbing: _bulkDeleting,
                      child: _buildList(scrollController, tokens),
                    ),
                  ),
                  if (_selecting) _buildSelectionBar(tokens),
                ],
              ),
              if (_loading)
                const Positioned(
                  right: 16,
                  bottom: 16,
                  child: SafeArea(
                    child: PhigitalLoadingWidget(size: 28, showShadows: false),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  // ── Controls: search, filter chips, count + sort ────────────────────────

  Widget _buildControls(GlassTokens tokens) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 2),
          child: _buildSearchField(tokens),
        ),
        ExplorerChipBar(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          fadeColor: tokens.background,
          children: [
            _kindChip(null, l10n.manageFilesPageFilterAll, Icons.apps_rounded),
            const SizedBox(width: 6),
            _kindChip(_FileKind.image, l10n.manageFilesPageFilterImages,
                Icons.image_outlined),
            const SizedBox(width: 6),
            _kindChip(_FileKind.video, l10n.manageFilesPageFilterVideos,
                Icons.movie_outlined),
            const SizedBox(width: 6),
            _kindChip(_FileKind.audio, l10n.manageFilesPageFilterAudio,
                Icons.audiotrack_rounded),
            const SizedBox(width: 6),
            _kindChip(_FileKind.other, l10n.manageFilesPageFilterOther,
                Icons.insert_drive_file_outlined),
            // Public / Private only mean something on a server that holds
            // private files.
            if (_privateCount > 0) ...[
              Container(
                width: 1,
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                color: tokens.borderSubtle,
              ),
              ExplorerChip(
                label: l10n.manageFilesPageFilterPublic,
                icon: Icons.public_rounded,
                active: _private == false,
                count: _all.length - _privateCount,
                onTap: () => _toggleVisibility(false),
              ),
              const SizedBox(width: 6),
              ExplorerChip(
                label: l10n.manageFilesPageFilterPrivate,
                icon: Icons.lock_outline_rounded,
                active: _private == true,
                count: _privateCount,
                onTap: () => _toggleVisibility(true),
              ),
            ],
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 2, 20, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.manageFilesPageShowing(
                      _visible.length, _formatBytes(_visibleBytes)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: tokens.textDim,
                  ),
                ),
              ),
              _buildSortMenu(tokens),
            ],
          ),
        ),
      ],
    );
  }

  Widget _kindChip(_FileKind? kind, String label, IconData icon) {
    return ExplorerChip(
      label: label,
      icon: icon,
      active: _kind == kind,
      count: kind == null ? _all.length : (_kindCounts[kind] ?? 0),
      onTap: () => _setKind(kind),
    );
  }

  Widget _buildSearchField(GlassTokens tokens) {
    return Container(
      decoration: BoxDecoration(
        color: tokens.glassFill,
        border: Border.all(color: tokens.borderSubtle),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _searchCtrl,
        textInputAction: TextInputAction.search,
        style: TextStyle(
          fontFamily: 'SpaceGrotesk',
          color: tokens.starkWhite,
          fontSize: 14,
        ),
        cursorColor: tokens.starkWhite,
        decoration: InputDecoration(
          isDense: true,
          prefixIcon:
              Icon(Icons.search_rounded, size: 18, color: tokens.textDim),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: _searchCtrl,
            builder: (context, value, _) {
              if (value.text.isEmpty) return const SizedBox.shrink();
              return IconButton(
                icon:
                    Icon(Icons.close_rounded, color: tokens.textDim, size: 18),
                onPressed: _searchCtrl.clear,
              );
            },
          ),
          hintText: context.l10n.manageFilesPageSearchHint,
          hintStyle: TextStyle(
            fontFamily: 'SpaceGrotesk',
            color: tokens.textDim,
            fontSize: 14,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildSortMenu(GlassTokens tokens) {
    return PopupMenuButton<_FileSort>(
      initialValue: _sort,
      onSelected: _setSort,
      color: tokens.surfaceDeep,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: tokens.borderSubtle),
      ),
      itemBuilder: (_) => [
        for (final s in _FileSort.values)
          PopupMenuItem<_FileSort>(
            value: s,
            child: Text(
              _sortLabel(s),
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                color: tokens.starkWhite,
              ),
            ),
          ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _sortLabel(_sort),
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                color: tokens.starkWhite,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.unfold_more_rounded, size: 16, color: tokens.textDim),
          ],
        ),
      ),
    );
  }

  // ── The list ────────────────────────────────────────────────────────────

  Widget _buildList(ScrollController c, GlassTokens tokens) {
    final l10n = context.l10n;
    final bottomInset = _selecting ? 0.0 : MediaQuery.paddingOf(context).bottom;
    return RefreshIndicator(
      onRefresh: () => _load(silent: true),
      color: tokens.starkWhite,
      backgroundColor: tokens.surfaceElevated,
      child: CustomScrollView(
        controller: c,
        physics: const AlwaysScrollableScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          if (_error != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: _errorBanner(tokens, _error!),
              ),
            ),
          if (_visible.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: (_loading || _error != null)
                  ? const SizedBox.shrink()
                  : _emptyHint(
                      tokens,
                      _all.isEmpty
                          ? l10n.manageServerPageNoMedia
                          : l10n.manageFilesPageNoMatches,
                    ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.fromLTRB(20, 4, 20, 24 + bottomInset),
              // Lazy on purpose: this is the fix. Do not turn it back into a
              // Column of rows.
              sliver: SliverList.builder(
                itemCount: _visible.length,
                itemBuilder: (context, i) => _buildRow(tokens, _visible[i]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRow(GlassTokens tokens, _FileRow file) {
    final l10n = context.l10n;
    final isImage = file.kind == _FileKind.image;
    // Browser-based affordances (non-image preview/download) are public-only:
    // the OS browser can't answer the envelope challenge.
    final hasPreview =
        isImage || (!file.isPrivate && _isKnownNonImageMime(file.mime));
    final hasDownload = hasPreview;
    final busy = _busy.contains(file.key);
    final selected = _selected.contains(file.key);
    return Padding(
      key: ValueKey(file.key),
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _selecting ? () => _toggleSelected(file) : null,
        onLongPress: _selecting ? null : () => _enterSelection(file),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
          decoration: BoxDecoration(
            color: selected
                ? tokens.connectedAccent.withValues(alpha: 0.10)
                : tokens.glassFill,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? tokens.connectedAccent.withValues(alpha: 0.6)
                  : tokens.borderSubtle,
            ),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: _thumbSize,
                  height: _thumbSize,
                  child: _buildThumb(tokens, file),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            file.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'SpaceGrotesk',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: tokens.starkWhite,
                            ),
                          ),
                        ),
                        if (file.isPrivate) ...[
                          const SizedBox(width: 6),
                          _privateBadge(tokens),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${file.mime.isEmpty ? l10n.manageServerPageUnknownMime : file.mime} · ${_formatBytes(file.fileSize)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'SpaceGrotesk',
                        fontSize: 11,
                        color: tokens.textDim,
                      ),
                    ),
                  ],
                ),
              ),
              if (_selecting)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 20,
                    color: selected ? tokens.connectedAccent : tokens.textDim,
                  ),
                )
              else if (busy)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: PhigitalLoadingWidget(size: 16, showShadows: false),
                )
              else ...[
                if (hasPreview)
                  _rowAction(
                    tokens,
                    icon: isImage
                        ? Icons.visibility_outlined
                        : Icons.open_in_new_rounded,
                    tooltip: isImage
                        ? l10n.manageServerPagePreview
                        : l10n.manageServerPageOpenInBrowser,
                    onTap: () => _previewFile(file),
                  ),
                if (hasDownload)
                  _rowAction(
                    tokens,
                    icon: Icons.download_outlined,
                    tooltip: l10n.manageServerPageDownload,
                    onTap: () => _downloadFile(file),
                  ),
                _rowAction(
                  tokens,
                  icon: Icons.link_rounded,
                  tooltip: l10n.manageServerPageCopyLink,
                  onTap: () => _copyFileUrl(file),
                ),
                _rowAction(
                  tokens,
                  icon: Icons.delete_outline_rounded,
                  tooltip: l10n.manageServerPageDelete,
                  color: Theme.of(context).colorScheme.error,
                  onTap: () => _deleteFile(file),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// The 40 px thumbnail. Images decode at thumbnail size. A video shows the
  /// server's poster and nothing heavier: when there is no poster the row
  /// gets an icon. Never cut a frame from the video here; that downloads the
  /// whole file.
  Widget _buildThumb(GlassTokens tokens, _FileRow file) {
    Widget iconBox(IconData icon) => Container(
          color: tokens.surfaceDeep,
          alignment: Alignment.center,
          child: Icon(icon, color: tokens.textDim, size: 18),
        );
    // 2x the box, in physical pixels: enough for BoxFit.cover to crop a wide
    // or tall picture without going soft.
    final decodeWidth =
        (_thumbSize * 2 * MediaQuery.devicePixelRatioOf(context)).round();
    switch (file.kind) {
      case _FileKind.image:
        return ZeroCachedImage(
          imageUrl: file.url,
          fit: BoxFit.cover,
          memCacheWidth: decodeWidth,
          preAuth: file.isPrivate,
          errorWidget: (_, __, ___) => iconBox(Icons.broken_image_outlined),
        );
      case _FileKind.video:
        return Stack(
          fit: StackFit.expand,
          children: [
            ZeroCachedImage(
              imageUrl: PublicOSSsp.posterUrlFor(file.url),
              fit: BoxFit.cover,
              memCacheWidth: decodeWidth,
              preAuth: file.isPrivate,
              placeholder: (_, __) => iconBox(Icons.movie_outlined),
              errorWidget: (_, __, ___) => iconBox(Icons.movie_outlined),
            ),
            Positioned(
              right: 2,
              bottom: 2,
              child: Container(
                padding: const EdgeInsets.all(1),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 12,
                ),
              ),
            ),
          ],
        );
      case _FileKind.audio:
      case _FileKind.other:
        return iconBox(_iconForMime(file.mime));
    }
  }

  Widget _privateBadge(GlassTokens tokens) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: tokens.fallbackAccent.withValues(alpha: 0.5),
        ),
        color: tokens.fallbackAccent.withValues(alpha: 0.08),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.lock_outline_rounded,
            size: 10,
            color: tokens.fallbackAccent,
          ),
          const SizedBox(width: 3),
          Text(
            context.l10n.manageServerPagePrivateBadge,
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: tokens.fallbackAccent,
            ),
          ),
        ],
      ),
    );
  }

  // ── Selection bar ───────────────────────────────────────────────────────

  Widget _buildSelectionBar(GlassTokens tokens) {
    final l10n = context.l10n;
    return Container(
      decoration: BoxDecoration(
        color: tokens.surfaceElevated,
        border: Border(top: BorderSide(color: tokens.borderSubtle)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 8, 6),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _bulkDeleting
                      ? l10n.manageFilesPageDeleting(_bulkDone, _bulkTotal)
                      : l10n.manageFilesPageSelectedCount(_selected.length),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: tokens.starkWhite,
                  ),
                ),
              ),
              if (_bulkDeleting)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: PhigitalLoadingWidget(size: 16, showShadows: false),
                )
              else ...[
                TextButton(
                  onPressed: _visible.isEmpty ? null : _toggleSelectAll,
                  style: TextButton.styleFrom(
                    foregroundColor: tokens.starkWhite,
                  ),
                  child: Text(l10n.manageFilesPageSelectAll),
                ),
                TextButton.icon(
                  onPressed: _selected.isEmpty ? null : _deleteSelected,
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: Text(l10n.manageServerPageDelete),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── Atoms (same look as Manage Server's) ────────────────────────────────

  Widget _rowAction(
    GlassTokens tokens, {
    required IconData icon,
    required String tooltip,
    required VoidCallback? onTap,
    Color? color,
  }) {
    final c = onTap == null
        ? tokens.textDim.withValues(alpha: 0.5)
        : (color ?? tokens.starkWhite);
    return Tooltip(
      message: tooltip,
      child: InkResponse(
        onTap: onTap,
        radius: 20,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 18, color: c),
        ),
      ),
    );
  }

  Widget _emptyHint(GlassTokens tokens, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            color: tokens.textDim,
            fontSize: 12,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _errorBanner(GlassTokens tokens, String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tokens.fallbackAccent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tokens.fallbackAccent.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded,
              size: 16, color: tokens.fallbackAccent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontSize: 12,
                color: tokens.fallbackAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── File model + MIME helpers ───────────────────────────────────────────────

/// One file of the merged library. Public and private rows differ only by the
/// PRIVATE badge and by which delete door they use.
class _FileRow {
  final String url;
  final String name;
  final int fileSize;
  final String createdAt;
  final bool isPrivate;
  final int? mediaId; // public rows: the deleteMedia key
  final String? pediaId; // private rows: the deletePedia key

  /// The displayable MIME ([_resolveMime]), the type bucket the filter chips
  /// use, and the lowercase name search and the name sort compare against.
  /// Worked out once per load, not once per build.
  final String mime;
  final _FileKind kind;
  final String nameLower;

  const _FileRow._({
    required this.url,
    required this.name,
    required this.fileSize,
    required this.createdAt,
    required this.isPrivate,
    required this.mediaId,
    required this.pediaId,
    required this.mime,
    required this.kind,
    required this.nameLower,
  });

  factory _FileRow.from({
    required String url,
    required String name,
    required String contentType,
    required int fileSize,
    required String createdAt,
    required bool isPrivate,
    int? mediaId,
    String? pediaId,
  }) {
    final mime = _resolveMime(contentType, name);
    return _FileRow._(
      url: url,
      name: name,
      fileSize: fileSize,
      createdAt: createdAt,
      isPrivate: isPrivate,
      mediaId: mediaId,
      pediaId: pediaId,
      mime: mime,
      kind: _kindOf(mime),
      nameLower: name.toLowerCase(),
    );
  }

  /// Stable per-row id: `m<id>` public, `p<id>` private.
  String get key => isPrivate ? 'p$pediaId' : 'm$mediaId';
}

/// The MIME a row shows and acts on. Some older uploads are stored as
/// `application/octet-stream`; for those the file name's extension decides.
/// Returns the stored type when it is already a real one.
String _resolveMime(String stored, String name) {
  if (stored.isNotEmpty && stored != 'application/octet-stream') {
    return stored;
  }
  final dot = name.lastIndexOf('.');
  if (dot < 0 || dot == name.length - 1) return stored;
  final ext = name.substring(dot + 1).toLowerCase();
  return _mimeForExtension(ext) ?? stored;
}

String? _mimeForExtension(String ext) {
  switch (ext) {
    case 'jpg':
    case 'jpeg':
      return 'image/jpeg';
    case 'png':
      return 'image/png';
    case 'gif':
      return 'image/gif';
    case 'webp':
      return 'image/webp';
    case 'bmp':
      return 'image/bmp';
    case 'svg':
      return 'image/svg+xml';
    case 'mp4':
      return 'video/mp4';
    case 'mov':
      return 'video/quicktime';
    case 'webm':
      return 'video/webm';
    case 'mp3':
      return 'audio/mpeg';
    case 'wav':
      return 'audio/wav';
    case 'm4a':
      return 'audio/mp4';
    case 'ogg':
      return 'audio/ogg';
    case 'pdf':
      return 'application/pdf';
    case 'txt':
      return 'text/plain';
    case 'md':
      return 'text/markdown';
    case 'html':
    case 'htm':
      return 'text/html';
    default:
      return null;
  }
}

_FileKind _kindOf(String mime) {
  if (mime.startsWith('image/')) return _FileKind.image;
  if (mime.startsWith('video/')) return _FileKind.video;
  if (mime.startsWith('audio/')) return _FileKind.audio;
  return _FileKind.other;
}

/// Non-image types a browser renders natively: these get the "Open in
/// browser" preview. Unknown types get no preview button.
bool _isKnownNonImageMime(String mime) {
  return mime.startsWith('video/') ||
      mime.startsWith('audio/') ||
      mime == 'application/pdf' ||
      mime == 'text/plain' ||
      mime == 'text/html' ||
      mime == 'text/markdown';
}

IconData _iconForMime(String mime) {
  if (mime.startsWith('video/')) return Icons.movie_outlined;
  if (mime.startsWith('audio/')) return Icons.audiotrack_rounded;
  if (mime == 'application/pdf') return Icons.picture_as_pdf_outlined;
  if (mime.startsWith('text/')) return Icons.description_outlined;
  return Icons.insert_drive_file_outlined;
}

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
}
