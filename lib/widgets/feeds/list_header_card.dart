import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:publicos_core/publicos_core.dart';
import 'package:publicos_desktop/widgets/feeds/feed_favicon.dart';
import 'package:publicos_desktop/widgets/glass_contact_icon.dart';
import 'package:publicos_desktop/widgets/members_stack.dart';
import 'package:publicos_desktop/widgets/shimmer_box.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';
import 'package:publicos_desktop/widgets/feeds/feed_source.dart';
import 'package:publicos_desktop/utils/feed_metadata_utils.dart';
import 'package:zero_cached_image/zero_cached_image.dart';

/// Who a list follows: the people (as contacts) and the individual feeds.
/// Loaded once by the host per list and after the list was managed, then
/// handed to both the scroll-away [ListHeaderCard] and the inline header's
/// [ListMiniStack], so the two never disagree.
///
/// Both lists come out **latest poster first**: ranked by the newest post
/// each one has in the list's cached deck, so the six tiles of a big list
/// are the six who posted last. Anyone with no cached post keeps the follow order, behind
/// the ones that did.
class ListFollowSummary {
  final List<Contact> people;
  final List<ListFeed> feeds;

  const ListFollowSummary({required this.people, required this.feeds});

  bool get isEmpty => people.isEmpty && feeds.isEmpty;

  /// [roster] is the host's resolved roster for the list (its feeds plus the
  /// followed accounts' channels); its cached posts give the ranking. Null
  /// leaves the follow order.
  static Future<ListFollowSummary> load(
    int listId, {
    List<FeedSource>? roster,
  }) async {
    final session = PublicOS.sessionBlockchainAddress;
    final follows = session == null
        ? const <FollowedAccount>[]
        : await PublicOS.database.listFollowedAccounts(
            session: session,
            listId: listId,
          );
    final feeds = await PublicOSFeedLists.getFeedsInList(listId);
    final people = <Contact>[];
    for (final f in follows) {
      try {
        final c = await PublicOSContacts.getContact(
          EthereumAddress.fromHex(f.accountAddress),
        );
        if (c != null) people.add(c);
      } catch (_) {}
    }
    if (roster == null || roster.isEmpty) {
      return ListFollowSummary(people: people, feeds: feeds);
    }

    // Newest post per feed url, and per account (an account's channels are
    // the roster rows found at its address; a signed post names it too).
    final byFeed = <String, DateTime>{};
    final byAccount = <String, DateTime>{};
    void bump(Map<String, DateTime> m, String? k, DateTime t) {
      if (k == null || k.isEmpty) return;
      final cur = m[k];
      if (cur == null || t.isAfter(cur)) m[k] = t;
    }

    try {
      final cached = await PublicOSFeedLists.getCachedPostsForFeeds([
        for (final r in roster)
          ListFeed(
            id: -1,
            listId: listId,
            feedUrl: r.url,
            feedTitle: r.title,
            feedFoundAtAccountAddress: r.effectiveFoundAtAddress,
            feedRecordKey: r.recordKey,
            addedAt: DateTime.fromMillisecondsSinceEpoch(0),
          ),
      ]);
      // The same decode carries each feed's icon: into the registry, so the
      // card's tiles paint from it.
      FeedMetadataUtils.rememberIcons(cached.feedIcons);
      final ownerOf = {
        for (final r in roster) r.url: r.effectiveFoundAtAddress?.toLowerCase(),
      };
      for (final p in cached.posts) {
        final t = p.createdAt;
        bump(byFeed, p.feedUrl, t);
        bump(byAccount, ownerOf[p.feedUrl], t);
        bump(byAccount, p.postAuthorAddress?.toLowerCase(), t);
      }
    } catch (_) {
      // No cache to rank by: the follow order stands.
    }

    List<T> ranked<T>(List<T> items, DateTime? Function(T) latest) {
      final indexed = [for (var i = 0; i < items.length; i++) (i, items[i])];
      indexed.sort((a, b) {
        final ta = latest(a.$2), tb = latest(b.$2);
        if (ta != null && tb != null) {
          final c = tb.compareTo(ta);
          if (c != 0) return c;
        } else if (ta != null) {
          return -1;
        } else if (tb != null) {
          return 1;
        }
        return a.$1.compareTo(b.$1);
      });
      return [for (final e in indexed) e.$2];
    }

    return ListFollowSummary(
      people: ranked(
        people,
        (c) => byAccount[c.publicosAddress?.eip55With0x.toLowerCase()],
      ),
      feeds: ranked(feeds, (f) => byFeed[f.feedUrl]),
    );
  }
}

