#include "deep_link.h"

#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>
#include <winrt/Windows.ApplicationModel.Activation.h>
#include <winrt/Windows.ApplicationModel.h>
#include <winrt/Windows.Foundation.h>

#include <cstdlib>
#include <memory>

namespace deep_link {

namespace {

// Per-SESSION, not global: two users signed into the same machine each get
// their own instance. "Global\" here would let one user's link hijack another
// user's window, or silently refuse to start their app at all.
constexpr wchar_t kMutexName[] = L"Local\\PublicOSDesktop.SingleInstance";

// The marker that says "this window is the live instance's deep-link target".
constexpr wchar_t kTargetProp[] = L"PublicOSDeepLinkTarget";

// Diagnostic modal box, off: the URL is routed to a real screen and the log
// below is the durable record. Raised from the wrong place the box stalls
// startup before the window exists and silently defeats the single-instance
// guard.
constexpr bool kShowActivationMessageBox = false;

// The Dart channel, and the cold-start URL waiting to be pulled through it.
//
// Same channel + method names publicos_client uses on Android, deliberately:
// Dart pulls `getInitialLink` once at boot, native pushes `onDeepLink` after.
constexpr char kChannelName[] = "com.publicos/deeplink";
std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> g_channel;
std::string g_initial_uri_utf8;

// Why the diagnosis string exists: "null" and "threw" and "wrong activation
// kind" are three different bugs, and an empty return hides which one happened.
std::wstring g_diagnosis = L"(not attempted)";

// Set by the WM_COPYDATA handler, read by the posted follow-up message. The
// handler must NOT block -- WM_COPYDATA is delivered with SendMessage, so the
// forwarding process is stuck inside its own send until we return. Showing a
// modal box there would freeze the sender until someone clicked OK, which is
// exactly the pile-up this whole feature exists to stop.
std::wstring g_pending_box_text;
std::wstring g_pending_box_caption;
constexpr UINT WM_PUBLICOS_SHOW_FORWARDED = WM_APP + 0x51;

std::string Utf8FromUtf16(const std::wstring& utf16) {
  if (utf16.empty()) {
    return std::string();
  }
  int len = ::WideCharToMultiByte(CP_UTF8, 0, utf16.data(),
                                  static_cast<int>(utf16.size()), nullptr, 0,
                                  nullptr, nullptr);
  if (len <= 0) {
    return std::string();
  }
  std::string utf8(len, '\0');
  ::WideCharToMultiByte(CP_UTF8, 0, utf16.data(), static_cast<int>(utf16.size()),
                        utf8.data(), len, nullptr, nullptr);
  return utf8;
}

std::wstring FindUriInCommandLine() {
  int argc = 0;
  LPWSTR* argv = ::CommandLineToArgvW(::GetCommandLineW(), &argc);
  if (!argv) {
    return L"";
  }
  std::wstring found;
  for (int i = 1; i < argc; ++i) {
    std::wstring arg(argv[i]);
    if (arg.rfind(L"publicos://", 0) == 0 || arg.rfind(L"https://", 0) == 0 ||
        arg.rfind(L"http://", 0) == 0) {
      found = arg;
      break;
    }
  }
  ::LocalFree(argv);
  return found;
}

struct FindTargetContext {
  DWORD skip_process_id;
  HWND result;
};

BOOL CALLBACK FindTargetProc(HWND window, LPARAM lparam) {
  auto* ctx = reinterpret_cast<FindTargetContext*>(lparam);
  if (!::GetPropW(window, kTargetProp)) {
    return TRUE;  // not one of ours, keep looking
  }
  DWORD pid = 0;
  ::GetWindowThreadProcessId(window, &pid);
  if (pid == ctx->skip_process_id) {
    return TRUE;  // our own window; never forward to ourselves
  }
  ctx->result = window;
  return FALSE;  // stop enumerating
}

}  // namespace

std::wstring GetActivationUri(std::wstring* out_source) {
  std::wstring uri;
  std::wstring source = L"winrt";
  try {
    auto args = winrt::Windows::ApplicationModel::AppInstance::GetActivatedEventArgs();
    if (!args) {
      g_diagnosis = L"GetActivatedEventArgs returned null";
    } else {
      auto kind = args.Kind();
      if (kind != winrt::Windows::ApplicationModel::Activation::ActivationKind::Protocol) {
        g_diagnosis = L"activated, but Kind=" +
                      std::to_wstring(static_cast<int>(kind)) + L" (not Protocol)";
      } else {
        auto protocol_args = args.as<
            winrt::Windows::ApplicationModel::Activation::IProtocolActivatedEventArgs>();
        uri = std::wstring(protocol_args.Uri().AbsoluteUri());
        g_diagnosis = L"Kind=Protocol, URI read from WinRT";
      }
    }
  } catch (winrt::hresult_error const& e) {
    // Routinely 0xD0000225 (no package identity) -- i.e. an unregistered dev
    // build run straight out of the build folder. Expected, not an error.
    wchar_t buf[64];
    swprintf_s(buf, L"hresult_error 0x%08X: ", static_cast<unsigned>(e.code()));
    g_diagnosis = std::wstring(buf) + std::wstring(e.message());
  } catch (...) {
    g_diagnosis = L"unknown exception";
  }

  if (uri.empty()) {
    uri = FindUriInCommandLine();
    if (!uri.empty()) {
      source = L"cmdline";
    }
  }
  if (out_source) {
    *out_source = source;
  }
  return uri;
}

void Log(const std::wstring& uri, const std::wstring& source) {
  std::wstring line = L"[" + source + L"] " + (uri.empty() ? L"(no uri)" : uri) +
                      L"\r\n        winrt: " + g_diagnosis +
                      L"\r\n        cmdline: " + std::wstring(::GetCommandLineW());
  ::OutputDebugStringW((L"[publicos] " + line + L"\n").c_str());

  wchar_t* local_app_data = nullptr;
  size_t len = 0;
  if (_wdupenv_s(&local_app_data, &len, L"LOCALAPPDATA") != 0 || !local_app_data) {
    return;
  }
  std::wstring dir = std::wstring(local_app_data) + L"\\PublicOS";
  free(local_app_data);
  ::CreateDirectoryW(dir.c_str(), nullptr);  // fine if it already exists

  HANDLE file = ::CreateFileW((dir + L"\\deeplink.log").c_str(), FILE_APPEND_DATA,
                              FILE_SHARE_READ, nullptr, OPEN_ALWAYS,
                              FILE_ATTRIBUTE_NORMAL, nullptr);
  if (file == INVALID_HANDLE_VALUE) {
    return;
  }
  SYSTEMTIME now;
  ::GetLocalTime(&now);
  wchar_t stamp[32];
  swprintf_s(stamp, L"%04d-%02d-%02d %02d:%02d:%02d  ", now.wYear, now.wMonth,
             now.wDay, now.wHour, now.wMinute, now.wSecond);
  std::string out = Utf8FromUtf16(std::wstring(stamp) + line + L"\r\n");
  DWORD written = 0;
  ::WriteFile(file, out.data(), static_cast<DWORD>(out.size()), &written, nullptr);
  ::CloseHandle(file);
  // Deliberately no UI here. Logging must never block: Log() runs before the
  // window exists, and a modal at that point stalls wWinMain -- see
  // ShowActivationBoxWhenIdle below.
}

void ShowActivationBoxWhenIdle(HWND window, const std::wstring& uri,
                               const std::wstring& source) {
  if (!kShowActivationMessageBox || uri.empty() || !window) {
    return;
  }
  // POSTED, never shown inline. A modal here would block wWinMain before the
  // message loop starts, which defeats the single-instance guard: instance #1
  // sits in a message box, so it never creates a findable window, so instance
  // #2 gives up forwarding and starts a second engine anyway.
  g_pending_box_text = uri + L"\n\nvia: " + source;
  g_pending_box_caption = L"PublicOS - Windows handed us this URL";
  ::PostMessageW(window, WM_PUBLICOS_SHOW_FORWARDED, 0, 0);
}

void SetInitialUri(const std::wstring& uri) {
  g_initial_uri_utf8 = Utf8FromUtf16(uri);
}

void AttachToEngine(flutter::FlutterEngine* engine) {
  if (!engine) {
    return;
  }
  g_channel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      engine->messenger(), kChannelName,
      &flutter::StandardMethodCodec::GetInstance());

