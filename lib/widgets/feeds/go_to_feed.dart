import 'package:flutter/widgets.dart';
import 'package:publicos_core/publicos_core.dart';
import 'package:publicos_desktop/router_helpers.dart';

/// "Go to feed". A post knows its feed URL and,
/// when its feed was reached through a profile tab, WHERE it was found:
/// `feedFoundAtAccountAddress` + `feedRecordKey`. That pointer is the
/// reader's, not the channel owner's: a profile lists a channel, it doesn't
/// own one, and nothing finds the listing tab from the channel.
///
/// Priority: the found-via profile's tab, when it still points at the same
/// channel; otherwise the feed on its own.
///
/// DELTA (desktop): no stack to push onto. A hit switches to Contacts on that
/// profile + tab (no Back); a miss opens the feed in the Feeds
/// pane ([AppNav.onOpenFeedUrl]) instead of the client's `FeedReaderPage`.

/// The feed [post] came from. Channel-direct reads (`getPostByUrl`, the
/// pinned card) leave `feedUrl` null; the permalink's channel base + `/json`
/// is exactly the server's own feed URL.
String? feedUrlOf(Post post) {
  final stored = post.feedUrl;
  if (stored != null && stored.isNotEmpty) return stored;
  final base = post.url == null ? null : channelBaseOf(post.url!);
  return base == null ? null : '$base/json';
}

/// Whether "Go to feed" has anywhere to go.
bool canGoToFeed(Post post) => feedUrlOf(post) != null;

/// The publicos link to the tab [post] was found on, or null when its feed
/// wasn't reached through a profile tab. Stored on a pinned post card.
String? feedLinkOf(Post post) {
  final addr = post.feedFoundAtAccountAddress;
  final key = post.feedRecordKey;
  if (addr == null || addr.isEmpty || key == null || key.isEmpty) return null;
  return 'https://publicos.dev/publicosAddress/$addr/tab/'
      '${Uri.encodeComponent(key)}';
}

/// [post] stamped for "Go to feed" from a pinned card's [feedLink]: the
/// found-via + tab key the pinner stored, and the derived feed URL.
Post withFeedLink(Post post, String? feedLink) {
  final link = feedLink == null ? null : parse(feedLink);
  final isTab = link != null &&
      link.kind == DeepLinkKind.publicosAddress &&
      link.type == DeepLinkTarget.tab &&
      link.key != null;
  return post.copyWith(
    feedUrl: feedUrlOf(post),
    feedFoundAtAccountAddress: isTab ? link.identifier : null,
    feedRecordKey: isTab ? link.key : null,
  );
}

/// The share link for [post]: the found-at tab's
/// link carrying the post when the post knows its tab, else `/post?url=`.
/// Null when the post has no address at all.
String? shareLinkOf(Post post) {
  final url = plainLinkOf(post);
  if (url == null) return null;
  return postShareLink(
    postUrl: url,
    feedUrl: feedUrlOf(post),
    foundAtAddress: post.feedFoundAtAccountAddress,
    tabKey: post.feedRecordKey,
  );
}

/// The post's own internet address: our permalink, or an outside article's
/// link.
String? plainLinkOf(Post post) {
  final url = post.url ?? post.externalUrl;
  return url == null || url.isEmpty ? null : url;
}

/// The channel tab [key] on [address] when it still lists the feed
/// [feedOrPostUrl] is under (Core's [sameChannel]: server, owner as written
/// and slug, cut after the channel's name). Null when the tab is gone, is not
/// a channel, points elsewhere, or the read failed. One eth_call.
Future<Record?> verifiedFeedTab(
    String address, String key, String feedOrPostUrl) async {
  try {
    final record =
        await PublicOSContacts.getRecord(key, EthereumAddress.fromHex(address));
    if (record != null &&
        record.routerSubtype == RouterSubtype.channel &&
        sameChannel(record.value, feedOrPostUrl)) {
      return record;
    }
  } catch (_) {}
  return null;
}

/// The tab a pin's [feedLink] names: the found-via account and the tab key,
/// or null when the pin carries none.
({String address, String key})? feedTabOf(String? feedLink) {
  final link = feedLink == null ? null : parse(feedLink);
  if (link == null ||
      link.kind != DeepLinkKind.publicosAddress ||
      link.type != DeepLinkTarget.tab ||
      link.key == null) {
    return null;
  }
  return (address: link.identifier, key: link.key!);
}

/// The feed name for a post read from its permalink alone (a pinned card):
/// the single-post read carries none, so the detail page's header fell back
/// to `#slug`. The found-via tab's name when the pin's tab still lists this
/// channel (what a tap from that tab shows), else the channel's own name.
/// Null when neither answers.
Future<String?> feedTitleFor(String postUrl, String? feedLink) async {
  final ref = postRefOf(postUrl);
  if (ref == null) return null;
  final tab = feedTabOf(feedLink);
  if (tab != null) {
    final record = await verifiedFeedTab(tab.address, tab.key, postUrl);
    final name = (record?.metadata['name'] as String?)?.trim();
    if (name != null && name.isNotEmpty) return name;
  }
  final resp = await PublicOSChannels.getChannel(
    ownerAddress: ref.owner,
    slug: ref.slug,
    serverAddress: ref.server,
  );
  final name = resp.data?.name.trim();
  return name == null || name.isEmpty ? null : name;
}

Future<void> goToFeed(BuildContext context, Post post) async {
  final feedUrl = feedUrlOf(post);
  if (feedUrl == null) return;
  final addr = post.feedFoundAtAccountAddress;
  final key = post.feedRecordKey;

  if (addr != null && addr.isNotEmpty && key != null && key.isNotEmpty) {
    // One eth_call. Null is "gone", "points elsewhere" or an RPC failure;
    // all read the feed.
    final record = await verifiedFeedTab(addr, key, feedUrl);
    if (!context.mounted) return;
    if (record != null) {
      await AppNav.toTab(context, addr, key);
      return;
    }
  }

  AppNav.onOpenFeedUrl?.call(feedUrl, post.feedTitle,
      post.feedFoundAtAccountAddress, post.feedRecordKey);
}
