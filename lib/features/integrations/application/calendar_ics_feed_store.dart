import 'package:shared_preferences/shared_preferences.dart';

/// Device-local Google iCal URL (ADR-050). Not exported; OAuth tables later.
abstract class CalendarIcsFeedStore {
  Future<String?> readUrl();
  Future<void> writeUrl(String url);
  Future<void> clear();
  Future<DateTime?> readLastFetchedAt();
  Future<void> writeLastFetchedAt(DateTime at);
}

class PrefsCalendarIcsFeedStore implements CalendarIcsFeedStore {
  PrefsCalendarIcsFeedStore({SharedPreferences? prefs}) : _prefs = prefs;

  static const urlKey = 'calendar.icsFeedUrl';
  static const fetchedKey = 'calendar.icsFeedFetchedAtMs';

  SharedPreferences? _prefs;

  Future<SharedPreferences?> _tryPrefs() async {
    if (_prefs != null) return _prefs;
    try {
      _prefs = await SharedPreferences.getInstance();
      return _prefs;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<String?> readUrl() async {
    final value = (await _tryPrefs())?.getString(urlKey);
    if (value == null || value.trim().isEmpty) return null;
    return value.trim();
  }

  @override
  Future<void> writeUrl(String url) async {
    await (await _tryPrefs())?.setString(urlKey, url.trim());
  }

  @override
  Future<void> clear() async {
    final prefs = await _tryPrefs();
    await prefs?.remove(urlKey);
    await prefs?.remove(fetchedKey);
  }

  @override
  Future<DateTime?> readLastFetchedAt() async {
    final ms = (await _tryPrefs())?.getInt(fetchedKey);
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
  }

  @override
  Future<void> writeLastFetchedAt(DateTime at) async {
    await (await _tryPrefs())?.setInt(
      fetchedKey,
      at.toUtc().millisecondsSinceEpoch,
    );
  }
}

class MemoryCalendarIcsFeedStore implements CalendarIcsFeedStore {
  String? url;
  DateTime? fetchedAt;

  @override
  Future<String?> readUrl() async => url;

  @override
  Future<void> writeUrl(String value) async => url = value.trim();

  @override
  Future<void> clear() async {
    url = null;
    fetchedAt = null;
  }

  @override
  Future<DateTime?> readLastFetchedAt() async => fetchedAt;

  @override
  Future<void> writeLastFetchedAt(DateTime at) async => fetchedAt = at.toUtc();
}
