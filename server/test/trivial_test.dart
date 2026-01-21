import 'package:test/test.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  test('sqlite works', () {
    final db = sqlite3.openInMemory();
    db.dispose();
  });
}
