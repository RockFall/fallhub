/// Pulls the saved Google iCal feed when the app is opened (ADR-050).
///
/// The first pull in a process always fetches. Later resumes honor
/// [staleAfter] so backgrounding the app for a few minutes is cheap.
class CalendarIcsAutoSync {
  CalendarIcsAutoSync({
    required this.refresh,
    this.staleAfter = const Duration(minutes: 15),
  });

  final Future<int?> Function({Duration maxAge}) refresh;
  final Duration staleAfter;

  var _hasOpened = false;

  bool get hasOpened => _hasOpened;

  /// Cold start / home becoming available for the first time this process.
  Future<int?> onOpened() {
    final maxAge = _hasOpened ? staleAfter : Duration.zero;
    _hasOpened = true;
    return refresh(maxAge: maxAge);
  }

  /// App returned to the foreground. Debounced after the first pull.
  Future<int?> onResumed() {
    _hasOpened = true;
    return refresh(maxAge: staleAfter);
  }
}
