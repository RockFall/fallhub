/// Normalizes a user-pasted Google Agenda / iCal subscription URL (ADR-050).
abstract final class IcsFeedPolicy {
  /// Accepts `https`, `http`, and `webcal` (rewritten to https).
  static Uri? normalize(String raw) {
    var text = raw.trim();
    if (text.isEmpty) return null;
    if (text.toLowerCase().startsWith('webcal://')) {
      text = 'https://${text.substring('webcal://'.length)}';
    }
    final uri = Uri.tryParse(text);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) return null;
    if (uri.scheme != 'https' && uri.scheme != 'http') return null;
    return uri;
  }

  /// True for typical Google iCal hosts or any path that looks like a calendar file.
  static bool looksLikeCalendarFeed(Uri uri) {
    final host = uri.host.toLowerCase();
    final path = uri.path.toLowerCase();
    if (host.contains('calendar.google.com')) return true;
    if (host.endsWith('google.com') && path.contains('/calendar/')) {
      return true;
    }
    return path.endsWith('.ics') || path.contains('.ics?');
  }
}
