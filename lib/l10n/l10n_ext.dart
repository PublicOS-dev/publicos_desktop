import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

/// Terse access to the generated localizations from any widget:
///
///   final l10n = context.l10n;
///   Text(l10n.settingsLanguageTitle)
///
/// Replaces the verbose `AppLocalizations.of(context).<key>` at every call
/// site. `of` is non-null (l10n.yaml sets `nullable-getter: false`), so no `!`.
extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
