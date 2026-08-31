import 'package:http/http.dart' as http;

class IcsFeedFetchException implements Exception {
  const IcsFeedFetchException(this.message);
  final String message;

  @override
  String toString() => message;
}

abstract class IcsFeedClient {
  Future<String> get(Uri url);
}

class HttpIcsFeedClient implements IcsFeedClient {
  HttpIcsFeedClient({http.Client? httpClient})
    : _http = httpClient ?? http.Client();

  final http.Client _http;

  @override
  Future<String> get(Uri url) async {
    final response = await _http.get(
      url,
      headers: const {
        'Accept': 'text/calendar, text/plain, */*',
        'User-Agent': 'FallhubColony/0.1 (local calendar import)',
      },
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw IcsFeedFetchException('HTTP ${response.statusCode}');
    }
    if (response.body.trim().isEmpty) {
      throw const IcsFeedFetchException('Calendário vazio');
    }
    return response.body;
  }
}

class FakeIcsFeedClient implements IcsFeedClient {
  FakeIcsFeedClient(this.body, {this.error});

  String body;
  Object? error;

  @override
  Future<String> get(Uri url) async {
    final err = error;
    if (err != null) {
      if (err is Exception) throw err;
      throw IcsFeedFetchException(err.toString());
    }
    return body;
  }
}
