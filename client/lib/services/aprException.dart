class apiException implements Exception {
  final String body;
  apiException(this.body);
}