/// The scroll-away header at the top of a LIST's feed, in the slot a single
/// channel uses for its description ([ChannelHeaderCard]: same behaviour and
/// placement, different contents). It is two [PhotoStack]s side by side: the
/// people the list
/// follows and its individual feeds, each a fan of tiles over a box that
/// carries the count. An empty side is not there at all, and a list that
/// follows nothing shows one line inviting the first follow. Any tap opens
/// "Manage [list]" (the Manage button itself lives in the inline header).
///
/// The tiles rise from behind the boxes once their images are on disk: the
/// card fetches the shown tiles' images first, with a
/// ceiling so a slow host never keeps the stack empty, then plays the rise
/// once per summary. Scrolling away and back does not replay it.
///
/// It is an item in the scroll view, so it leaves with the content and comes
/// back at the top; the host watches the scroll to know when it is gone and
/// moves the mini stack into the inline header then.
class ListHeaderCard extends StatefulWidget {
  final ListFollowSummary? summary;

  /// Same inset as the posts below ([ChannelHeaderCard.leftInset]).
  final double leftInset;
  final VoidCallback onManage;

  const ListHeaderCard({
    super.key,
    required this.summary,
    required this.onManage,
    this.leftInset = 16,
  });

  @override
  State<ListHeaderCard> createState() => _ListHeaderCardState();
}

class _ListHeaderCardState extends State<ListHeaderCard>
    with TickerProviderStateMixin {
  /// The summary whose rise already played, by WHO IS IN IT ([_signature]).
  /// Static, so the card coming back after a scroll (a fresh State) shows
  /// its tiles in place. Not by object: every reload of the feed hands the
  /// card a fresh summary of the same list, and the rise would replay each
  /// time one finished, e.g. on coming back from Contacts. It plays the first
  /// time the reader lands here and not again when a load finishes.
  static String? _played;

  /// The people and feeds a summary holds, order aside: a reload that only
  /// re-ranks the latest posters is still the same list.
  static String _signature(ListFollowSummary s) {
    final people = [
      for (final c in s.people)
        c.publicosAddress?.eip55With0x.toLowerCase() ?? c.displayName,
    ]..sort();
    final feeds = [for (final f in s.feeds) f.feedUrl]..sort();
    return '${people.join(',')}|${feeds.join(',')}';
  }

  /// Longest wait for the images before the tiles rise anyway.
  static const _warmCeiling = Duration(milliseconds: 2500);

  // One sweep for every tile still loading, in sync (the post card's rate).
  late final AnimationController _shimmer = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  late final AnimationController _rise = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    _arm();
  }

  @override
  void didUpdateWidget(ListHeaderCard old) {
    super.didUpdateWidget(old);
    if (!identical(old.summary, widget.summary)) _arm();
  }

  @override
  void dispose() {
    _shimmer.dispose();
    _rise.dispose();
    super.dispose();
  }

  void _arm() {
    final s = widget.summary;
    if (s == null) return;
    final sig = _signature(s);
    if (sig == _played) {
      _rise.value = 1;
      return;
    }
    _rise.value = 0;
    _warm(s).timeout(_warmCeiling, onTimeout: () {}).whenComplete(() {
      if (!mounted || !identical(widget.summary, s)) return;
      _played = sig;
      _rise.forward(from: 0);
    });
  }

  /// Fetch the shown tiles' images to the disk cache, the way the tiles
  /// themselves resolve them: a contact's verified NFT art or avatar, a
  /// feed's own image or its site favicon.
  Future<void> _warm(ListFollowSummary s) async {
    final jobs = <Future<void>>[];
    for (final c in s.people.take(PhotoStack.maxTiles)) {
      final ref = c.nftAvatar;
      final cache = c.verifiedNftAvatarData;
      final url =
          (ref != null &&
              cache != null &&
              cache.matches(ref) &&
              (cache.imageUrl?.isNotEmpty ?? false))
          ? cache.imageUrl
          : (c.getRecordValue('profile.avatar.resolved') ?? c.avatarUrl);
      jobs.add(_fetch(url));
    }
    for (final f in s.feeds.take(PhotoStack.maxTiles)) {
      // The registry answers at once for any feed a load has read; an
      // unknown one shares the tile's own fetch (one per feed, not two).
      jobs.add(() async {
        await _fetch(await FeedMetadataUtils.resolveDisplayIcon(f.feedUrl));
      }());
    }
    await Future.wait(jobs);
  }

  /// One image to the disk cache. Data URIs and SVGs paint without a fetch.
  static Future<void> _fetch(String? url) {
    if (url == null ||
        url.isEmpty ||
        url.startsWith('data:') ||
        url.toLowerCase().split('?').first.endsWith('.svg')) {
      return Future.value();
    }
    final done = Completer<void>();
    final stream = ZeroCachedImageProvider(
      url,
    ).resolve(ImageConfiguration.empty);
    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (_, __) {
        if (!done.isCompleted) done.complete();
        stream.removeListener(listener);
      },
      onError: (_, __) {
        if (!done.isCompleted) done.complete();
        stream.removeListener(listener);
      },
    );
    stream.addListener(listener);
    return done.future;
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.summary;
    final leftInset = widget.leftInset;
    final onManage = widget.onManage;
    // Nothing until the counts are known, so the numbers never jump.
    if (s == null) return const SizedBox(height: 18);
    final tokens = GlassTokens.of(context);
    final l10n = context.l10n;
    final Widget body;
    if (s.isEmpty) {
      body = Text(
        l10n.listHeaderEmpty,
        style: TextStyle(
          color: tokens.textDim,
          fontSize: 12.5,
          fontWeight: FontWeight.w500,
        ),
      );
    } else {
      body = Wrap(
        spacing: 16,
        runSpacing: 12,
        children: [
          if (s.people.isNotEmpty)
            PhotoStack(
              tokens: tokens,
              count: s.people.length,
              word: l10n.listHeaderPeopleWord(s.people.length),
              rise: _rise,
              tiles: [
                for (final c in s.people.take(PhotoStack.maxTiles))
                  GlassContactIcon(contact: c, size: PhotoStack.tileSize),
              ],
            ),
          if (s.feeds.isNotEmpty)
            PhotoStack(
              tokens: tokens,
              count: s.feeds.length,
              word: l10n.listHeaderFeedsWord(s.feeds.length),
              rise: _rise,
              tiles: [
                for (final f in s.feeds.take(PhotoStack.maxTiles))
                  FeedFavicon(
                    feedUrl: f.feedUrl,
                    size: PhotoStack.tileSize,
                    cornerRadius: PhotoStack.tileSize * 0.4,
                    // A shimmer while the icon comes, not the RSS glyph.
                    placeholder: ShimmerBox(
                      progress: _shimmer,
                      width: PhotoStack.tileSize,
                      height: PhotoStack.tileSize,
                      radius: PhotoStack.tileSize * 0.4,
                      base: tokens.surfaceElevated,
                      highlight: Color.alphaBlend(
                        tokens.starkWhite.withValues(alpha: 0.10),
                        tokens.surfaceElevated,
                      ),
                    ),
                  ),
              ],
            ),
        ],
      );
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onManage,
      child: Padding(
        padding: EdgeInsets.fromLTRB(leftInset, 12, 16, 16),
        child: body,
      ),
    );
  }
}

