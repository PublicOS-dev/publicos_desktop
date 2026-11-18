import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:publicos_core/publicos_core.dart';
import 'package:zero_cached_image/zero_cached_image.dart';
import 'package:zero_cached_thumbnail/zero_cached_thumbnail.dart';
import 'package:publicos_desktop/widgets/shimmer_box.dart';
import 'package:publicos_desktop/widgets/feeds/go_to_feed.dart';
import 'package:publicos_desktop/widgets/feeds/post_card.dart';
import 'package:publicos_desktop/widgets/feeds/post_detail_page.dart';
import 'package:publicos_desktop/widgets/profile/content_card.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/utils/media_mime.dart';

/// Metadata of a pinned-post card (`cardKind: 'post'`).
/// The record's `value` is the post's own
/// permalink, `<server>/api/<owner>/channels/<slug>/posts/<uid>`, and nothing
/// about the post itself is stored: the card reads it live on every view, so
/// a reader's own gate decides what they see and a deleted post reads as gone.
///
/// What the OWNER stores (their look, not the post's content):
/// - the background, in the content card's keys, one mode at a time:
///   `metadata.image` · `metadata.gradient` · `color`, faded by `opacity`;
/// - [postMedia]: `true` = the post's own media sits IN FRONT of the
///   background (banner, else image, else the first attachment, video
///   included). Independent of the background by design: no cross-checks.
class PostCardMeta {
  static const kind = 'post';
  static const postMedia = 'postMedia';

  /// Where the pinner found the post, as a publicos tab link
  /// (`https://publicos.dev/publicosAddress/<foundVia>/tab/<key>`).
  /// Absent when the feed wasn't reached
  /// through a profile tab; "Go to feed" then opens the feed reader.
  static const feedLink = 'feedLink';

  /// A post card is always the grid's full width and its height is the
  /// post's own: the stored `width` /
  /// `height` are ignored. The height is capped at this many rows' worth;
  /// past it the card scrolls.
  static const maxRows = 4;
}

/// DELTA (desktop): where a pinned post opens. The `Browser` provides this
/// around its content area, so tapping a card shows the post IN that area,
/// over the profile, with the header collapsed. Scoped by the widget tree
/// rather than a static `AppNav` registry because desktop mounts two
/// Browsers at once (Contacts and Messages panes).
class PostFocusScope extends InheritedWidget {
  final void Function(Widget Function(VoidCallback onBack) builder) open;

  const PostFocusScope({super.key, required this.open, required super.child});

  static PostFocusScope? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<PostFocusScope>();

  @override
  bool updateShouldNotify(PostFocusScope oldWidget) => false;
}

/// What the card could make of its URL on the last read.
enum _PostCardState { loading, ready, gone, locked, failed }

class _CacheEntry {
  final Post? post;
  final _PostCardState state;
  final DateTime at;
  const _CacheEntry(this.post, this.state, this.at);
}

/// One piece of the post's media.
class _Media {
  final String url;
  final bool isVideo;
  const _Media(this.url, this.isVideo);
}

/// The face of a pinned-post card. Fetches the post through
/// `PublicOSChannels.getPostByUrl` (the URL's own server, owner casing kept)
/// and, when [interactive], opens it in [PostDetailPage] on tap, which is
/// exactly what a tap does in the feed reader.
///
/// The full post scrolls inside the card, but only when it overflows, so a
/// short post never takes the profile's vertical swipe. Bottom row, by the
/// card's width in grid cells: 3+ = reactions · comments · media, 2 = media,
/// 1 = nothing; the media counter only when the post has media.
///
/// Edit affordances (pencil / trash) are NOT drawn here: `RecordButton`
/// overlays them, as it does for every other kind.
class ProfilePostCard extends StatefulWidget {
  final String url;
  final double borderRadius;
  final bool interactive;

  /// [PostCardMeta.feedLink], when the pin stored one.
  final String? feedLink;

  /// The card's width in grid cells (`record.width`), which picks the
  /// counters.
  final int cells;

  /// The owner's background (the content card's keys). At most one of
  /// [image] / [gradient] / [color] is set by the editor; [opacity] fades it.
  final Color? color;
  final CardGradient? gradient;
  final String? image;
  final double opacity;

  /// Paint the post's own media in front of the background.
  final bool postMedia;

  const ProfilePostCard({
    super.key,
    required this.url,
    this.borderRadius = 16,
    this.interactive = true,
    this.feedLink,
    this.cells = 4,
    this.color,
    this.gradient,
    this.image,
    this.opacity = 1,
    this.postMedia = false,
  });

