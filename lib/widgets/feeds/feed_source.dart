// The client's single feed currency.
//
// A [FeedSource] is ONE feed url plus that feed's own display context —
// via/foundAt is per-feed, not per-surface (in a merged list every feed has
// its own "via"). Hosts (feeds_view, browser) derive a roster of these and
// pass it to PostsList; PostsList fetches each url and renders each post with
// its FeedSource's context. Runtime objects — resolution output, never
// persisted. Bookmarks are NOT a FeedSource (they leave the feed
// abstraction entirely; see BookmarkPostSource).

import 'package:publicos_core/publicos_core.dart';

/// Where a feed in a list came from — drives the per-post verb. Sealed so an
/// origin always carries exactly the data its verb needs (no nullable-sibling
/// conventions): an [AccountFeedOrigin] can always be muted, a
/// [ListRowFeedOrigin] can always be removed. A standalone feed (channel
/// pick, browser tab) has a null origin and no verb.
sealed class FeedSourceOrigin {
  const FeedSourceOrigin();
}

/// Came from a followed account's profile channel records. The record key is
/// the stable channel identity — the mute anchor that survives the author
/// re-pointing the url.
class AccountFeedOrigin extends FeedSourceOrigin {
  final String accountAddress;
  final String recordKey;
  const AccountFeedOrigin({
    required this.accountAddress,
    required this.recordKey,
  });
}

/// A hand-added `list_feeds` row. [listFeedId] is what
/// `removeFeedFromList` needs; -1/null marks a synthesized row that has no
/// stored counterpart.
class ListRowFeedOrigin extends FeedSourceOrigin {
  final int? listFeedId;
  const ListRowFeedOrigin({this.listFeedId});
}

/// ONE feed + its own display context.
class FeedSource {
  /// The feed. Fetch key + dedupe identity.
  final String url;

  /// Display name (channel name, tab name, feed title).
  final String? title;

  /// "via X" — the contact this feed was discovered under, when the host
  /// already holds the resolved [Contact] (the browser door).
  final Contact? foundAtContact;

  /// Same provenance as an address, when only the address is known (list
  /// resolution). [effectiveFoundAtAddress] merges the two forms.
  final String? foundAtAccountAddress;

  /// The router `record.key` of the channel tab on the found-via profile
  /// this feed came from. With [effectiveFoundAtAddress] it names the tab a
  /// post's "Go to feed" lands on. Null when the feed wasn't reached through
  /// a profile tab (pasted feed, own channel pick).
  final String? recordKey;

  /// Null = standalone (channel pick, browser tab): no list verb.
  final FeedSourceOrigin? origin;

  /// The owner deleted this channel (its record is gone from their profile —
  /// `PublicOSFollows.resolveListFeedsDetailed`). PostsList renders "Channel
  /// not found" without fetching. A server 404
  /// reaches the same screen from the fetch side.
  final bool gone;

  const FeedSource({
    required this.url,
    this.title,
    this.foundAtContact,
    this.foundAtAccountAddress,
    this.recordKey,
    this.origin,
    this.gone = false,
  });

  /// Promote Core's resolver output ([PublicOSFollows.resolveListItems])
  /// 1:1 into the client currency — the redesign promotes this shape, it
  /// doesn't invent it.
  factory FeedSource.fromFollowedFeed(FollowedFeed f) => FeedSource(
        url: f.feedUrl,
        title: f.title,
        foundAtAccountAddress: f.feedFoundAtAccountAddress,
        recordKey: f.recordKey,
        origin: f.origin == FeedOrigin.account &&
                f.accountAddress != null &&
                f.recordKey != null
            ? AccountFeedOrigin(
                accountAddress: f.accountAddress!,
                recordKey: f.recordKey!,
              )
            : ListRowFeedOrigin(listFeedId: f.listFeedId),
      );

  String? get effectiveFoundAtAddress =>
      foundAtContact?.publicosAddress?.eip55With0x ?? foundAtAccountAddress;
}

/// Parse a channel stub out of a feed URL matching
/// `/api/<owner>/channels/<slug>/…`. Returns null for any other shape.
///
/// This predicate is NEVER used to decide how to FETCH — every url is
/// fetched identically through the one Core path. It exists only for
/// non-fetch jobs: the compose target, the vote owner/slug, and the
/// private-feed gate's channel identity.
Channel? channelStubFromFeedUrl(String feedUrl) {
  final uri = Uri.tryParse(feedUrl);
  if (uri == null) return null;
  final segs = uri.pathSegments;
  if (segs.length < 4 || segs[0] != 'api' || segs[2] != 'channels') {
    return null;
  }
  final owner = segs[1];
  final slug = segs[3];
  if (owner.isEmpty || slug.isEmpty) return null;
  final serverAddress = '${uri.scheme}://${uri.authority}';
  final now = DateTime.now().toIso8601String();
  return Channel(
    id: 0,
    accountId: 0,
    name: slug,
    description: '',
    slug: slug,
    isPrivate: true,
    ownerAddress: owner,
    serverAddress: serverAddress,
    createdAt: now,
    updatedAt: now,
  );
}
