// PostSource — where posts come from.
//
// A source yields posts plus a STATE, and optional chrome for the list it
// feeds. It knows how to get more (pages, refresh), what it refused and how to
// unlock it, and which verbs each of its posts carries. It never scrolls,
// never measures, never lays out a card: that is PostListView's, the
// renderer, which receives posts and callbacks and nothing about sources.
//
// Between them sits PostSurface, the common ancestor: it owns the switch
// (loading / gated / gone / error / the renderer) and hands the renderer what
// the source produced. The whole-view screens are HORIZONTAL to the renderer,
// never inside it.
//
// Two sources today: FeedPostSource (a roster of FeedSources, network) and
// BookmarkPostSource (local DB blobs). The renderer cannot tell them apart.

import 'package:flutter/material.dart';
import 'package:publicos_core/publicos_core.dart';
import 'package:publicos_desktop/widgets/feeds/post_list_view.dart'
    show HeldPosts, PostHooks, PostListEmptyContent;
import 'package:publicos_desktop/router.dart';

export 'package:publicos_desktop/widgets/feeds/post_list_view.dart'
    show HeldPosts, PostHooks, PostListEmptyContent, postIdentityKey;

// ── State ────────────────────────────────────────────────────────────────────

/// What the surface sees at any moment. One shape, every source.
sealed class PostSourceState {
  const PostSourceState();
}

/// Nothing to look at yet.
class PostsLoading extends PostSourceState {
  const PostsLoading();
}

/// The source refused the whole view and knows how to unlock it (feed only:
/// sign-in · subscribe · tier · request access). The SOURCE builds the locked
/// widget — it holds the code, the stub, the paywall, the sign-in row and the
/// feed url the decision needs; the surface insets and places it. A null
/// [screen] is "private, but nothing to unlock" (no channel in the url): the
/// surface shows its generic private error.
class PostsGated extends PostSourceState {
  final Widget Function(BuildContext context)? screen;
  const PostsGated(this.screen);
}

/// The one feed no longer exists (its owner deleted it, or the server said
/// 404). The surface draws "Channel not found", plus Unfollow when given.
class PostsGone extends PostSourceState {
  final VoidCallback? onUnfollow;
  const PostsGone({this.onUnfollow});
}

/// A failure that is NOT a gate. The surface draws the error screen; Retry is
/// [PostSource.load].
class PostsFailed extends PostSourceState {
  final String message;
  const PostsFailed(this.message);
}

/// Posts to render. Zero posts still reaches the renderer, which puts its
/// empty content under the chrome (never a blank screen).
class PostsReady extends PostSourceState {
  final List<Post> posts;

  /// A revalidation is running behind posts already on screen — the host's
  /// peripheral hint, never a blocking spinner.
  final bool refreshing;

  /// A page is being appended — the tail loader.
  final bool loadingMore;

  /// New posts held behind the reader: the "New posts" chip.
  final HeldPosts? held;

  const PostsReady({
    required this.posts,
    this.refreshing = false,
    this.loadingMore = false,
    this.held,
  });
}

// ── Host ─────────────────────────────────────────────────────────────────────

/// What the surface lends a source: a context for the dialogs, snackbars and
/// navigation a source's verbs need, the scroll-to-top the renderer's
/// controller performs, and the layout facts the source's chrome mirrors.
abstract class PostListHost {
  BuildContext get context;
  void scrollToTop();

  /// PostCard's content inset for the current layout mode — header cards
  /// align their text to it.
  double get leftInset;
  Color? get accent;
}

// ── The abstraction ──────────────────────────────────────────────────────────

abstract class PostSource extends ChangeNotifier {
  PostListHost? _host;
  bool _started = false;
  bool _disposed = false;

  /// The surface showing this source, while one does.
  PostListHost? get host => _host;

  /// A source outlives nothing: whoever created it disposes it. Async work
  /// that lands after that must not notify.
  bool get isDisposed => _disposed;

  /// The surface attaches on mount. The FIRST attach starts the first load —
  /// a source loads when something shows it, so the post-load asks (the
  /// channel sign-in dialog) have a context to speak through.
  void attach(PostListHost host) {
    _host = host;
    if (!_started) {
      _started = true;
      load();
    }
  }

