import 'package:flutter/widgets.dart';
import 'package:publicos_core/publicos_core.dart';

/// **Desktop delta — the navigation shim.** See `router.dart` for the why.
///
/// The client's `AppNav.toContact` pushes the browser onto the nav stack at the
/// profile tab. Desktop has no nav stack: opening a contact means **switching
/// the shell to the Contacts pane, focused on that contact** — which the shell
/// can already do (it is exactly what the "My Account" sidebar row does, via a
/// monotonic focus token).
///
/// `AppShell` registers [onOpenContact] at mount. Keeping the client's class and
/// method name means `post_card.dart` — which calls `AppNav.toContact(context,
/// contact)` when you tap a post's author avatar — ports **verbatim**, with no
/// callback threaded down through `posts_list` to reach it.
class AppNav {
  AppNav._();

  /// Set by `AppShell`. Null before the shell mounts (e.g. on the logged-out
  /// account picker), in which case a tap is a no-op rather than a crash.
  static void Function(Contact contact)? onOpenContact;

  /// Set by `AppShell`. Switches the shell to a nav destination by its
  /// `kShellDestinations` index.
  static void Function(int index)? onOpenDestination;

  /// Set by `AppShell`. Switch the shell to the Feeds pane, so a post can open
  /// in its reading column ([toPost]) from anywhere (e.g. a
  /// notification's post).
  static VoidCallback? onShowFeeds;

  /// Open a contact's profile. Desktop: focus the Contacts pane on [contact].
  static void toContact(BuildContext context, Contact contact) {
    onOpenContact?.call(contact);
  }

  /// Open a profile by ADDRESS — the client signature (`context.push(
  /// '/publicosAddress/$address')`, used by `MentionText` taps and the manage
  /// pages). Desktop delta: resolve the stored contact and focus the Contacts
  /// pane on it. An address we have no stored contact for is a no-op — desktop
  /// has no "browse an arbitrary address" surface yet (the mention render
  /// resolver may know the name display-only, but the Contacts pane renders
  /// stored rows). Returns a completed future to match the client's awaitable
  /// shape.
  static Future<void> toProfile(BuildContext context, String address) async {
    try {
      final owner = EthereumAddress.fromHex(address);
      // Stored copy first, then a chain fetch. The fallback is there for
      // deep links (`utils/deep_links.dart`): a link can name an address we
      // have never stored — a stranger's profile shared from outside the
      // app — and without the fetch this method would be a SILENT no-op, so
      // the link would do nothing at all. `toApp` below resolves owners the
      // same way, and it also covers `MentionText` taps on a stranger.
      // `fetchContact` returns a non-nullable Contact (a stub for an address
      // with nothing on chain), so there is no null branch left to guard.
      final contact = await PublicOSContacts.getContact(owner) ??
          await PublicOSContacts.fetchContact(owner);
      onOpenContact?.call(contact);
    } catch (_) {}
  }

  /// Set by `AppShell`. Focus the Contacts (or Orgs) pane on the app owner's
  /// profile, landing on that app's tab.
  static void Function(Contact owner, AppBookmark app)? onOpenApp;

  /// Set by `AppShell`. Focus Contacts on [owner] landing on the custom tab
  /// whose ROUTER RECORD KEY is given — `/publicosAddress/:address/tab/:key`.
  static void Function(Contact owner, String tabKey)? onOpenTab;

  /// Set by `AppShell`. Open one feed by URL in the Feeds pane, outside any
  /// list: a post's "Go to feed" when there is no profile tab to land on.
  /// The client pushes `FeedReaderPage`.
  static void Function(String url, String? title,
      String? foundAtAccountAddress, String? recordKey)? onOpenFeedUrl;

  /// Open a profile landing on one of its custom tabs (feed or web).
  ///
  /// The client expresses this as a route (`/publicosAddress/$address/tab/$key`)
  /// resolved by `browser.dart`'s `_resolveLandingTab`; desktop resolves it in
  /// the Browser's own tab strip instead. Deep links call it, and so does a
  /// post's "Go to feed" (`widgets/feeds/go_to_feed.dart`).
  ///
  /// Owner resolution mirrors [toApp]: stored copy first, then a chain fetch,
  /// so a link naming someone we have never stored still lands.
  /// An unmatched [tabKey] is NOT an error — the Browser falls back to the
  /// profile, since the record may have expired or been deleted since the
  /// link was shared.
  static Future<void> toTab(
      BuildContext context, String address, String tabKey) async {
    try {
      final owner = EthereumAddress.fromHex(address);
      final contact = await PublicOSContacts.getContact(owner) ??
          await PublicOSContacts.fetchContact(owner);
      onOpenTab?.call(contact, tabKey);
    } catch (_) {}
  }

