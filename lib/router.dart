import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:publicos_core/publicos_core.dart';

/// **Desktop delta — the router shim.**
///
/// publicos_client is a routed app (`router.dart` + `router_helpers.dart`);
/// publicos_desktop is a **shell app** — one `AppShell` swapping panes in place,
/// no named routes. Ported client widgets nonetheless reach into the client's
/// `router.dart` for two things, so desktop mirrors them **under the same names**
/// and the ported tree compiles untouched. Same trick as `theme/theme_provider.dart`
/// and `l10n/` — mirror the API, supply a desktop-shaped implementation.

/// Watched by `TappableMedia` / `VideoUrlThumbnail`, which subscribe as
/// [RouteAware] to **pause video when a route is pushed over them** (open a
/// dialog on top of a playing feed video and it must not keep playing behind).
///
/// Must be registered in `MaterialApp.navigatorObservers` or the subscribe call
/// silently never fires — the video would keep playing under a dialog. Wired in
/// `main.dart`.
final RouteObserver<PageRoute<dynamic>> appRouteObserver =
    RouteObserver<PageRoute<dynamic>>();

/// The root navigator, so code with no `BuildContext` of its own can still
/// navigate. It exists for **deep links** (`utils/deep_links.dart`): a
/// URL arrives from the OS on a platform channel, not from a widget tap, so
/// there is no context anywhere in the call chain.
///
/// Must be passed to `MaterialApp.navigatorKey` in `main.dart` — without it
/// `currentContext` is null and every deep link silently does nothing.
/// [AppNav.toApp] in particular needs a *real* context: it pops the dialog
/// stack (`Navigator.of(context, rootNavigator: true)`) before switching panes.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

/// The signed-in user's cached [Contact].
///
/// **This is why ported feed widgets import `router.dart`** — it is where the
/// client happens to define this class, and `post_card` / `posts_list` read
/// `AppStateNotifier.currentMyContact` in six places (is this post mine? is this
/// reaction mine? never tip yourself). Core has no `PublicOS.currentMyContact`,
/// so the client keeps its own cache; desktop mirrors it rather than
/// rewriting six call sites.
///
/// Only the self-contact half of the client's class is mirrored. The rest of it
/// (init phase, auth flags, pending route) is routing/boot state that desktop's
/// `_InitGate` + `AppShell` already own — reproducing it would be two sources of
/// truth for the same thing.
class AppStateNotifier extends ChangeNotifier {
  /// Created once in `main()`. Null-safe everywhere: before login there is no
  /// self contact, and every getter below tolerates that.
  static AppStateNotifier? instance;

  Contact? _myContact;
  StreamSubscription<Contact>? _selfContactSub;

  AppStateNotifier() {
    // Subscribe ONCE. Core emits the signed-in user's fresh Contact here every
    // time `fetchContact` refreshes our own profile (avatar / membership /
    // records). Domain-event stream carrying the payload — the allowed side of
    // the no-stream-subscriptions rule, same as the XMTP stream.
    _selfContactSub = PublicOS.selfContactUpdates.listen((contact) {
      _myContact = contact;
      notifyListeners();
    });
  }

  /// Cached Contact for the currently logged-in account. Verbatim semantics
  /// from the client: null until [loadMyContact] runs at login.
  static Contact? get currentMyContact => instance?._myContact;

  /// Load and cache the current account's Contact. Safe to call repeatedly.
  /// Called from `select_account_screen._selectAccount` at the same boot slot
  /// the client uses (`app_initializer.runBoot`).
  static Future<Contact?> loadMyContact() async {
    final self = instance;
    if (self == null) return null;
    final addrHex = PublicOS.myPublicosAddress;
    if (addrHex == null) {
      self._myContact = null;
      self.notifyListeners();
      return null;
    }
    try {
      final contact =
          await PublicOSContacts.getContact(EthereumAddress.fromHex(addrHex));
      self._myContact = contact;
      self.notifyListeners();
      return contact;
    } catch (_) {
      return self._myContact;
    }
  }

  /// Overwrite the cached contact after an in-app edit (e.g. updating records).
  static void setMyContact(Contact? contact) {
    final self = instance;
    if (self == null) return;
    self._myContact = contact;
    self.notifyListeners();
  }

  @override
  void dispose() {
    _selfContactSub?.cancel();
    super.dispose();
  }
}