  /// The height each post card needs to show its whole post without
  /// scrolling, keyed `url@width` (the card's own laid-out width, rounded),
  /// published by the card after it lays out. The profile grid reads it to
  /// size the post card's row; the width in the key keeps a preview at a
  /// different width (the editor sheet) from overwriting the grid's value.
  static final ValueNotifier<Map<String, double>> naturalHeights =
      ValueNotifier(const {});

  static String heightKey(String url, double width) =>
      '$url@${width.round()}';

  /// The natural height for [url] at [width], or null until the card has
  /// laid out once at that width.
  static double? naturalHeightFor(String url, double width) =>
      naturalHeights.value[heightKey(url, width)];

  /// Reads everything the owner stored off a `cardKind:'post'` record. The
  /// stored footprint is ignored: a post card is always full width.
  factory ProfilePostCard.fromRecord(Record r, {bool interactive = true}) {
    final img = r.metadata['image'];
    return ProfilePostCard(
      url: r.value,
      borderRadius: r.borderRadius,
      interactive: interactive,
      feedLink: r.metadata[PostCardMeta.feedLink] as String?,
      cells: 4,
      color: r.color,
      gradient: CardGradient.tryParse(r.metadata['gradient']),
      image: img is String && img.trim().isNotEmpty ? img.trim() : null,
      opacity: (r.metadata['opacity'] as num?)?.toDouble() ?? 1,
      postMedia: r.metadata[PostCardMeta.postMedia] == true,
    );
  }

  @override
  State<ProfilePostCard> createState() => _ProfilePostCardState();
}

