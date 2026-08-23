import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

/// Intl date symbols for profile locales (default `pt_BR`).
///
/// `DateFormat(..., 'pt_BR')` throws until [initializeDateFormatting] runs.
/// Tests already did this; the app did not — opening Agenda crashed.
abstract final class AppLocale {
  static const fallback = 'pt_BR';

  static var _ready = false;

  /// Safe to call from `main` and from formatters. Local data init is sync.
  static Future<void> ensureInitialized() async {
    ensureSync();
  }

  static void ensureSync() {
    if (_ready) return;
    // date_symbol_data_local initializes all locales in the function body,
    // then returns Future.value().
    initializeDateFormatting();
    Intl.defaultLocale = fallback;
    _ready = true;
  }

  static DateFormat date(String pattern, [String? locale]) {
    ensureSync();
    return DateFormat(pattern, _resolve(locale));
  }

  static DateFormat time({required bool use24Hour, String? locale}) {
    ensureSync();
    final resolved = _resolve(locale);
    return use24Hour ? DateFormat.Hm(resolved) : DateFormat.jm(resolved);
  }

  static String _resolve(String? locale) {
    final raw = locale?.trim();
    if (raw == null || raw.isEmpty) return fallback;
    return raw;
  }
}
