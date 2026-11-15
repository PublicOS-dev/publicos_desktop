import 'l10n/app_localizations.dart';

/// Boot / init progress phases, ported from publicos_client's
/// `lib/l10n/boot_phase.dart`.
///
/// On the client these codes travel from `AppInitializer.runBoot` — which runs
/// with no `BuildContext` and so cannot localize — through an `onStatus` sink,
/// and the loader widgets map the code to a localized label. Desktop works the
/// same way: [bootPhaseLabel] takes the `AppLocalizations` the caller already
/// has and resolves the code against the generated `boot*` getters.
///
/// ⚠ It must not return the client's English `app_en.arb` copy verbatim:
/// desktop is localized, and a Spanish UI would show English boot captions.
///
/// The enum is kept complete even though `select_account_screen` only emits
/// `restoringSession` onward: the first three belong to the pre-login
/// `_InitGate` (`main.dart`), which shows the generic `bootLoading` caption
/// and can adopt them without touching this file.
enum BootPhase {
  initializing,
  checkingAuth,
  checkingLogin,
  restoringSession,
  connectingChain,
  loadingKeys,
  connectingFeed,
  loadingMessages,
  settingUpNotifs,
  opening,
}

/// Map a [BootPhase] `.name` code (or null/unknown) → a localized loader
/// caption. Unknown input is returned verbatim, so a raw status string that
/// slips through still renders instead of vanishing.
String? bootPhaseLabel(AppLocalizations l10n, String? code) {
  switch (code) {
    case 'initializing':
      return l10n.bootInitializing;
    case 'checkingAuth':
      return l10n.bootCheckingAuth;
    case 'checkingLogin':
      return l10n.bootCheckingLogin;
    case 'restoringSession':
      return l10n.bootRestoringSession;
    case 'connectingChain':
      return l10n.bootConnectingChain;
    case 'loadingKeys':
      return l10n.bootLoadingKeys;
    case 'connectingFeed':
      return l10n.bootConnectingFeed;
    case 'loadingMessages':
      return l10n.bootLoadingMessages;
    case 'settingUpNotifs':
      return l10n.bootSettingUpNotifs;
    case 'opening':
      return l10n.bootOpening;
    default:
      return code;
  }
}
