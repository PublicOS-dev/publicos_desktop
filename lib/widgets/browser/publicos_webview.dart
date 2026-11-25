// PORT of publicos_client's `components/browser/publicos_webview.dart`.
//
// Same structure, same member names, same order, so a re-sync is a diff rather
// than a re-read. Every departure is marked `DELTA` with its reason, and all of
// them are forced by the platform rather than chosen:
//
//   DELTA 1  engine            WebView2 (zero_webview_windows) vs webview_flutter.
//   DELTA 2  injection         document-start here, page-finish there.
//   DELTA 3  pull-to-refresh   dropped — a touch gesture riding an engine-only
//                              scroll callback. Also the in-webview debug panel,
//                              which exists because a phone has no console.
//   DELTA 4  route interception dropped — the client pushes first-party links
//                              into GoRouter; desktop has no router.
//
// **Presentation only.** The EIP-1193 provider, the dispatch, the grant gate
// and every line that touches a key live in `publicos_web3_bridge`, shared with
// the client. Change the bridge once and both apps move together.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:publicos_core/publicos_core.dart' show AppCardRef, PublicOS;
import 'package:publicos_web3_bridge/publicos_web3_bridge.dart';
import 'package:web3dart/web3dart.dart' show EthPrivateKey;
import 'package:zero_webview_windows/zero_webview_windows.dart';

import 'package:publicos_desktop/data/chain_registry.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';
import 'package:publicos_desktop/widgets/browser/web3_adapters.dart';
import 'package:publicos_desktop/widgets/browser/web3_host.dart';
import 'package:publicos_desktop/widgets/pixel_rain_loading_widget.dart';
import 'package:publicos_desktop/widgets/wave_text.dart';

/// Web3-enabled WebView wrapper for PublicOS
///
/// This component wraps the standard WebView with Web3 provider injection,
/// enabling dApps to interact with the user's wallet through window.ethereum
class PublicOSWebView extends StatefulWidget {
  final String initialUrl;
  final Function(String)? onError;
  final Function(String)? onPageFinished;

  /// DELTA 1: the client hands back its `WebViewController` here so the Browser
  /// can hold a handle for `goBack()`. The two engines' controllers are
  /// different types, so desktop hands back the capability instead of the
  /// object — the host only ever wanted the one method.
  final void Function(Future<void> Function() goBack)? onControllerCreated;

  /// Fired on every navigation edge with the current `canGoBack()` state, so
  /// the host can mirror it synchronously.
  final void Function(bool canGoBack)? onCanGoBackChanged;

  /// Pins the browser to a SPECIFIC account instead of the global web-selected
  /// key. Set by the Manage-wallet flow to the wallet the user pressed
  /// "Manage" on — its `address` (a Safe address for a Safe, the EOA for a
  /// keychain key). When null (the standalone Browser), the global
  /// web-selected key is used.
  final String? overrideAccountAddress;

  /// The key that signs for [overrideAccountAddress]: the keychain key for an
  /// EOA wallet, or the account owner key for a Safe (EIP-1271 / Safe-routing
  /// is deferred). When null, signing falls back to the web-selected/session key.
  final EthPrivateKey? overrideSigningKey;

  /// True when [overrideAccountAddress] is a wallet this device holds NO key
  /// for (a linked address the user only watches). The page may be shown the
  /// address; a signature request is refused, and [onNoSigningKey] says so.
  /// Its approval is kept for this view only, never stored (see the bridge's
  /// `PinnedGrantStore`).
  final bool overrideWatchOnly;

  /// A counter the host bumps to open THIS page's key permissions through its
  /// own gate (the Manage view's key chip). In a pinned view that is the one
  /// pinned key: approve it for the site, or take the approval back.
  final int permissionsRevision;

  /// The page asked a granted address to sign and no key is held for it (a
  /// watched wallet). The host shows the notice where the user can see it;
  /// with no host callback a snackbar is used.
  final VoidCallback? onNoSigningKey;