/// A handful of tiles fanned over a box, like photos spilling out of a
/// frame. Every count from 1 to 6 has its own hand-placed shape, a symmetric
/// arc that tilts outward from the middle and widens with the count; a
/// formula that spreads any count over the full width would put two tiles
/// at the far ends. The box hugs its label, the count over the word, and
/// is never narrower than the fan. The tiles are whatever the caller hands
/// in (contact icons, favicons), already sized [tileSize], latest first.
///
/// [rise] drives the entrance: each tile comes up from behind the box, a
/// little after the one on its left, into its slot.
class PhotoStack extends StatelessWidget {
  final GlassTokens tokens;
  final List<Widget> tiles;
  final int count;
  final String word;
  final Animation<double> rise;

  static const int maxTiles = 6;
  static const double tileSize = 28;
  static const double boxHeight = 44;
  static const double fanHeight = 30;

  /// Per count, per tile: (x of the tile's centre from the box's centre,
  /// top, tilt in degrees, paint order).
  static const List<List<(double, double, double, int)>> _shapes = [
    [(0, 3, -6, 1)],
    [(-11, 5, -10, 1), (11, 3, 9, 2)],
    [(-20, 7, -13, 1), (0, 1, 2, 3), (20, 6, 12, 2)],
    [(-28, 8, -15, 1), (-10, 2, -5, 2), (10, 1, 6, 3), (28, 7, 14, 2)],
    [
      (-34, 9, -16, 1),
      (-17, 3, -8, 2),
      (0, 0, 1, 4),
      (17, 3, 9, 3),
      (34, 9, 16, 2),
    ],
    [
      (-38, 10, -17, 1),
      (-23, 4, -10, 2),
      (-8, 1, -3, 3),
      (8, 0, 4, 4),
      (23, 4, 11, 3),
      (38, 10, 17, 2),
    ],
  ];

