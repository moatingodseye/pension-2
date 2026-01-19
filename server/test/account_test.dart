import 'package:test/test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:full_pension_server/db.dart';
import 'package:full_pension_server/account.dart';
import 'package:shared/models/account.dart';
import 'package:shared/models/account_type.dart';
import 'dart:convert';
import 'package:shelf/shelf.dart';

void main() {
  group('Account Tests', () {
    late Database db;
    late AccountApi accountHandler;

    setUp(() {
      db = sqlite3.openInMemory();
      // Setup Schema
      db.execute('''
        CREATE TABLE account (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          userid INTEGER,
          istype INTEGER, 
          name TEXT,
          amount REAL,
          amountat TEXT,
          rate REAL,
          age INTEGER
        )
      ''');
      
      pension.mockDb(db);
      accountHandler = AccountApi(db);
    });

    tearDown(() {
      db.dispose();
    });

    test('Add Account', () async {
      final req = Request(
        'POST', 
        Uri.parse('http://localhost/account'),
        context: {'uid': 1},
        body: jsonEncode({
          'name': 'Pension Pot 1',
          'amount': 50000.0,
          'istype': 0, // Pension
          'amountat': '2025-01-01',
          'rate': 0.05,
          'age': 30
        })
      );
      
      final res = await accountHandler.insert(req);
      expect(res.statusCode, 200);
      
      final rows = db.select('SELECT * FROM account');
      expect(rows.length, 1);
      expect(rows.first['name'], 'Pension Pot 1');
      expect(rows.first['istype'], 0);
    });

    test('List Accounts', () async {
      db.execute("INSERT INTO account (userid, name, amount, istype, amountat, rate, age) VALUES (1, 'Pot A', 1000, 0, '2023-01-01', 0.0, 50)");
      
      final req = Request('GET', Uri.parse('http://localhost/account'), context: {'uid': 1});
      final res = await accountHandler.select(req);
      expect(res.statusCode, 200);
      
      final body = jsonDecode(await res.readAsString()) as List;
      expect(body.length, 1);
      // Check it matches model structure
      expect(body.first['name'], 'Pot A');
      expect(body.first['istype'], 0);
    });

    test('Update Account', () async {
      db.execute("INSERT INTO account (id, userid, name, amount, istype, amountat, rate, age) VALUES (1, 1, 'Old Name', 1000, 0, '2023-01-01', 0.0, 50)");
      
      final req = Request(
        'PUT', 
        Uri.parse('http://localhost/account/1'),
        context: {'uid': 1},
        body: jsonEncode({
          'name': 'New Name',
          'amount': 2000.0,
          'istype': 1, // Savings
          'amountat': '2024-01-01',
          'rate': 0.02,
          'age': 51
        })
      );
      
      final res = await accountHandler.update(req, '1');
      expect(res.statusCode, 200);
      
      final row = db.select('SELECT * FROM account WHERE id=1').first;
      expect(row['name'], 'New Name');
      expect(row['istype'], 1);
      expect(row['amount'], 2000.0);
    });

    test('Delete Accounts', () async {
       db.execute("INSERT INTO account (id, userid, name, amount, istype, amountat, rate) VALUES (1, 1, 'To delete', 0, 0, '2022-01-01', 0)");
       final req = Request('DELETE', Uri.parse('http://localhost/account/1'), context: {'uid': 1});
       final res = await accountHandler.delete(req, '1');
       expect(res.statusCode, 200);
       
       final rows = db.select('SELECT * FROM account');
       expect(rows.isEmpty, true);
    });
  });
}