  g_channel->SetMethodCallHandler(
      [](const flutter::MethodCall<flutter::EncodableValue>& call,
         std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
        if (call.method_name() != "getInitialLink") {
          result->NotImplemented();
          return;
        }
        // Hand it over ONCE. A hot restart re-runs Dart main() and would
        // otherwise replay the original link and yank the user back to it.
        if (g_initial_uri_utf8.empty()) {
          result->Success();
        } else {
          std::string uri = g_initial_uri_utf8;
          g_initial_uri_utf8.clear();
          result->Success(flutter::EncodableValue(uri));
        }
      });
}

void SendToDart(const std::wstring& uri) {
  if (uri.empty()) {
    return;
  }
  if (!g_channel) {
    // Forwarded before the engine came up (the window exists a beat earlier).
    // Keep it as the initial link rather than dropping it -- Dart's pull at
    // boot will collect it a moment from now.
    g_initial_uri_utf8 = Utf8FromUtf16(uri);
    return;
  }
  g_channel->InvokeMethod(
      "onDeepLink",
      std::make_unique<flutter::EncodableValue>(Utf8FromUtf16(uri)));
}

bool AcquireSingleInstanceMutex() {
  // Deliberately never released: the handle lives for the process lifetime and
  // Windows drops it on exit, including on a crash. Releasing it by hand would
  // open a window where a second instance could start while we are still up.
  ::CreateMutexW(nullptr, TRUE, kMutexName);
  return ::GetLastError() != ERROR_ALREADY_EXISTS;
}

