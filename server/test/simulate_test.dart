import 'package:test/test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:full_pension_server/db.dart';
import 'package:full_pension_server/simulate.dart';
import 'dart:convert';
import 'package:shelf/shelf.dart';

void main() {
  group('Simulation Tests', () {
    late Database db;

    setUp(() {
      db = sqlite3.openInMemory();
      db.execute('''
        CREATE TABLE user (id INTEGER PRIMARY KEY, dob TEXT);
        CREATE TABLE account (id INTEGER PRIMARY KEY, userid INTEGER, istype INTEGER, name TEXT, amount REAL, age INTEGER, amountat TEXT, rate REAL);
        CREATE TABLE income (id INTEGER PRIMARY KEY, userid INTEGER, name TEXT, intoid INTEGER, amount REAL, startat TEXT, endat TEXT, rate REAL);
        CREATE TABLE outgoing (id INTEGER PRIMARY KEY, userid INTEGER, name TEXT, fromid INTEGER, amount REAL, startat TEXT, endat TEXT, rate REAL);
        CREATE TABLE transfer (id INTEGER PRIMARY KEY, userid INTEGER, name TEXT, fromid INTEGER, intoid INTEGER, amount REAL, startat TEXT, endat TEXT, rate REAL);
      ''');
      pension.mockDb(db);
    });

    tearDown(() {
      db.dispose();
    });

    test('Simulation runs with basic pension and current account', () async {
      db.execute("INSERT INTO user (id, dob) VALUES (1, '1980-01-01')");
      db.execute("INSERT INTO account (id, userid, istype, name, amount, amountat, rate) VALUES (1, 1, 0, 'My Pension', 100000, '2025-01-01', 0.05)");
      db.execute("INSERT INTO account (id, userid, istype, name, amount, amountat, rate) VALUES (2, 1, 2, 'Bank', 10000, '2025-01-01', 0.0)");
      db.execute("INSERT INTO transfer (id, userid, fromid, intoid, amount, startat, rate) VALUES (1, 1, 1, 2, 500, '2030-01-01', 0)");
      db.execute("INSERT INTO income (id, userid, intoid, amount, startat, endat, rate) VALUES (1, 1, 2, 2000, '2025-01-01', '2045-01-01', 0)");
      db.execute("INSERT INTO outgoing (id, userid, fromid, amount, startat, rate) VALUES (1, 1, 2, 1500, '2025-01-01', 0)");

      final req = Request('POST', Uri.parse('http://localhost/simulate'), context: {'uid': 1});
      final Simulate sim = Simulate();
      final res = await sim.simulate(req);

      expect(res.statusCode, 200);
      final body = jsonDecode(await res.readAsString());
      
      expect(body['pots'], hasLength(2));
      expect(body['sum'], isNotEmpty);
      expect(body['monteMin'], isNotEmpty);
      expect(body['monteMax'], isNotEmpty);
      
      List<dynamic> pots = body['pots'];
      List<double> potA = List<double>.from(pots[0]);
      expect(potA[0], closeTo(100000, 5000));
    });
  });
}
