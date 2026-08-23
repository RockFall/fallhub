import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

/// Intl date symbols for profile locales (default `pt_BR`).
///
/// `DateFormat(..., 'pt_BR')` throws [LocaleDataException] until
/// [initializeDateFormatting] runs. Tests already did this; the app did not.
abstract final class AppLocale {
  static const fallback = 'pt_BR';

  static var _ready = false;

  static Future<void> ensureInitialized() async {
    if (_ready) return;
    await initializeDateFormatting();
    Intl.defaultLocale = fallback;
    _ready = true;
  }

  static DateFormat date(String pattern, [String? locale]) {
    final resolved = _resolve(locale);
    return _safe(
      () => DateFormat(pattern, resolved),
      () => DateFormat(pattern),
    );
  }

  static DateFormat time({required bool use24Hour, String? locale}) {
    final resolved = _resolve(locale);
    return _safe(
      () => use24Hour ? DateFormat.Hm(resolved) : DateFormat.jm(resolved),
      () => use24Hour ? DateFormat.Hm() : DateFormat.jm(),
    );
  }

  static String _resolve(String? locale) {
    final raw = locale?.trim();
    if (raw == null || raw.isEmpty) return fallback;
    return raw;
  }

  static DateFormat _safe(
    DateFormat Function() preferred,
    DateFormat Function() fallbackFormat,
  ) {
    try {
      return preferred();
    } on LocaleDataException {
      return fallbackFormat();
    }
  }
}
