import 'package:test/test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:full_pension_server/db.dart';
import 'package:full_pension_server/outgoing.dart';
import 'package:shared/models/outgoing.dart';
import 'dart:convert';
import 'package:shelf/shelf.dart';

void main() {
  group('Outgoing Tests', () {
    late Database db;
    late OutgoingApi handler;

    setUp(() {
      db = sqlite3.openInMemory();
      db.execute('CREATE TABLE outgoing (id INTEGER PRIMARY KEY, userid INTEGER, name TEXT, fromid INTEGER, amount REAL, startat TEXT, endat TEXT, rate REAL)');
      pension.mockDb(db);
      handler = OutgoingApi(db);
    });

    tearDown(() {
      db.dispose();
    });

    test('Add Outgoing', () async {
      final req = Request(
        'POST', 
        Uri.parse('http://localhost/outgoing'),
        context: {'uid': 1},
        body: jsonEncode({
          'name': 'Rent',
          'fromid': 1,
          'amount': 1500.0,
          'startat': '2025-01-01',
          'endat': '2030-01-01',
          'rate': 0.0
        })
      );
      
      final res = await handler.insert(req);
      expect(res.statusCode, 200);
      
      final rows = db.select('SELECT * FROM outgoing');
      expect(rows.length, 1);
      expect(rows.first['name'], 'Rent');
    });
  });
}
