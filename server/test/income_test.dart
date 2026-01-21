import 'package:test/test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:full_pension_server/db.dart';
import 'package:full_pension_server/income.dart';
import 'dart:convert';
import 'package:shelf/shelf.dart';

void main() {
  group('Income Tests', () {
    late Database db;
    late IncomeApi handler;

    setUp(() {
      db = sqlite3.openInMemory();
      db.execute('CREATE TABLE income (id INTEGER PRIMARY KEY, userid INTEGER, name TEXT, intoid INTEGER, amount REAL, startat TEXT, endat TEXT, rate REAL)');
      pension.mockDb(db);
      handler = IncomeApi(db);
    });

    tearDown(() {
      db.dispose();
    });

    test('Add Income', () async {
      final req = Request(
        'POST', 
        Uri.parse('http://localhost/income'),
        context: {'uid': 1},
        body: jsonEncode({
          'name': 'Salary',
          'intoid': 1,
          'amount': 3000.0,
          'startat': '2025-01-01',
          'endat': '2050-01-01',
          'rate': 0.02
        })
      );
      
      final res = await handler.insert(req);
      expect(res.statusCode, 200);
      
      final rows = db.select('SELECT * FROM income');
      expect(rows.length, 1);
      expect(rows.first['name'], 'Salary');
    });

    test('List Incomes', () async {
       db.execute("INSERT INTO income (userid, name, amount, startat, rate) VALUES (1, 'Job', 2000, '2023', 0)");
       final req = Request('GET', Uri.parse('http://localhost/income'), context: {'uid': 1});
       final res = await handler.select(req);
       expect(res.statusCode, 200);
       
       final body = jsonDecode(await res.readAsString()) as List;
       expect(body.length, 1);
       expect(body.first['name'], 'Job');
    });
  });
}