  /// Fired whenever this page's CONNECTION state changes — `true` on a fresh
  /// grant (connect sheet) or a returning-granted load, `false` on an ungranted
  /// load or a web-key switch to a key this origin lacks. It is a connect
  /// *event*, never a bare re-display.
  final void Function(bool connected)? onConnectionChanged;

  /// The address the page now sees first, or null — fired beside
  /// [onConnectionChanged] so the host's key chip can show which key this site
  /// is using.
  final void Function(String? address)? onActiveAccountChanged;

  /// A counter the host bumps whenever this site's PERMISSION changed outside
  /// the provider — the key indicator's picker closing, a revoke in the
  /// keychain.
  ///
  /// It is a revision number rather than the preferred-key label on purpose:
  /// switching the preferred key does not change what a site may see, so
  /// watching that label would re-evaluate the page on a non-event and miss
  /// the real one. A revision number says only "grants moved, re-read them",
  /// which is exactly what the host knows.
  final int grantsRevision;

  /// Hands the host THIS page's [ChainRegistry], once, when the widget
  /// mounts — so the deck cluster can show which chain the tab is on and
  /// move it.
  ///
  /// The registry stays owned by this webview, which is the invariant that
  /// matters: it is created and discarded with the page, so a switch moves
  /// one tab and can never leak into another. The host holds the reference
  /// only to read `currentChainId` and call `switchChain`.
  final void Function(ChainRegistry registry)? onChainRegistryCreated;

  /// The tab's chain moved — by a page calling `wallet_switchEthereumChain`,
  /// or by the user. Carries the new `0x`-prefixed id so chrome can
  /// re-render without polling the registry.
  final void Function(String chainId)? onChainChanged;

  /// Hands the host a reload for THIS page.
  ///
  /// DELTA: the client hands back its whole `WebViewController` and calls
  /// `reload()` on it; the two engines' controllers are different types, so
  /// desktop hands back the capability instead — same shape as
  /// [onControllerCreated] already uses for `goBack`. Needed because a
  /// user-chosen chain switch reloads the page (a legacy dApp reads the
  /// chain once on mount and never listens for `chainChanged`).
  final void Function(Future<void> Function() reload)? onReloadCreated;

  /// What this view is allowed to reach. Permissive by default, matching the
  /// client — the safeguard ships with its policy open so that tightening it
  /// later is changing a value rather than threading a parameter through every
  /// construction site.
  final WebScope scope;

  /// Whether this page is denied the Web3 wallet bridge entirely.
  ///
  /// **Defaults to FALSE — every existing surface keeps the bridge exactly as
  /// it always had it**, matching the client. It exists for **app cards**,
  /// which pass `true`: a card mounts on a profile someone is merely *reading*,
  /// with no navigation act behind it, so it is the one surface that should
  /// never reach a wallet.
  ///
  /// This engine needs the guard in THREE places, not two: WebView2 registers
  /// the provider with `injectAtDocumentStart` BEFORE the first navigation and
  /// it survives every navigation after — so a sandboxed page must never have
  /// it registered at all, on top of skipping the bridge and the per-page
  /// re-injection. That document-start registration is exactly what makes the
  /// desktop provider win the race against a dApp's own scripts, and it is why
  /// forgetting this guard here would be worse than forgetting it on mobile.
  ///
  /// ⚠ Whether *website-record* tabs should lose the bridge too is an open
  /// question; this flag would be its mechanism.
  final bool sandboxed;

  /// Render as an **app card** rather than a browser page: no error screen and
  /// no loading state, both of which render nothing so the card's own image
  /// keeps showing underneath. Twin of the client's `cardMode`.
  final bool cardMode;

  /// When set, the page may not navigate outside this URL prefix.
  ///
  /// ⚠ Enforced REACTIVELY on this platform -- see `_enforceOrigin`. WebView2
  /// as wrapped here has no navigation-request gate, so an off-origin page
  /// begins loading before it is refused. The client's is preventive.
  final Uri? allowedOrigin;