void MarkAsDeepLinkTarget(HWND window) {
  if (window) {
    ::SetPropW(window, kTargetProp, reinterpret_cast<HANDLE>(1));
  }
}

bool ForwardToRunningInstance(const std::wstring& uri, DWORD timeout_ms) {
  const DWORD deadline = ::GetTickCount() + timeout_ms;
  const DWORD self = ::GetCurrentProcessId();

  for (;;) {
    FindTargetContext ctx{self, nullptr};
    ::EnumWindows(FindTargetProc, reinterpret_cast<LPARAM>(&ctx));
    if (ctx.result) {
      // Surface the existing window first, so the user sees a response even if
      // there is no URL to deliver (a bare second launch).
      if (::IsIconic(ctx.result)) {
        ::ShowWindow(ctx.result, SW_RESTORE);
      }
      ::SetForegroundWindow(ctx.result);

      if (!uri.empty()) {
        COPYDATASTRUCT data{};
        data.dwData = kCopyDataId;
        data.cbData = static_cast<DWORD>((uri.size() + 1) * sizeof(wchar_t));
        data.lpData = const_cast<wchar_t*>(uri.c_str());
        ::SendMessageW(ctx.result, WM_COPYDATA, reinterpret_cast<WPARAM>(nullptr),
                       reinterpret_cast<LPARAM>(&data));
      }
      return true;
    }
    // The other instance holds the mutex but has not created its window yet.
    // Give it a moment rather than dropping the URL on a cold start.
    if (::GetTickCount() >= deadline) {
      return false;
    }
    ::Sleep(100);
  }
}

bool HandleForwardedCopyData(HWND window, LPARAM lparam) {
  auto* data = reinterpret_cast<COPYDATASTRUCT*>(lparam);
  if (!data || data->dwData != kCopyDataId || !data->lpData || data->cbData == 0) {
    return false;
  }
  // Trust the id, not the contents: bound the copy by cbData and force a
  // terminator, so a malformed sender cannot walk us off the end of the buffer.
  const size_t chars = data->cbData / sizeof(wchar_t);
  std::wstring uri(static_cast<const wchar_t*>(data->lpData), chars);
  const size_t nul = uri.find(L'\0');
  if (nul != std::wstring::npos) {
    uri.resize(nul);
  }
  if (uri.empty()) {
    return false;
  }

  Log(uri, L"forwarded");
  SendToDart(uri);

  if (::IsIconic(window)) {
    ::ShowWindow(window, SW_RESTORE);
  }
  ::SetForegroundWindow(window);

  if (kShowActivationMessageBox) {
    // Post, never show inline: see g_pending_box_text above. The sender is
    // blocked inside SendMessage until this returns.
    g_pending_box_text = uri + L"\n\nvia: forwarded to the running instance";
    g_pending_box_caption = L"PublicOS - second launch forwarded, no new process";
    ::PostMessageW(window, WM_PUBLICOS_SHOW_FORWARDED, 0, 0);
  }
  return true;
}

}  // namespace deep_link

// Handled here rather than in the header so the message id stays private.
namespace deep_link {
bool HandlePostedShowForwarded(UINT message) {
  if (message != WM_PUBLICOS_SHOW_FORWARDED) {
    return false;
  }
  if (!g_pending_box_text.empty()) {
    // Copy and clear FIRST: MessageBoxW pumps messages, so another forward can
    // arrive and re-enter this handler while the box is up.
    std::wstring text = g_pending_box_text;
    std::wstring caption = g_pending_box_caption;
    g_pending_box_text.clear();
    g_pending_box_caption.clear();
    ::MessageBoxW(nullptr, text.c_str(), caption.c_str(),
                  MB_OK | MB_ICONINFORMATION | MB_SETFOREGROUND);
  }
  return true;
}
}  // namespace deep_link
