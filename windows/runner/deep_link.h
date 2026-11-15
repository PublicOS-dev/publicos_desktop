#ifndef RUNNER_DEEP_LINK_H_
#define RUNNER_DEEP_LINK_H_

#include <flutter/flutter_engine.h>
#include <windows.h>

#include <string>

// Deep-link activation + single-instance forwarding for Windows.
//
// Two jobs that have to be solved together:
//
//  1. COLD START -- Windows launches us with a URL, either through
//     `windows.appUriHandler` (https://publicos.dev/...) or `windows.protocol`
//     (publicos://...). Both are declared in windows/packaging/AppxManifest.xml
//     and both arrive as ActivationKind::Protocol.
//
//  2. WARM START -- the app is ALREADY running. Windows does not know that; it
//     starts a second process. Without a guard that means two Flutter engines
//     and two handles on the same publicos.sqlite, which is a data-integrity
//     problem, not a cosmetic one. So the second process forwards its URL to
//     the first and exits before ever building an engine.
//
// Android solves (2) with `launchMode=singleTask`. Windows has no equivalent,
// so it is a named mutex plus WM_COPYDATA, done by hand here.

namespace deep_link {

// Magic value in COPYDATASTRUCT::dwData, so a stray WM_COPYDATA from some
// other process is never mistaken for one of ours.
constexpr ULONG_PTR kCopyDataId = 0x5055424CU;  // 'PUBL'

// Returns the URL Windows activated this process with, or empty.
//
// Tries WinRT `AppInstance::GetActivatedEventArgs()` first, then falls back to
// scanning the command line -- a packaged full-trust Win32 app gets the URI
// BOTH ways for a protocol activation, and the fallback also covers a plain
// `publicos_desktop.exe <url>` invocation. [out_source] receives "winrt" or
// "cmdline" so the log can say which path answered.
std::wstring GetActivationUri(std::wstring* out_source);

// Appends one line to %LOCALAPPDATA%\PublicOS\deeplink.log and mirrors it to
// OutputDebugString. Logs EVERY launch, including ones with no URL, because
// while this is still being proven "nothing happened" and "logging is broken"
// must not look the same.
//
// NOTE the path is subject to packaged-app AppData redirection: when the app
// runs WITH package identity this can land under
// %LOCALAPPDATA%\Packages\<PFN>\LocalCache\Local\. Check both before
// concluding nothing was written.
void Log(const std::wstring& uri, const std::wstring& source);

// Queues the "Windows handed us this URL" box to appear once the message loop
// is running. Diagnostic scaffolding; no-op when there is no URL.
//
// Must be called AFTER the window exists, and it POSTS rather than shows: a
// modal raised from wWinMain before the loop starts stalls the process before
// it has a findable window, which silently defeats the single-instance guard.
void ShowActivationBoxWhenIdle(HWND window, const std::wstring& uri,
                               const std::wstring& source);

// --- The Dart bridge -------------------------------------------------------

// Stores the cold-start URL so Dart can pull it once the engine is up. Set by
// wWinMain before the engine exists, which is why it cannot simply be pushed.
void SetInitialUri(const std::wstring& uri);

// Opens the `com.publicos/deeplink` channel on [engine]. Same channel and same
// two method names publicos_client already uses on Android, so the two
// platforms read as twins: Dart pulls `getInitialLink`, native pushes
// `onDeepLink`.
void AttachToEngine(flutter::FlutterEngine* engine);

// Pushes [uri] to Dart. No-op (and the URL is retained as the initial link)
// when the channel is not up yet, so a forward that arrives mid-boot is not
// dropped.
void SendToDart(const std::wstring& uri);

// --- Single instance -------------------------------------------------------

// Takes the single-instance mutex. True = this process is the first instance
// and owns it for its lifetime. False = another instance is already running.
bool AcquireSingleInstanceMutex();

// Marks [window] as the live instance's deep-link target, so a later process
// can find it. Called once by the first instance after its window exists.
//
// Needed because every Flutter app on Windows shares the window class name
// "FLUTTER_RUNNER_WIN32_WINDOW", and the title can change at runtime -- so
// neither is safe to match on. A window property is ours alone.
void MarkAsDeepLinkTarget(HWND window);

// Finds the running instance's window and hands it [uri]. Returns true if a
// window was found and the message was delivered.
//
// [timeout_ms] retries while the first instance is still starting up: it may
// hold the mutex before its window exists, and losing the URL in that window
// would be a race that only shows up on a cold machine.
bool ForwardToRunningInstance(const std::wstring& uri, DWORD timeout_ms);

// Handles a WM_COPYDATA that carries a forwarded URL. Returns true if the
// message was ours and was consumed. Called from FlutterWindow::MessageHandler.
//
// Restores and foregrounds [window] -- a forwarded link should surface the app,
// which is the whole visible point of not spawning a second window.
bool HandleForwardedCopyData(HWND window, LPARAM lparam);

// Companion to the above: consumes the private follow-up message that
// HandleForwardedCopyData posts to itself. Returns true if [message] was ours.
// Exists so the WM_COPYDATA handler can return immediately instead of blocking
// the forwarding process inside its SendMessage.
bool HandlePostedShowForwarded(UINT message);

}  // namespace deep_link

#endif  // RUNNER_DEEP_LINK_H_