  void detach() {
    _host = null;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  /// The one way a source announces a change. Safe after dispose.
  @protected
  void changed() {
    if (!_disposed) notifyListeners();
  }

  PostSourceState get state;

  /// First load AND pull-to-refresh.
  Future<void> load();

  /// After the user's own compose: re-fetch and apply the result directly,
  /// no "New posts" chip (there is no reading position to protect), then ask
  /// the host to scroll to the top so the author sees their post.
  Future<void> refreshShowingNewest();

  bool get canLoadMore => false;
  Future<void> loadMore() async {}

  /// The "New posts" chip was tapped: apply the held posts.
  void applyHeld() {}

  // ── Chrome slots — null = nothing there. Feed-only today. ────────────────

  /// Scroll-away banner above the header (a list's "some feeds are private").
  Widget? bannerSlot(BuildContext context) => null;

  /// Scroll-away header (the channel description + credits + stats card, or
  /// a list's header).
  Widget? headerSlot(BuildContext context) => null;

  /// Scrolls up with the header, then sticks (the sort bar).
  Widget? pinnedSlot(BuildContext context) => null;

  /// Bottom-right action (compose).
  Widget? floatingAction(BuildContext context) => null;

  /// What "no posts" means for this source, under the chrome (usually a
  /// [PostListEmptyContent]).
  Widget emptySlot(BuildContext context);

  // ── Per-post ─────────────────────────────────────────────────────────────

  /// Verbs and flags this source contributes to one card.
  PostHooks hooksFor(BuildContext context, Post post) => const PostHooks();

  /// The surface un-bookmarked [post] (a generic card verb). The bookmark
  /// source drops its row; others ignore it.
  void didUnbookmark(Post post) {}

  // ── Contacts — resolved ONCE here, for every source ──────────────────────
  //
  // The addresses on the posts (author, discovery account, channel owner)
  // resolve to contacts in one batched pass after every landing. The surface
  // passes the map to the renderer; a source's own chrome (header credits,
  // the chip's faces) reads it directly. This is the batched-parallel form of
  // the address-row resolver.

  Map<String, Contact> _contacts = {};
  bool _resolving = false;
  int _resolveGeneration = 0;

  Map<String, Contact> get contacts => _contacts;

  /// True while a pass is in flight — PostCard shimmers the author slot
  /// instead of showing the no-author fallbacks for contacts that just
  /// haven't resolved yet.
  bool get awaitingContacts => _resolving;

  /// Resolve the addresses on [posts]. Subclasses call it right after the
  /// posts land; the in-flight flag is raised synchronously so the frame that
  /// first renders the cards already sees it. Generation-guarded so a reload
  /// mid-resolution can't have the stale pass drop the flag early.
  @protected
  Future<void> resolveContacts(Iterable<Post> posts) async {
    final addresses = <String>{};
    for (final post in posts) {
      final a = post.feedFoundAtAccountAddress;
      final b = post.postAuthorAddress;
      // Channel owner too — needed by the tip sheet's actor list (and any
      // other channel-owner-as-contact surface). Deduped against
      // author/found-via, so posts where the owner is also the
      // author/discovery cost nothing extra.
      final c = post.channelOwnerAddress;
      if (a != null && a.isNotEmpty) addresses.add(a);
      if (b != null && b.isNotEmpty) addresses.add(b);
      if (c != null && c.isNotEmpty) addresses.add(c);
    }
    if (addresses.isEmpty) return;
    final gen = ++_resolveGeneration;
    _resolving = true;
    final results = await Future.wait(addresses.map((addr) async {
      try {
        var c = await PublicOSContacts.searchContacts(addr);
        if (c == null) {
          c = await PublicOSContacts.resolveByIdentifier(addr);
          if (c != null) await PublicOSContacts.saveContact(c);
        }
        return MapEntry(addr, c);
      } catch (_) {
        return MapEntry(addr, null);
      }
    }));
    if (_disposed) return;
    final fresh = <String, Contact>{};
    for (final e in results) {
      if (e.value != null) fresh[e.key] = e.value!;
    }
    final me = AppStateNotifier.currentMyContact;
    if (me?.publicosAddress != null) {
      fresh[me!.publicosAddress!.eip55With0x] = me;
    }
    // An address is one account whatever its case: posts carry the author
    // lowercase, contacts are stored EIP-55. Key every hit under the asked
    // spelling, lowercase and EIP-55, so any reader's lookup lands
    // (otherwise, offline, a lowercase author shows as a short address).
    for (final e in fresh.entries.toList()) {
      final k = e.key;
      fresh.putIfAbsent(k.toLowerCase(), () => e.value);
      try {
        fresh.putIfAbsent(
            EthereumAddress.fromHex(k).eip55With0x, () => e.value);
      } catch (_) {}
    }
    if (gen != _resolveGeneration) return; // a newer pass owns the flag
    _contacts = fresh;
    _resolving = false;
    changed();
  }
}
