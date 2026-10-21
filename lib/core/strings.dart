import 'package:flutter/widgets.dart';

import '../l10n/app_localizations.dart';

/// The current locale's strings, for code that has no BuildContext: sessions
/// and stores write messages, not widgets. Set from the app's resolved
/// [Locale] in [CatusshApp]'s build.
class S {
  S._();

  static L10n _current = lookupL10n(const Locale('en'));

  static L10n get l => _current;

  static void setLocale(Locale locale) {
    final supported = L10n.supportedLocales.any(
      (l) => l.languageCode == locale.languageCode,
    );
    // lookupL10n throws for a language there are no strings for; English is
    // the one every message has.
    _current = lookupL10n(supported ? locale : const Locale('en'));
  }
}
