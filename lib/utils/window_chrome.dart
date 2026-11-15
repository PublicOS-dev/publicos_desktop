import 'dart:ffi';
import 'dart:io' show Platform;

import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';

import '../theme/shell_tones.dart';

/// Tints the native Windows title bar to the shell canvas so the window bar
/// dissolves into the app (the "one canvas" rule). DWM caption tint, NOT a
/// frameless custom bar: native drag, snap
/// layouts and maximize behavior all stay stock. Direct dwmapi/user32 FFI —
/// no window-management package for two attribute writes.
///
/// Win11 (build 22000+) only; on older builds DwmSetWindowAttribute answers
/// E_INVALIDARG for these attributes and the bar simply stays default —
/// results are deliberately ignored.
abstract final class WindowChrome {
  static const int _dwmwaCaptionColor = 35;
  static const int _dwmwaTextColor = 36;

  // The stock Flutter runner's window class (windows/runner/win32_window.cpp).
  static const String _windowClass = 'FLUTTER_RUNNER_WIN32_WINDOW';

  static final _dwmSetWindowAttribute = DynamicLibrary.open('dwmapi.dll')
      .lookupFunction<
          Int32 Function(IntPtr, Uint32, Pointer<Uint32>, Uint32),
          int Function(int, int, Pointer<Uint32>, int)>(
    'DwmSetWindowAttribute',
  );

  static final _findWindow = DynamicLibrary.open('user32.dll').lookupFunction<
      IntPtr Function(Pointer<Utf16>, Pointer<Utf16>),
      int Function(Pointer<Utf16>, Pointer<Utf16>)>('FindWindowW');

  /// Applies the canvas tint for [mode] to the app window's title bar.
  /// Call at startup and again on every theme toggle.
  static void apply(ThemeMode mode) {
    if (!Platform.isWindows) return;

    final tones =
        mode == ThemeMode.light ? ShellTones.light : ShellTones.dark;
    final caption = tones.canvas;
    // Caption text keeps the same contrast role as GlassTokens.starkWhite.
    final text =
        mode == ThemeMode.light ? const Color(0xFF0A0A0A) : Colors.white;

    final className = _windowClass.toNativeUtf16();
    final hwnd = _findWindow(className, nullptr);
    calloc.free(className);
    if (hwnd == 0) return;

    _setColor(hwnd, _dwmwaCaptionColor, caption);
    _setColor(hwnd, _dwmwaTextColor, text);
  }

  static void _setColor(int hwnd, int attribute, Color color) {
    // COLORREF is 0x00BBGGRR.
    final r = (color.r * 255).round();
    final g = (color.g * 255).round();
    final b = (color.b * 255).round();
    final colorref = calloc<Uint32>()..value = (b << 16) | (g << 8) | r;
    _dwmSetWindowAttribute(hwnd, attribute, colorref, 4);
    calloc.free(colorref);
  }
}
