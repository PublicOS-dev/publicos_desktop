import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:publicos_core/publicos_core.dart';

import '../l10n/l10n_ext.dart';
import '../router.dart' show appNavigatorKey;
import '../router_helpers.dart';

/// Inbound deep links on Windows — the Dart half.
///
/// The native half is `windows/runner/deep_link.{h,cpp}`: Windows activates the
/// app with a URL (`windows.appUriHandler` for `https://publicos.dev/…`,
/// `windows.protocol` for `publicos://…`), and a *second* launch forwards its
/// URL to the running instance instead of starting a second process.
///
/// **Channel name is `com.publicos/deeplink` on purpose** — the same name and
/// the same two method names publicos_client already uses on Android
/// (`getInitialLink` pull on cold start, `onDeepLink` push on warm start). One
/// contract across platforms, so the mobile wiring reads as the twin of this.
///
/// Parsing lives in Core ([parse]); only DISPATCH is here, because where a link
/// lands is per-app: the client pushes a GoRouter route, desktop swaps a pane
/// through the [AppNav] shim.
abstract final class DeepLinks {
  static const MethodChannel _channel = MethodChannel('com.publicos/deeplink');

  /// A link that arrived before anything could act on it.
  ///
  /// Load-bearing: Windows can activate us at a moment when the shell does not
  /// exist yet — cold start (Flutter boots long before `AppShell` mounts) or
  /// while the account picker is up and nobody is signed in. [AppNav]'s
  /// callbacks are null then and a dispatch is a silent no-op, so the URL would
  /// simply evaporate. Held here instead and replayed by [flushPending].
  static String? _pending;

  static bool _started = false;

