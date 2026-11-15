import 'package:flutter/material.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';
import 'package:publicos_desktop/utils/app_update.dart';

/// Small dim label naming the running build: `v1.0.0+202611151825`.
///
/// The client's label reads the installed package's version. A desktop kit is
/// a folder, so the version and the build id are compiled in by the packaging
/// script instead (`scripts/package_windows.ps1`). A build made any other way
/// has neither and says `dev build`.
class AppVersionLabel extends StatelessWidget {
  const AppVersionLabel({super.key});

  static const String _version = String.fromEnvironment('PUBLICOS_VERSION');

  static String get text => AppUpdate.ownBuild == 0
      ? 'dev build'
      : 'v${_version.isEmpty ? '?' : _version}+${AppUpdate.ownBuild}';

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'SpaceGrotesk',
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: tokens.textDim,
      ),
    );
  }
}
