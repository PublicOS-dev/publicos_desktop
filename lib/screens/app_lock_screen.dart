import 'dart:io' show exit;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:publicos_core/publicos_core.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/l10n_ext.dart';
import '../theme/glass_tokens.dart';
import '../theme/shell_tones.dart';

/// The app's own lock, shown at boot in place of the Windows Hello prompt
/// when Windows Hello is not set up, or when an app PIN already exists.
/// Twin of publicos_client's `components/app_lock_screen.dart`.
///
/// The rules are Core's (`PublicOSAuth`, app PIN section): six digits, ten
/// wrong tries lock it for good, and a forgotten or locked PIN has one way
/// out, a reset of everything the app keeps on this computer.
///
/// [onDone] re-runs the boot. It is called once the PIN unlocked the app
/// (Core has set `isAuthenticated`), or when the person says they set up
/// Windows Hello (the boot then asks Windows for it).
class AppLockScreen extends StatefulWidget {
  final AuthGate gate;
  final VoidCallback onDone;

  const AppLockScreen({super.key, required this.gate, required this.onDone});

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

enum _Mode { noLock, setPin, confirmPin, enterPin, locked }

class _AppLockScreenState extends State<AppLockScreen> {
  late _Mode _mode;
  final _pin = TextEditingController();
  final _focus = FocusNode();
  String? _firstPin;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _mode = switch (widget.gate) {
      AuthGate.appPin => _Mode.enterPin,
      AuthGate.appPinLocked => _Mode.locked,
      _ => _Mode.noLock,
    };
  }

  @override
  void dispose() {
    _pin.dispose();
    _focus.dispose();
    super.dispose();
  }

  bool get _isPinMode =>
      _mode == _Mode.setPin ||
      _mode == _Mode.confirmPin ||
      _mode == _Mode.enterPin;

  void _show(_Mode mode, {String? error}) {
    if (!mounted) return;
    setState(() {
      _mode = mode;
      _error = error;
      _busy = false;
      _pin.clear();
    });
    if (_isPinMode) _focus.requestFocus();
  }

  Future<void> _onPinTyped(String value) async {
    if (_busy || value.length != PublicOSAuth.pinLength) return;
    final l10n = context.l10n;
    switch (_mode) {
      case _Mode.setPin:
        _firstPin = value;
        _show(_Mode.confirmPin);
      case _Mode.confirmPin:
        if (value != _firstPin) {
          _firstPin = null;
          _show(_Mode.setPin, error: l10n.lockPinMismatch);
          return;
        }
        setState(() => _busy = true);
        var ok = false;
        try {
          ok = await PublicOSAuth.setPin(value);
        } catch (_) {}
        _firstPin = null;
        if (ok) {
          widget.onDone();
        } else {
          _show(_Mode.setPin, error: l10n.errorGeneric);
        }
      case _Mode.enterPin:
        setState(() => _busy = true);
        final result = await PublicOSAuth.verifyPin(value);
        switch (result) {
          case PinCheck.ok:
            widget.onDone();
          case PinCheck.locked:
            _show(_Mode.locked);
          case PinCheck.wrong:
            final left = await PublicOSAuth.pinAttemptsLeft();
            _show(_Mode.enterPin, error: l10n.lockWrongPin(left));
        }
      default:
        break;
    }
  }

  Future<void> _confirmReset() async {
    final tokens = GlassTokens.of(context);
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: tokens.surfaceDeep,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: tokens.borderSubtle),
        ),
        title: Text(
          l10n.lockResetTitle,
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            color: tokens.starkWhite,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Text(
            l10n.lockResetBody,
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              color: tokens.textDim,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              l10n.dlgCancel,
              style: TextStyle(
                  fontFamily: 'SpaceGrotesk', color: tokens.textDim),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              l10n.lockResetConfirm,
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                color: tokens.fallbackAccent,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    await PublicOSAuth.wipeLocalData();
    // Core is closed and its files are gone: this process cannot go on.
    exit(0);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final l10n = context.l10n;

    final (String title, String? body) = switch (_mode) {
      _Mode.noLock => (l10n.lockNoLockTitle, l10n.lockNoLockBody),
      _Mode.setPin => (l10n.lockSetPinTitle, l10n.lockSetPinBody),
      _Mode.confirmPin => (l10n.lockConfirmPinTitle, null),
      _Mode.enterPin => (l10n.lockEnterPinTitle, null),
      _Mode.locked => (l10n.lockLockedTitle, l10n.lockLockedBody),
    };

    return Scaffold(
      backgroundColor: ShellTones.of(context).canvas,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _mode == _Mode.locked
                      ? Icons.lock_rounded
                      : Icons.lock_outline_rounded,
                  color: _mode == _Mode.locked
                      ? tokens.fallbackAccent
                      : tokens.starkWhite,
                  size: 40,
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    color: tokens.starkWhite,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (body != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    body,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      color: tokens.textDim,
                      fontSize: 13,
                      height: 1.45,
                    ),
                  ),
                ],
                if (_isPinMode) ...[
                  const SizedBox(height: 24),
                  SizedBox(
                    width: 240,
                    child: TextField(
                      controller: _pin,
                      focusNode: _focus,
                      autofocus: true,
                      enabled: !_busy,
                      obscureText: true,
                      enableSuggestions: false,
                      autocorrect: false,
                      textAlign: TextAlign.center,
                      maxLength: PublicOSAuth.pinLength,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      style: TextStyle(
                        color: tokens.starkWhite,
                        fontSize: 26,
                        letterSpacing: 12,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: tokens.borderSubtle),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide:
                              BorderSide(color: tokens.connectedAccent),
                        ),
                      ),
                      onChanged: _onPinTyped,
                    ),
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      color: tokens.fallbackAccent,
                      fontSize: 13,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                ..._actions(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _actions(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final l10n = context.l10n;

    Widget primary(String label, VoidCallback onTap) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: tokens.connectedAccent,
              foregroundColor: Colors.black,
            ),
            onPressed: _busy ? null : onTap,
            child: Text(label),
          ),
        );

    Widget quiet(String label, VoidCallback onTap, {Color? color}) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: TextButton(
            onPressed: _busy ? null : onTap,
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                color: color ?? tokens.textDim,
                letterSpacing: 1,
              ),
            ),
          ),
        );

    switch (_mode) {
      case _Mode.noLock:
        return [
          primary(
            l10n.lockOpenSettings,
            () => launchUrl(Uri.parse('ms-settings:signinoptions')),
          ),
          quiet(l10n.lockIHaveSetLock, widget.onDone,
              color: tokens.starkWhite),
          quiet(l10n.lockSetPinInstead, () => _show(_Mode.setPin)),
        ];
      case _Mode.setPin:
      case _Mode.confirmPin:
        return [
          quiet(l10n.dlgCancel, () {
            _firstPin = null;
            _show(_Mode.noLock);
          }),
        ];
      case _Mode.enterPin:
        return [quiet(l10n.lockForgotPin, _confirmReset)];
      case _Mode.locked:
        return [
          quiet(l10n.lockResetButton, _confirmReset,
              color: tokens.fallbackAccent),
        ];
    }
  }
}
