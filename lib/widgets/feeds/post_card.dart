import 'dart:math' as math;

import 'package:publicos_core/publicos_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:publicos_desktop/router_helpers.dart';
import 'package:publicos_desktop/widgets/glass_contact_icon.dart';
import 'package:publicos_desktop/widgets/glass_context_menu.dart';
import 'package:publicos_desktop/widgets/reaction_burst.dart';
import 'package:publicos_desktop/screens/compose_post_page.dart';
import 'package:publicos_desktop/widgets/feeds/comment_rules_sheet.dart';
import 'package:publicos_desktop/widgets/feeds/post_detail_page.dart';
import 'package:publicos_desktop/widgets/feeds/go_to_feed.dart';
import 'package:publicos_desktop/widgets/feeds/pin_post.dart';
import 'package:publicos_desktop/widgets/feeds/post_source_details_page.dart';
import 'package:publicos_desktop/widgets/feeds/post_vote_buttons.dart';
import 'package:publicos_desktop/widgets/feeds/emoji_picker_dialog.dart';
import 'package:publicos_desktop/widgets/feeds/reaction_button.dart';
import 'package:publicos_desktop/widgets/feeds/reaction_quick_bar.dart';
import 'package:publicos_desktop/widgets/feeds/feed_favicon.dart';
import 'package:publicos_desktop/widgets/feeds/mention_text.dart';
import 'package:publicos_desktop/widgets/feeds/translation_service.dart';
import 'package:zero_mentions/zero_mentions.dart' show mentionToken;
import 'package:publicos_desktop/widgets/shimmer_box.dart';
import 'package:publicos_desktop/widgets/messages/reaction_details_sheet.dart';
import 'package:publicos_desktop/widgets/transactions/send_sheet.dart';
import 'package:publicos_desktop/widgets/phigital_loading_widget.dart';
import 'package:publicos_desktop/widgets/pixel_rain_loading_widget.dart';
import 'package:publicos_desktop/theme/theme_provider.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';
import 'package:publicos_desktop/widgets/natural_ratio_media.dart';
import 'package:publicos_desktop/utils/media_mime.dart';
import 'package:publicos_desktop/widgets/tappable_image.dart';
import 'package:publicos_desktop/widgets/tappable_media.dart';
import 'package:publicos_desktop/widgets/media_overlay.dart'
    show MediaGalleryItem, MediaKind, MediaOverlay, VideoHandoff;
import 'package:publicos_desktop/widgets/video_controls_pill.dart'
    show VideoGlassPill, VideoGlassButton;
import 'package:publicos_desktop/widgets/post_file_tile.dart';
import 'package:publicos_desktop/widgets/post_signature_mark.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:publicos_desktop/router.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/widgets/error/error_l10n.dart';
import 'package:publicos_desktop/widgets/flag_sheet.dart';
import 'package:publicos_desktop/widgets/post_audio_row.dart';
import 'package:publicos_desktop/widgets/profile/profile_post_card.dart' show PostFocusScope;
import 'package:publicos_desktop/widgets/horizontal_wheel.dart';

/// Reading-layout mode for `PostCard`. Persisted user preference, threaded in
/// from the feeds reading-settings sheet via `PostsList` → `feeds_view`.
///
/// - [compact]: two-column microblog layout — avatar column on the left,
///   author/title/body/banner/images/actions all indented under it
///   (`_textInset = 56`). The default.
/// - [wide]: avatar+author live in a single header row at the top; everything
///   below (title, body, banner, images, action row) drops the avatar indent
///   and uses a flat 16pt left/right pad so media + text occupy more width.
///   Vote stack and external-link button (which live in the avatar column in
///   compact) move into the action row.
enum PostLayoutMode { compact, wide }

/// Ordered content blocks under the author line. Used by `_buildContentColumn`
/// + `_blockGap` so the vertical rhythm between them is one source of truth,
/// shared identically by both layout modes. See [_blockGap] for the spacing.
enum _PostBlock { legend, title, banner, audio, summary, body }

/// Widget for displaying post cards
/// Unified to work with the Post model
class PostCard extends StatefulWidget {
  /// Where a post's text starts, per layout: compact = past the avatar column,
  /// wide = the card margin (twin of the client's).
  static const double compactContentInset = _PostCardState._hPad +
      _PostCardState._avatarSize +
      _PostCardState._gutter;
  static const double wideContentInset = _PostCardState._hPad;

  /// The card geometry the composer renders in (the compose page IS the
  /// card while writing). Read
  /// from here, never copied, so the two cannot drift.
  static const double hPad = _PostCardState._hPad;
  static const double hPadRight = _PostCardState._hPadRight;
  static const double avatarSize = _PostCardState._avatarSize;
  static const double gutter = _PostCardState._gutter;
  static const double headerTopPad = 14;
  static const double mediaTileHeight = _PostCardState._imageHeight;
  static const double videoBannerScrimHeight =
      _PostCardState._heroHeaderScrimHeight;
  static const double singleMediaWidthFactor =
      _PostCardState._singleMediaWidthFactor;

  /// Height cap of a single image/video rendered [width] wide. DESKTOP
  /// DELTA: the bound is absolute (`_singleMediaMaxHeight`), not a ratio of
  /// the width, because the reading column here can be as wide as the user
  /// sets it (see the single-media sizing notes in the state).
  static double singleMediaMaxHeight(double width) =>
      _PostCardState._singleMediaMaxHeight;

  /// The least a hero box is tall: room for the inline player's two stacked
  /// discs (loop over mute) with their insets. A
  /// wider-than-that clip is letterboxed on black to reach it.
  static const double heroMinHeight = 112;

  /// Tile width of the multi-media carousel for [count] items.
  static double mediaTileWidth(int count) {
    if (count == 1) return 320;
    if (count == 2) return 280;
    return 220;
  }

  final Post post;
  final ThemeData theme;
  final Map<String, Contact> resolvedContacts;
  final double titleTextSize;
  final double descriptionTextSize;
  final bool showCommentsIndicator;
  final bool interactive;
  final VoidCallback? onPostDeleted;
  final VoidCallback? onPostUpdated;
  final void Function(String feedUrl)? onRemoveFeedFromList;

  /// Non-null only when this post's feed is an `account`-origin channel in the
  /// merged "Following" view. Its presence swaps "Remove from list" for "Mute
  /// channel" in the overflow menu (the two are mutually exclusive).
  final void Function(String feedUrl)? onMuteChannel;
  final bool isBookmarked;
  final VoidCallback? onBookmarkToggled;

  /// Bookmarks surface only: the server answered "gone" on the last refresh —
  /// this local copy may be the only copy left. Renders the cloud-off badge
  /// in the action row (additive; nothing else about the card changes) so the
  /// user knows un-bookmarking loses the post.
  final bool isUnavailable;

  /// When non-null the overflow menu grows a "Refresh" item — surfaces that
  /// keep a local copy (bookmarks) wire it to their write-back refresh.
  final VoidCallback? onRefreshRequested;

  /// Fired when the card pushes its detail page. Bookmarks uses it to write
  /// back a fresh server snapshot while the user reads, so the card behind
  /// the detail page is current when they return.
  final VoidCallback? onDetailOpened;

  final bool isFocused;
  final bool showVoting;
  final Function(int value)? onVote;
  /// When set (> 0), summary + body render truncated to this combined character
  /// budget with a trailing ellipsis. Null or 0 shows the whole post.
  final int? bodyMaxChars;
  /// When true, the card renders a `[feed_name] · via [icon] foundAt` subtitle
  /// under the author line. Set on any regular (non-single) aggregate-list
  /// surface — `AggregatorSource` — even when the list holds a single feed,
  /// because a list is not the feed's own page. Single-flagged lists (which
  /// route through `RssUrlSource` and carry their identity in the list header /
  /// drawer row), channel pages, forum pages, post detail, bookmarks: leave
  /// false — the page header already carries the feed identity.
  final bool showFeedContext;

  /// Offer "Go to feed" in the 3-dot menu. False where the reader is already
  /// on this post's one feed (a channel tab, a single-feed list).
  final bool showGoToFeed;
  /// Reading-layout mode. See [PostLayoutMode]. Default [PostLayoutMode.compact]
  /// is the layout for surfaces that don't thread the user
  /// setting through (post detail, single-post previews).
  final PostLayoutMode layoutMode;

  /// True while the parent's contact resolution is still in flight. While set,
  /// a post whose author/foundAt address is absent from [resolvedContacts]
  /// shows a loading shimmer in the avatar + name slots instead of the
  /// RSS-icon / `—` fallbacks — those fallbacks mean "genuinely no author",
  /// not "not loaded yet". Surfaces that pass a pre-resolved map (post detail)
  /// leave this false and keep the immediate fallback behaviour.
  final bool awaitingContacts;

  /// The focused post opens on the hero page the list card showed, its
  /// video where the user left it, muted and looping as it was.
  /// The list card passes both when it opens the post; the defaults are
  /// page 0 and the player's own start.
  final int initialHeroPage;
  final VideoHandoff? videoHandoff;

  /// Hands this card's OWN header row and action row to a host that lays
  /// them out around its own content (the pinned post card on a profile). They are the
  /// same widgets on this card's state, so the icon, the name, the "on
  /// account/feed" line, the reaction button and its sheets are the feed's.
  /// The header comes with no actions and no outer padding; the host insets.
  final Widget Function(BuildContext context, Widget header, Widget actions)?
      partsBuilder;

  /// The tokens the parts are built on; null = the theme's. A host that
  /// paints them over a picture or a colour passes the dark set.
  final GlassTokens? partsTokens;

