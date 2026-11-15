import 'package:flutter/material.dart';

import 'package:publicos_desktop/theme/glass_tokens.dart';
// DESKTOP DELTA: on the client this file also defines SystemAppActionButton +
// DashedRRectPainter. Desktop keeps those in `system_app_action_button.dart`;
// the implementations are byte-identical, so this port re-exports rather than
// duplicating the classes.
export 'package:publicos_desktop/widgets/system_app_action_button.dart';

/// Shared chrome for the system-app pages launched from the Apps grid
/// (Treasury / Account Center / Settings / Nodes / BSP / SSP). Provides:
///
///  - `Scaffold` + transparent `AppBar` + back button (pops via
///    `Navigator.pop` so iOS swipe-back + Android back both work)
///  - Icon pill + title in the AppBar (pinned via `pinHeader: true`, the
///    canonical mode for system-app pages — title lives in the AppBar at
///    full opacity, no big body header)
///
/// Usage:
///
/// ```dart
/// SystemAppScaffold(
///   title: 'Nodes',
///   icon: Icons.hub_rounded,
///   pinHeader: true,
///   builder: (context, scrollController, tokens) {
///     return ListView(
///       controller: scrollController,
///       children: [
///         SizedBox(height: kToolbarHeight + 60),
///         // sections — use local _sectionHeader(tokens, icon, title)
///         // helper, no outer card.
///       ],
///     );
///   },
/// )
/// ```
///
/// The page owns its body widget (typically `ListView` or `CustomScrollView`)
/// and must attach the provided `ScrollController`.
class SystemAppScaffold extends StatefulWidget {
  final String title;
  final IconData icon;

  /// Optional bundled art (`assets/system_apps/*.png`, Fluent style) shown in
  /// place of [icon] — the picture the rail and the Apps tile already show for
  /// this page, so the place you clicked and the page you land on read as one
  /// thing. [icon] stays the decode-failure fallback and the glyph for pages
  /// with no art (Nodes).
  final String? asset;
  final Widget Function(
    BuildContext context,
    ScrollController scrollController,
    GlassTokens tokens,
  ) builder;

  /// Optional trailing widgets shown in the AppBar (refresh / overflow / etc.)
  final List<Widget>? actions;

  /// When true, the AppBar shows icon + title at full opacity always (no
  /// scroll fade). Caller is expected to omit [SystemAppHeader] from the
  /// body since the title is already visible in the AppBar.
  final bool pinHeader;

  /// Whether to show the AppBar back button.
  ///
  /// DESKTOP DELTA: defaults to "only when there is something to
  /// pop". On the client every system app is a pushed route, so a back button
  /// is always right. On desktop some of these same pages are mounted
  /// DIRECTLY as shell panes (Nodes / Treasury / Account), where the shell is
  /// the root route and `Navigator.pop` would have nothing to pop. Deriving it
  /// from `canPop()` keeps both mounts correct without the ported pages having
  /// to know which one they are in — set it explicitly only to override.
  final bool? showBack;

  /// Optional max width for the page — and the switch into PANE MODE.
  ///
  /// DESKTOP DELTA: the client's system apps are full-bleed phone
  /// pages. Mounted as a desktop shell pane they stretch every row to the
  /// window edge, which is unreadable on a wide monitor. When set, the WHOLE
  /// scaffold is centred in a column of this width. 720 is the pane width
  /// every shell-mounted system page uses (Settings / Account / Treasury /
  /// Nodes).
  ///
  /// DESKTOP DELTA: in pane mode the client's AppBar (icon pill + 16 pt
  /// tracked title, centred) is
  /// REPLACED by the Settings-style page header — the page's papercraft art
  /// ([asset], 32 px; a grey 22 px glyph when there is none) and a
  /// 24 pt w800 title, left-aligned in the content gutter, [actions] at the
  /// row's right end. It is still PINNED: an opaque `tokens.background` block
  /// exactly [kPaneHeaderHeight] tall sits over the scrolling body, so the
  /// client pages' verbatim `SizedBox(height: kToolbarHeight + 60)` first
  /// child clears it with the same 28 px breath Settings has always had —
  /// the ported pages need no edit to pick this up. This gives Settings,
  /// Account, Treasury and Nodes one header on the same rail.
  ///
  /// Null (the default) keeps the client's full-bleed AppBar behaviour, which
  /// is correct for the pushed-route / dialog callers (Notifications).
  final double? maxContentWidth;

  /// Pane-mode header block height: 28 top breath + the 24 pt title line +
  /// 28 below = 88, which is `kToolbarHeight + 60 - 28` — so the client
  /// pages' toolbar spacer leaves exactly 28 px between header and first
  /// section, matching the Settings pane it was modelled on.
  static const double kPaneHeaderHeight = kToolbarHeight + 32;