  /// Called with a navigation refused by [allowedOrigin].
  final void Function(String url)? onOffOriginNavigation;

  /// Which storage profile -- cookies, localStorage, IndexedDB, cache --
  /// this page lives in. `null` = the current session's own jar
  /// ([WebStorageProfileId.account]). The wallet manager passes
  /// [WebStorageProfileId.wallet] so the wallet dApp never shares a jar with
  /// an app tab of the same account. Twin of the client's.
  final String? profileId;

  /// The fifth seam: builds the engine controller for [profileId]. Defaults
  /// to this app's implementation; injectable so a test can hand in a fake.
  final WebStorageProfile<WebviewController> storage;

  const PublicOSWebView({
    super.key,
    required this.initialUrl,
    this.onError,
    this.onPageFinished,
    this.onControllerCreated,
    this.onCanGoBackChanged,
    this.overrideAccountAddress,
    this.overrideSigningKey,
    this.overrideWatchOnly = false,
    this.permissionsRevision = 0,
    this.onNoSigningKey,
    this.onConnectionChanged,
    this.onActiveAccountChanged,
    this.onChainRegistryCreated,
    this.onChainChanged,
    this.onReloadCreated,
    this.grantsRevision = 0,
    this.scope = WebScope.unrestricted,
    this.sandboxed = false,
    this.cardMode = false,
    this.allowedOrigin,
    this.onOffOriginNavigation,
    this.profileId,
    this.storage = const DesktopWebStorage(),
  });

  @override
  State<PublicOSWebView> createState() => _PublicOSWebViewState();
}

class _PublicOSWebViewState extends State<PublicOSWebView> {
  /// DELTA 1: `late`, not `final ... = WebviewController()`. The seam builds
  /// AND initializes the controller (WebView2 binds its folder at
  /// `initialize`), so it exists only once `_initializeController` has run
  /// that far. `_controllerBound` guards the two paths that can run earlier:
  /// `didUpdateWidget` and `dispose`.
  late final WebviewController _controller;
  bool _controllerBound = false;
  String? _error;

  /// DELTA 3: the client's pull-to-refresh cluster (11 members) and its
  /// in-webview debug panel are absent here.

  // ── the bridge ──────────────────────────────────────────────────────────
  //
  // Built once the controller exists, torn down with the widget. The widget
  // never reaches past these: it feeds the host lifecycle events and page
  // messages, and reads `_chains.currentChainId` for display.

  WebView2Host? _host;
  Web3Dispatcher? _dispatcher;
  ConnectGate? _gate;
  // The chain list comes from the APP, not the package: `kBridgeChainRpcMap`
  // is derived from `lib/data/chain_registry.dart`, the same file the Send
  // sheet, the network pills and the brand marks read. The bridge's own
  // `defaultChains` stays a standalone fallback we never take, which is what
  // stops the browser and the wallet drifting onto different endpoints for
  // the same chain.
  late final ChainRegistry _chains = ChainRegistry(
    chains: kBridgeChainRpcMap,
    onChainChanged: (id) {
      // The page first (it is the spec's audience), then the chrome.
      _channel?.emit(Web3Events.chainChanged, id);
      widget.onChainChanged?.call(id);
    },
    log: _log,
  );
  Web3Channel? _channel;

  /// The origin of the document currently loaded, as the bridge sees it.
  /// Updated on every navigation edge, because an SPA can move without one.
  Uri? _currentOrigin;

  /// DELTA 1: WebView2 initialization is async, so there is a moment before
  /// the surface exists. The client's engine has no such phase.
  bool _ready = false;

  /// The engine has painted at least one page, so the texture holds something
  /// worth showing. Separate from [_ready]: `loadUrl` returns when
  /// navigation STARTS, so revealing on `_ready` alone would put a texture on
  /// screen before the document has painted — a mount-time white flash.
  bool _painted = false;