  const PhotoStack({
    super.key,
    required this.tokens,
    required this.tiles,
    required this.count,
    required this.word,
    required this.rise,
  });

  @override
  Widget build(BuildContext context) {
    final n = math.min(tiles.length, maxTiles);
    final shape = n == 0
        ? const <(double, double, double, int)>[]
        : _shapes[n - 1];
    final fanWidth = n == 0 ? 0.0 : shape.last.$1 * 2 + tileSize + 6;
    // Paint order: lowest first, so the higher ones sit on top.
    final order = [for (var i = 0; i < n; i++) i]
      ..sort((a, b) => shape[a].$4.compareTo(shape[b].$4));
    return Stack(
      clipBehavior: Clip.none,
      children: [
        for (final i in order)
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: AnimatedBuilder(
              animation: rise,
              builder: (context, child) {
                // Staggered left to right; each tile takes 60% of the run.
                final start = n > 1 ? 0.4 * i / (n - 1) : 0.0;
                final t = Curves.easeOutBack.transform(
                  ((rise.value - start) / 0.6).clamp(0.0, 1.0),
                );
                final (x, y, deg, _) = shape[i];
                // From tucked behind the box, upright, to its slot.
                const hidden = fanHeight + 8;
                return Transform.translate(
                  offset: Offset(x, hidden + (y - hidden) * t),
                  child: Transform.rotate(
                    angle: deg * t * math.pi / 180,
                    child: child,
                  ),
                );
              },
              child: Center(child: tiles[i]),
            ),
          ),
        // The box, in front, hugging the count and the word.
        Padding(
          padding: const EdgeInsets.only(top: fanHeight),
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: fanWidth),
            child: Align(
              widthFactor: 1,
              heightFactor: 1,
              child: Container(
                height: boxHeight,
                constraints: const BoxConstraints(minWidth: boxHeight),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                // No border: the fill alone is the box.
                decoration: BoxDecoration(
                  // The "+" post button's fill: the
                  // Contacts search box's colour, opaque.
                  color: Color.alphaBlend(
                    tokens.glassFill,
                    tokens.background,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$count',
                      style: TextStyle(
                        color: tokens.starkWhite,
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      word,
                      style: TextStyle(
                        color: tokens.textDim,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The same follows in one short row: the people as a small Members stack
/// (30 px lead) and
/// the feeds as a favicon stack. Sits left of the Manage button in the
/// inline header once [ListHeaderCard] has scrolled away. A tap opens
/// "Manage [list]".
class ListMiniStack extends StatelessWidget {
  final ListFollowSummary summary;
  final GlassTokens tokens;
  final VoidCallback onTap;

  /// Wraps each icon, people first then feeds, index 0 = leftmost
  /// ([ListMiniStackFlyIn] moves them one by one).
  final Widget Function(int index, Widget tile)? tileWrap;

  const ListMiniStack({
    super.key,
    required this.summary,
    required this.tokens,
    required this.onTap,
    this.tileWrap,
  });

  /// How many icons the stack draws for [summary].
  static int iconCount(ListFollowSummary summary) =>
      MembersStack.tileCount(summary.people.length) +
      math.min(summary.feeds.length, _FaviconStack._max);

  @override
  Widget build(BuildContext context) {
    final wrap = tileWrap;
    final peopleTiles = MembersStack.tileCount(summary.people.length);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (summary.people.isNotEmpty)
            MembersStack(
              tokens: tokens,
              contacts: summary.people,
              scale: 30 / 36,
              shrinkWrap: true,
              onTap: onTap,
            ),
          if (summary.people.isNotEmpty && summary.feeds.isNotEmpty)
            const SizedBox(width: 6),
          if (summary.feeds.isNotEmpty)
            _FaviconStack(
              feeds: summary.feeds,
              tileWrap: wrap == null
                  ? null
                  : (i, tile) => wrap(peopleTiles + i, tile),
            ),
        ],
      ),
    );
  }
}

/// [ListMiniStack] as the feeds header shows it: the
/// icons come in from the right, one by one, each sliding left and settling
/// with a small bounce; the first (leftmost) is the fastest and each next
/// one a bit slower. Leaving, each pulls a little to the left, then shoots
/// out to the right, in the same order. The slot's width opens at the start
/// of the arrival and closes at the end of the leave, so the header's other
/// items slide over.
class ListMiniStackFlyIn extends StatefulWidget {
  final bool show;
  final ListFollowSummary summary;
  final GlassTokens tokens;
  final VoidCallback onTap;
  final EdgeInsetsGeometry padding;

  const ListMiniStackFlyIn({
    super.key,
    required this.show,
    required this.summary,
    required this.tokens,
    required this.onTap,
    this.padding = EdgeInsets.zero,
  });

  @override
  State<ListMiniStackFlyIn> createState() => _ListMiniStackFlyInState();
}

class _ListMiniStackFlyInState extends State<ListMiniStackFlyIn>
    with SingleTickerProviderStateMixin {
  /// The first icon's run, and how much longer each next icon takes (ms).
  static const double _firstMs = 300;
  static const double _stepMs = 70;

  /// How far to the right an icon starts (and ends up when it leaves): past
  /// the screen edge from anywhere in the stack.
  static const double _travel = 180;

  /// The share of the run in which the slot's width opens / closes.
  static const double _widthShare = 0.3;

  late final AnimationController _c;
  bool _leaving = false;

  double get _totalMs {
    final n = math.max(1, ListMiniStack.iconCount(widget.summary));
    return _firstMs + _stepMs * (n - 1);
  }

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: _totalMs.round()),
      value: widget.show ? 1 : 0,
    );
  }

  @override
  void didUpdateWidget(ListMiniStackFlyIn old) {
    super.didUpdateWidget(old);
    _c.duration = Duration(milliseconds: _totalMs.round());
    if (old.show != widget.show) {
      _leaving = !widget.show;
      if (widget.show) {
        _c.forward();
      } else {
        _c.reverse();
      }
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  /// Icon [i]'s horizontal offset right now (0 = at rest).
  double _dx(int i) {
    if (_leaving) {
      // The speeds are mirrored on the way out, not just the animation:
      // the RIGHTMOST icon is the fastest and each one to
      // its left a bit slower, so they leave in the reverse of the order
      // they came in and none flies across another.
      final n = math.max(1, ListMiniStack.iconCount(widget.summary));
      final rank = (n - 1 - i).clamp(0, n - 1);
      final share = (_firstMs + _stepMs * rank) / _totalMs;
      // easeInBack: a short pull to the left first, then out to the right.
      final p = ((1 - _c.value) / share).clamp(0.0, 1.0);
      return _travel * Curves.easeInBack.transform(p);
    }
    final share = (_firstMs + _stepMs * i) / _totalMs;
    // easeOutBack: past the resting place to the left, then back onto it.
    final p = (_c.value / share).clamp(0.0, 1.0);
    return _travel * (1 - Curves.easeOutBack.transform(p));
  }

  double get _widthFactor {
    if (_leaving) {
      final p = ((1 - _c.value - (1 - _widthShare)) / _widthShare)
          .clamp(0.0, 1.0);
      return 1 - Curves.easeInCubic.transform(p);
    }
    final p = (_c.value / _widthShare).clamp(0.0, 1.0);
    return Curves.easeOutCubic.transform(p);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        if (_c.isDismissed) return const SizedBox.shrink();
        return Align(
          alignment: Alignment.centerLeft,
          widthFactor: _widthFactor,
          heightFactor: 1,
          child: Padding(
            padding: widget.padding,
            child: ListMiniStack(
              summary: widget.summary,
              tokens: widget.tokens,
              onTap: widget.onTap,
              tileWrap: (i, tile) => Transform.translate(
                offset: Offset(_dx(i), 0),
                child: tile,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Up to four feed favicons overlapping, the feed-side twin of the people
/// stack. A stack is a sign of "several", not an index, so no "+N" tile; the
/// count sits next to it.
class _FaviconStack extends StatelessWidget {
  final List<ListFeed> feeds;
  final Widget Function(int index, Widget tile)? tileWrap;
  const _FaviconStack({required this.feeds, this.tileWrap});

  static const _size = 20.0;
  static const _stride = 13.0;
  static const _max = 4;

  @override
  Widget build(BuildContext context) {
    final shown = feeds.take(_max).toList();
    return SizedBox(
      width: _size + _stride * (shown.length - 1),
      height: _size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Right to left, so the first feed stays in front.
          for (var i = shown.length - 1; i >= 0; i--)
            Positioned(
              left: _stride * i,
              child:
                  tileWrap?.call(
                    i,
                    FeedFavicon(feedUrl: shown[i].feedUrl, size: _size),
                  ) ??
                  FeedFavicon(feedUrl: shown[i].feedUrl, size: _size),
            ),
        ],
      ),
    );
  }
}
