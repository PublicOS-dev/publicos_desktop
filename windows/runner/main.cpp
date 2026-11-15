#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include <string>

#include "deep_link.h"
#include "flutter_window.h"
#include "utils.h"

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  // ---- Deep-link activation -----------------------------------------------
  //
  // Read the URL Windows started us with BEFORE anything expensive: if another
  // instance is already running we are going to hand this over and exit, and
  // that decision must happen before a Flutter engine exists.
  std::wstring activation_source;
  std::wstring activation_uri = deep_link::GetActivationUri(&activation_source);

  // SINGLE INSTANCE. Windows has no `launchMode=singleTask`: every activation
  // starts a fresh process. Two processes means two Flutter engines and two
  // handles on the same publicos.sqlite, so this is a data-integrity guard,
  // not a tidiness one.
  if (!deep_link::AcquireSingleInstanceMutex()) {
    // Wait a beat for the first instance's window: it takes the mutex before
    // the window exists, and dropping the URL in that gap would be a race that
    // only ever shows up on a cold machine.
    if (deep_link::ForwardToRunningInstance(activation_uri, 8000)) {
      ::CoUninitialize();
      return EXIT_SUCCESS;
    }
    // Could not find the live window (it may be wedged, or mid-shutdown). Fall
    // through and start normally: a second window is worse than nothing, but
    // refusing to launch at all is worse than both.
    deep_link::Log(activation_uri, L"forward-failed, starting anyway");
  } else {
    deep_link::Log(activation_uri, activation_source);
  }

  // Park the cold-start URL where the channel can hand it to Dart. The engine
  // does not exist yet, so this is a pull (`getInitialLink`), not a push.
  deep_link::SetInitialUri(activation_uri);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  // NOTE: the URL is deliberately NOT also appended to the Dart entrypoint
  // arguments. Two delivery paths for one URL means Dart can act on it twice
  // -- and only the channel covers the warm-start case, so the argument would
  // be the weaker half of a confusing pair.
  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(L"publicos_desktop", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  // Make this window findable by a later launch. Every Flutter app on Windows
  // shares the window class "FLUTTER_RUNNER_WIN32_WINDOW" and the title can
  // change at runtime, so neither is safe to match on -- a window property is.
  deep_link::MarkAsDeepLinkTarget(window.GetHandle());

  // Scaffolding: the visible "we got a URL" box, queued to appear once the loop
  // below is pumping. It has to be here, not in Log(), because a modal raised
  // before this point stops the window from ever existing, which defeats the
  // single-instance guard above.
  deep_link::ShowActivationBoxWhenIdle(window.GetHandle(), activation_uri,
                                       activation_source);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
