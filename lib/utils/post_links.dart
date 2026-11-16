import 'package:flutter/cupertino.dart';
import 'package:publicos_core/publicos_core.dart';

import '../router_helpers.dart';
import '../widgets/feeds/feeds_settings_sheet.dart' show parsePostLayoutMode;
import '../widgets/feeds/post_card.dart' show PostLayoutMode;
import '../widgets/feeds/post_detail_page.dart';

/// Fetch a post from its permalink. A `#comment-<uid>` fragment (a social
/// notification's `item_url` for a comment, a reply or a comment reaction)
/// points inside the post and is dropped for the fetch. The post comes from
/// the URL's own host, never the reader's SSP.
Future<Post?> fetchPostFromUrl(String url) async {
  final clean = url.split('#').first;
  if (clean.isEmpty) return null;
  final r = await PublicOSChannels.getPostByUrl(clean);
  return r.data;
}

/// Open a post from its permalink. DESKTOP DELTA: when the Feeds pane is on
/// screen the post opens in its reading column (`AppNav.toPost`, the same
/// shape the post cards use); otherwise the client's push, with the page's
/// back arrow popping the route. False when the post could not be fetched.

/// The reader's feed settings for a post opened with no list behind it (a
/// notification tap, a link): the same keys `PostsList`, the explore and the
/// bookmarks views read, so the detail page keeps the reader's layout (wide /
/// compact) and text sizes. Defaults match
/// `PostDetailPage`'s on any miss.
Future<({PostLayoutMode layout, double title, double desc})>
    readerPostSettings() async {
  var layout = PostLayoutMode.compact;
  var title = 16.0;
  var desc = 14.0;
  try {
    final t = await PublicOSSettings.getSetting('rss_feeds_title_text_size');
    final d =
        await PublicOSSettings.getSetting('rss_feeds_description_text_size');
    final l = await PublicOSSettings.getSetting('rss_feeds_layout_mode');
    if (t != null) title = double.tryParse(t.value) ?? title;
    if (d != null) desc = double.tryParse(d.value) ?? desc;
    if (l != null) layout = parsePostLayoutMode(l.value);
  } catch (_) {}
  return (layout: layout, title: title, desc: desc);
}

Future<bool> openPostFromUrl(BuildContext context, String url) async {
  final post = await fetchPostFromUrl(url);
  if (post == null || !context.mounted) return false;
  final prefs = await readerPostSettings();
  if (!context.mounted) return false;
  if (AppNav.onOpenPost != null) {
    AppNav.toPost(
      context,
      (onBack) => PostDetailPage(
        post: post,
        onBack: onBack,
        layoutMode: prefs.layout,
        titleTextSize: prefs.title,
        descriptionTextSize: prefs.desc,
      ),
    );
    return true;
  }
  await Navigator.of(context).push(CupertinoPageRoute(
    builder: (routeContext) => PostDetailPage(
      post: post,
      onBack: () => Navigator.of(routeContext).pop(),
      layoutMode: prefs.layout,
      titleTextSize: prefs.title,
      descriptionTextSize: prefs.desc,
    ),
  ));
  return true;
}

/// Open [post] in the Feeds pane's reading column, bringing Feeds up first
/// when another pane is showing (a notification's post opens in the feed
/// reader, not over the whole window). Feeds registers
/// [AppNav.onOpenPost] when it mounts, so this waits a few frames for it.
/// No context: the caller may already have closed the dialog it came from.
/// False when Feeds never came up.
///
/// The post opens over ITS OWN feed (the "Go to feed" path, `onOpenFeedUrl`),
/// so the header names its channel and ← returns to what was being read; on
/// top of whatever was selected it would keep that header (e.g. "Latest
/// posts"). [permalink] is the URL it was fetched from, the feed's source
/// when the post carries no feed URL.
Future<bool> openPostInFeeds(Post post, {String? permalink}) async {
  final prefs = await readerPostSettings();
  final m = RegExp(r'^(https?://[^/]+)/api/(0x[0-9a-fA-F]{40})/channels/([^/?#]+)/posts/')
      .firstMatch((permalink ?? post.url ?? '').split('#').first);
  final feedUrl = post.feedUrl ??
      (m == null ? null : '${m.group(1)}/api/${m.group(2)}/channels/${m.group(3)}/json');
  final openFeed = AppNav.onOpenFeedUrl;
  if (feedUrl != null && openFeed != null) {
    openFeed(feedUrl, null, m?.group(2), null);
    // Let Feeds mount (or take the focus) and select the feed: that clears
    // any open post, so the post goes on after it.
    for (var i = 0; i < 30 && AppNav.onOpenPost == null; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 16));
    }
    await Future<void>.delayed(const Duration(milliseconds: 32));
  } else if (AppNav.onOpenPost == null) {
    AppNav.onShowFeeds?.call();
    for (var i = 0; i < 30 && AppNav.onOpenPost == null; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 16));
    }
  }
  final open = AppNav.onOpenPost;
  if (open == null) return false;
  open((onBack) => PostDetailPage(
        post: post,
        onBack: onBack,
        layoutMode: prefs.layout,
        titleTextSize: prefs.title,
        descriptionTextSize: prefs.desc,
      ));
  return true;
}