  const SystemAppScaffold({
    super.key,
    required this.title,
    required this.icon,
    this.asset,
    required this.builder,
    this.actions,
    this.pinHeader = false,
    this.showBack,
    this.maxContentWidth,
  });

  @override
  State<SystemAppScaffold> createState() => _SystemAppScaffoldState();
}

class _SystemAppScaffoldState extends State<SystemAppScaffold> {
  final ScrollController _scrollController = ScrollController();

  /// 0 = big title fully visible (and compact title hidden)
  /// 1 = big title scrolled past (compact title fully in header)
  double _headerProgress = 0.0;

  static const double _fadeStart = 40;
  static const double _fadeEnd = 100;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final offset = _scrollController.offset;
    final next = ((offset - _fadeStart) / (_fadeEnd - _fadeStart))
        .clamp(0.0, 1.0);
    if ((next - _headerProgress).abs() > 0.01) {
      setState(() => _headerProgress = next);
    }
  }

  /// [SystemAppScaffold.asset] at [size], rounded like the rail's art
  /// (radius 9 at 28 px), or [fallback] when there is no art or it fails to
  /// decode.
  Widget _headerArt(double size, Widget fallback) {
    final asset = widget.asset;
    if (asset == null) return fallback;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 9 / 28),
      child: Image.asset(
        asset,
        width: size,
        height: size,
        fit: BoxFit.cover,
        cacheWidth: (size * dpr).round(),
        errorBuilder: (_, __, ___) => fallback,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final pinned = widget.pinHeader;
    final progress = pinned ? 1.0 : _headerProgress;
    final accent = tokens.connectedAccent;
    final constrained = widget.maxContentWidth != null;
    if (constrained) return _buildPane(context, tokens);
    final scaffold = Scaffold(
      // Transparent when constrained: the host pane already paints the content
      // tone, and letting it show through avoids a faintly visible column edge
      // where `background` and `ShellTones.content` diverge (they are equal in
      // dark, ~1% apart in light).
      backgroundColor: constrained ? Colors.transparent : tokens.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: tokens.background.withValues(
          alpha: pinned ? 0.85 : progress * 0.85,
        ),
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        leading: (widget.showBack ?? Navigator.of(context).canPop())
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                color: tokens.starkWhite,
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        title: pinned
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _headerArt(
                    28,
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: tokens.glassFill,
                        border: Border.all(
                          color: accent.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Icon(widget.icon, color: accent, size: 16),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    widget.title,
                    style: TextStyle(
                      color: tokens.starkWhite,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              )
            : Opacity(
                opacity: progress,
                child: Transform.translate(
                  offset: Offset(0, (1 - progress) * 12),
                  child: Text(
                    widget.title,
                    style: TextStyle(
                      color: tokens.starkWhite,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
        centerTitle: true,
        actions: widget.actions,
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: widget.builder(context, _scrollController, tokens),
      ),
    );
    return scaffold;
  }

  /// PANE MODE (see [SystemAppScaffold.maxContentWidth]): the Settings-style
  /// header pinned over the scrolling body, the whole thing centred in a
  /// [SystemAppScaffold.maxContentWidth] column. Transparent scaffold: the
  /// host pane already paints the content tone.
  Widget _buildPane(BuildContext context, GlassTokens tokens) {
    final showBack = widget.showBack ?? Navigator.of(context).canPop();
    final header = Container(
      height: SystemAppScaffold.kPaneHeaderHeight,
      // Opaque, so body content scrolling underneath disappears behind it
      // exactly as it did behind the AppBar. `background` == the pane's
      // content tone (ShellTones.content), so the block is invisible at rest.
      color: tokens.background,
      padding: const EdgeInsets.fromLTRB(20, 28, 12, 0),
      alignment: Alignment.topLeft,
      child: Row(
        children: [
          if (showBack) ...[
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              color: tokens.starkWhite,
              onPressed: () => Navigator.of(context).pop(),
            ),
            const SizedBox(width: 4),
          ],
          // Art at 32 px (the title line's height); a page with no art keeps a
          // GREY glyph — teal is a state colour, not a page mark.
          _headerArt(32, Icon(widget.icon, color: tokens.textDim, size: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                color: tokens.starkWhite,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
          ),
          ...?widget.actions,
        ],
      ),
    );
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: widget.maxContentWidth!),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              Positioned.fill(
                child: SafeArea(
                  top: false,
                  bottom: false,
                  child: widget.builder(context, _scrollController, tokens),
                ),
              ),
              Positioned(top: 0, left: 0, right: 0, child: header),
            ],
          ),
        ),
      ),
    );
  }
}