  /// Open a registry app — the client signature (`context.push(
  /// '/publicosAddress/$address/app/$appName', extra: app)`), used by the Apps
  /// view's tiles and the app-profile sheet. The client's route lands the
  /// Browser on the owner's profile at the app tab; **desktop does the same
  /// thing**: resolve the owner contact (stored copy first, chain fetch when
  /// we have none — an app owner is not necessarily a contact yet), then
  /// focus the Contacts pane on it with [app] as the landing tab.
  ///
  /// Desktop delta: the caller is usually inside the Apps big dialog (or the
  /// app-profile dialog stacked on it), and the pane switch happens
  /// underneath — so every dialog above the shell is popped first. Called
  /// from the shell itself (the rail's history), the stack is already at its
  /// root and the pop is a no-op.
  static Future<void> toApp(BuildContext context, String address,
      {String? appName, AppBookmark? app}) async {
    if (app == null) return;
    Navigator.of(context, rootNavigator: true).popUntil((r) => r.isFirst);
    try {
      final owner = EthereumAddress.fromHex(address);
      final contact = await PublicOSContacts.getContact(owner) ??
          await PublicOSContacts.fetchContact(owner);
      onOpenApp?.call(contact, app);
    } catch (_) {}
  }

  /// Open the Treasury destination (index 5). Used by `handleWriteError` when an
  /// SSP gate refuses a write ("not subscribed" → SUBSCRIBE). The pane behind it
  /// is still a placeholder.
  static void toTreasury(BuildContext context) {
    onOpenDestination?.call(5);
  }

  // ── Feeds detail ───────────────────────────────────────────────────────────
  //
  // The client PUSHES `PostDetailPage` / `PostSourceDetailsPage` as routes from
  // inside `post_card`. Desktop renders them IN PLACE in the feeds reading
  // column (master-detail), which only `FeedsPane` can
  // do — but `post_card` is nested several widgets below it and is a verbatim
  // port we don't want to thread a callback through.
  //
  // So FeedsPane registers these while it is mounted, exactly like the shell
  // registers [onOpenContact]. Null when Feeds isn't on screen → tap is a no-op,
  // not a crash.
  //
  // ⚠ These take a BUILDER, not a Post, and that is load-bearing. The caller
  // (`post_card`) is the ONLY place that holds the right arguments — above all
  // `widget.resolvedContacts`, the map PostsList built by resolving the post
  // AUTHORS. FeedsPane has a `_resolvedContacts` of its own, but it is the
  // DRAWER/header map (single-list "via" lines) and the client says so out loud:
  // *"The body (PostsList) keeps its own separate map for post bodies — by
  // design, no coupling."* Rebuilding the args in the pane from that map
  // leaves the author unresolved on the detail page. Handing the
  // builder up means `post_card` passes the client's argument list VERBATIM;
  // the host only supplies `onBack`, which is the one thing it alone knows.

  static void Function(Widget Function(VoidCallback onBack) builder)? onOpenPost;
  static void Function(Widget Function(VoidCallback onBack) builder)?
      onOpenPostSource;

  /// Open a post's detail (post + comments) in the feeds reading column.
  static void toPost(
    BuildContext context,
    Widget Function(VoidCallback onBack) builder,
  ) {
    onOpenPost?.call(builder);
  }

  /// Open a post's source details (where this feed came from).
  static void toPostSource(
    BuildContext context,
    Widget Function(VoidCallback onBack) builder,
  ) {
    onOpenPostSource?.call(builder);
  }

  // ── Feeds flow pages ───────────────────────────────────────────────────────
  //
  // The client PUSHES ComposePostPage / CreateChannelPage / ManageChannelPage /
  // ManageServerPage as routes and awaits their pop result. Desktop renders
  // them **inside the reading column** (post writing is a full thing inside
  // the content area) via `InlineFlowHost` — a
  // nested Navigator, so the pages' own `Navigator.pop(context, result)`,
  // AppBar back buttons and internal pushes (ManageServer → ManageChannel) all
  // work VERBATIM, no body edits.
  //
  // Registered by FeedsPane while mounted, same lifecycle contract as
  // [onOpenPost]. Null (Feeds off screen) → resolves null, like a dismissed
  // page.

  static Future<dynamic> Function(Widget page)? onOpenFlow;

  /// Push [page] as an in-content-area flow and complete with its pop result.
  /// The desktop stand-in for the client's
  /// `Navigator.push(context, MaterialPageRoute(builder: (_) => page))`.
  static Future<dynamic> openFlow(BuildContext context, Widget page) {
    final open = onOpenFlow;
    if (open == null) return Future<dynamic>.value();
    return open(page);
  }

  // ── Messages ───────────────────────────────────────────────────────────────
  //
  // The client's messages_view routes conversation opens through AppNav
  // (`context.push('/conversationTopic/…')` / `('/inboxId/…')` → the mobile
  // browser). Desktop renders the Browser in the Messages pane's right
  // side, which only MessagesPane can do — so it registers these while
  // mounted (the FeedsPane pattern), cleared in dispose so a stale handler
  // can't fire into a dead State. Null → tap is a no-op, not a crash.

  /// Open a conversation by TOPIC (groups; also DM fallback). Registered by
  /// `MessagesPane`.
  static Future<void> Function(String topic)? onOpenConversationTopic;

  /// Open a DM by peer inbox ID. Registered by `MessagesPane`.
  static void Function(String inboxId)? onOpenInbox;

  /// Client signature (`context.push('/conversationTopic/$topic')`).
  static Future<void> toConversation(BuildContext context, String topic) async {
    await onOpenConversationTopic?.call(topic);
  }

  /// Client signature (`context.push('/inboxId/$inboxId')`).
  static void toInbox(BuildContext context, String inboxId) {
    onOpenInbox?.call(inboxId);
  }
}
