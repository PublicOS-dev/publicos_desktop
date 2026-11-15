import 'dart:typed_data' show Uint8List;

import 'package:flutter/material.dart';
import 'package:publicos_core/publicos_core.dart';
import 'package:zero_cached_image/zero_cached_image.dart' show ZeroFetchHooks;
import 'package:zero_video_windows/zero_video_windows.dart';

import 'data/shell_prefs.dart';
import 'l10n/app_localizations.dart';
import 'l10n/l10n_ext.dart';
import 'router.dart';
import 'theme/glass_tokens.dart';
import 'theme/locale_provider.dart';
import 'theme/shell_tones.dart';
import 'utils/deep_links.dart';
import 'utils/window_chrome.dart';
import 'widgets/pixel_rain_loading_widget.dart';
import 'widgets/wave_text.dart';
import 'screens/select_account_screen.dart';
import 'screens/app_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // video_player has no Windows implementation; without this every
  // VideoPlayerController throws on initialize(). Must run before the first one
  // is built. See the zero_video_windows package.
  ZeroVideoWindows.ensureInitialized();
  // Private-media fetch hooks —
  // same wiring as publicos_client's main.dart: gated URLs answer 401 +
  // WWW-Authenticate → requestAuth signs a pedia_read envelope to that URL
  // and the fetch retries once; responses marked X-Publicos-Sealed are ECIES
  // ciphertext → responseTransform decrypts before caching. Public URLs never
  // challenge and never carry the header — untouched path.
  ZeroFetchHooks.requestAuth = (url) async => PublicOSSsp.pediaRequestAuth(url);
  ZeroFetchHooks.responseTransform = (bytes, headers) async =>
      PublicOSSsp.pediaResponseTransform(
          bytes is Uint8List ? bytes : Uint8List.fromList(bytes), headers);
  // Self-contact cache read by ported feed widgets (post_card / posts_list ask
  // "is this mine?"). Constructed once; it subscribes to Core's
  // selfContactUpdates for its lifetime. Populated at login by
  // `AppStateNotifier.loadMyContact()` in select_account_screen.
  AppStateNotifier.instance = AppStateNotifier();
  await loadThemePreference();
  await ShellPrefs.load();
  // App-shell language override (the client's `LocaleProvider`, ported
  // verbatim): SharedPreferences `app_locale`, null = follow the device.
  // Set before the first frame so the account picker is already localized.
  LocaleProvider.instance = LocaleProvider();
  // One-canvas rule: tint the native title bar to
  // the shell canvas so the window bar dissolves into the app. The Win32
  // window already exists by the time Dart main runs; re-applied on toggle.
  WindowChrome.apply(themeNotifier.value);
  themeNotifier.addListener(() => WindowChrome.apply(themeNotifier.value));
  // Inbound deep links. Opens the
  // `com.publicos/deeplink` channel and pulls the cold-start URL. Must run
  // before runApp so a link that launched the app is already in hand; it is
  // replayed by `AppShell` once there is somewhere to send it.
  await DeepLinks.start();
  // Framework errors (the red screen) into the in-app log too, so a shared
  // log carries the FIRST error (same hook as publicos_client).
  final previousOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    Log.e('Flutter', '${details.exceptionAsString()}\n${details.stack ?? ''}');
    previousOnError?.call(details);
  };
  runApp(const PublicOSDesktopApp());
}

class PublicOSDesktopApp extends StatelessWidget {
  const PublicOSDesktopApp({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = LocaleProvider.instance!; 
    return ListenableBuilder(
      listenable: localeProvider,
      builder: (context, _) => ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, themeMode, _) {
        return MaterialApp(
          title: 'PublicOS',
          debugShowCheckedModeBanner: false,
          themeMode: themeMode,
          theme: buildLightTheme(),
          darkTheme: buildDarkTheme(),
          // Mirrors publicos_client `MaterialApp.router(locale: …)`: null =>
          // device resolution / EN fallback, non-null = the Settings override.
          locale: localeProvider.locale,
          // Mirrors publicos_client. `AppLocalizations.of` is a non-null getter
          // (nullable-getter: false), so widgets ported from the client call
          // `context.l10n.x` directly -- without these delegates registered that
          // call throws at runtime, not at compile time.
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          // TappableMedia / VideoUrlThumbnail subscribe to this to pause video
          // when a route covers them. Unregistered, the subscribe is a silent
          // no-op and a feed video keeps playing behind a dialog.
          navigatorObservers: [appRouteObserver],
          // Deep links arrive from the OS on a platform channel, not from a
          // widget tap, so there is no BuildContext in that call chain. Without
          // this key every inbound link is a silent no-op.
          navigatorKey: appNavigatorKey,
          home: const _InitGate(),
        );
      },
      ),
    );
  }
}