  /// Reveal anyway if nothing ever completes. A page that hangs must not leave
  /// the pane on a spinner forever; a slow one simply keeps the placeholder,
  /// which is the honest picture either way.
  Timer? _revealTimer;
  static const _revealTimeout = Duration(milliseconds: 2500);

  /// The pane's own size and scale, recorded in [build] on the placeholder
  /// pass so the surface can be sized BEFORE the first navigation.
  ///
  /// The engine creates its surface at a hardcoded 1280x720 at scale 1.0 and
  /// the package only resizes it from a post-frame callback, so without this
  /// the first paint is laid out at the wrong size and stretched into the
  /// pane.
  Size? _paneSize;
  double _paneScale = 1.0;

  StreamSubscription<WebViewEvent>? _eventSub;
  StreamSubscription<String>? _messageSub;
  StreamSubscription<HistoryChanged>? _historySub;

  String get _chainId => _chains.currentChainId;

  /// A granted address was asked to sign and this device holds no key for it.
  void _noSigningKey() {
    if (!mounted) return;
    final tell = widget.onNoSigningKey;
    if (tell != null) {
      tell();
      return;
    }
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(content: Text(context.l10n.walletWatchOnlyCantSign)),
    );
  }

  /// Open this page's key permissions through its own gate, so every write
  /// goes through the same store the page reads ([permissionsRevision]).
  Future<void> _openPermissions() async {
    final gate = _gate;
    if (gate == null) return;
    try {
      await gate.requestPermissions(_currentOrigin);
    } catch (_) {
      // Dismissed, or the page has no origin yet. Nothing changed.
    }
  }

  /// Reads `widget.` through closures on every call, NOT captured once.
  ///
  /// The wallet manager builds this webview BEFORE its managed key has
  /// resolved, so a captured value would freeze `null` for the life of the
  /// bridge and every signature would fall back to the web-selected key
  /// instead of the pinned wallet's — the page told one address, signing with
  /// another. Same reasoning and same code as the client.
  SessionWalletBinding get _wallet => SessionWalletBinding(
        userAddressOf: currentUserAddress,
        overrideAccountAddressOf: () => widget.overrideAccountAddress,
        overrideSigningKeyOf: () => widget.overrideSigningKey,
      );

  /// Host + page-lifecycle subscription. **Always runs, sandboxed or not.**
  ///
  /// These were originally inside [_buildBridge], which meant gating the bridge
  /// also silently killed every lifecycle event -- so a sandboxed view had no
  /// page-finished, no error reporting, and no way to watch where it navigated.
  /// A card needs all three precisely BECAUSE it has no bridge. Split out.
  void _buildHost() {
    final host = WebView2Host(_controller, log: _log);
    _host = host;

    _eventSub = host.events.listen((e) async {
      switch (e.kind) {
        case WebViewEventKind.pageStarted:
        case WebViewEventKind.urlChanged:
          // Tracked on BOTH, because an SPA moving by history.pushState fires
          // only the url change — and the bridge's scope check reads this on
          // every request.
          _currentOrigin = Uri.tryParse(e.url);
          _enforceOrigin(e.url);
        case WebViewEventKind.pageFinished:
          _currentOrigin = Uri.tryParse(e.url);
          // Before the origin lock: a refused page still painted, and the
          // placeholder must not outlive whatever the user is looking at.
          _markPainted();
          if (_enforceOrigin(e.url)) return;
          await _injectProvider();
          widget.onPageFinished?.call(e.url);
        case WebViewEventKind.error:
          if (e.isMainFrame) {
            if (mounted) setState(() => _error = e.message);
            widget.onError?.call(e.message ?? 'Navigation failed');
          }
      }
    });

    _historySub = _controller.historyChanged.listen((h) {
      _host?.canGoBackNow = h.canGoBack;
      widget.onCanGoBackChanged?.call(h.canGoBack);
    });
  }

  /// The origin lock. Returns true when [url] was refused.
  ///
  /// ⚠ **REACTIVE, not preventive -- and weaker than the client's.** The client
  /// gets `NavigationDecision.prevent` from `webview_flutter` and stops the
  /// navigation before it starts. WebView2 as wrapped by `zero_webview_windows`
  /// exposes a URL *stream* and no navigation-request gate, so the only move
  /// available here is to notice after the fact and tear the page down. An
  /// off-origin page therefore BEGINS loading before it is refused.
  ///
  /// Tolerable for a card because a card carries no bridge, so the worst case
  /// is a foreign page flashing for a frame rather than reaching a key. Stated
  /// rather than hidden, in the same spirit as the host's
  /// `supportsDocumentStartInjection`: this asymmetry is real and the next
  /// reader needs to see it. Closing it properly means adding request
  /// interception to our `zero_webview_windows` fork.
  bool _enforceOrigin(String url) {
    final origin = widget.allowedOrigin;
    if (origin == null) return false;
    // The teardown navigation is exempt from the origin lock. This engine has
    // a real `dispose()` and never loads about:blank itself, so the line is
    // parity with the client, where iOS routes the about:blank teardown
    // through the gate and refusing it cancelled the teardown.
    if (url == 'about:blank') return false;
    final target = Uri.tryParse(url);
    if (target != null && AppCardRef.isUnder(target, origin)) return false;
    _log('[PublicOSWebView] off-origin, refusing: $url');
    widget.onOffOriginNavigation?.call(url);
    return true;
  }

  void _buildBridge() {
    final host = _host;
    if (host == null) return;
    final channel = HostWeb3Channel(host, log: _log);
    final wallet = _wallet;

    final gate = ConnectGate(
      wallet: wallet,
      // The grant table as THIS view may see it. Pinned (the Manage view):
      // only the pinned key's own approval, and the site's stored active key
      // is never read or written, so the regular browser's choices for the
      // same site are untouched. Not pinned: the table as it is.
      grants: PinnedGrantStore(
        const CoreGrantStore(),
        pinOf: () => widget.overrideAccountAddress,
        watchOnlyOf: () => widget.overrideWatchOnly,
      ),
      consent: SheetWeb3Consent(
        contextOf: () => mounted ? context : null,
        chainIdOf: () => _chainId,
      ),
      channel: channel,
      // Session, not account: a user can hold several sessions for one account
      // on one device, and an account-scoped grant cannot tell them apart.
      sessionAddress: currentSessionAddress(),
      onConnectionChanged: (c) => widget.onConnectionChanged?.call(c),
      onActiveAccountChanged: (a) => widget.onActiveAccountChanged?.call(a),
      log: _log,
    );

    _channel = channel;
    _gate = gate;
    _dispatcher = Web3Dispatcher(
      gate: gate,
      wallet: wallet,
      consent: SheetWeb3Consent(
        contextOf: () => mounted ? context : null,
        chainIdOf: () => _chainId,
      ),
      channel: channel,
      chains: _chains,
      rpc: HttpWeb3Rpc(_chains, log: _log),
      transactions: ChainTransactionExecutor(_chains, log: _log),
      currentOrigin: () => _currentOrigin,
      onNoSigningKey: (_) => _noSigningKey(),
      scope: widget.scope,
      log: _log,
    );

    // DELTA 1: the client wires these through its NavigationDelegate, which it
    // owns because the same callbacks drive its chrome. WebView2 reports them
    // as streams, folded into one lifecycle by WebView2Host.
    _messageSub = host.messages.listen((raw) => _dispatcher?.handle(raw));

  }

  /// Install the EIP-1193 provider into the page.
  ///
  /// **DELTA 2 — document-start, not page-finish.** The client injects on
  /// `onPageFinished` because `webview_flutter` exposes neither Android's
  /// `addDocumentStartJavaScript` nor iOS's `WKUserScript`, so a dApp that
  /// reads `window.ethereum` before its own first script wins the race.
  /// WebView2 has no such limit.
  ///
  /// The consequence is worth understanding before anyone "fixes" it. A
  /// document-start script is registered ONCE, before any URL is known, so it
  /// cannot bake in a per-origin address the way the client's per-page
  /// injection does. The provider is therefore always installed identity-less,
  /// and WHO it speaks for is announced here, after the grant for THIS origin
  /// has been checked. Same grant rule as the client, later announcement — and
  /// the stricter ordering of the two, since no origin can receive an address
  /// before its grant is evaluated.
  Future<void> _injectProvider() async {
    // Third guard. A sandboxed page never has a host or gate anyway, because
    // the bridge was never built -- this states the intent rather than relying
    // on a null-check to imply it.
    if (widget.sandboxed) return;
    final gate = _gate;
    final channel = _channel;
    if (gate == null || channel == null) return;

    // Resolved unconditionally, unlike the grant's own use of it, because a
    // `granted: false` is unreadable without the two values that produced it.
    // A grant row is keyed by (origin, session, eoa), and a site may hold
    // SEVERAL of them -- its permission is the set. `selectedAddress` is a
    // scalar, so it gets `accounts[0]`: the preferred key if this site holds
    // it, otherwise the first permitted key in keychain order. Printing the
    // origin and the count next to the verdict is what makes a surprise
    // answerable.
    final accounts = await gate.grantedAccounts(_currentOrigin);
    final granted = accounts.isNotEmpty;
    final address = granted ? accounts.first : null;

    final originKey = _currentOrigin == null
        ? 'null'
        : ConnectGate.originKey(_currentOrigin!);
    _log('[PublicOSWebView] injecting provider '
        '(origin: $originKey, '
        'keys: ${accounts.length} -> ${address ?? 'NONE'}, '
        'session: ${currentSessionAddress()}, '
        'granted: $granted, chain: $_chainId, '
        'pinned: ${widget.overrideAccountAddress != null})');

    try {
      await channel.setLiveAccount(address);
      await channel.emit(Web3Events.accountsChanged, accounts);
      // A granted load IS a connect event (lights the chip); an ungranted one
      // reports false, which hides a chip left over from the previous page.
      widget.onConnectionChanged?.call(granted);
      widget.onActiveAccountChanged?.call(address);
    } catch (e) {
      _log('[PublicOSWebView] provider announce failed: $e');
    }
  }

  /// DELTA 1: the client varies the user agent per domain, so sites serving a
  /// mobile layout get one. Desktop already is a desktop browser, so WebView2's
  /// own UA is left alone.

  void _log(String message) => debugPrint(message);

  @override
  void initState() {
    super.initState();
    _currentOrigin = Uri.tryParse(widget.initialUrl);
    // Hand the chrome this page's registry and its starting chain,
    // POST-FRAME: initState runs inside the host's build and the host
    // answers these by calling setState.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.onChainRegistryCreated?.call(_chains);
      widget.onChainChanged?.call(_chains.currentChainId);
    });
    _initializeController();
  }

  @override
  void didUpdateWidget(PublicOSWebView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialUrl != oldWidget.initialUrl && _controllerBound) {
      _controller.loadUrl(widget.initialUrl);
    }
    // This site's permission changed while the page is running. Re-read the
    // set and tell the page: still granted → re-announce it, disconnected →
    // `accountsChanged([])` and the chip hides. Only fires when the URL is
    // unchanged — a URL change reloads and re-injects anyway.
    if (widget.grantsRevision != oldWidget.grantsRevision &&
        widget.initialUrl == oldWidget.initialUrl) {
      _gate?.refresh(_currentOrigin);
    }
    if (widget.permissionsRevision != oldWidget.permissionsRevision) {
      _openPermissions();
    }
  }

  /// DELTA 1: async, because WebView2 initialization is. The client's is
  /// synchronous and its controller exists immediately.
  Future<void> _initializeController() async {
    _log('[PublicOSWebView] Initializing controller for: ${widget.initialUrl}');

    try {
      final version = await WebviewController.getWebViewVersion();
      if (version == null) {
        throw StateError(
          'The Microsoft Edge WebView2 Runtime is not installed on this machine.',
        );
      }

      // A missing session address is the zero address, not null: the profile
      // id is part of the storage path, and a mounted webview with no session
      // must still get SOME jar of its own. Twin of the client's.
      final String profile = widget.profileId ??
          WebStorageProfileId.account(
            PublicOS.sessionBlockchainAddress ??
                '0x0000000000000000000000000000000000000000',
          );
      final controller = await widget.storage.createController(profile);
      if (!mounted) {
        // Unmounted during the await: dispose already ran and found nothing
        // bound, so this engine is ours to kill.
        await controller.dispose();
        return;
      }
      _controller = controller;
      _controllerBound = true;

      // Opaque surface, same value as the client: 0xFF15181c is the glass-dark
      // chrome, so the pre-paint flash matches the app.
      await _controller.setBackgroundColor(const Color(0xFF15181C));

      // DELTA 1 — a WebView2 default the wrapper must own. Popup policy
      // defaults to `allow`, which lets a page open a window we paint no chrome
      // for, showing whatever it likes. The client's engine has no equivalent
      // knob because it has no popups.
      await _controller.setPopupWindowPolicy(WebviewPopupWindowPolicy.deny);

      // Sandboxed pages get no bridge and no document-start provider. Skipping
      // construction outright means there is nothing to reach even if a future
      // edit forgets one of the other guards.
      _buildHost();

      if (!widget.sandboxed) {
        _buildBridge();

        // DELTA 2 — registered BEFORE the first navigation, so the provider is
        // present at document-created on every page including the first, and
        // survives every navigation without re-registration.
        await _host?.injectAtDocumentStart(buildProviderScript(
          address: null,
          chainId: _chainId,
          transport: BridgeTransport.webMessage,
        ));
      }

      // Size the surface BEFORE the first navigation, so the page lays out at
      // the pane's real size and scale rather than the engine's 1280x720
      // default (see [_paneSize]). The package's own post-frame resize still
      // runs when the Webview widget mounts; it lands on the same numbers.
      await _sizeSurface();

      await _controller.loadUrl(widget.initialUrl);

      // Armed at navigation start, disarmed by the first page-finished.
      _revealTimer?.cancel();
      _revealTimer = Timer(_revealTimeout, () {
        _log('[PublicOSWebView] reveal timeout - showing the engine anyway');
        _markPainted();
      });

      widget.onControllerCreated?.call(() => _controller.goBack());
      widget.onReloadCreated?.call(() => _controller.reload());
      _emitCanGoBack();

      if (mounted) setState(() => _ready = true);
    } catch (e) {
      _log('[PublicOSWebView] init failed: $e');
      if (mounted) setState(() => _error = '$e');
      widget.onError?.call('$e');
    }
  }

  /// Push the pane's real size and scale into the engine.
  ///
  /// Safe before the [Webview] widget exists: the surface and the WebView2
  /// bounds are the controller's, not the texture widget's.
  Future<void> _sizeSurface() async {
    // Initialization can outrun the first layout pass; one frame is all it
    // takes for [build] to record the box. Null after that means there is
    // genuinely nothing to measure, and the package's post-frame resize is
    // the fallback.
    if (_paneSize == null) await WidgetsBinding.instance.endOfFrame;
    final size = _paneSize;
    if (!mounted || size == null || size.isEmpty) return;
    try {
      await _controller.ready;
      await _controller.setSize(size, scaleFactor: _paneScale);
    } catch (e) {
      // Never fatal: a wrong-sized surface is a cosmetic flash, and the
      // package's post-frame resize corrects it a few frames later.
      _log('[PublicOSWebView] could not pre-size the surface: $e');
    }
  }

  /// The engine has something on screen. Idempotent — first caller wins,
  /// whether that is the first page-finished or the reveal timeout.
  void _markPainted() {
    _revealTimer?.cancel();
    _revealTimer = null;
    if (_painted || !mounted) return;
    setState(() => _painted = true);
  }

  /// Re-query the controller's history depth and report it to the host.
  ///
  /// DELTA 1: WebView2 pushes history state as an event rather than answering a
  /// query, so the last pushed value is mirrored on the host and read back
  /// here. The client awaits `controller.canGoBack()` directly.
  Future<void> _emitCanGoBack() async {
    final canGoBack = _host?.canGoBackNow ?? false;
    if (mounted) widget.onCanGoBackChanged?.call(canGoBack);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);

    // Recorded on every pass, including the placeholder ones that run while
    // the engine is still initializing — which is what lets [_sizeSurface]
    // size the surface before the first navigation. Assignment only: a
    // setState here would loop.
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.hasBoundedWidth && constraints.hasBoundedHeight) {
        _paneSize = constraints.biggest;
        _paneScale = MediaQuery.devicePixelRatioOf(context);
      }
      return _content(tokens);
    });
  }

  /// True once there is something worth putting on screen: the engine exists
  /// AND it has painted. Both halves matter — see [_painted].
  bool get _engineVisible => _ready && _painted;

  Widget _content(GlassTokens tokens) {
    if (widget.cardMode) {
      // Nothing to show is the CORRECT rendering: the card paints its own image
      // underneath, so an error or a not-yet-ready engine simply leaves that
      // image visible. Twin of the client's card path.
      if (_error != null || !_engineVisible) return const SizedBox.shrink();
      return _engine();
    }

    if (_error != null) {
      return Container(
        color: tokens.surfaceDeep,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.public_off_rounded, size: 36, color: tokens.textDim),
            const SizedBox(height: 14),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: tokens.textDim, fontSize: 13),
            ),
          ],
        ),
      );
    }

    // Cross-faded rather than swapped: the engine's first frame and the
    // placeholder's last one overlap, so there is no frame showing neither.
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: _engineVisible
          ? _engine()
          : Container(
              key: const ValueKey('webview-placeholder'),
              color: tokens.surfaceDeep,
              // Bottom-right, not centred: the standard loading affordance
              // for a full surface (as in the system-page shell).
              // Pixel rain rather than the app-wide PhigitalLoading — a
              // per-surface choice, same scoping as the BSP/SSP dialogs.
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const PixelRainLoadingWidget(size: 22, showShadows: false),
                    const SizedBox(width: 9),
                    WaveText(
                      text: context.l10n.desktopWebviewLoading,
                      style: TextStyle(
                        fontFamily: 'SpaceGrotesk',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: tokens.textDim,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _engine() => Webview(
        _controller,
        key: const ValueKey('webview-engine'),
        // DELTA 1 — the second WebView2 default the wrapper owns. With no
        // delegate registered, WebView2 shows ITS OWN native permission prompt
        // over our app: UI we do not control, on a wallet surface. Deny by
        // default; anything we ever want to allow goes through our own consent.
        permissionRequested: (url, kind, isUserInitiated) {
          _log('[PublicOSWebView] denied ${kind.name} for $url');
          return WebviewPermissionDecision.deny;
        },
      );

  @override
  void dispose() {
    _revealTimer?.cancel();
    _eventSub?.cancel();
    _messageSub?.cancel();
    _historySub?.cancel();
    _host?.dispose();
    _host = null;
    _dispatcher = null;
    _gate = null;
    _channel = null;
    if (_controllerBound) _controller.dispose();
    super.dispose();
  }
}