  const PostCard({
    super.key,
    required this.post,
    required this.theme,
    this.resolvedContacts = const {},
    this.titleTextSize = 16.0,
    this.descriptionTextSize = 14.0,
    this.showCommentsIndicator = true,
    this.interactive = true,
    this.onPostDeleted,
    this.onPostUpdated,
    this.onRemoveFeedFromList,
    this.onMuteChannel,
    this.isBookmarked = false,
    this.onBookmarkToggled,
    this.isUnavailable = false,
    this.onRefreshRequested,
    this.onDetailOpened,
    this.isFocused = false,
    this.showVoting = false,
    this.onVote,
    this.bodyMaxChars,
    this.showFeedContext = false,
    this.showGoToFeed = true,
    this.layoutMode = PostLayoutMode.compact,
    this.awaitingContacts = false,
    this.initialHeroPage = 0,
    this.videoHandoff,
    this.partsBuilder,
    this.partsTokens,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard>
    with SingleTickerProviderStateMixin {
  /// Emojis whose add is on the wire, so a second tap sends nothing.
  final Set<String> _reactingEmojis = {};

  /// Bumped on every add the reader makes, from anywhere (the heart, the
  /// double tap, the sheet, the hold pill): [ReactionButton] plays the jelly
  /// on it.
  int _reactPulse = 0;

  /// Drives the avatar/name loading shimmer; runs only while
  /// [_authorSlotPending] so settled cards cost nothing.
  late final AnimationController _shimmerCtrl;

  /// People this card resolved ITSELF. The parent's [PostCard.resolvedContacts]
  /// is the fast path (one batched pass for a whole list); these fill its gaps
  /// so every door to a post names people right: a notification tap, a deep
  /// link, a share, any caller that passes no map. Resolution order per
  /// address: local contact cache, then `resolveByIdentifier` on the chain, saved like the list's pass does.
  /// While an address is in flight the author slot shimmers; a miss settles on
  /// the short address + identicon, never a borrowed name.
  final Map<String, Contact> _selfResolved = {};
  final Set<String> _selfResolving = {};
  final Set<String> _selfFailed = {};

  // Optimistic reaction state: emoji -> added (true) or removed (false)
  final Map<String, bool> _optimisticReactions = {};

  // Optimistic vote state
  int _localScore = 0;
  int? _localUserVote;
  bool _voteInitialized = false;

  // ---- Translation state (transient — zero persistence by design) --------
  // ML Kit on-device translate. Detected source language is cached in widget
  // state only; the translated strings live only while the card is on screen.
  final _translator = TranslationService.instance;
  String? _detectedLang;
  bool _translating = false;
  String _translatingLabel = 'Translating…';
  bool _showingTranslation = false;
  String? _tTitle;
  String? _tSummary;
  String? _tBody;
  String? _translateError;

  String get _targetLang => _translator.deviceLanguage;

  @override
  void initState() {
    super.initState();
    ReactionPrefs.warm();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _ensurePeople();
    _syncShimmer();
    _detectPostLanguage();
  }

  @override
  void didUpdateWidget(PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _ensurePeople();
    _syncShimmer();
    if (oldWidget.post.uid != widget.post.uid ||
        oldWidget.post.url != widget.post.url) {
      _resetHeroPager();
    }

    // Settle the optimistic reaction bet.
    //
    // [_optimisticReactions] is a +1/-1 delta laid ON TOP of the count the
    // server last told us. The moment the server speaks again — a refreshed
    // body carrying different counts, or (without a key on the card) a wholly
    // different post recycled into this slot — the bet is decided and the delta
    // must be dropped. Keep it, and it double-counts the very reaction it was
    // predicting: the server says 1, we add our stale +1, the chip reads 2.
    if (widget.post.uid != oldWidget.post.uid ||
        widget.post.reactions != oldWidget.post.reactions) {
      _optimisticReactions.clear();
    }
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    _heroPages.dispose();
    super.dispose();
  }

  /// The hero pager's position (two or more heroes): the page shown and the
  /// `1/N` counter read it. Reset when another post is recycled into this
  /// card.
  late final PageController _heroPages =
      PageController(initialPage: widget.initialHeroPage);
  // The corner pill's expand reaches the video tile on screen through it.
  final ExpandHandle _heroExpand = ExpandHandle();
  late int _heroPage = widget.initialHeroPage;

  void _resetHeroPager() {
    if (_heroPage == 0) return;
    _heroPage = 0;
    if (_heroPages.hasClients) _heroPages.jumpToPage(0);
  }

  /// The author slot (avatar + name) is still unknown: the parent is resolving
  /// contacts and the address this card would render isn't resolved yet. A
  /// usable free-text author renders immediately — it never waits on foundAt.
  bool get _authorSlotPending {
    // Only the on-chain author can still be resolving. Once every pass has
    // settled we render whatever we have (resolved name, short address, free
    // text, or nothing) — we never shimmer waiting on the discovery account,
    // which is not used as an author fallback.
    final author = widget.post.postAuthorAddress;
    if (author == null || author.isEmpty) return false;
    if (_contactFor(author) != null) return false;
    if (widget.awaitingContacts) return true; // the parent's pass
    return _selfResolving.contains(author); // our own pass
  }

  /// Parent map first, then what this card resolved itself.
  Contact? _contactFor(String? address) {
    if (address == null || address.isEmpty) return null;
    return widget.resolvedContacts[address] ?? _selfResolved[address];
  }

  /// Resolve the post's people the parent did not: author, discovery account,
  /// channel owner. Skipped while the parent's own pass is in flight (it owns
  /// the shimmer then); runs once per address per card, misses are remembered
  /// so a card never re-hammers the chain.
  void _ensurePeople() {
    if (widget.awaitingContacts) return;
    final post = widget.post;
    for (final address in [
      post.postAuthorAddress,
      post.feedFoundAtAccountAddress,
      post.channelOwnerAddress,
    ]) {
      if (address == null || address.isEmpty) continue;
      if (_contactFor(address) != null) continue;
      if (_selfResolving.contains(address) || _selfFailed.contains(address)) {
        continue;
      }
      _selfResolving.add(address);
      _selfResolve(address);
    }
  }

  Future<void> _selfResolve(String address) async {
    Contact? contact;
    try {
      contact = await PublicOSContacts.searchContacts(address);
      if (contact == null) {
        contact = await PublicOSContacts.resolveByIdentifier(address);
        if (contact != null) await PublicOSContacts.saveContact(contact);
      }
    } catch (_) {
      contact = null;
    }
    if (!mounted) return;
    setState(() {
      _selfResolving.remove(address);
      if (contact != null) {
        _selfResolved[address] = contact;
      } else {
        _selfFailed.add(address);
      }
    });
    _syncShimmer();
  }

  void _syncShimmer() {
    if (_authorSlotPending) {
      if (!_shimmerCtrl.isAnimating) _shimmerCtrl.repeat();
    } else if (_shimmerCtrl.isAnimating) {
      _shimmerCtrl.stop();
    }
  }

  /// Skeleton highlight per the trust-tree skeleton recipe.
  Color _shimmerHighlight(GlassTokens tokens) => Color.alphaBlend(
        tokens.starkWhite.withValues(alpha: 0.10),
        tokens.surfaceElevated,
      );

  Future<void> _detectPostLanguage() async {
    if (!TranslationService.isSupported) return;
    if (!await TranslationPrefs.isEnabled()) return;
    final p = widget.post;
    final src = (p.contentText?.isNotEmpty ?? false)
        ? p.contentText!
        : (p.summary?.isNotEmpty ?? false)
            ? p.summary!
            : p.title;
    if (src.trim().isEmpty) return;
    var code = await _translator.detect(src);
    if (code != null && !await TranslationPrefs.isSourceSuggested(code)) {
      code = null;
    }
    if (mounted) setState(() => _detectedLang = code);
  }

  bool get _canTranslatePost =>
      TranslationService.isSupported &&
      _detectedLang != null &&
      _detectedLang != _targetLang &&
      _translator.supportsPair(_detectedLang!, _targetLang);

  bool get _hasTranslation =>
      _tBody != null || _tTitle != null || _tSummary != null;

  Future<void> _onTapTranslate() async {
    if (_hasTranslation) {
      setState(() => _showingTranslation = !_showingTranslation);
      return;
    }
    final l10n = context.l10n;
    final from = _detectedLang!, to = _targetLang;
    final needsDownload = !await _translator.isModelReady(from, to);
    if (needsDownload) {
      final ok = await _confirmModelDownload(from, to);
      if (ok != true) return;
    }
    final wifiOnly = await TranslationPrefs.wifiOnly();
    if (!mounted) return;
    setState(() {
      _translating = true;
      _translateError = null;
      _translatingLabel = needsDownload
          ? (wifiOnly
              ? l10n.postCardWaitingForWifi
              : l10n.postCardDownloadingLanguage)
          : l10n.postCardTranslating;
    });
    try {
      if (needsDownload) {
        await _translator.ensureModel(from, to, requireWifi: wifiOnly);
        if (!mounted) return;
        setState(() => _translatingLabel = l10n.postCardTranslating);
      }
      final p = widget.post;
      final tBody = (p.contentText?.isNotEmpty ?? false)
          ? await _translator.translate(p.contentText!, from: from, to: to, requireWifi: wifiOnly)
          : null;
      final tTitle = p.title.isNotEmpty
          ? await _translator.translate(p.title, from: from, to: to, requireWifi: wifiOnly)
          : null;
      final tSummary = (p.summary?.isNotEmpty ?? false)
          ? await _translator.translate(p.summary!, from: from, to: to, requireWifi: wifiOnly)
          : null;
      if (!mounted) return;
      setState(() {
        _tBody = tBody;
        _tTitle = tTitle;
        _tSummary = tSummary;
        _showingTranslation = true;
        _translating = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _translateError = '$e';
          _translating = false;
        });
      }
    }
  }

  Future<bool?> _confirmModelDownload(String from, String to) {
    final tokens = GlassTokens.of(context);
    final l10n = context.l10n;
    final fromName = kPostLangNames[from] ?? from.toUpperCase();
    final toName = kPostLangNames[to] ?? to.toUpperCase();
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: tokens.surfaceDeep,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: tokens.borderSubtle),
        ),
        constraints: const BoxConstraints(minWidth: DialogWidth.min, maxWidth: DialogWidth.s),
        title: Text(l10n.postCardDownloadLangPackTitle,
            style: TextStyle(color: tokens.starkWhite)),
        content: Text(
          l10n.postCardDownloadLangPackBody(fromName, toName),
          style: TextStyle(color: tokens.textDim, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.dlgCancel, style: TextStyle(color: tokens.textDim)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              l10n.postCardDownload,
              style: TextStyle(
                color: tokens.connectedAccent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// True when the translate legend renders (any of: translating, error, or a
  /// tappable translate/show-original affordance). Drives whether the `legend`
  /// block participates in the content column's gap rhythm.
  bool get _showTranslateHint =>
      _translating || _translateError != null || _canTranslatePost;

  /// The header's trailing actions: the translate button
  /// (when this post can be translated), then the 3-dot menu. Passed into
  /// `_buildAuthorLine`'s name row, which centres them on the name.
  Widget _buildHeaderActions(
    BuildContext context,
    Post post,
    ThemeData theme,
    GlassTokens tokens, {
    bool menu = true,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_showTranslateHint) _buildTranslateButton(tokens),
        // On a hero that carries the row, the menu lives in the hero's corner
        // pill instead (`_buildHero`).
        if (menu)
          SizedBox(
            width: 28,
            height: 19,
            child: _buildPostMenu(context, post, theme, tokens),
          ),
      ],
    );
  }

  /// Translate, collapsed to one icon left of the 3-dot menu. Its states
  /// are icon states, with the words in the tooltip:
  ///  - can translate → dim icon;
  ///  - working (download / translate) → the bare pixel rain (peripheral);
  ///  - showing the translation → accent icon (tap = show original);
  ///  - failed → error-tinted icon (tap = retry).
  Widget _buildTranslateButton(GlassTokens tokens) {
    final l10n = context.l10n;
    if (_translating) {
      return Tooltip(
        message: _translatingLabel,
        child: const SizedBox(
          width: 26,
          height: 19,
          child: Center(child: PixelRainLoadingWidget(size: 14)),
        ),
      );
    }
    final String tip;
    final Color color;
    if (_translateError != null) {
      tip = l10n.errTranslateFailed;
      color = Theme.of(context).colorScheme.error;
    } else {
      final detectedName = _detectedLang == null
          ? ''
          : (kPostLangNames[_detectedLang!] ?? _detectedLang!.toUpperCase());
      if (!_hasTranslation) {
        tip = l10n.postCardTranslateFrom(detectedName);
        color = tokens.textDim;
      } else if (_showingTranslation) {
        tip = l10n.postCardTranslatedFromShowOriginal(detectedName);
        color = tokens.connectedAccent;
      } else {
        tip = l10n.postCardShowTranslation(
            kPostLangNames[_targetLang] ?? _targetLang.toUpperCase());
        color = tokens.textDim;
      }
    }
    return Tooltip(
      message: tip,
      child: InkResponse(
        onTap: _onTapTranslate,
        radius: 16,
        child: SizedBox(
          width: 26,
          height: 19,
          child: Icon(Icons.translate_rounded, size: 16, color: color),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_voteInitialized) {
      _localScore = widget.post.score;
      _localUserVote = widget.post.userVote;
      _voteInitialized = true;
    }
    return _buildPostCard(context);
  }

  void _handleVote(int value) {
    if (widget.onVote == null) return;
    setState(() {
      if (_localUserVote == value) {
        // Toggle off
        _localScore -= value;
        _localUserVote = null;
      } else if (_localUserVote != null) {
        // Flip vote
        _localScore += value * 2;
        _localUserVote = value;
      } else {
        // New vote
        _localScore += value;
        _localUserVote = value;
      }
    });
    widget.onVote!(value);
  }

  // Layout constants — text/image content shares a left inset matching the
  // avatar column so the action row + carousel align with body text. Right
  // side gets a tighter inset so content can use more of the screen width.
  static const double _hPad = 12;
  static const double _hPadRight = 8;
  static const double _avatarSize = 44;
  static const double _gutter = 8;
  static const double _textInset = _hPad + _avatarSize + _gutter; // 64
  // Wide-mode flat horizontal pad. Title/body/banner/carousel/actions all
  // sit at this inset so media + text gain the avatar column back.
  /// Wide mode's one left edge: the avatar's. Title, body, tags, carousel and
  /// the reaction row all start where the avatar does.
  static const double _widePad = _hPad;
  /// A hero that carries the header row (`_buildHeroHeader`): height of the
  /// top scrim under the overlaid row.
  static const double _heroHeaderScrimHeight = 96;

  /// A hero that carries the header row: the top of the corner pill, so the
  /// pill (40) is centred on the row's avatar (14 pad + 40 / 2 = 34).
  static const double _heroCornerTop = 14;

  /// Inner horizontal padding of a reaction chip / the collapsed cluster, and
  /// of the add-reaction button. Wide mode pulls the reaction row left by the
  /// first item's pad so its glyph — not its hit box — sits on the edge.
  static const double _chipHPad = 6;
  static const double _addReactionHPad = 4;
  static const double _imageHeight = 200;

  // ── Single-media sizing (the two knobs; tune by eye) ────────────────────
  //
  // ⚠ The FEED CARD's lone image does not use these: it is
  // full width + 9:16 cap like the client (`_buildImageScroller`,
  // items.length == 1), and a lone video is full width too. The knobs below
  // size a lone FILE tile (the factor), the hero pager and the composer
  // preview (`PostCard.singleMediaMaxHeight`).
  //
  // DESKTOP DELTA. A single item renders at its NATURAL ratio, bounded by
  // both of these. `NaturalRatioMedia` clamps height first and then shrinks
  // width to match (`natural_ratio_media.dart:213-216`, `w = h * ratio`), so
  // the ratio is never distorted and nothing is cropped — the image just gets
  // smaller.
  //
  // How they interact: width starts at `available * _singleMediaWidthFactor`;
  // if the resulting height exceeds `_singleMediaMaxHeight`, height wins and
  // width is recomputed from it. So the factor governs LANDSCAPE media and the
  // max-height governs PORTRAIT.
  //
  // Note the factor is inherited from mobile, where it is the ONLY height
  // governor (a portrait would otherwise tower over the card). With a real
  // max-height here, the factor is not needed for that job — it can go
  // up, or to 1.0, without portraits running away. Desktop's reading column is
  // already max-width-constrained by the user's own setting, so these two
  // compound with it.
  static const double _singleMediaWidthFactor = 0.44;
  static const double _singleMediaMaxHeight = 420;

  // A VIDEO banner in the compact content column (`_buildBanner`): the web
  // page's rule (`.post-banner video`, 66 % / 540). Deliberately bigger
  // than the carousel's single-media box above — the banner slot is the
  // post's headline media. Image banners are not bounded: full column width.
  static const double _bannerVideoMaxHeight = 540;

  // The WIDE layout's video banner (`_buildHeroHeader`, the clip as the
  // card's top with the header row on it): height cap only, at the
  // clip's own ratio. The cap must not change the text width, however wide
  // the reading setting is.
  static const double _wideVideoBannerMaxHeight = 620;


  /// Vertical gap above a content block, keyed on the preceding block. This is
  /// the single source of the under-author rhythm, identical in both layout
  /// modes. `prev == null` is the first block (gap from the author/header).
  ///
  /// The rule: 8px author→legend, 4px legend→title, and when no
  /// legend renders, a straight 8px author→title (so the legend occupies the
  /// 8px slot rather than adding to it). Generalised: first block always 8,
  /// anything after the legend 4, title→banner 8, everything else 6.
  static double _blockGap(_PostBlock? prev, _PostBlock next) {
    if (prev == null) return 8;
    if (prev == _PostBlock.legend) return 4;
    if (next == _PostBlock.banner || next == _PostBlock.audio) return 8;
    return 6;
  }

  /// The audio row's colour: the author's `color` record when they have one
  /// (the message bubble's rule), else the text colour.
  Color _audioColor(Post post, GlassTokens tokens) {
    // The author's `color` record is OFF for now; the white default goes
    // straight in. The rule stays here for when it comes back:
    // final raw = _contactFor(post.postAuthorAddress)?.getRecordValue('color');
    // final v = raw == null ? null : int.tryParse(raw);
    // return v == null ? tokens.starkWhite : Color(v);
    return tokens.starkWhite;
  }

  /// The post's sound track as ONE row, under the hero and above the text
  /// (the same spot without a hero). The composer draws the same widget.
  Widget _buildAudioRow(Post post, GlassTokens tokens) {
    final a = post.audio!;
    final name = a.url.split('/').last;
    return PostAudioRow(
      key: ValueKey('audio_${post.uid}_${a.url}'),
      url: a.url,
      title: (a.title ?? '').isNotEmpty ? a.title! : name,
      durationHint: a.durationInSeconds,
      loop: a.loop,
      color: _audioColor(post, tokens),
      // The list's playback slot, the inline video's rules, measured on
      // the whole card: the track plays while the POST is on screen.
      playbackId: 'audio_${post.uid}',
      postKey: _rootKey,
    );
  }

  Widget _buildPostCard(BuildContext context) {
    final post = widget.post;
    final theme = widget.theme;
    final parts = widget.partsBuilder;
    if (parts != null) {
      final partsTokens = widget.partsTokens ?? GlassTokens.of(context);
      return parts(
        context,
        _buildHeaderRow(context, post, theme, partsTokens,
            actions: false, padding: EdgeInsets.zero),
        _buildActionRow(post, theme, partsTokens),
      );
    }
    final tokens = GlassTokens.of(context);
    final isWide = widget.layoutMode == PostLayoutMode.wide;
    final titleTextSize = widget.titleTextSize;
    final descriptionTextSize = widget.descriptionTextSize;
    final images = post.carouselImages;
    final heroHeader = _heroCarriesHeader(post);
    // Summary and body are rendered separately so posts with both show both.
    // Apply the optional combined-length trim budget across the two fields.
    final (summaryText, bodyText) = _trimmedSummaryAndBody(
      summary: post.summary ?? '',
      body: post.contentText ?? '',
      maxChars: widget.bodyMaxChars,
    );

    // Wrap the whole card in an InkWell when interactive so taps on
    // empty space (around the title / body / margins) open the detail
    // page. Specific tap targets (image, reaction chips, action icons,
    // 3-dot menu) absorb their own taps via InkResponse / GestureDetector,
    // so they keep working without firing this outer handler.
    final cardBody = AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: widget.isFocused
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
            : null,
        border: Border(
          left: widget.isFocused
              ? BorderSide(color: theme.colorScheme.primary, width: 3)
              : BorderSide.none,
          bottom: BorderSide(color: tokens.borderSubtle, width: 0.5),
        ),
      ),
      // Wide only: the hero carries the header row on the media itself
      // (compact keeps the hero inside the content column).
      child: isWide
          ? _buildWideBody(
              context, post, theme, tokens, images,
              summaryText: summaryText,
              bodyText: bodyText,
              titleTextSize: titleTextSize,
              descriptionTextSize: descriptionTextSize,
              heroHeader: heroHeader,
            )
          : _buildCompactBody(
              context, post, theme, tokens, images,
              summaryText: summaryText,
              bodyText: bodyText,
              titleTextSize: titleTextSize,
              descriptionTextSize: descriptionTextSize,
            ),
    );

    // A right click anywhere on the card opens the reaction quick bar. Tap
    // keeps opening the post.
    if (!widget.interactive) {
      return GestureDetector(
        // DESKTOP DELTA: right click, not a hold.
        onSecondaryTapUp: (d) => _holdForQuickBar(post, d.globalPosition),
        child: cardBody,
      );
    }
    // The double-tap heart lives on the hero media and the text blocks
    // (`_doubleTapToLike`), not on this root: here its recognizer would join
    // the arena of every tap inside the card, so the action row, the chips
    // and the header would wait the 300 ms double-tap window before they
    // fire, which feels laggy. The bursts still draw on this
    // Stack, keyed so the inner detectors can place them.
    return Stack(
      key: _rootKey,
      clipBehavior: Clip.none,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showCommentsSheet(context, post),
            // DESKTOP DELTA: a right click opens the pill at the pointer;
            // no hold.
            onSecondaryTapUp: (d) => _holdForQuickBar(post, d.globalPosition),
            child: cardBody,
          ),
        ),
        for (final b in _bursts)
          Positioned(
            left: b.at.dx - ReactionBurst.size / 2,
            top: b.at.dy - ReactionBurst.size * ReactionBurst.originFraction,
            child: IgnorePointer(
              child: ReactionBurst(
                key: ValueKey(b.id),
                emoji: b.emoji,
                seed: b.id,
                onDone: () => setState(
                    () => _bursts.removeWhere((x) => x.id == b.id)),
              ),
            ),
          ),
      ],
    );
  }

  /// Where the double-tap heart lives: the hero media and the
  /// title / summary / body, each wrapped by its builder. Buttons are outside
  /// it and answer at once; a tap on the media or the text still waits the
  /// double-tap window, the trade a double-tap like makes. The burst lands
  /// where the finger did, placed on the root Stack through [_rootKey].
  Widget _doubleTapToLike(Post post, Widget child) {
    if (!widget.interactive) return child;
    return GestureDetector(
      onDoubleTapDown: (d) => _burstAtGlobal(d.globalPosition),
      onDoubleTap: () => _likeByDoubleTap(post),
      child: child,
    );
  }

  final _rootKey = GlobalKey();

  void _burstAtGlobal(Offset global, {String? emoji}) {
    final box = _rootKey.currentContext?.findRenderObject();
    if (box is! RenderBox) return;
    _burstAt(box.globalToLocal(global), emoji: emoji);
  }

  // ── Double-tap like ─────────────────────────────────────────────────────

  /// Each burst carries its own emoji: the double tap's is the reader's
  /// default, a hold-pill pick's is the picked one.
  final List<({int id, Offset at, String emoji})> _bursts = [];
  int _burstSeq = 0;

  void _burstAt(Offset at, {String? emoji}) {
    setState(() => _bursts.add((
      id: ++_burstSeq,
      at: at,
      emoji: emoji ?? ReactionPrefs.doubleTapEmojiSync,
    )));
  }

  /// A double tap only ever ADDS the heart. The server's reaction verb is a
  /// toggle, so when it answers "removed" (the heart was already there) it
  /// is put straight back; the burst plays either way.
  /// Whether the reader has [emoji] on this post: this session's optimistic
  /// answer first (a removal wins over a stale yes), else the server's own
  /// word, `viewerReactions`, which a signed interactions read fills.
  /// Per emoji; the double tap asks about the reader's default (`ReactionPrefs`).

  bool _hasReaction(Post post, String emoji) {
    final optimistic = _optimisticReactions[emoji];
    if (optimistic != null) return optimistic;
    return post.viewerReactions?.contains(emoji) ?? false;
  }

  /// The reader's emojis on this post, in the order they were added: the
  /// server's `viewerReactions`, minus this session's removals, plus its adds.
  /// Empty = the button shows the empty heart.
  List<String> _myEmojis(Post post) {
    final out = <String>[
      for (final e in post.viewerReactions ?? const <String>[])
        if (_optimisticReactions[e] != false) e,
    ];
    for (final entry in _optimisticReactions.entries) {
      if (entry.value && !out.contains(entry.key)) out.add(entry.key);
    }
    return out;
  }

  /// Sets the reader's [emoji] on or off in this session's layer. The layer
  /// is a delta over the server's word (`viewerReactions` + the counts): a
  /// change that lands back on the server's state CLEARS the entry, never
  /// stacks on it. Stacking would double count: remove in the sheet (entry
  /// false, count 0), tap the heart (entry overwritten true) = the server's
  /// 1 + 1 = 2.
  void _markMine(Post post, String emoji, bool on) {
    final server = post.viewerReactions?.contains(emoji) ?? false;
    if (on == server) {
      _optimisticReactions.remove(emoji);
    } else {
      _optimisticReactions[emoji] = on;
    }
  }

  Future<bool> _likeByDoubleTap(Post post) =>
      _addReaction(post, ReactionPrefs.doubleTapEmojiSync);

  /// ADD-only (the double tap and the quick bar): the server's
  /// verb is a toggle, so an answer of "removed" is toggled straight back.
  ///
  /// Every add bumps [_reactPulse], so the jelly plays on the reaction button
  /// whatever started it. True = the reaction is on (or already was).
  Future<bool> _addReaction(Post post, String emoji) async {
    if (!PublicOSChannels.canReact(post)) return false;
    // Already on, by the server's word or this session's: nothing to send.
    if (_hasReaction(post, emoji)) return true;
    if (_reactingEmojis.contains(emoji)) return true;
    HapticFeedback.mediumImpact();
    final before = _optimisticReactions[emoji];
    void restore() => before == null
        ? _optimisticReactions.remove(emoji)
        : _optimisticReactions[emoji] = before;
    setState(() {
      _reactingEmojis.add(emoji);
      _markMine(post, emoji, true);
      _reactPulse++;
    });
    var ok = true;
    try {
      final added =
          await PublicOSChannels.toggleReaction(post: post, emoji: emoji);
      if (!added) {
        await PublicOSChannels.toggleReaction(post: post, emoji: emoji);
        // It was counted already; the optimistic +1 would double it.
        if (mounted) setState(() => _optimisticReactions.remove(emoji));
      }
    } catch (e) {
      ok = false;
      if (mounted) {
        setState(restore);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizedError(context.l10n, e))),
        );
      }
    } finally {
      if (mounted) setState(() => _reactingEmojis.remove(emoji));
    }
    return ok;
  }

  /// The card-wide hold opens the reaction quick bar at the pointer, five
  /// slots + `+`. The signature shimmer
  /// plays on its own (`SignatureShimmerPrefs`), and the `!` mark keeps the
  /// three-states dialog on tap.
  void _holdForQuickBar(Post post, Offset at) {
    final tokens = GlassTokens.of(context);
    ReactionQuickBar.showAt(
      context,
      at,
      // A post you may not react to still gets share and bookmark.
      reactions: PublicOSChannels.canReact(post),
      // DESKTOP DELTA: copies of the action row's share and bookmark,
      // after a hairline.
      actions: [
        QuickBarAction(
          icon: Icons.ios_share_rounded,
          onTap: () => _sharePost(post),
        ),
        QuickBarAction(
          icon: widget.isBookmarked
              ? Icons.bookmark_rounded
              : Icons.bookmark_border_rounded,
          color: widget.isBookmarked ? tokens.connectedAccent : null,
          onTap: () => widget.onBookmarkToggled?.call(),
        ),
      ],
      // The pick bursts where the hold was, with the picked emoji, then
      // adds.
      onPick: (emoji) {
        _burstAtGlobal(at, emoji: emoji);
        _addReaction(post, emoji);
      },
      onMore: () => _showEmojiPicker(context, post),
    );
  }

  /// Wide layout: a post the author marked `media_post` has its hero (one
  /// picture or video, or the pager of two or more) as the card's top with
  /// the header row laid on it (`_buildHeroHeader`). The author says it, the
  /// reader never infers it (PublicOS Feed v1 § Media posts). Compact keeps
  /// the hero in the
  /// content column under the header.
  static bool _heroCarriesHeader(Post post) =>
      post.heroMedia.isNotEmpty && post.mediaPost;

  /// Two-column microblog layout (default). Avatar column on the left holds
  /// the icon + vote stack + external-link launcher; the right column carries
  /// the author/menu row and the shared content column (title/banner/summary/
  /// body) tight beneath the author. Carousel/tags/action row are indented
  /// under the avatar column via `_textInset`.
  ///
  /// Shares the contact icon, author line, content column (`_buildContentColumn`)
  /// and action row with [_buildWideBody] so switching layout mode keeps the
  /// icon + display name in the same place — only the body inset changes.
  Widget _buildCompactBody(
    BuildContext context,
    Post post,
    ThemeData theme,
    GlassTokens tokens,
    List<String> images, {
    required String summaryText,
    required String bodyText,
    required double titleTextSize,
    required double descriptionTextSize,
  }) {
    // When showing the translation, swap each text field to its translated
    // variant AND re-apply the user's "trim long posts" budget — the setting
    // applies uniformly regardless of which language is rendered.
    final (displayTitle, displaySummary, displayBody) =
        _displayTexts(post: post, summaryText: summaryText, bodyText: bodyText);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header — avatar column + content column + 3-dot menu
        Padding(
          padding: const EdgeInsets.fromLTRB(_hPad, 14, _hPadRight, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar column: icon + vote stack (forum) + launch (external).
              // Vote stack renders when the caller opts in via showVoting OR
              // when the post itself is known to live in a forum channel —
              // the latter auto-enables voting on forum posts that surface
              // outside a forum-scoped view (e.g. the Following aggregator).
              // The icon carries a 4px top pad so it aligns with the author
              // text baseline — same offset wide uses, keeping the icon put.
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: _buildPostContactIcon(),
                  ),
                  if (widget.showVoting ||
                      widget.post.isForumChannel == true) ...[
                    const SizedBox(height: 8),
                    PostVoteButtons(
                      score: _localScore,
                      userVote: _localUserVote,
                      onVote: _handleVote,
                    ),
                  ],
                  if (post.externalUrl != null &&
                      post.externalUrl!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildLeftColumnButton(
                      icon: Icons.open_in_new,
                      tooltip: context.l10n.postCardOpenLink,
                      onPressed: () => _openLink(context, post.externalUrl),
                    ),
                  ],
                ],
              ),
              const SizedBox(width: _gutter),
              // Content column: author+menu row, then the shared content column
              // tight beneath it. The 3-dot menu sits inline with the author
              // line so the title and body below span the full content width.
              // Tags + attachments carousel render outside this column, below
              // the header, so they can go full-bleed edge-to-edge.
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                child: _buildAuthorLine(post, tokens,
                    trailing: _buildHeaderActions(
                        context, post, theme, tokens)),
              ),
                      ],
                    ),
                    _buildContentColumn(
                      post, theme, tokens,
                      displayTitle: displayTitle,
                      displaySummary: displaySummary,
                      displayBody: displayBody,
                      titleTextSize: titleTextSize,
                      descriptionTextSize: descriptionTextSize,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Full-bleed image carousel — outside outer padding so it scrolls
        // edge-to-edge. First image aligns with text column inset.
        if (post.carouselItems.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildImageScroller(post.carouselItems, startInset: _textInset),
        ],
        // External link the author attached (post.externalUrl, NOT the
        // canonical post URL). Sits between the body/carousel and tags so
        // it reads as "here's the thing this micropost is pointing at".
        if ((post.externalUrl ?? '').isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(
              left: _textInset,
              right: _hPadRight,
              top: 10,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: _buildUrlPill(post.externalUrl!, tokens),
            ),
          ),
        ],
        // Tags render after attachments, aligned with the text column inset.
        if (post.tags != null && post.tags!.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(
              left: _textInset,
              right: _hPadRight,
              top: 10,
            ),
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children:
                  post.tags!.map((t) => _buildTag(t, tokens)).toList(),
            ),
          ),
        ],
        // Single inline action row: comments + reaction chips + share + bookmark.
        // Reactions live inside an Expanded Wrap so multiple chips wrap onto
        // additional lines if needed, while the side icons stay fixed.
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.only(
            left: _textInset,
            right: _hPad,
            bottom: 8,
          ),
          child: _buildActionRow(post, theme, tokens, isWide: false),
        ),
      ],
    );
  }

  /// Wide layout. Avatar + author + 3-dot menu live in a single header row
  /// at the top; the body content (title, banner, summary, body, carousel,
  /// tags, action row) drops the avatar indent and uses flat `_widePad`
  /// horizontal padding so media + text gain the avatar column back. The
  /// vote stack and external-link launcher — homeless without an avatar
  /// column — fold into the action row as horizontal items.
  ///
  /// Header uses the same `_hPad` + icon top-offset as [_buildCompactBody], so
  /// the icon and display name sit in the exact same place in both modes; only
  /// the body content un-indents from `_textInset` to `_widePad`.
  Widget _buildWideBody(
    BuildContext context,
    Post post,
    ThemeData theme,
    GlassTokens tokens,
    List<String> images, {
    required String summaryText,
    required String bodyText,
    required double titleTextSize,
    required double descriptionTextSize,
    bool heroHeader = false,
  }) {
    final (displayTitle, displaySummary, displayBody) =
        _displayTexts(post: post, summaryText: summaryText, bodyText: bodyText);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row — avatar + author column + 3-dot menu. Same `_hPad` and
        // 4px icon top-offset as compact so the icon + name don't shift on
        // layout switch.
        // A hero carries the row itself (`_buildHeroHeader`).
        if (heroHeader)
          _buildHeroHeader(context, post, theme, tokens)
        else
          _buildHeaderRow(context, post, theme, tokens),
        // TRIAL: a media_post's actions sit right under its hero and audio.
        if (heroHeader) ...[
          if (post.audio != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(_widePad, 8, _widePad, 0),
              child: _buildAudioRow(post, tokens),
            ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: _widePad),
            child: _buildActionRow(post, theme, tokens, isWide: true),
          ),
        ],
        // Body content — flat `_widePad` (= the avatar's edge), no avatar inset. Shares the
        // gap rhythm + widgets with compact via `_buildContentColumn`. The pad
        // is applied per block so the banner can run edge-to-edge (wide
        // only, square corners).
        _buildContentColumn(
          post, theme, tokens,
          displayTitle: displayTitle,
          displaySummary: displaySummary,
          displayBody: displayBody,
          titleTextSize: titleTextSize,
          descriptionTextSize: descriptionTextSize,
          blockPad: _widePad,
          includeBanner: !heroHeader,
          includeAudio: !heroHeader,
        ),
        // Carousel — edge-to-edge, first item left-padded by `_widePad`.
        if (post.carouselItems.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildImageScroller(post.carouselItems, startInset: _widePad),
        ],
        // External link pill the author attached (post.externalUrl). Distinct
        // from the launcher icon — the pill renders the URL itself; the
        // launcher folds into the action row below in wide mode.
        if ((post.externalUrl ?? '').isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(_widePad, 10, _widePad, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: _buildUrlPill(post.externalUrl!, tokens),
            ),
          ),
        if (post.tags != null && post.tags!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(_widePad, 10, _widePad, 0),
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children:
                  post.tags!.map((t) => _buildTag(t, tokens)).toList(),
            ),
          ),
        if (!heroHeader) ...[
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(
              left: _widePad,
              right: _widePad,
              bottom: 8,
            ),
            child: _buildActionRow(post, theme, tokens, isWide: true),
          ),
        ] else
          const SizedBox(height: 8),
      ],
    );
  }

  /// The wide header row: avatar + author line + header actions, at `_hPad`
  /// with the 4 px icon top-offset, so the icon and name sit exactly where
  /// compact puts them.
  Widget _buildHeaderRow(
    BuildContext context,
    Post post,
    ThemeData theme,
    GlassTokens tokens, {
    bool menuInRow = true,
    bool actions = true,
    EdgeInsets padding = const EdgeInsets.fromLTRB(_hPad, 14, _hPadRight, 0),
  }) {
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: _buildPostContactIcon(),
          ),
          const SizedBox(width: _gutter),
          Expanded(
            child: _buildAuthorLine(post, tokens,
                trailing: actions
                    ? _buildHeaderActions(context, post, theme, tokens,
                        menu: menuInRow)
                    : null),
          ),
        ],
      ),
    );
  }

  /// The post's header for the focused media screen's fixed top row: the
  /// same row (contact icon, display name), no actions. The
  /// overlay is black whatever the theme, so it is built on the dark tokens
  /// (the overlay also themes it dark).
  Widget _overlayHeader() => _buildHeaderRow(
        context,
        widget.post,
        Theme.of(context),
        GlassTokens.dark,
        actions: false,
      );

  /// The hero as the card's top with the header row ON it (the story
  /// look): a picture at its ratio or the pager of two or more,
  /// flush, the same block the content column would draw (`_buildHero`); a
  /// lone video as the inline player at the clip's natural ratio. The row
  /// keeps `_buildHeaderRow`'s offsets, so the icon and name land on the same
  /// pixels as on every other card; a short top scrim keeps them readable
  /// over a bright frame. The row's own widgets (icon, translate, menu) take
  /// their taps; the rest of the row opens the post like the card body does,
  /// so a tap aimed at the name never opens the picture, toggles the video or
  /// swipes the pager.
  Widget _buildHeroHeader(
    BuildContext context,
    Post post,
    ThemeData theme,
    GlassTokens tokens,
  ) {
    // DESKTOP DELTA: a lone clip is capped at
    // `_wideVideoBannerMaxHeight` at its own ratio. A landscape clip still
    // fills the card; a portrait one shrinks to `620 * ratio` wide and sits on
    // the left. Two widths on purpose: the media and its scrim are one inner
    // Stack at the MEDIA's width, while the outer Stack is forced to the
    // CARD's width so the header row spans the post — the contact icon keeps
    // landing on the video, and the ⋯ menu sits at the card's top-right
    // corner, over the action row's far end. A picture and the pager take
    // the card's width, so both Stacks
    // coincide. The content column below is untouched: a wide reading setting
    // widens the text, never the clip.
    return SizedBox(
      width: double.infinity,
      child: Stack(
        children: [
          Stack(
            children: [
              // The corner pill comes last, over the row (`_heroCorner`).
              _buildHero(post, tokens, flush: true, corner: false),
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: _heroHeaderScrimHeight,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.55),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.interactive
                  ? () => _showCommentsSheet(context, post)
                  : () {},
              child: _buildHeaderRow(context, post, theme, tokens,
                menuInRow: false),
            ),
          ),
          _heroCorner(
            post,
            flush: true,
            menu: _buildPostMenu(context, post, theme, tokens, size: 22),
          ),
          // TRIAL: the rail is off; a media_post's action row sits under
          // the hero + audio instead (`_buildWideBody`). Uncomment to restore.
          // _tallHeroRail(post),
        ],
      ),
    );
  }

  /// The tall-hero rail: on a tall media post the reader cannot see the
  /// reaction counts, the comments or the other buttons. Wide layout
  /// only, on every hero whether or not the header rides it (`media_post`
  /// plays no part). When the hero is at least [_tallHeroShare] of the screen's height
  /// the action row under it is off screen while the media shows, so the
  /// actions ride the media's right edge as well: reaction with its count,
  /// comments with its count, share, bookmark, top to bottom; glyphs under a
  /// soft shade, no background; the same handlers as the row. The share is
  /// measured against the screen, so the same clip qualifies on a phone and
  /// not on a tablet. A 9:16 hero at a phone's column width is ~73 %, a 4:5
  /// ~51 %, hence 60 %.
  static const double _tallHeroShare = 0.6;

  // ignore: unused_element
  Widget _tallHeroRail(Post post) {
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (ctx, c) {
          final screen = MediaQuery.sizeOf(ctx).height;
          if (!c.hasBoundedHeight || c.maxHeight < screen * _tallHeroShare) {
            return const SizedBox.shrink();
          }
          var total = 0;
          for (final r in post.parsedReactions) {
            total += r.$2;
          }
          for (final v in _optimisticReactions.values) {
            total += v ? 1 : -1;
          }
          final mine = _myEmojis(post);
          final hearted = mine.isNotEmpty;
          return Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              // Clear of a video's mute and loop discs and the pager's dots.
              // The same right inset as the discs (8): every item is a
              // disc-wide box, so the rail's centre line is the discs'.
              padding: const EdgeInsets.only(right: 8, bottom: 72),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _railItem(
                    icon: hearted
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    // Reacted: the reader's own first emoji; not yet: their
                    // default (the heart glyph when it is ❤️).
                    emoji: hearted
                        ? (mine.first == ReactionPrefs.heart ? null : mine.first)
                        : (ReactionPrefs.doubleTapEmojiSync == ReactionPrefs.heart
                            ? null
                            : ReactionPrefs.doubleTapEmojiSync),
                    count: total,
                    // The single button's rule: not reacted yet
                    // = react; reacted = the reactions sheet.
                    onTap: () => hearted
                        ? _showReactionDetails(context, post, null)
                        : _likeByDoubleTap(post),
                  ),
                  // Not on the focused post: the reader is already in the
                  // comments (the page passes `showCommentsIndicator: false`,
                  // the action row's rule too).
                  if (widget.showCommentsIndicator)
                    _railItem(
                      icon: (post.commentsCount ?? 0) > 0
                          ? Icons.chat_bubble_rounded
                          : Icons.chat_bubble_outline_rounded,
                      count: post.commentsCount ?? 0,
                      onTap: () => _showCommentsSheet(context, post),
                    ),
                  _railItem(
                    icon: Icons.ios_share_rounded,
                    onTap: () => _sharePost(post),
                    onLongPress: () => _sharePost(post, plain: true),
                  ),
                  _railItem(
                    icon: widget.isBookmarked
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    onTap: () => widget.onBookmarkToggled?.call(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// [emoji] replaces the glyph: the rail's like item shows the reader's
  /// double-tap emoji when it isn't the heart (`ReactionPrefs`).
  Widget _railItem({
    required IconData icon,
    String? emoji,
    int? count,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
  }) {
    // Ink, not a bare detector: a ripple lets the user know the tap landed.
    return InkResponse(
      onTap: onTap,
      onLongPress: onLongPress,
      radius: 24,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: SizedBox(
          width: VideoGlassButton.defaultSize,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            if (emoji != null)
              Text(emoji, style: const TextStyle(fontSize: 24, height: 1.1))
            else
              Icon(icon, size: 27, color: Colors.white),
            if (count != null && count > 0)
              Text(
                _formatCount(count),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Shared content column beneath the author line: translate legend, title,
  /// banner, summary, body — in that order, with vertical gaps from the single
  /// `_blockGap` table so the rhythm is identical in both layout modes and
  /// absent blocks never leave a stray gap. Only present blocks are added; the
  /// first present block always leads with the 8px author/header gap.
  ///
  /// [blockPad] > 0 (wide mode) pads every block horizontally EXCEPT the
  /// banner, which then runs edge-to-edge with square corners.
  /// [includeBanner] false = the hero is the card's top, with the header row
  /// on it (`_buildHeroHeader`), so the column skips it.
  Widget _buildContentColumn(
    Post post,
    ThemeData theme,
    GlassTokens tokens, {
    required String displayTitle,
    required String displaySummary,
    required String displayBody,
    required double titleTextSize,
    required double descriptionTextSize,
    double blockPad = 0,
    bool includeBanner = true,
    bool includeAudio = true,
  }) {
    final entries = <(_PostBlock, Widget)>[];
    // Translate is an icon in the header (`_buildTranslateButton`).
    if (displayTitle.isNotEmpty) {
      entries.add((
        _PostBlock.title,
        _doubleTapToLike(
          post,
          Text(
            displayTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: titleTextSize,
              height: 1.25,
              color: tokens.starkWhite,
            ),
          ),
        ),
      ));
    }
    if (includeBanner && post.heroMedia.isNotEmpty) {
      entries.add((
        _PostBlock.banner,
        _buildHero(post, tokens, flush: blockPad > 0),
      ));
    }
    if (includeAudio && post.audio != null) {
      entries.add((_PostBlock.audio, _buildAudioRow(post, tokens)));
    }
    if (displaySummary.isNotEmpty) {
      entries.add((
        _PostBlock.summary,
        _doubleTapToLike(
          post,
          Text(
            displaySummary,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: tokens.starkWhite,
              fontSize: descriptionTextSize,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
        ),
      ));
    }
    if (displayBody.isNotEmpty) {
      entries.add((
        _PostBlock.body,
        _doubleTapToLike(
          post,
          MentionText(
            displayBody,
            // Content always uses the body/description size regardless of
            // whether the post has a title.
            style: theme.textTheme.bodyMedium?.copyWith(
              color: tokens.starkWhite.withValues(alpha: 0.92),
              fontSize: descriptionTextSize,
              height: 1.4,
            ),
          ),
        ),
      ));
    }

    if (entries.isEmpty) return const SizedBox.shrink();

    final children = <Widget>[];
    _PostBlock? prev;
    for (final (kind, child) in entries) {
      // Wide only: +4 px between the header and the title.
      final wideTitleExtra =
          blockPad > 0 && prev == null && kind == _PostBlock.title ? 4.0 : 0.0;
      children.add(SizedBox(height: _blockGap(prev, kind) + wideTitleExtra));
      children.add(blockPad > 0 && kind != _PostBlock.banner
          ? Padding(
              padding: EdgeInsets.symmetric(horizontal: blockPad),
              child: child,
            )
          : child);
      prev = kind;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }

  /// Author line: display name · time [· edited]
  ///
  /// Author always leads — resolved from `postAuthorAddress` (chain author).
  /// Falls back to free-text `authorName` (RSS `<author>` tag) when no on-chain
  /// author is set, or to the discovery contact's name as a last resort.
  ///
  /// Subtitle `[feed_name] · via [icon] foundAt_displayName` is rendered
  /// below the line only when [PostCard.showFeedContext] is true (regular
  /// non-single aggregate-list surfaces). Drops the via segment when foundAt
  /// is null.
  /// [trailing] (the header actions: translate + 3-dot menu) rides the NAME
  /// row itself, so the row's centre alignment puts it on the name whatever
  /// the font metrics (a fixed offset from outside lands above the name).
  Widget _buildAuthorLine(Post post, GlassTokens tokens, {Widget? trailing}) {
    final displayName = _displayedAuthorName(post);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // const SizedBox(height: 4),
        DefaultTextStyle.merge(
          style: TextStyle(color: tokens.textDim, fontSize: 13, height: 1.2),
          child: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                    Flexible(
                      child: _authorSlotPending
                          ? ShimmerBox(
                              progress: _shimmerCtrl,
                              width: 110,
                              height: 13,
                              radius: 4,
                              base: tokens.surfaceElevated,
                              highlight: _shimmerHighlight(tokens),
                            )
                          // The name shimmers once in rainbow when the
                          // card's long-press finds a verified signature
                          // (the Easter egg).
                          : SignedAuthorName(
                              post: post,
                              name: displayName,
                              style: TextStyle(
                                color: tokens.starkWhite,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                              ),
                            ),
                    ),
                    const SizedBox(width: 6),
                    Text('·', style: TextStyle(color: tokens.textDim)),
                    const SizedBox(width: 6),
                    Flexible(
                      flex: 0,
                      // Time + the signature mark: amber `!`
                      // when the post is unsigned, red when its signature is
                      // bad, nothing when it verifies. Tap explains; a
                      // long-press shimmers the author's name.
                      child: PostSignatureMark(
                        post: post,
                        child: Text(
                          post.formattedDate,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: tokens.textDim, fontSize: 12),
                        ),
                      ),
                    ),
                    if (_wasEdited(post)) ...[
                      const SizedBox(width: 6),
                      Text('·', style: TextStyle(color: tokens.textDim)),
                      const SizedBox(width: 6),
                      Text(
                        context.l10n.postCardEdited,
                        style: TextStyle(
                          color: tokens.textDim,
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                    ],
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
          ),
        ),
        // The feed-context line carries the server mark; without the line
        // the mark stands alone.
        if (widget.showFeedContext)
          _buildFeedContextSubtitle(post, tokens)
        else
          PostServerMark(post: post),
      ],
    );
  }

  /// Multi-feed-list subtitle: `[avatar] foundAt_displayName/feed_name` —
  /// the tab the feed was found on, written as a path. Renders nothing when
  /// neither feedTitle nor foundAt resolves; with no foundAt (a pasted feed)
  /// it is the feed name alone. The whole line taps through to the feed —
  /// the same `goToFeed` as the 3-dot menu's *Go to feed* — and is plain
  /// text wherever that item would be hidden.
  Widget _buildFeedContextSubtitle(Post post, GlassTokens tokens) {
    final feedName = post.feedTitle?.trim();
    final hasFeedName = feedName != null && feedName.isNotEmpty;
    final foundAt = _foundAtContact;
    if (!hasFeedName && foundAt == null) {
      return PostServerMark(post: post);
    }
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // "on account/feed" (a trial).
        Text('${context.l10n.postCardFeedContextOn} ',
            style: TextStyle(color: tokens.textDim, fontSize: 11)),
        if (foundAt != null) ...[
          GlassContactIcon(contact: foundAt, size: 14),
          const SizedBox(width: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 140),
            child: Text(
              foundAt.displayName ?? '—',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: tokens.starkWhite.withValues(alpha: 0.85),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (hasFeedName)
            Text('/', style: TextStyle(color: tokens.textDim, fontSize: 11)),
        ],
        if (hasFeedName)
          Flexible(
            child: Text(
              feedName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: tokens.textDim,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
    final canTap = widget.showGoToFeed && canGoToFeed(post);
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: DefaultTextStyle.merge(
        style: TextStyle(
          color: tokens.textDim,
          fontSize: 11,
          height: 1.2,
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          // An amber `!` right of the line when the post's server is not a
          // registered SSP; outside the
          // ink box, so its tap opens the server dialog, not the feed.
          child: PostServerMark(
            post: post,
            child: !canTap
                ? row
                // Pulled left by the ink box's 2 px pad so the TEXT starts on
                // the name's edge; the ripple bleeds 2 px out.
                : Transform.translate(
                    offset: const Offset(-2, 0),
                    child: InkWell(
                      onTap: () => goToFeed(context, post),
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 2, vertical: 1),
                        child: row,
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  /// Author display name: the signed author's contact name > its short
  /// address > the author line as written > '—'. Only a signed post's author
  /// is an account (`postAuthorAddress`, Core sets it for signed posts
  /// alone); an unsigned post's `author` and an RSS `<author>` are labels,
  /// shown as written and never looked up: a name as text, an address as a
  /// short address (spec § Authors).
  String _displayedAuthorName(Post post) {
    final contact = _authorContact;
    final cn = contact?.displayName;
    if (cn != null && cn.isNotEmpty) return cn;
    // Signed author not resolved yet → its short address. Never borrow the
    // free-text / discovery name here: for a PublicOS post that
    // misattributes authorship (e.g. a signing key with no account
    // surfacing under the channel owner / discovery account's name).
    final addr = post.postAuthorAddress;
    if (addr != null && addr.isNotEmpty) return _shortAddr(addr);
    final raw = post.authorName?.trim();
    if (raw == null || raw.isEmpty) return '—';
    if (_looksLikeAddress(raw)) return _shortAddr(raw);
    return raw.length > 30 ? '${raw.substring(0, 30)}…' : raw;
  }

  static final RegExp _addressShape = RegExp(r'^0x[0-9a-fA-F]{40}$');
  static bool _looksLikeAddress(String s) => _addressShape.hasMatch(s);

  /// `0x1234…abcd` short form for an unresolved author address.
  String _shortAddr(String a) =>
      a.length < 10 ? a : '${a.substring(0, 6)}…${a.substring(a.length - 4)}';

  /// Detect whether the post has been edited. Driven by Core's `dateModified`
  /// — server stamps it only in `UpdatePost`, never on bridged inserts or
  /// replays. Null = never edited. Do not infer it from
  /// `updatedAt - createdAt`: that lies for bridged content.
  bool _wasEdited(Post post) => post.dateModified != null;

  /// Apply the "trim long posts" reading setting. Summary is preferred — if
  /// it alone exceeds the budget it gets truncated and the body is dropped.
  /// Otherwise the remaining budget applies to the body. Null/zero budget
  /// means show the whole thing.
  (String, String) _trimmedSummaryAndBody({
    required String summary,
    required String body,
    required int? maxChars,
  }) {
    if (maxChars == null || maxChars <= 0) return (summary, body);
    if (summary.length > maxChars) {
      return ('${summary.substring(0, maxChars).trimRight()}…', '');
    }
    final remaining = maxChars - summary.length;
    if (body.length > remaining) {
      final cut = _tokenSafeCut(body, remaining);
      final keep = cut > 0 ? body.substring(0, cut).trimRight() : '';
      return (summary, keep.isEmpty ? '…' : '$keep…');
    }
    return (summary, body);
  }

  /// Never cut a `@[0xAddr]` mention token in half — a partial token fails
  /// the render regex and would show raw hex garbage. If [cut] lands inside
  /// a token, back it up to the token's start.
  int _tokenSafeCut(String text, int cut) {
    if (cut <= 0) return cut;
    for (final m in mentionToken.allMatches(text)) {
      if (m.start >= cut) break;
      if (m.end > cut) return m.start;
    }
    return cut;
  }

  /// Pick the (title, summary, body) triple to render. When showing the
  /// translation, swap to the translated variants AND re-apply
  /// `_trimmedSummaryAndBody` against the same `bodyMaxChars` budget so the
  /// user's "trim long posts" setting wins regardless of which language is
  /// rendered. Title is never trimmed (matches the original `post.title` path).
  (String, String, String) _displayTexts({
    required Post post,
    required String summaryText,
    required String bodyText,
  }) {
    final showT = _showingTranslation && _hasTranslation;
    if (!showT) return (post.title, summaryText, bodyText);
    final (s, b) = _trimmedSummaryAndBody(
      summary: _tSummary ?? '',
      body: _tBody ?? '',
      maxChars: widget.bodyMaxChars,
    );
    return (_tTitle ?? '', s, b);
  }

  /// The hero block: one picture or video is the banner ([_buildBanner]);
  /// two or more are [_buildHeroPager]: one box in the same place, paged.
  /// Either way the **corner pill** sits top-right over it: the `x/y`
  /// counter past four items, expand, and the post menu when the header row
  /// is on the hero ([menu], passed by [_buildHeroHeader]); then it is
  /// centred on the contact row ([_heroCornerTop]), otherwise at the plain
  /// 8 px inset. Expand opens the focused viewer
  /// on the item shown: through the video tile's [ExpandHandle] for a video
  /// (decoder released first, position handed over), the lightbox for a
  /// picture.
  Widget _buildHero(
    Post post,
    GlassTokens tokens, {
    bool flush = false,
    Widget? menu,
    bool corner = true,
  }) {
    final heroes = post.heroMedia;
    Widget media;
    if (heroes.length == 1) {
      final hero = heroes.first;
      // DESKTOP DELTA: in wide, a lone clip is capped at
      // `_wideVideoBannerMaxHeight` at its own ratio (a portrait one shrinks
      // to `620 * ratio` wide and sits on the left); compact goes through
      // `_buildBanner`'s own rule.
      media = flush && hero.isVideo
          ? NaturalRatioMedia(
              mediaUrl: hero.url,
              heroTag: 'post_banner_$_uniquePostId',
              overlayHeader: _overlayHeader(),
              maxHeight: _wideVideoBannerMaxHeight,
              // Full card width, the clip centred on black, like a page of
              // the pager.
              contain: true,
              expandHandle: _heroExpand,
              videoHandoff: widget.videoHandoff,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            )
          : _buildBanner(hero.url, tokens, flush: flush);
    } else {
      final list = heroes.take(_maxHeroItems).toList();
      final gallery = [
        for (var i = 0; i < list.length; i++)
          MediaGalleryItem(
            url: list[i].url,
            heroTag: 'post_banner_${_uniquePostId}_$i',
          ),
      ];
      media = _buildHeroPager(list, gallery, tokens, flush: flush);
    }
    // The media alone carries the double tap; the corner pill, the rail and
    // the header-on-hero row sit above it in the Stack and never see it.
    media = _doubleTapToLike(post, media);
    if (!corner) return media;
    return Stack(
      children: [
        media,
        _heroCorner(post, flush: flush, menu: menu),
        // Wide layout: the tall-hero rail rides any hero, `media_post` or
        // not. The
        // header-on-hero path adds the same rail after its row.
        // TRIAL: the rail is off (see `_buildHeroHeader`).
        // if (flush) _tallHeroRail(post),
      ],
    );
  }

  /// The corner pill for [post]'s hero, positioned: `x/y` past four items,
  /// expand on the item shown (the video tile's handle, or the lightbox),
  /// and [menu] when the row is on the hero. Drawn by [_buildHero] over the
  /// media, or by [_buildHeroHeader] AFTER the header row, since that row is
  /// a full-width tap target and would take the pill's taps otherwise.
  Positioned _heroCorner(Post post, {required bool flush, Widget? menu}) {
    final heroes = post.heroMedia.take(_maxHeroItems).toList();
    final VoidCallback onExpand;
    int? count;
    if (heroes.length == 1) {
      final hero = heroes.first;
      onExpand = hero.isVideo
          ? _heroExpand.call
          : () => _openImageLightbox(hero.url, 'post_banner_$_uniquePostId');
    } else {
      final gallery = [
        for (var i = 0; i < heroes.length; i++)
          MediaGalleryItem(
            url: heroes[i].url,
            heroTag: 'post_banner_${_uniquePostId}_$i',
          ),
      ];
      final page = _heroPage.clamp(0, heroes.length - 1);
      onExpand = heroes[page].isVideo
          ? _heroExpand.call
          : () => _openHeroLightbox(gallery);
      count = heroes.length;
    }
    return Positioned(
      top: flush ? _heroCornerTop : 8,
      right: 8,
      child: _heroCornerPill(count: count, onExpand: onExpand, menu: menu),
    );
  }

  /// The lightbox on a lone picture hero, from the corner pill's expand: the
  /// same push the picture's own tap does.
  void _openImageLightbox(String url, String heroTag) {
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.transparent,
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, __, ___) => MediaOverlay(
          imageUrl: url,
          heroTag: heroTag,
          header: _overlayHeader(),
          onClose: () => Navigator.pop(context),
        ),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  /// Readers show the first 30 heroes (PublicOS Feed v1 § Limits).
  static const int _maxHeroItems = 30;

  /// The pager's box at [width]: each item's height from its own pixels
  /// (width x height / width), the tallest one wins, capped. An item without
  /// pixels fills whatever the others decided; with no pixels anywhere the
  /// box is square. DESKTOP DELTA: the cap is the banner slot's own absolute
  /// bound (`_bannerVideoMaxHeight`, the headline-media size), not a 9:16 of
  /// the width: the reading column here can be as wide as the user sets it.
  static double _heroBoxHeight(List<PostMedia> heroes, double width) {
    double tallest = 0;
    for (final m in heroes) {
      final w = m.width, h = m.height;
      if (w == null || h == null || w <= 0 || h <= 0) continue;
      final at = width * h / w;
      if (at > tallest) tallest = at;
    }
    if (tallest <= 0) tallest = width;
    return math.max(
      math.min(tallest, _bannerVideoMaxHeight),
      PostCard.heroMinHeight,
    );
  }

  /// Two or more heroes: a horizontal `PageView` in one box the biggest
  /// item's shape, every item CONTAINED in it
  /// over black (a picture letterboxed, never cropped; a video the same),
  /// swiped (dragged with the mouse here). **Navigation dots sit just under
  /// the box's bottom edge**, and past four items an `x/y` counter sits
  /// bottom-right inside the box, left of the expand disc. A tap on a
  /// picture, or its expand disc, opens the lightbox
  /// on that item, whole, paging through the heroes. A video on the page on
  /// screen is the same inline player a lone video hero gets (autoplay muted,
  /// the list's one-at-a-time rules, the controls with their own expand disc
  /// in the same corner); every other page is a poster tile with a play
  /// circle and holds no decoder, so the page shown is the only candidate
  /// the playback scope sees and a swipe between two videos hands the slot
  /// over. [flush]: wide mode, edge to edge with square corners, like the
  /// banner.
  /// A page arrow for a carousel, DESKTOP DELTA, for a reader who would
  /// rather not drag: the mute/loop disc's glass, 32 px, centred on the
  /// box's side.
  Widget _pageArrow({required bool left, required VoidCallback onTap}) {
    return Positioned(
      left: left ? 10 : null,
      right: left ? null : 10,
      top: 0,
      bottom: 0,
      child: Center(
        child: VideoGlassButton(
          icon: left
              ? Icons.chevron_left_rounded
              : Icons.chevron_right_rounded,
          size: 32,
          iconSize: 22,
          onTap: onTap,
        ),
      ),
    );
  }

  Widget _buildHeroPager(
    List<PostMedia> heroes,
    List<MediaGalleryItem> gallery,
    GlassTokens tokens, {
    bool flush = false,
  }) {
    final radius = flush ? BorderRadius.zero : BorderRadius.circular(12);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = _heroBoxHeight(heroes, width);
        // The tall-hero rule (`_tallHeroShare`, wide only): the dots move
        // INSIDE the box, the same 8 px from its bottom edge but inwards,
        // where the rail lives too.
        final tall = flush &&
            height >= MediaQuery.sizeOf(context).height * _tallHeroShare;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: radius,
              child: SizedBox(
                width: width,
                height: height,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // The letterbox: every page is contained in the box, and
                    // what the item does not cover is black.
                    const ColoredBox(color: Colors.black),
                    // DESKTOP DELTA: Flutter's default ScrollBehavior only
                    // lets touch/stylus DRAG a scrollable, so with a mouse
                    // the pages past the first would be unreachable. Same fix
                    // as the carousel below / explorer_chip.dart.
                    // No wheel here on purpose: the feed scrolls under the
                    // pointer.
                    ScrollConfiguration(
                      behavior: ScrollConfiguration.of(context).copyWith(
                        dragDevices: {
                          PointerDeviceKind.touch,
                          PointerDeviceKind.stylus,
                          PointerDeviceKind.mouse,
                          PointerDeviceKind.trackpad,
                        },
                      ),
                      child: PageView.builder(
                        controller: _heroPages,
                        itemCount: heroes.length,
                        // The pages either side are built too, so the next picture is
                        // decoded before the swipe lands on it and does not flicker.
                        // Those pages are posters at most, never a player.
                        allowImplicitScrolling: true,
                        onPageChanged: (i) => setState(() => _heroPage = i),
                        itemBuilder: (context, i) {
                          final m = heroes[i];
                          // Only the page on screen may hold a player; the
                          // others are poster tiles. Turning the page
                          // rebuilds both: the leaving page disposes its
                          // player (the scope forgets it), the arriving one
                          // mounts and reports itself.
                          final shown = i == _heroPage;
                          return TappableMedia(
                            mediaUrl: m.url,
                            kindOverride: m.isVideo
                                ? MediaKind.video
                                : (m.isImage ? MediaKind.image : null),
                            posterUrl: m.thumbnailUrl,
                            heroTag: gallery[i].heroTag,
                            overlayHeader: _overlayHeader(),
                            gallery: gallery,
                            galleryIndex: i,
                            width: width,
                            height: height,
                            fit: BoxFit.contain,
                            videoTapToFullscreen: !shown,
                            expandHandle: _heroExpand,
                            videoHandoff:
                                i == widget.initialHeroPage ? widget.videoHandoff : null,
                            errorBuilder: (_, __, ___) =>
                                const SizedBox.shrink(),
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return const Center(
                                child: PhigitalLoadingWidget(size: 24),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    if (tall)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 8,
                        child: IgnorePointer(
                          child: _heroDots(heroes.length, tokens, inside: true),
                        ),
                      ),
                    // DESKTOP DELTA: arrows for a mouse that would rather
                    // click than drag. None before the first page or past
                    // the last.
                    if (_heroPage > 0)
                      _pageArrow(
                        left: true,
                        onTap: () => _heroPages.animateToPage(
                          _heroPage - 1,
                          duration: const Duration(milliseconds: 280),
                          curve: Curves.easeOutCubic,
                        ),
                      ),
                    if (_heroPage < heroes.length - 1)
                      _pageArrow(
                        left: false,
                        onTap: () => _heroPages.animateToPage(
                          _heroPage + 1,
                          duration: const Duration(milliseconds: 280),
                          curve: Curves.easeOutCubic,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (!tall) _heroDots(heroes.length, tokens),
          ],
        );
      },
    );
  }

  /// The pager's navigation dots, 8 px under the box's bottom edge: the
  /// lightbox's dots, lit 8 px, dim 6 px. Many items
  /// shrink to fit the width rather than overflow it.
  Widget _heroDots(int count, GlassTokens tokens, {bool inside = false}) {
    final page = _heroPage.clamp(0, count - 1);
    return Padding(
      padding: EdgeInsets.only(top: inside ? 0 : 8),
      child: SizedBox(
        height: 8,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Semantics(
            label: '${page + 1} / $count',
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < count; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: i == page ? 8 : 6,
                    height: i == page ? 8 : 6,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: tokens.starkWhite.withValues(
                        alpha: i == page ? 1.0 : 0.35,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The lightbox on the pager's current page, from the expand disc of a
  /// picture page. The same push the picture's own tap does.
  void _openHeroLightbox(List<MediaGalleryItem> gallery) {
    final index = _heroPage.clamp(0, gallery.length - 1);
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.transparent,
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, __, ___) => MediaOverlay(
          gallery: gallery,
          initialIndex: index,
          heroTag: gallery[index].heroTag,
          header: _overlayHeader(),
          onClose: () => Navigator.pop(context),
        ),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  /// The hero's corner pill: `x/y` (past four items), expand, and the post
  /// menu when the header row is on the hero. One glass capsule, 36 px.
  Widget _heroCornerPill({
    int? count,
    required VoidCallback onExpand,
    Widget? menu,
  }) {
    return VideoGlassPill(
      children: [
        if (count != null && count > 4) _heroCounterText(count),
        VideoGlassPill.item(
          icon: Icons.open_in_full_rounded,
          iconSize: 22,
          onTap: onExpand,
        ),
        if (menu != null)
          SizedBox(
            width: 36,
            height: VideoGlassPill.height,
            child: Center(child: menu),
          ),
      ],
    );
  }

  Widget _heroCounterText(int count) {
    final page = _heroPage.clamp(0, count - 1) + 1;
    return Semantics(
      label: '$page / $count',
      child: Padding(
        padding: const EdgeInsets.only(left: 12, right: 2),
        child: Text(
          '$page/$count',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
        ),
      ),
    );
  }

  /// Banner hero image — fills content column width, clipped with a subtle
  /// border, and taps open the shared fullscreen overlay (same Hero animation
  /// as the attachment carousel). Errors render empty so broken links don't
  /// leave an icon tombstone.
  ///
  /// [flush]: wide mode — the banner spans the card edge-to-edge with square
  /// corners (no inset, no rounding).
  Widget _buildBanner(String url, GlassTokens tokens, {bool flush = false}) {
    final radius = flush ? BorderRadius.zero : BorderRadius.circular(12);
    // A video banner plays through the same widget as single-media posts.
    // DESKTOP DELTA (compact; wide paints a video banner as the header-on-clip
    // in `_buildHero`): the column's full width, height ≤
    // `_bannerVideoMaxHeight`, the clip at its own ratio CENTRED on black,
    // like a page of the pager. An image
    // banner keeps the full column width at its own height.
    if (isVideoUrl(url)) {
      return NaturalRatioMedia(
        mediaUrl: url,
        heroTag: 'post_banner_$_uniquePostId',
        overlayHeader: _overlayHeader(),
        maxHeight: _bannerVideoMaxHeight,
        contain: true,
        // Room for the player's discs on a very wide clip.
        minHeight: PostCard.heroMinHeight,
        expandHandle: _heroExpand,
        videoHandoff: widget.videoHandoff,
        borderRadius: radius,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      );
    }
    return Container(
      decoration: BoxDecoration(
        // border: Border.all(color: tokens.borderSubtle, width: 1), // TRIAL: ring off
        borderRadius: radius,
      ),
      child: TappableImage(
        imageUrl: url,
        heroTag: 'post_banner_$_uniquePostId',
        overlayHeader: _overlayHeader(),
        width: double.infinity,
        fit: BoxFit.contain,
        borderRadius: radius,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            height: 180,
            alignment: Alignment.center,
            color: tokens.surfaceDeep,
            child: const PhigitalLoadingWidget(size: 24),
          );
        },
      ),
    );
  }

  Widget _buildUrlPill(String url, GlassTokens tokens) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openLink(context, url),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(color: tokens.borderSubtle, width: 1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.link_rounded, size: 14, color: tokens.textDim),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  _cleanUrl(url),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: tokens.textDim,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _cleanUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final host = uri.host;
      final path = uri.path.isEmpty || uri.path == '/' ? '' : uri.path;
      return host.isEmpty ? url : '$host$path';
    } catch (_) {
      return url;
    }
  }

  Widget _buildTag(String label, GlassTokens tokens) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: tokens.borderSubtle, width: 1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: tokens.textDim,
          fontSize: 11,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  /// Glass 3-dot menu. Items branch on three roles:
  ///   - author (`_isPostAuthor`): edit
  ///   - author OR channel owner (`_canManagePost`): delete, lock/unlock
  ///     comments, comment rules
  ///   - everyone: copy link, optional remove-feed-from-list, view source
  /// Channel-owner-deleting-someone-else's-post relabels delete as "Remove
  /// from channel" so the action and confirmation copy match the role.
  /// The post's "…" button. It opens the canonical frosted [GlassContextMenu]
  /// (the pills' glass: blur over a 30 % black wash) 6 px under itself. [size]
  /// is the glyph: 18 in the header row, 22 in the hero's corner pill.
  Widget _buildPostMenu(
    BuildContext context,
    Post post,
    ThemeData theme,
    GlassTokens tokens, {
    double size = 18,
  }) {
    return Builder(
      builder: (anchor) => InkResponse(
        radius: size,
        onTap: () => _openPostMenu(anchor, post),
        child: Icon(
          Icons.more_horiz_rounded,
          size: size,
          color: tokens.textDim,
        ),
      ),
    );
  }

  void _openPostMenu(BuildContext anchor, Post post) {
    final box = anchor.findRenderObject() as RenderBox?;
    if (box == null) return;
    // The menu opens 12 px below the point it is given; the button's bottom
    // edge less 6 puts it 6 px under the glyph, like the profile's "…".
    final position = box.localToGlobal(box.size.bottomCenter(Offset.zero)) -
        const Offset(0, 6);
    final isOwnerNotAuthor = _isChannelOwner && !_isPostAuthor;
    final commentsLocked = post.commentPolicy == 'closed';
    final l10n = context.l10n;
    GlassContextMenu.show(
      context,
      position: position,
      frosted: true,
      items: [
        if (_isPostAuthor)
          GlassContextMenuItem(
            icon: Icons.edit_outlined,
            label: l10n.postCardEditPost,
            onTap: () => _showEditPostSheet(context, post),
          ),
        if (_canManagePost)
          GlassContextMenuItem(
            icon: Icons.delete_outline_rounded,
            label: isOwnerNotAuthor
                ? l10n.postCardRemoveFromChannel
                : l10n.postCardDeletePost,
            destructive: true,
            onTap: () => _showDeleteConfirmation(context, post),
          ),
        if (_canManagePost)
          GlassContextMenuItem(
            icon: commentsLocked
                ? Icons.lock_open_rounded
                : Icons.lock_outline_rounded,
            label: commentsLocked
                ? l10n.postCardUnlockComments
                : l10n.postCardLockComments,
            onTap: () => _toggleComments(post),
          ),
        if (_canManagePost)
          GlassContextMenuItem(
            icon: Icons.gavel_rounded,
            label: l10n.postCardCommentRules,
            onTap: () => _openCommentRules(context, post),
          ),
        if (widget.onRefreshRequested != null)
          GlassContextMenuItem(
            icon: Icons.refresh_rounded,
            label: l10n.postCardRefreshPost,
            onTap: () => widget.onRefreshRequested?.call(),
          ),
        GlassContextMenuItem(
          icon: Icons.link_rounded,
          label: l10n.postCardCopyLink,
          onTap: () => _sharePost(post),
        ),
        if (widget.showGoToFeed && canGoToFeed(post))
          GlassContextMenuItem(
            icon: Icons.dynamic_feed_rounded,
            label: l10n.postCardMenuGoToFeed,
            onTap: () => goToFeed(context, post),
          ),
        if (canPinPost(post))
          GlassContextMenuItem(
            icon: Icons.push_pin_outlined,
            label: l10n.postCardMenuPinToProfile,
            onTap: () => pinPostToProfile(context, post),
          ),
        if (widget.onMuteChannel != null && post.feedUrl != null)
          GlassContextMenuItem(
            icon: Icons.notifications_off_outlined,
            label: l10n.postCardMuteChannel,
            onTap: () => widget.onMuteChannel?.call(post.feedUrl!),
          ),
        if (widget.onRemoveFeedFromList != null && post.feedUrl != null)
          GlassContextMenuItem(
            icon: Icons.playlist_remove,
            label: l10n.postCardRemoveFeedFromList,
            onTap: () => _showRemoveFeedConfirmation(context, post),
          ),
        if (_canFlag(post))
          GlassContextMenuItem(
            icon: Icons.flag_outlined,
            label: l10n.flagAction,
            onTap: () => showFlagSheet(context,
                owner: _flagOwner(post)!,
                kind: FlagTargetKind.post,
                url: post.url!),
          ),
        GlassContextMenuItem(
          icon: Icons.data_object_rounded,
          label: l10n.postCardViewSource,
          onTap: () => _showPostSourceDetails(context, post),
        ),
      ],
    );
  }

  /// Single-row inline action strip: `comments | reaction chips + add | share | bookmark`.
  /// Reaction chips live in an Expanded Wrap so they grow to fill the middle
  /// space and wrap to a second line only when there are too many. Comments,
  /// share, bookmark stay fixed on either side.
  ///
  /// `isWide` folds the vote stack (when applicable) and the external-link
  /// launcher into this row — they have no avatar column to live in. Score
  /// renders inline between the up/down arrows.
  Widget _buildActionRow(Post post, ThemeData theme, GlassTokens tokens,
      {bool isWide = false}) {
    final showComments =
        widget.showCommentsIndicator && post.commentPolicy != 'closed';
    final canReact = PublicOSChannels.canReact(post);
    final displayed = _displayedReactions(post);
    final mine = _myEmojis(post);
    final hasButton = canReact || displayed.isNotEmpty;
    // Wide mode: the first GLYPH starts on the avatar's edge, not its padded
    // box: the empty heart leads with `_addReactionHPad`, the emojis with
    // `_chipHPad` (the button's group padding).
    final leadInset = !isWide || !hasButton
        ? 0.0
        : (canReact && mine.isEmpty ? _addReactionHPad : _chipHPad);
    final showVote =
        isWide && (widget.showVoting || widget.post.isForumChannel == true);
    final showLaunch =
        isWide && (post.externalUrl != null && post.externalUrl!.isNotEmpty);
    // Tippable actors (author / found-via / channel owner, minus self). Empty
    // for external RSS posts with no on-chain actor → no tip button.
    final tipCandidates = _tipCandidates();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: !hasButton
              ? const SizedBox.shrink()
              : Transform.translate(
                  offset: Offset(-leadInset, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    // One button: the
                    // empty heart while the reader hasn't reacted, the top
                    // emojis, the total. Heart = react; emojis/count = sheet.
                    child: ReactionButton(
                      reactions: displayed,
                      mine: mine,
                      canReact: canReact,
                      pulse: _reactPulse,
                      onHeart: () => _likeByDoubleTap(post),
                      onOpen: () => _showReactionDetails(context, post, null),
                      // Long press / long left click: the quick row grows out
                      // of the pressed part.
                      onLongPress: canReact
                          ? (anchor) => ReactionQuickBar.show(
                                anchor,
                                onPick: (e) => _addReaction(post, e),
                                onMore: () => _showEmojiPicker(context, post),
                              )
                          : null,
                      // 26 so the react hitbox is big enough to hit; the
                      // emoji 18 / count 16 of the chips.
                      heartSize: 26,
                      emojiSize: 18,
                      countSize: 16,
                      heartPadding: const EdgeInsets.symmetric(
                          horizontal: _addReactionHPad, vertical: 2),
                    ),
                  ),
                ),
        ),
        const SizedBox(width: 12),
        if (showVote) ...[
          _buildInlineVoteCluster(theme, tokens),
          const SizedBox(width: 14),
        ],
        if (showLaunch) ...[
          _buildActionItem(
            icon: Icons.open_in_new,
            color: tokens.textDim,
            onTap: () => _openLink(context, post.externalUrl),
          ),
          const SizedBox(width: 14),
        ],
        if (showComments) ...[
          _buildActionItem(
            icon: (post.commentsCount ?? 0) > 0
                ? Icons.chat_bubble_rounded
                : Icons.chat_bubble_outline_rounded,
            count: post.commentsCount ?? 0,
            color: tokens.textDim,
            onTap: () => _showCommentsSheet(context, post),
          ),
          const SizedBox(width: 14),
        ],
        if (tipCandidates.isNotEmpty) ...[
          _buildActionItem(
            icon: Icons.volunteer_activism_rounded,
            color: tokens.textDim,
            onTap: () => showSendSheet(
              context: context,
              config: SendSheetConfig(
                targetMode: SendTargetMode.pickFrom,
                candidates: tipCandidates,
                title: context.l10n.tipSheetTitle,
                confirmLabel: context.l10n.tipSheetSendTip,
                confirmIcon: Icons.volunteer_activism_rounded,
              ),
            ),
          ),
          const SizedBox(width: 14),
        ],
        if (widget.isUnavailable) ...[
          Tooltip(
            message: context.l10n.postCardNoLongerAvailable,
            child: const Icon(
              Icons.cloud_off_rounded,
              size: 16,
              // Dark orange — a warning, not an error: the post is gone from
              // the server but the local copy still renders.
              color: Color(0xFFE67E22),
            ),
          ),
          const SizedBox(width: 14),
        ],
        _buildActionItem(
          icon: Icons.ios_share_rounded,
          color: tokens.textDim,
          onTap: () => _sharePost(post),
          onLongPress: () => _sharePost(post, plain: true),
        ),
        const SizedBox(width: 14),
        _buildActionItem(
          icon: widget.isBookmarked
              ? Icons.bookmark_rounded
              : Icons.bookmark_border_rounded,
          color: widget.isBookmarked
              ? tokens.connectedAccent
              : tokens.textDim,
          onTap: () => widget.onBookmarkToggled?.call(),
        ),
      ],
    );
  }

  /// Horizontal vote cluster for the wide-mode action row — same up/score/down
  /// logic as `PostVoteButtons` (used in compact's avatar column), laid out
  /// inline instead of stacked.
  Widget _buildInlineVoteCluster(ThemeData theme, GlassTokens tokens) {
    final isUpvoted = _localUserVote == 1;
    final isDownvoted = _localUserVote == -1;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkResponse(
          onTap: () => _handleVote(1),
          radius: 18,
          child: Icon(
            Icons.arrow_upward_rounded,
            size: 18,
            color: isUpvoted
                ? theme.colorScheme.primary
                : tokens.textDim,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '$_localScore',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: isUpvoted
                ? theme.colorScheme.primary
                : isDownvoted
                    ? theme.colorScheme.error
                    : tokens.textDim,
          ),
        ),
        const SizedBox(width: 4),
        InkResponse(
          onTap: () => _handleVote(-1),
          radius: 18,
          child: Icon(
            Icons.arrow_downward_rounded,
            size: 18,
            color: isDownvoted
                ? theme.colorScheme.error
                : tokens.textDim,
          ),
        ),
      ],
    );
  }

  /// The reactions the card is showing right now: the server's counts plus
  /// this session's optimistic toggles, most popular first. Feeds both the
  /// chips and the details sheet's instant first paint.
  List<(String, int)> _displayedReactions(Post post) {
    final baseReactions = post.parsedReactions;
    final reactionsMap = <String, int>{};
    for (final (emoji, count) in baseReactions) {
      reactionsMap[emoji] = count;
    }
    for (final entry in _optimisticReactions.entries) {
      final emoji = entry.key;
      final wasAdded = entry.value;
      final currentCount = reactionsMap[emoji] ?? 0;
      if (wasAdded) {
        reactionsMap[emoji] = currentCount + 1;
      } else {
        final newCount = currentCount - 1;
        if (newCount <= 0) {
          reactionsMap.remove(emoji);
        } else {
          reactionsMap[emoji] = newCount;
        }
      }
    }
    final displayReactions = reactionsMap.entries
        .where((e) => e.value > 0)
        .map((e) => (e.key, e.value))
        .toList();
    // Most popular first. Server CSV order is arbitrary, and the optimistic
    // pass appends new emojis at the end, so without this the "top 4" would be
    // whatever the server happened to list first.
    displayReactions.sort((a, b) => b.$2.compareTo(a.$2));
    return displayReactions;
  }

  Widget _buildActionItem({
    required IconData icon,
    required Color color,
    int? count,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
  }) {
    final showCount = count != null && count > 0;
    return InkResponse(
      onTap: onTap,
      onLongPress: onLongPress,
      radius: 20,
      child: Padding(
        // 21 px glyph, hitbox 4px larger (2px each side) for easier taps.
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 21, color: color),
            if (showCount) ...[
              const SizedBox(width: 6),
              Text(
                _formatCount(count),
                style: TextStyle(color: color, fontSize: 13.5),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  /// Copy the canonical post URL to the clipboard. Falls back to externalUrl
  /// for RSS posts where the server hasn't filled `url` yet.
  Future<void> _sharePost(Post post, {bool plain = false}) async {
    final l10n = context.l10n;
    // Tap: the publicos.dev link. Long press ([plain]): the post's own
    // internet address.
    final url = plain ? plainLinkOf(post) : shareLinkOf(post);
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.postCardNoShareLink),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    await Clipboard.setData(ClipboardData(text: url));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.postCardLinkCopied),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Resolved chain author (`postAuthorAddress`) — null for RSS / external
  /// feeds where the author is just a free-text name from `<author>`.
  Contact? get _authorContact => _contactFor(widget.post.postAuthorAddress);

  /// Resolved discovery account (`feedFoundAtAccountAddress`) — the contact
  /// whose record tab held this feed's URL when it was added. Independent
  /// of authorship.
  Contact? get _foundAtContact =>
      _contactFor(widget.post.feedFoundAtAccountAddress);

  /// The post's tippable actors — author, the account it was found via, and the
  /// channel owner — deduped of nothing here (the tip sheet merges duplicate
  /// addresses) but stripped of self (you don't tip your own post) and any
  /// unparseable / zero address. Pre-resolved contacts ride along from
  /// [resolvedContacts] so the sheet can render names/avatars immediately.
  /// Empty for external RSS posts that carry no on-chain actor.
  List<SendCandidate> _tipCandidates() {
    final post = widget.post;
    final me = _myAddress?.toLowerCase();
    const zero = '0x0000000000000000000000000000000000000000';
    final out = <SendCandidate>[];

    void add(SendRole role, String? raw, Contact? contact) {
      if (raw == null || raw.isEmpty) return;
      EthereumAddress addr;
      try {
        addr = EthereumAddress.fromHex(raw);
      } catch (_) {
        return; // free-text RSS author etc.
      }
      final lower = addr.eip55With0x.toLowerCase();
      if (lower == zero || lower == me) return; // never tip self / zero
      out.add(SendCandidate(role: role, address: addr, contact: contact));
    }

    add(SendRole.author, post.postAuthorAddress, _authorContact);
    add(SendRole.foundVia, post.feedFoundAtAccountAddress, _foundAtContact);
    add(
      SendRole.channelOwner,
      post.channelOwnerAddress,
      _contactFor(post.channelOwnerAddress),
    );
    return out;
  }

  /// Generate a unique identifier for hero tags
  /// Uses server ID for PublicOS posts, or externalUrl hash for external posts
  ///
  /// Scoped by surface: the focused card (detail page, `interactive: false`)
  /// gets a `detail_` prefix, so its media never shares a tag with the same
  /// post's card in the list and does NOT fly between the two on push/pop.
  /// Each card's own tap-to-fullscreen
  /// still animates, because the card and its overlay share that tag.
  String get _uniquePostId =>
      widget.interactive ? _basePostId : 'detail_$_basePostId';

  String get _basePostId {
    final post = widget.post;
    if (post.uid.isNotEmpty) {
      return post.uid;
    }
    // For external posts (no uid), use hash of externalUrl + title + createdAt
    final uniqueString = '${post.externalUrl ?? ''}${post.title}${post.createdAt.millisecondsSinceEpoch}';
    return uniqueString.hashCode.abs().toString();
  }

  String? get _myAddress =>
      AppStateNotifier.currentMyContact?.publicosAddress?.eip55With0x;

  /// Whose content a flag on this post names: the chain author, else the
  /// channel owner. Null for an external RSS item (no account to name).
  EthereumAddress? _flagOwner(Post post) {
    final a = post.postAuthorAddress ?? post.channelOwnerAddress;
    if (a == null || !RegExp(r'^0x[0-9a-fA-F]{40}$').hasMatch(a)) return null;
    return EthereumAddress.fromHex(a);
  }

  /// A PublicOS post by someone else, with its SSP address (the flag target).
  bool _canFlag(Post post) {
    final owner = _flagOwner(post);
    final me = _myAddress;
    return owner != null &&
        (post.url?.isNotEmpty ?? false) &&
        me != null &&
        owner.eip55With0x.toLowerCase() != me.toLowerCase();
  }

  /// True when the current user authored this post. Gated on `uid` so RSS
  /// posts (no server uid) never qualify even if addresses happen to match.
  ///
  /// Checks `postAuthorAddress` (the chain author), NOT
  /// `feedFoundAtAccountAddress` (the discovery account). For owner-only
  /// channels these coincide; for open / approved channels they don't, and
  /// we want edit rights to follow authorship.
  bool get _isPostAuthor {
    final post = widget.post;
    final me = _myAddress;
    return me != null &&
        post.uid.isNotEmpty &&
        post.postAuthorAddress != null &&
        post.postAuthorAddress!.toLowerCase() == me.toLowerCase();
  }

  /// True when the current user owns the channel this post lives in. Lets
  /// the owner moderate posts they didn't author (delete, lock comments,
  /// manage per-post comment rules) without granting edit rights — the
  /// author still keeps content authority.
  bool get _isChannelOwner {
    final post = widget.post;
    final me = _myAddress;
    return me != null &&
        post.uid.isNotEmpty &&
        post.channelOwnerAddress != null &&
        post.channelOwnerAddress!.toLowerCase() == me.toLowerCase();
  }

  /// Author OR channel owner — the cohort that can delete, lock, and run
  /// comment rules on this post.
  bool get _canManagePost => _isPostAuthor || _isChannelOwner;

  /// Avatar slot — author primary, with initials fallback for free-text
  /// authors (RSS), and a generic feed icon as last resort. While the parent
  /// is still resolving contacts, an unknown slot shows a shimmer instead of
  /// jumping through the fallbacks.
  Widget _buildPostContactIcon() {
    if (_authorSlotPending) {
      final tokens = GlassTokens.of(context);
      return ShimmerBox(
        progress: _shimmerCtrl,
        width: _avatarSize,
        height: _avatarSize,
        radius: _avatarSize * 0.4, // matches GlassContactIcon's squircle
        base: tokens.surfaceElevated,
        highlight: _shimmerHighlight(tokens),
      );
    }

    final author = _authorContact;
    if (author != null) {
      final hasPublicOSProfile = author.publicosAddress != null &&
          author.publicosAddress!.eip55With0x !=
              '0x0000000000000000000000000000000000000000';
      return GlassContactIcon(
        contact: author,
        size: _avatarSize,
        onTap: hasPublicOSProfile ? () => _navigateToProfile(author) : null,
      );
    }

    // On-chain author present but unresolved → identicon from the address
    // (matches the short-address name). Never borrow the discovery/owner
    // avatar — that misattributes authorship.
    final authorAddr = widget.post.postAuthorAddress;
    if (authorAddr != null && authorAddr.isNotEmpty) {
      return GlassContactIcon(address: authorAddr, size: _avatarSize);
    }

    // No on-chain author = a classic RSS / Atom / JSON Feed post: Core sets
    // `postAuthorAddress` only from PublicOS signals, so such an author never
    // has a contact. The face is the FEED's — its own image → site favicon →
    // RSS glyph. The name slot
    // still shows the free-text <author>.
    final feedUrl = widget.post.feedUrl;
    if (feedUrl != null && feedUrl.isNotEmpty) {
      return FeedFavicon(
        feedUrl: feedUrl,
        size: _avatarSize,
        cornerRadius: _avatarSize * 0.4, // GlassContactIcon's squircle
        faviconFirst: true, // the site, then the feed's image
      );
    }

    // Nothing resolvable — generic feed icon. No discovery/owner avatar
    // borrow (that misattributed authorship); the "via" subtitle still
    // surfaces the discovery account separately.
    return Container(
      width: _avatarSize,
      height: _avatarSize,
      decoration: BoxDecoration(
        color: ThemeProvider.amberAccent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.rss_feed,
        color: Colors.white,
        size: 18,
      ),
    );
  }

  /// Navigate to profile page for a PublicOS contact
  void _navigateToProfile(Contact contact) {
    AppNav.toContact(context, contact);
  }

  /// Build a button for the left column (icon only, no background)
  Widget _buildLeftColumnButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    final theme = widget.theme;
    return SizedBox(
      width: 32,
      height: 32,
      child: IconButton(
        visualDensity: VisualDensity.compact,
        onPressed: onPressed,
        icon: Icon(
          icon,
          size: 20,
          color: theme.colorScheme.surfaceContainerHighest,
        ),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        tooltip: tooltip,
      ),
    );
  }

  /// Show emoji picker for adding reaction (glass categorized dialog)
  Future<void> _showEmojiPicker(BuildContext context, Post post) async {
    final emoji = await showEmojiPickerDialog(context);
    if (emoji != null) _addReaction(post, emoji);
  }

  /// Show reaction details sheet with who reacted
  /// Open the who-reacted card NOW on what the post card already shows
  /// (counts, the tapped emoji's tab); the sheet fetches the reactor lists and
  /// fills itself in place (a signed GET plus serial contact
  /// lookups before the sheet would make every tap feel stuck).
  void _showReactionDetails(BuildContext context, Post post, String? emoji) {
    if (!PublicOSChannels.canReact(post)) return;

    final myAddress =
        AppStateNotifier.currentMyContact?.publicosAddress?.eip55With0x;
    final mine = _myEmojis(post);
    final instant = [
      for (final (e, count) in _displayedReactions(post))
        MessageReactionSummary(
          emoji: e,
          count: count,
          hasMyReaction: mine.contains(e),
          senderInboxIds: const [],
        ),
    ];

    // DESKTOP DELTA: the client's bottom sheet becomes a centered card.
    // `asCard` swaps the widget's DraggableScrollableSheet shell for a plain
    // sized card so it centers cleanly in the dialog instead of bottom-anchoring
    // inside it. Same widget, same args.
    showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (sheetCtx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: DialogWidth.m, maxHeight: 560),
          child: ReactionDetailsSheet(
            onContactTap: (c) {
              Navigator.of(sheetCtx).pop();
              AppNav.toContact(context, c);
            },
            asCard: true,
            reactions: instant,
            load: () => _loadReactionDetails(post, myAddress),
            // Not in this device's contacts: ask the chain, like comments do, and
            // keep what it finds.
            resolveMissing: (addr) async {
              final c = await PublicOSContacts.resolveByIdentifier(addr);
              if (c != null) await PublicOSContacts.saveContact(c);
              return c;
            },
            // Still unresolved: open the profile by address; the Browser resolves.
            onUnresolvedTap: (addr) {
              Navigator.of(sheetCtx).pop();
              AppNav.toProfile(context, addr);
            },
            initialEmoji: emoji,
            currentUserId: myAddress,
            onRemoveMyReaction: (em) => _removeMyReaction(post, em),
        // The add row: extra reactions are added here, and the
        // card's button jellies behind the sheet.
        onAddReaction: (em) => _addReaction(post, em),
          ),
        ),
      ),
    );
  }

  /// The slow half of the sheet: the SSP's per-address reaction list (a signed
  /// GET when the channel wants one), then every reactor's contact from the
  /// local DB, all in parallel. Null = the fetch failed.
  Future<({List<MessageReactionSummary> reactions, Map<String, Contact> contacts})?>
      _loadReactionDetails(Post post, String? myAddress) async {
    final reactionsData = await PublicOSChannels.getReactions(post);
    if (reactionsData == null) return null;

    final emojiToAddresses = <String, List<String>>{};
    for (final ur in reactionsData.userReactions) {
      emojiToAddresses.putIfAbsent(ur.emoji, () => []).add(ur.accountAddress);
    }

    final summaries = <MessageReactionSummary>[];
    for (final fr in reactionsData.reactions) {
      final addresses = emojiToAddresses[fr.emoji] ?? [];
      summaries.add(MessageReactionSummary(
        emoji: fr.emoji,
        count: fr.count,
        hasMyReaction: myAddress != null &&
            addresses.any((a) => a.toLowerCase() == myAddress.toLowerCase()),
        senderInboxIds: addresses,
      ));
    }

    final addresses = emojiToAddresses.values.expand((a) => a).toSet().toList();
    final found = await Future.wait(addresses.map(PublicOSContacts.searchContacts));
    final contacts = <String, Contact>{};
    for (var i = 0; i < addresses.length; i++) {
      final c = found[i];
      if (c != null) contacts[addresses[i]] = c;
    }
    return (reactions: summaries, contacts: contacts);
  }

  /// Toggle off the current user's reaction. The server endpoint is a single
  /// toggle — calling [PublicOSChannels.toggleReaction] when the user already
  /// has the reaction removes it. We update [_optimisticReactions] so the
  /// chip count on the card drops without waiting for a feed reload.
  Future<bool> _removeMyReaction(Post post, String emoji) async {
    try {
      final added = await PublicOSChannels.toggleReaction(
        post: post,
        emoji: emoji,
      );
      if (added) {
        // Server says it added (we expected it to remove). Means our local
        // assumption was off — undo locally so the chip stays consistent.
        return false;
      }
      if (mounted) {
        setState(() {
          _markMine(post, emoji, false);
        });
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Full-bleed horizontal media carousel. The first frame is left-padded by
  /// [startInset] so it aligns with the text column at rest, but the scroll
  /// view extends to both card edges so subsequent items can scroll past
  /// the right and the first item can scroll all the way to the left edge.
  ///
  /// Items are dispatched on URL extension via [TappableMedia] — known video
  /// extensions (`.mp4 .webm .mov .m4v`) render `PublicOSVideo` posters,
  /// everything else renders `ZeroCachedImage`.
  Widget _buildImageScroller(List<PostMediaItem> items, {double startInset = 0}) {
    if (items.isEmpty) return const SizedBox.shrink();
    final tokens = GlassTokens.of(context);
    // Files (a MIME that is neither image nor video) render as openable
    // tiles; the overlay's gallery holds the media only, so
    // a media tile's place in it is its index among the media.
    final gallery = [
      for (var i = 0; i < items.length; i++)
        if (!items[i].isFile)
          MediaGalleryItem(
            url: items[i].url,
            heroTag: 'post_media_${_uniquePostId}_$i',
          ),
    ];

    // Single-media: full post-content width at the media's natural aspect ratio.
    // NaturalRatioMedia probes dimensions via ZeroCachedImageProvider (image)
    // or VideoPlayerController.initialize (video) and rebuilds when known.
    if (items.length == 1) {
      if (items[0].isFile) {
        return Padding(
          padding: EdgeInsets.only(left: startInset, right: 16),
          child: LayoutBuilder(
            builder: (context, constraints) => Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: constraints.maxWidth * _singleMediaWidthFactor,
                child: PostFileTile(item: items[0], compact: true),
              ),
            ),
          ),
        );
      }
      // A lone VIDEO takes the full content width in a black box capped at
      // `_singleMediaMaxHeight`, the clip contained and centred in it: a
      // portrait clip gets black stripes either side.
      if (isVideoUrl(items[0].url)) {
        return Padding(
          padding: EdgeInsets.only(left: startInset, right: _widePad),
          child: NaturalRatioMedia(
            mediaUrl: items[0].url,
            heroTag: 'post_media_${_uniquePostId}_0',
            overlayHeader: _overlayHeader(),
            borderRadius: BorderRadius.circular(14),
            maxHeight: _singleMediaMaxHeight,
            contain: true,
            errorBuilder: (context, error, stackTrace) =>
                const SizedBox.shrink(),
          ),
        );
      }
      // A lone IMAGE takes the full content width at its natural ratio,
      // capped at 9:16 portrait: taller media keeps the width and is cropped
      // (fillWidth); the lightbox still shows the whole file. Client parity
      // (publicos_client post_card).
      // The left inset is kept, so compact mode still respects its padding,
      // like the hero. The cap is computed here, not via
      // `PostCard.singleMediaMaxHeight`, which the hero pager and the
      // composer read as desktop's absolute 420.
      return Padding(
        padding: EdgeInsets.only(left: startInset, right: _widePad),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Container(
              decoration: BoxDecoration(
                // border: Border.all(color: tokens.borderSubtle, width: 1), // TRIAL: ring off
                borderRadius: BorderRadius.circular(14),
              ),
              child: NaturalRatioMedia(
                mediaUrl: items[0].url,
                heroTag: 'post_media_${_uniquePostId}_0',
                overlayHeader: _overlayHeader(),
                maxHeight: constraints.maxWidth / (9 / 16),
                fillWidth: true,
                borderRadius: BorderRadius.circular(14),
                errorBuilder: (context, error, stackTrace) =>
                    const SizedBox.shrink(),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: tokens.surfaceDeep,
                    child: const Center(
                      child: PhigitalLoadingWidget(size: 24),
                    ),
                  );
                },
              ),
            );
          },
        ),
      );
    }

    // Multi-media: fixed-size horizontal scroller.
    final width = _imageItemWidth(items.length);

    return SizedBox(
      height: _imageHeight,
      // DESKTOP DELTA: Flutter's default ScrollBehavior only lets
      // touch/stylus DRAG a scrollable, so with a mouse the frames past the
      // card edge would be unreachable except by Shift+wheel. Same fix as
      // explorer_chip.dart / vote_card.dart.
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.stylus,
            PointerDeviceKind.mouse,
            PointerDeviceKind.trackpad,
          },
        ),
        child: HorizontalWheel(child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.only(left: startInset),
          itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = items[index];
          if (item.isFile) {
            return PostFileTile(
              item: item,
              width: width,
              height: _imageHeight,
              borderRadius: BorderRadius.circular(14),
            );
          }
          final mediaUrl = item.url;
          return ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              decoration: BoxDecoration(
                // border: Border.all(color: tokens.borderSubtle, width: 1), // TRIAL: ring off
                borderRadius: BorderRadius.circular(14),
              ),
              child: TappableMedia(
                mediaUrl: mediaUrl,
                heroTag: 'post_media_${_uniquePostId}_$index',
                overlayHeader: _overlayHeader(),
                // The overlay pages through the post's media from this
                // tile, with dots; files stay out.
                gallery: gallery,
                galleryIndex: gallery.indexWhere((g) => g.url == mediaUrl),
                width: width,
                height: _imageHeight,
                borderRadius: BorderRadius.circular(14),
                // Video tiles fill the same fixed footprint as image tiles and
                // tap through to the focused video screen — no inline player
                // per tile.
                videoTapToFullscreen: true,
                errorBuilder: (context, error, stackTrace) =>
                    const SizedBox.shrink(),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    width: width,
                    height: _imageHeight,
                    color: tokens.surfaceDeep,
                    child: const Center(
                      child: PhigitalLoadingWidget(size: 24),
                    ),
                  );
                },
              ),
            ),
          );
        },
        )),
      ),
    );
  }

  double _imageItemWidth(int count) => PostCard.mediaTileWidth(count);

  Future<void> _openLink(BuildContext context, String? link) async {
    if (link == null || link.isEmpty) return;
    final l10n = context.l10n;

    try {
      final uri = Uri.parse(link);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.inAppBrowserView,
          webViewConfiguration: const WebViewConfiguration(
            enableJavaScript: true,
            enableDomStorage: true,
          ),
        );
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.postCardCouldNotOpenLink(link))),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizedError(l10n, e))),
        );
      }
    }
  }

  // --- DESKTOP DELTAS -------------------------------------------------------
  // The client PUSHES these as routes. Desktop renders them in place in the
  // feeds reading column (master-detail / the inline flow host), which only
  // FeedsPane can do -- so they go through the AppNav shim rather than
  // threading a callback down through posts_list into this verbatim file.

  void _showPostSourceDetails(BuildContext context, Post post) {
    // DELTA (desktop): inside a Browser the page opens IN that
    // browser, exactly like `_showCommentsSheet` below. `AppNav.toPostSource`
    // is answered only by the Feeds pane, so from a Browser it goes nowhere.
    final open = PostFocusScope.maybeOf(context)?.open ??
        (Widget Function(VoidCallback onBack) b) =>
            AppNav.toPostSource(context, b);
    open((onBack) => PostSourceDetailsPage(post: post, onBack: onBack));
  }

  void _showCommentsSheet(BuildContext context, Post post) {
    // The "user is focusing this post" signal — bookmarks writes back a fresh
    // server snapshot behind the detail view.
    widget.onDetailOpened?.call();
    // Argument list is the client's, verbatim -- only `Navigator.push(builder:)`
    // is `AppNav.toPost(builder)` here. `widget.resolvedContacts` is the whole
    // point: it is PostsList's post-AUTHOR map, and this widget is the only one
    // that has it.
    //
    // DELTA (desktop): inside a Browser (a profile's feed in
    // Contacts or Messages) the post opens IN that browser, the way a pinned
    // post does ([PostFocusScope]). `AppNav.toPost` is answered only by the
    // Feeds pane, so from Contacts the tap would go nowhere.
    final open = PostFocusScope.maybeOf(context)?.open ??
        (Widget Function(VoidCallback onBack) b) => AppNav.toPost(context, b);
    open(
      (onBack) => PostDetailPage(
        post: post,
        resolvedContacts: widget.resolvedContacts,
        titleTextSize: widget.titleTextSize,
        descriptionTextSize: widget.descriptionTextSize,
        layoutMode: widget.layoutMode,
        isBookmarked: widget.isBookmarked,
        onBookmarkToggled: widget.onBookmarkToggled,
        initialHeroPage: _heroPage,
        videoHandoff: _heroExpand.snapshot?.call(),
        onBack: onBack,
      ),
    );
  }

  void _showEditPostSheet(BuildContext context, Post post) {
    // In-content-area flow: same page, hosted by the reading column's
    // nested navigator instead of a pushed route.
    AppNav.openFlow(
      context,
      ComposePostPage(
        existing: post,
        onPostSaved: widget.onPostUpdated,
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Post post) {
    final tokens = GlassTokens.of(context);
    // Channel-owner-removing-someone-else's-post path. Different framing
    // because the actor isn't the author — they're moderating their channel.
    final l10n = context.l10n;
    final isModeration = _isChannelOwner && !_isPostAuthor;
    final title = isModeration
        ? l10n.postCardRemoveFromChannelTitle
        : l10n.postCardDeletePostTitle;
    final body = isModeration
        ? l10n.postCardDeleteBodyModeration(
            post.channelSlug ?? l10n.postCardThisChannel)
        : l10n.postCardDeleteBody;
    final confirmLabel =
        isModeration ? l10n.postCardRemove : l10n.postCardDelete;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        constraints: const BoxConstraints(minWidth: DialogWidth.min, maxWidth: DialogWidth.s),
        backgroundColor: tokens.surfaceDeep,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: tokens.borderSubtle),
        ),
        title: Text(
          title,
          style: TextStyle(color: tokens.starkWhite),
        ),
        content: Text(
          body,
          style: TextStyle(color: tokens.textDim, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.dlgCancel, style: TextStyle(color: tokens.textDim)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deletePost(post);
            },
            child: Text(
              confirmLabel,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Lock or unlock commenting on this single post via `updatePost`'s
  /// `commentPolicy` (the sole source of truth). Toggle flips between current policy and "closed" — when
  /// unlocking from "closed", we restore "open" (the default). Author and
  /// channel owner can both flip it; reactionPolicy is left untouched
  /// (independently togglable). On success we trigger `onPostUpdated` so the
  /// caller can refresh the post and the menu's lock label flips on the
  /// next open.
  Future<void> _toggleComments(Post post) async {
    final l10n = context.l10n;
    final channelSlug = post.channelSlug;
    if (channelSlug == null || channelSlug.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.postCardCannotLockMissingSlug),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }
    final isClosed = post.commentPolicy == 'closed';
    final nextPolicy = isClosed ? 'open' : 'closed';
    try {
      final response = await PublicOSChannels.updatePost(
        // The post as it is: Core re-sends every field and signs the edit
        // chain (prev_hashes) from its current object. comment_policy is a
        // setting outside the signed object, but an edit is the whole post
        // again, so the chain must continue.
        post: post,
        commentPolicy: nextPolicy,
        serverAddress: post.serverAddress,
      );
      if (!mounted) return;
      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isClosed
                ? l10n.postCardCommentsUnlocked
                : l10n.postCardCommentsLocked),
            behavior: SnackBarBehavior.floating,
          ),
        );
        widget.onPostUpdated?.call();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.postCardUpdateFailed(
                  response.error?['message'] ?? l10n.postCardUnknownError),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizedError(l10n, e))),
        );
      }
    }
  }

  Future<void> _openCommentRules(BuildContext context, Post post) async {
    final slug = post.channelSlug ?? '';
    if (slug.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.postCardMissingChannelInfo),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    await showCommentRulesSheet(
      context,
      post: post,
      slug: slug,
      serverAddress: post.serverAddress,
    );
  }

  void _showRemoveFeedConfirmation(BuildContext context, Post post) {
    final l10n = context.l10n;
    final feedTitle = post.feedTitle ?? post.feedUrl ?? l10n.postCardThisFeed;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        constraints: const BoxConstraints(minWidth: DialogWidth.min, maxWidth: DialogWidth.s),
        title: Text(l10n.postCardRemoveFeedTitle),
        content: Text(l10n.postCardRemoveFeedBody(feedTitle)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.dlgCancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onRemoveFeedFromList?.call(post.feedUrl!);
            },
            child: Text(l10n.postCardRemove),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePost(Post post) async {
    final l10n = context.l10n;
    final channelSlug = post.channelSlug;
    if (channelSlug == null || channelSlug.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.postCardCannotDeleteMissingSlug)),
        );
      }
      return;
    }

    try {
      final response = await PublicOSChannels.deletePost(
        postUid: post.uid,
        slug: channelSlug,
      );

      if (mounted) {
        if (response.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.postCardPostDeleted)),
          );
          widget.onPostDeleted?.call();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.postCardDeleteFailed(
                  response.error?['message'] ?? l10n.postCardUnknownError)),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizedError(l10n, e))),
        );
      }
    }
  }
}