enum _Phase { loading, initError, login, ready }

/// Boot gate. Runs the boot sequence (init Core → drafts → authenticate →
/// auto-login restore), then lands on the glass screens: SelectAccountScreen,
/// then the shell.
class _InitGate extends StatefulWidget {
  const _InitGate();

  @override
  State<_InitGate> createState() => _InitGateState();
}

class _InitGateState extends State<_InitGate> {
  _Phase _phase = _Phase.loading;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    setState(() {
      _phase = _Phase.loading;
      _error = null;
    });

    // Phase 1 — initialize Core.
    try {
      final ok = PublicOS.isInitialized || await PublicOS.initialize();
      if (!ok) {
        _fail(PublicOS.lastError ?? 'Initialization failed');
        return;
      }
    } catch (e) {
      _fail(e.toString());
      return;
    }

    // Resolve module addresses up front — session-independent and required
    // PRE-login. The link-device / new-account consent QR signs an EIP-712
    // whose verifyingContract is the resolved ACCOUNT_MANAGER; a fresh device
    // never reaches login/initBSP (no session), so without this it stays on the
    // hardcoded fallback and signs against a stale manager → invalid consent
    // signature. resolveModuleAddresses self-catches (can't block startup);
    // polling keeps it fresh. Mirrors publicos_client's AppInitializer.
    await PublicOSBsp.resolveModuleAddresses();
    PublicOSBsp.startPolling();

    await PublicOSConversations.loadDrafts();

    // Phase 2 — authenticate (no-op on platforms without device auth).
    try {
      final authed =
          PublicOS.isAuthenticated || await PublicOSAuth.authenticate();
      if (!authed && !PublicOS.debugNoAuthNeeded) {
        _fail(PublicOS.lastError ?? 'Authentication needed to continue');
        return;
      }
    } catch (e) {
      _fail(e.toString());
      return;
    }

    // Phase 3 — auto-login if armed.
    final autoLogin =
        await PublicOS.secureStorage.read(key: 'auto_login') ?? 'false';
    if (autoLogin == 'true') {
      try {
        final selected = await PublicOSAccounts.getSelectedAccountAddress();
        if (selected != null &&
            await PublicOSAccounts.restoreSession(selected)) {
          await PublicOS.loadLastUsedXmtpKey();
          await PublicOSKeychain.loadWebSelectedKey(selected.eip55With0x);
          if (PublicOS.clientXmtpInboxId != null) {
            await PublicOSConversations.initializeMessages();
          }
          if (await PublicOSSettings.getBackgroundNotifications()) {
            await PublicOS.registerBackgroundSync();
          }
          if (PublicOS.clientXmtpInboxId != null) {
            PublicOSConversations.syncAll(consentStates: ['allowed', 'unknown'])
                .catchError((e) {
              debugPrint('[Main] background sync failed: $e');
              return <String, int>{};
            });
          }
          _go(_Phase.ready);
          return;
        }
      } catch (_) {
        // fall through to account selection
      }
    }

    _go(_Phase.login);
  }

  void _fail(String message) {
    if (!mounted) return;
    setState(() {
      _phase = _Phase.initError;
      _error = message;
    });
  }

  void _go(_Phase phase) {
    if (!mounted) return;
    setState(() => _phase = phase);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    switch (_phase) {
      case _Phase.loading:
        // Shell canvas (not tokens.background) — the DWM-tinted title bar
        // must blend from the very first frame.
        //
        // Pixel-rain + waving caption, bottom-right at the same inset the
        // login overlay uses (select_account_screen). Deliberate: this gate
        // hands straight over to the picker, so the loader never moves — one
        // corner holds the whole boot, the caption just changes.
        return Scaffold(
          backgroundColor: ShellTones.of(context).canvas,
          body: Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 40, bottom: 32),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const PixelRainLoadingWidget(size: 28, showShadows: false),
                  const SizedBox(width: 14),
                  WaveText(
                    text: context.l10n.bootLoading,
                    style: TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      fontWeight: FontWeight.w600,
                      color: tokens.textDim,
                      fontSize: 13,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      case _Phase.initError:
        return Scaffold(
          backgroundColor: ShellTones.of(context).canvas,
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline_rounded,
                    color: tokens.fallbackAccent, size: 40),
                const SizedBox(height: 16),
                Text('Could not start',
                    style: TextStyle(
                        color: tokens.starkWhite,
                        fontSize: 18,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Text(
                    _error ?? 'Unknown error',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: tokens.textDim, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: tokens.connectedAccent,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: _init,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        );
      case _Phase.login:
        return SelectAccountScreen(onLoggedIn: () => _go(_Phase.ready));
      case _Phase.ready:
        return AppShell(onLogout: () => _go(_Phase.login));
    }
  }
}