class _ProfilePostCardState extends State<ProfilePostCard>
    with SingleTickerProviderStateMixin {
  /// Process-wide: a profile repack or a sheet preview mounts a fresh State
  /// for the same URL, and a refetch on every mount would flash the loader.
  static final Map<String, _CacheEntry> _cache = {};
  static const _fresh = Duration(minutes: 2);

  Post? _post;
  _PostCardState _state = _PostCardState.loading;
  Contact? _author;

  /// The feed's name, for the "on account/feed" line and the opened post's
  /// header. The single-post read carries none, so it is
  /// looked up beside it.
  static final Map<String, String> _feedTitles = {};
  String? _feedTitle;

  String get _feedKey => '${widget.url}|${widget.feedLink ?? ''}';

  void _resolveFeed() {
    final key = _feedKey;
    _feedTitle = _feedTitles[key];
    if (_feedTitle == null) _loadFeedTitle(key);
  }

  Future<void> _loadFeedTitle(String key) async {
    try {
      final title = await feedTitleFor(widget.url, widget.feedLink);
      if (title == null) return;
      _feedTitles[key] = title;
      if (mounted && key == _feedKey) setState(() => _feedTitle = title);
    } catch (_) {}
  }

  final ScrollController _scroll = ScrollController();

  /// Whether the post is taller than the card. Only then does the card
  /// scroll; otherwise the profile keeps the vertical swipe.
  bool _overflows = false;

  // The loading rule: the card shimmers until it has EVERYTHING its final face
  // needs, the post AND its author's name + avatar, then the content fades in.
  // The author gets [_authorGraceDuration]; past it the post shows with the
  // short address and the name replaces it when it lands.
  late final AnimationController _shimmer = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  );
  bool _authorSettled = false;
  Timer? _authorGrace;
  static const _authorGraceDuration = Duration(milliseconds: 1500);

  void _settleAuthor() {
    _authorGrace?.cancel();
    if (!_authorSettled && mounted) setState(() => _authorSettled = true);
  }

  @override
  void initState() {
    super.initState();
    _load();
    _resolveFeed();
  }

  @override
  void didUpdateWidget(covariant ProfilePostCard old) {
    super.didUpdateWidget(old);
    if (old.url != widget.url) {
      _author = null;
      _authorSettled = false;
      _authorGrace?.cancel();
      _authorGrace = null;
      _load();
    }
    if (old.url != widget.url || old.feedLink != widget.feedLink) {
      _resolveFeed();
    }
  }

  @override
  void dispose() {
    _authorGrace?.cancel();
    _shimmer.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load({bool force = false}) async {
    final cached = _cache[widget.url];
    if (cached != null) {
      _post = cached.post;
      _state = cached.state;
      if (_post != null) _resolveAuthor(_post!);
      if (!force && DateTime.now().difference(cached.at) < _fresh) {
        if (mounted) setState(() {});
        return;
      }
    } else {
      _state = _PostCardState.loading;
    }
    final url = widget.url;
    final resp = await PublicOSChannels.getPostByUrl(url);
    if (!mounted || url != widget.url) return;
    final _PostCardState next;
    Post? post;
    if (resp.success && resp.data != null) {
      post = resp.data;
      next = _PostCardState.ready;
    } else {
      final code = resp.error?['code'] as String?;
      next = switch (code) {
        'POST_NOT_FOUND' ||
        'CHANNEL_NOT_FOUND' ||
        'ACCOUNT_NOT_FOUND' ||
        'BAD_POST_URL' =>
          _PostCardState.gone,
        // The SSP's read-ladder refusals. The single-post read runs the
        // same gate as the feed, before it reveals whether the post exists.
        'ENVELOPE_MISSING' ||
        'ENVELOPE_INVALID' ||
        'PRIVATE_FEED' ||
        'PRIVATE_FEED_NOT_APPROVED' ||
        'PAYWALL_DENIED' ||
        'STANDING_REQUIRED' ||
        'VERIFIED_ONLY' ||
        'ACCOUNT_ONLY' ||
        'ACCESS_DENIED' ||
        'BANNED' =>
          _PostCardState.locked,
        _ => _PostCardState.failed,
      };
    }
    // A transient failure keeps a copy we already had on screen.
    if (next == _PostCardState.failed && _post != null) return;
    _cache[url] = _CacheEntry(post, next, DateTime.now());
    setState(() {
      _post = post;
      _state = next;
    });
    if (post != null) _resolveAuthor(post);
  }

  Future<void> _resolveAuthor(Post post) async {
    final addr = post.postAuthorAddress ?? post.channelOwnerAddress;
    if (addr == null || addr.isEmpty) return _settleAuthor();
    if (_author?.publicosAddress?.eip55With0x.toLowerCase() ==
        addr.toLowerCase()) {
      return _settleAuthor();
    }
    _authorGrace ??= Timer(_authorGraceDuration, _settleAuthor);
    try {
      var c = await PublicOSContacts.searchContacts(addr);
      if (c == null) {
        c = await PublicOSContacts.resolveByIdentifier(addr);
        if (c != null) await PublicOSContacts.saveContact(c);
      }
      if (mounted && c != null) setState(() => _author = c);
    } catch (_) {
      // An unresolved author shows its short address; never a nearby name.
    }
    _settleAuthor();
  }

  /// The post as the post card and the detail page read it: the pin's
  /// found-via + tab key, the derived feed URL and the feed's name.
  Post _stamped(Post post) =>
      withFeedLink(post, widget.feedLink).copyWith(feedTitle: _feedTitle);

  void _open() {
    final loaded = _post;
    if (loaded == null) {
      if (_state == _PostCardState.failed) _load(force: true);
      return;
    }
    // The feed's name too, so the page's header reads as it does for a post
    // tapped from the feed.
    final post = _stamped(loaded);
    final addr = post.postAuthorAddress;
    final contacts = <String, Contact>{
      if (addr != null && _author != null) addr: _author!,
    };
    // DELTA (desktop): inside a Browser the post opens IN its content area
    // ([PostFocusScope]); a builder is handed up, the same shape as
    // `AppNav.toPost`, so the host only supplies `onBack`. Anywhere else
    // (no Browser above) the client's push, with the page's back arrow
    // popping the route.
    final scope = PostFocusScope.maybeOf(context);
    if (scope != null) {
      scope.open((onBack) => PostDetailPage(
            post: post,
            resolvedContacts: contacts,
            onBack: onBack,
          ));
      return;
    }
    Navigator.of(context).push(CupertinoPageRoute(
      builder: (routeContext) => PostDetailPage(
        post: post,
        resolvedContacts: contacts,
        onBack: () => Navigator.of(routeContext).pop(),
      ),
    ));
  }

  /// The post's media, deduplicated, in the order the card uses it: the
  /// heroes, then the support media the carousel renders (images and videos).
  List<_Media> _mediaOf(Post post) {
    final out = <_Media>[];
    final seen = <String>{};
    void add(PostMedia m) {
      final url = m.url.trim();
      if (url.isEmpty || !seen.add(url)) return;
      out.add(_Media(url, m.isVideo || isVideoUrl(url)));
    }

    post.heroMedia.forEach(add);
    for (final m in post.supportMedia) {
      if (m.isRenderableMedia) add(m);
    }
    return out;
  }

  /// Whether the owner gave the card a background of its own.
  bool get _ownBackground =>
      widget.image != null ||
      widget.gradient != null ||
      (widget.color != null && widget.color!.a > 0);

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final radius = BorderRadius.circular(widget.borderRadius);
    // Skeleton until the final face is complete (post + author), then fade.
    final skeleton = _state == _PostCardState.loading ||
        (_state == _PostCardState.ready && !_authorSettled);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (skeleton && !_shimmer.isAnimating) _shimmer.repeat();
      if (!skeleton && _shimmer.isAnimating) _shimmer.stop();
    });
    final Widget face = skeleton
        ? _buildSkeleton(tokens)
        : switch (_state) {
      _PostCardState.loading => _background(tokens),
      _PostCardState.ready => _buildPost(context, tokens, _post!),
      _PostCardState.gone => _buildNotice(tokens, Icons.link_off_rounded,
          context.l10n.postCardPinnedGone),
      _PostCardState.locked => _buildNotice(
          tokens, Icons.lock_rounded, context.l10n.postCardPinnedLocked),
      _PostCardState.failed => _buildNotice(tokens, Icons.refresh_rounded,
          context.l10n.postCardPinnedFailed),
    };
    final child = AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      layoutBuilder: (current, previous) => Stack(
        fit: StackFit.expand,
        children: [...previous, if (current != null) current],
      ),
      child: KeyedSubtree(
        key: ValueKey<String>(skeleton ? 'skeleton' : _state.name),
        child: face,
      ),
    );
    return ClipRRect(
      borderRadius: radius,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.interactive ? _open : null,
        child: child,
      ),
    );
  }

  /// The owner's background: image, gradient or colour at [opacity], else
  /// the plain glass panel.
  Widget _background(GlassTokens tokens) {
    final image = widget.image;
    if (image != null) {
      return Opacity(
        opacity: widget.opacity.clamp(0.0, 1.0),
        child: ZeroCachedImage(imageUrl: image, fit: BoxFit.cover),
      );
    }
    final gradient = widget.gradient;
    if (gradient != null) {
      return DecoratedBox(
        decoration: BoxDecoration(
            gradient: gradient.toLinearGradient(opacity: widget.opacity)),
      );
    }
    final color = widget.color;
    if (color != null && color.a > 0) {
      return ColoredBox(color: color.withValues(alpha: widget.opacity));
    }
    return Container(
      decoration: BoxDecoration(
        color: tokens.glassFill,
        border: Border.all(color: tokens.borderSubtle),
        borderRadius: BorderRadius.circular(widget.borderRadius),
      ),
    );
  }

  /// The post's first media, full-bleed, with a scrim so the text reads.
  Widget _mediaLayer(_Media m) {
    final Widget pic = m.isVideo
        ? ZeroCachedThumbnailWidget(
            source: ThumbnailSource.url(m.url),
            fit: BoxFit.cover,
            placeholder: (_) => const ColoredBox(color: Colors.black),
          )
        : ZeroCachedImage(imageUrl: m.url, fit: BoxFit.cover);
    return Stack(
      fit: StackFit.expand,
      children: [
        pic,
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x66000000), Color(0x40000000), Color(0xCC000000)],
              stops: [0, 0.45, 1],
            ),
          ),
        ),
      ],
    );
  }

  /// The skeleton: the final face's geometry in [ShimmerBox]es: the author's
  /// squircle + name, a title bar, three body lines, the counters row. Painted
  /// on the owner's background; the lines are clipped rather than overflow on
  /// a short card.
  Widget _buildSkeleton(GlassTokens tokens) {
    final own = _ownBackground;
    final base = own
        ? Colors.white.withValues(alpha: 0.10)
        : tokens.surfaceElevated;
    final highlight = own
        ? Colors.white.withValues(alpha: 0.22)
        : Color.alphaBlend(
            tokens.starkWhite.withValues(alpha: 0.10), tokens.surfaceElevated);
    Widget bar(double h, double w, {double r = 5}) => ShimmerBox(
        progress: _shimmer,
        height: h,
        width: w,
        radius: r,
        base: base,
        highlight: highlight);
    return Stack(
      fit: StackFit.expand,
      children: [
        _background(tokens),
        Padding(
          padding: const EdgeInsets.all(10),
          child: LayoutBuilder(builder: (context, c) {
            final w = c.maxWidth;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  bar(PostCard.avatarSize, PostCard.avatarSize,
                      r: PostCard.avatarSize * 0.40),
                  const SizedBox(width: PostCard.gutter),
                  bar(13, 110),
                ]),
                const SizedBox(height: 8),
                Expanded(
                  child: ClipRect(
                    child: OverflowBox(
                      alignment: Alignment.topLeft,
                      maxHeight: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          bar(13, w * 0.58, r: 6),
                          const SizedBox(height: 7),
                          bar(9, w * 0.96),
                          const SizedBox(height: 6),
                          bar(9, w * 0.90),
                          const SizedBox(height: 6),
                          bar(9, w * 0.72),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [bar(9, 28), bar(9, 28), bar(9, 28)],
                ),
              ],
            );
          }),
        ),
      ],
    );
  }

  Widget _buildNotice(GlassTokens tokens, IconData icon, String text) {
    final dim = _ownBackground ? Colors.white70 : tokens.textDim;
    return Stack(
      fit: StackFit.expand,
      children: [
        _background(tokens),
        Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: dim),
              const SizedBox(height: 6),
              Text(
                text,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: dim, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// The text column inside the scroll view, measured for [_publishHeight].
  final GlobalKey _textKey = GlobalKey();

  void _checkOverflow() {
    if (!mounted || !_scroll.hasClients) return;
    final o = _scroll.position.maxScrollExtent > 0;
    if (o != _overflows) setState(() => _overflows = o);
    _publishHeight();
  }

  /// The height this card needs for its whole post: its current height, less
  /// the scroll viewport, plus the text's own height. Exact whatever height
  /// the grid gave it, so the grid can converge in one step.
  void _publishHeight() {
    final text = _textKey.currentContext?.findRenderObject();
    final size = context.size;
    if (text is! RenderBox || !text.hasSize || size == null) return;
    final natural = size.height -
        _scroll.position.viewportDimension +
        text.size.height;
    final key = ProfilePostCard.heightKey(widget.url, size.width);
    final old = ProfilePostCard.naturalHeights.value[key];
    if (old != null && (old - natural).abs() < 0.5) return;
    ProfilePostCard.naturalHeights.value = {
      ...ProfilePostCard.naturalHeights.value,
      key: natural,
    };
  }

  Widget _buildPost(BuildContext context, GlassTokens tokens, Post post) {
    final media = _mediaOf(post);
    final showMedia = widget.postMedia && media.isNotEmpty;
    final onColor = _ownBackground || showMedia;
    final title = post.title.trim();
    final body = (post.contentText ?? post.summary ?? '').trim();
    final fg = onColor ? Colors.white : tokens.starkWhite;
    final dim = onColor ? Colors.white70 : tokens.textDim;
    // Body text sits 3/4 of the way from the dim tone to the title's (the dim
    // tone alone reads too dark); the title stays brighter.
    final bodyColor = Color.lerp(dim, fg, 0.75)!;
    final stamped = _stamped(post);
    final authorAddr = post.postAuthorAddress;
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkOverflow());

    return Stack(
      fit: StackFit.expand,
      children: [
        _background(tokens),
        if (showMedia) _mediaLayer(media.first),
        Padding(
          padding: const EdgeInsets.all(10),
          // The post card's OWN header row and action row, on its state (the
          // icon, the name, the "on account/feed" line, the reaction button
          // and its sheets), laid around this card's text. Dead in edit mode and in
          // a preview, where the taps belong to the grid.
          child: IgnorePointer(
            ignoring: !widget.interactive,
            child: PostCard(
              post: stamped,
              theme: Theme.of(context),
              resolvedContacts: {
                if (authorAddr != null && _author != null)
                  authorAddr: _author!,
              },
              // The line shows when the pin carries where it was found.
              showFeedContext: feedTabOf(widget.feedLink) != null,
              partsTokens: onColor ? GlassTokens.dark : null,
              partsBuilder: (context, header, actions) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 18),
                        child: header,
                      ),
                      Positioned(
                        top: 6,
                        right: 0,
                        child: Icon(Icons.push_pin_rounded,
                            size: 13, color: dim),
                      ),
                    ],
                  ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: SingleChildScrollView(
                        controller: _scroll,
                        // Scroll only a post that overflows, and never in edit mode
                        // or a preview (where the drag belongs to the grid).
                        physics: widget.interactive && _overflows
                            ? const ClampingScrollPhysics()
                            : const NeverScrollableScrollPhysics(),
                        child: Column(
                          key: _textKey,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (title.isNotEmpty) ...[
                              Text(
                                title,
                                style: TextStyle(
                                    color: fg,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 3),
                            ],
                            if (body.isNotEmpty)
                              Text(
                                body,
                                style: TextStyle(
                                    color: bodyColor, fontSize: 12, height: 1.35),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    actions,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
