import 'package:test/test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:full_pension_server/db.dart';
import 'package:full_pension_server/date.dart';
import 'package:full_pension_server/simulate.dart';
import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shared/models/account.dart';
import 'package:shared/models/simulation_result.dart';

void main() {
  group('Simulation Tests', () {
    late Database db;

    setUp(() {
      db = sqlite3.openInMemory();
      // Setup Schema
      db.execute('''
        CREATE TABLE users (id INTEGER PRIMARY KEY, dob TEXT);
        CREATE TABLE account (id INTEGER PRIMARY KEY, userid INTEGER, istype TEXT, name TEXT, amount REAL, age INTEGER, amountat TEXT, rate REAL);
        CREATE TABLE income (id INTEGER PRIMARY KEY, userid INTEGER, name TEXT, intoid INTEGER, amount REAL, startat TEXT, endat TEXT, rate REAL);
        CREATE TABLE outgoing (id INTEGER PRIMARY KEY, userid INTEGER, name TEXT, fromid INTEGER, amount REAL, startat TEXT, endat TEXT, rate REAL);
        CREATE TABLE transfer (id INTEGER PRIMARY KEY, userid INTEGER, name TEXT, fromid INTEGER, intoid INTEGER, amount REAL, startat TEXT, endat TEXT, rate REAL);
      ''');
      
      // Mock DB provider
      pension.mockDb(db);
    });

    tearDown(() {
      db.dispose();
    });

    test('Simulation runs with basic pension and current account', () async {
      // 1. Create User (DOB 1980)
      db.execute("INSERT INTO users (id, dob) VALUES (1, '1980-01-01')");
      
      // 2. Create Pension Account (100k, 5% growth, type 0)
      db.execute("INSERT INTO account (id, userid, istype, name, amount, amountat, rate) VALUES (1, 1, 0, 'My Pension', 100000, '2025-01-01', 0.05)");
      
      // 3. Create Current Account (10k, 0% growth, type 2)
      db.execute("INSERT INTO account (id, userid, istype, name, amount, amountat, rate) VALUES (2, 1, 2, 'Bank', 10000, '2025-01-01', 0.0)");
      
      // 4. Create Transfer (Pension -> Current, 500/month, start 2030)
      db.execute("INSERT INTO transfer (id, userid, fromid, intoid, amount, startat, rate) VALUES (1, 1, 1, 2, 500, '2030-01-01', 0)");

      // 5. Create Income (Salary, 2000/month, into Current, 2025-2045)
      db.execute("INSERT INTO income (id, userid, intoid, amount, startat, endat, rate) VALUES (1, 1, 2, 2000, '2025-01-01', '2045-01-01', 0)");

      // 6. Create Outgoing (Living Exp, 1500/month, from Current, start 2025)
      db.execute("INSERT INTO outgoing (id, userid, fromid, amount, startat, rate) VALUES (1, 1, 2, 1500, '2025-01-01', 0)");

      // Run Simulation
      final req = Request('POST', Uri.parse('http://localhost/simulate'), context: {'uid': 1});
      final res = await simulate(req);

      expect(res.statusCode, 200);
      final body = jsonDecode(await res.readAsString());
      expect(body['success'], true);
      
      final data = body['data'];
      expect(data['pots'], hasLength(2)); // 2 accounts
      expect(data['sum'], isNotEmpty);
      expect(data['income'], isNotEmpty);
      
      // Verify basic logic:
      // Year 0 (2025): Pension grows. Current +Income(24k) -Outgoing(18k) = +6k/year.
      List<double> currentAcc = List<double>.from(data['pots'][1]); // ID 2 is second added? accountIds order depends on select.
      // IDs are collected in loop. Select * order usually insertion order.
      // Account 1 (Pension) should grow.
      // Account 2 (Current) should grow by ~6k in first year.
      
      // Let's check sums
      // Pension start 100k.
      // Current start 10k.
      // Year 1 end: 
      // Pension = 100k * 1.05 = 105k.
      // Current = 10k + (24k - 18k) = 16k.
      // Sum = 121k.
      
      // Note: Data is monthly or yearly? "Monthly deterministic calculation" comment in code but loop was "for (int y=0;y<count;y++)".
      // Code logic: "pot[i][y] *= 1 + rate;" implies Yearly steps.
      // Flows logic: "amount * 12".
      
      // Check first year values (index 0 is start amount? or end of year 1? Logic: "pot[i][0] = amount". Loop "if (y>0) pot[i][y]=..."
      // So index 0 is Initial.
      // Index 1 is End of Year 1.
      
      expect(currentAcc[0], 16000.0);
      // Wait, loop runs 0 to count.
      // Loop y=0 logic:
      // if (y>0) copy prev. Else (y=0) it keeps initial?
      // "pot[i][0] = amount" set before loop.
      // In loop y=0:
      // "accountSeries[id]![y] *= (1+rate)" -> Applies interest to Year 0?
      // Usually Year 0 is "Start". Applying interest to Start implies it becomes "End of Year 0"?
      // If loop applies flows and interest, then index 0 becomes "End of Year 1" effectively if 'amount' was start.
      // Or we should initialize index 0 and start loop from 1?
      // Current Code: 
      // y=0: Multiplies interest. Adds income/transfers. 
      // So result[0] is End of First Year.
      
      // Let's verify result[0]
      // Pension: 100000 * 1.05 = 105000.
      // Current: 10000 * 1.0 + (24000 - 18000) = 16000.
      // But wait! `accountSeries[id]![0]` was set to initial amount before loop. 
      // Then loop y=0 modifies it.
      // So `pots[0]` is End of Year 1.
      
      double p0 = 105000;
      double c0 = 16000;
      
      // accountIds list order might vary, but we have values.
      final pots = data['pots'] as List;
      List<double> potA = List<double>.from(pots[0]);
      List<double> potB = List<double>.from(pots[1]);
      
      // Find which is which
      double valA = potA[0];
      double valB = potB[0];
      
      // Allow slight float diffs
      if ((valA - p0).abs() < 1) {
          expect(valA, closeTo(p0, 1.0));
          expect(valB, closeTo(c0, 1.0));
      } else {
          expect(valB, closeTo(p0, 1.0));
          expect(valA, closeTo(c0, 1.0));
      }
    });
  });
}
