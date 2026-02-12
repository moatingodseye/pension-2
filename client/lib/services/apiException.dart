import 'dart:convert';

class apiException implements Exception {
  final String body;

  apiException(this.body);

  @override
  String toString() {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        if (decoded.containsKey('message')) {
          return decoded['message'];
        }
        if (decoded.containsKey('error')) {
          return decoded['error'];
        }
      }
    } catch (_) {
      // Not JSON, return raw body or generic error if too long/html
      if (body.startsWith('<')) {
        return 'Server Error';
      }
    }
    return body;
  }
}