  /// Wire up the channel and consume the cold-start URL. Call once from
  /// `main()`, before `runApp`.
  static Future<void> start() async {
    if (_started) return;
    _started = true;

    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onDeepLink') {
        final url = call.arguments;
        if (url is String && url.isNotEmpty) {
          handle(url);
        }
      }
      return null;
    });

    // Cold start: the runner stashed the activation URL before building the
    // engine. Pull rather than wait for a push — the native side has it before
    // Dart exists, so there is nobody to push to yet.
    try {
      final initial = await _channel.invokeMethod<String>('getInitialLink');
      if (initial != null && initial.isNotEmpty) {
        _pending = initial;
      }
    } on MissingPluginException {
      // Non-Windows, or a runner without the channel. Not an error.
    } catch (e) {
      Log.w('DeepLinks', 'getInitialLink failed: $e');
    }
  }

  /// Replay whatever arrived too early. Called by `AppShell` right after it
  /// registers its [AppNav] callbacks — that is the first instant a dispatch
  /// can actually land somewhere.
  static void flushPending() {
    final url = _pending;
    if (url == null) return;
    _pending = null;
    handle(url);
  }

  /// Tell the user a link did not resolve.
  ///
  /// A deep link that fails silently is indistinguishable from one that never
  /// arrived — the app just sits on a profile and the person assumes nothing
  /// happened. Every dead end below therefore reports.
  ///
  /// Reuses the strings the client's own browser already shows for the same
  /// failures, in both languages — a parallel set of "not found" copy would
  /// drift from it the first time either was reworded.
  /// [pick] receives the context so the string is resolved at show time —
  /// these are localized, and the caller has no context of its own.
  static void _report(String Function(BuildContext) pick) {
    final context = appNavigatorKey.currentContext;
    if (context == null) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.showSnackBar(SnackBar(content: Text(pick(context))));
  }

  /// Route [url], or stash it if the shell is not ready.
  static void handle(String url) {
    final link = parse(url);
    if (link == null) {
      // Two different situations, and conflating them would be wrong.
      //
      // Addressed to us but malformed (`/publicosAddress/notanaddress`) is a
      // BROKEN LINK and the user should hear about it. A publicos.dev path we
      // deliberately do not claim (the marketing site) is not an
      // error at all and must stay silent.
      if (isAddressedToPublicOs(url)) {
        Log.w('DeepLinks', 'malformed PublicOS link: $url');
        _report((c) => c.l10n.browserContactNotFound);
      } else {
        Log.d('DeepLinks', 'ignoring non-PublicOS link: $url');
      }
      return;
    }
    if (AppNav.onOpenContact == null) {
      Log.d('DeepLinks', 'shell not ready, holding $url');
      _pending = url;
      return;
    }
    _dispatch(link);
  }

  static Future<void> _dispatch(DeepLink link) async {
    final context = appNavigatorKey.currentContext;
    if (context == null) {
      Log.w('DeepLinks', 'no navigator context; holding ${link.identifier}');
      return;
    }

    switch (link.kind) {
      case DeepLinkKind.inboxId:
        AppNav.toInbox(context, link.identifier);
        return;

      case DeepLinkKind.conversationTopic:
        await AppNav.toConversation(context, link.identifier);
        return;

      case DeepLinkKind.publicosAddress:
        await _dispatchAddress(context, link);
        return;
    }
  }

  static Future<void> _dispatchAddress(context, DeepLink link) async {
    final address = EthereumAddress.fromHex(link.identifier);

    switch (link.type) {
      // `/chat/:label` — the DURABLE inbox address. The label is resolved
      // against the on-chain registry rather than trusting an inbox id in the
      // URL, which is exactly what lets the link survive the owner rotating
      // keys. Same resolution the client's browser does for this route.
      case DeepLinkTarget.chat:
        final label = link.key;
        if (label == null || label.isEmpty) break;
        final bytes = await PublicOSXmtp.getAccountInboxIdByLabel(address, label);
        if (bytes == null) {
          // The label is not in the account's on-chain inbox directory —
          // renamed, removed, or the link was mistyped. Land on the profile
          // (the right contact, at least) but SAY so: silently showing a
          // profile when the user asked for a conversation reads as the link
          // having done nothing.
          Log.w('DeepLinks', 'no inbox labelled "$label" on ${link.identifier}');
          _report((c) => c.l10n.inboxIdsInboxNotFound);
          break;
        }
        final inboxId = bytes32ToString(bytes);
        final mine = PublicOS.clientXmtpInboxId;
        if (mine != null &&
            mine.isNotEmpty &&
            inboxId.toLowerCase() == mine.toLowerCase()) {
          // You cannot message yourself. The client quietly lands on the
          // profile in this case; desktop matches rather than inventing a
          // second behaviour for the same link.
          break;
        }
        AppNav.toInbox(context, inboxId);
        return;

      // `/app/:name` — the URL carries only the app's NAME, never the
      // AppBookmark, and `AppNav.toApp` refuses a null one. So resolve it from
      // the registry first, the way the client's browser does.
      case DeepLinkTarget.app:
        final name = link.key;
        if (name == null || name.isEmpty) break;
        final apps = await PublicOSAppRegistry.getAllAccountApps(address);
        AppBookmark? match;
        for (final app in apps ?? const <AppBookmark>[]) {
          if (app.appName == name) {
            match = app;
            break;
          }
        }
        if (match == null) {
          Log.w('DeepLinks', 'no app "$name" on ${link.identifier}');
          _report((c) => c.l10n.browserAppNotFound);
          break;
        }
        await AppNav.toApp(context, link.identifier, appName: name, app: match);
        return;

      // `/tab/:key` — a custom tab, feed or web. The key is the ROUTER
      // RECORD'S key, and the Browser matches on it across both kinds.
      //
      // No existence check here on purpose: the records arrive with the
      // Contact, so the Browser already has the full list and matches against
      // it. Pre-checking would mean a second fetch to answer a question the
      // landing code answers anyway — and an unmatched key is not an error,
      // it lands on the profile (the record may have expired or been deleted
      // since the link was shared).
      case DeepLinkTarget.tab:
        final tabKey = link.key;
        if (tabKey == null || tabKey.isEmpty) break;
        await AppNav.toTab(context, link.identifier, tabKey);
        return;

      // profile / settings / management / unknown-or-absent type: the profile
      // is the correct landing for all of them today. Desktop reaches settings
      // and management through the Browser's own tab strip, not a route.
      case DeepLinkTarget.profile:
      case DeepLinkTarget.settings:
      case DeepLinkTarget.management:
      case null:
        break;
    }

    await AppNav.toProfile(context, link.identifier);
  }
}
