import 'package:test/test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:full_pension_server/db.dart';
import 'package:full_pension_server/transfer.dart';
import 'dart:convert';
import 'package:shelf/shelf.dart';

void main() {
  group('Transfer Tests', () {
    late Database db;
    late TransferApi handler;

    setUp(() {
      db = sqlite3.openInMemory();
      db.execute('CREATE TABLE transfer (id INTEGER PRIMARY KEY, userid INTEGER, name TEXT, fromid INTEGER, intoid INTEGER, amount REAL, startat TEXT, endat TEXT, rate REAL)');
      pension.mockDb(db);
      handler = TransferApi(db);
    });

    tearDown(() {
      db.dispose();
    });

    test('Add Transfer', () async {
      final req = Request(
        'POST', 
        Uri.parse('http://localhost  ransfer'),
        context: {'uid': 1},
        body: jsonEncode({
          'name': 'Move Money',
          'fromid': 1,
          'intoid': 2,
          'amount': 500.0,
          'startat': '2025-01-01',
          'rate': 0.0
        })
      );
      
      final res = await handler.insert(req);
      expect(res.statusCode, 200);
      
      final rows = db.select('SELECT * FROM transfer');
      expect(rows.length, 1);
      expect(rows.first['fromid'], 1);
    });
  });
}
