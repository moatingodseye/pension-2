void requireFields(Map body, List<String> fields) {
  for (final f in fields) {
    if (!body.containsKey(f)) {
      throw Exception('Missing field: ');
    }
  }
}

bool strongPassword(String p) =>
  p.length >= 8 &&
  p.contains(RegExp(r'[A-Z]')) &&
  p.contains(RegExp(r'[0-9]'));
