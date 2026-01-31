import 'package:test/test.dart';
import 'package:shared/models/simulate.dart';
import 'package:shared/models/account.dart';
import 'package:shared/models/account_type.dart';
import 'package:shared/models/income.dart';
import 'package:shared/models/outgoing.dart';
import 'package:shared/models/transfer.dart';
import 'package:shared/models/user.dart';
import 'package:shared/models/ageOrDate.dart';

void main() {
  group('Simulate', () {
    late User testUser;
    late List<Account> accounts;
    late List<Income> incomes;
    late List<Outgoing> outgoings;
    late List<Transfer> transfers;

    setUp(() {
      testUser = User(
        id: 1,
        username: 'testuser',
        dob: DateTime(1980, 1, 1),
      );

      accounts = [
        Account(
          id: 1,
          name: 'Pension Pot',
          amount: 100000.0,
          type: AccountType.pension,
          amountAt: AgeOrDate(date: DateTime(2025, 1, 1)),
          rate: 0.05,
        ),
        Account(
          id: 2,
          name: 'Current Account',
          amount: 5000.0,
          type: AccountType.current,
          amountAt: AgeOrDate(date: DateTime(2025, 1, 1)),
          rate: 0.0,
        ),
      ];

      incomes = [];
      outgoings = [];
      transfers = [];
    });

    test('simulate returns null for empty account list', () {
      final sim = Simulate([], incomes, outgoings, transfers, testUser);
      final result = sim.simulate(0.1, 0.0, false, null, null);
      expect(result, isNull);
    });

    test('simulate returns SimulationResult for valid accounts', () {
      final sim = Simulate(accounts, incomes, outgoings, transfers, testUser);
      final result = sim.simulate(0.1, 0.0, false, null, null);
      expect(result, isNotNull);
      expect(result!.nameList.length, 2);
      expect(result.accountMap.length, 2);
    });

    test('simulate calculates interest correctly', () {
      final sim = Simulate(accounts, incomes, outgoings, transfers, testUser);
      final result = sim.simulate(0.0, 0.0, false, null, null); // No volatility, no rate adjustment
      expect(result, isNotNull);
      // First account (pension) starts at 100000, with 5% rate
      // After 1 year: 100000 * 1.05 = 105000
      expect(result!.accountMap[0][1], closeTo(105000, 1000));
    });

    test('simulate handles income into account', () {
      incomes = [
        Income(
          id: 1,
          name: 'State Pension',
          amount: 1000.0, // monthly
          intoId: 2, // into current account
          startAt: AgeOrDate(date: DateTime(2025, 1, 1)),
          rate: 0.0,
        ),
      ];

      final sim = Simulate(accounts, incomes, outgoings, transfers, testUser);
      final result = sim.simulate(0.0, 0.0, false, null, null);
      expect(result, isNotNull);
      // Current account should increase by income (1000 * 12 = 12000 per year)
      expect(result!.incomeList[1], greaterThan(0));
    });

    test('simulate handles outgoing from account', () {
      outgoings = [
        Outgoing(
          id: 1,
          name: 'Living Expenses',
          amount: 500.0, // monthly
          fromId: 2, // from current account
          startAt: AgeOrDate(date: DateTime(2025, 1, 1)),
          rate: 0.0,
        ),
      ];

      final sim = Simulate(accounts, incomes, outgoings, transfers, testUser);
      final result = sim.simulate(0.0, 0.0, false, null, null);
      expect(result, isNotNull);
    });

    test('simulate handles transfers between accounts', () {
      transfers = [
        Transfer(
          id: 1,
          name: 'Drawdown',
          amount: 500.0,
          fromId: 1, // from pension
          intoId: 2, // to current
          startAt: AgeOrDate(date: DateTime(2025, 1, 1)),
          rate: 0.0,
        ),
      ];

      final sim = Simulate(accounts, incomes, outgoings, transfers, testUser);
      final result = sim.simulate(0.0, 0.0, false, null, null);
      expect(result, isNotNull);
    });

    test('simulate generates Monte Carlo min/max lists', () {
      final sim = Simulate(accounts, incomes, outgoings, transfers, testUser);
      final result = sim.simulate(0.15, 0.0, false, null, null); // 15% volatility
      expect(result, isNotNull);
      expect(result!.monteMinList.length, greaterThan(0));
      expect(result.monteMaxList.length, greaterThan(0));
    });

    test('simulate calculates age list correctly', () {
      final sim = Simulate(accounts, incomes, outgoings, transfers, testUser);
      final result = sim.simulate(0.0, 0.0, false, null, null);
      expect(result, isNotNull);
      // User born 1980, accounts start 2025 = age 45
      expect(result!.ageList.first, closeTo(45, 1));
    });

    test('rateAdjustment affects simulation', () {
      final sim1 = Simulate(accounts, [], [], [], testUser);
      final result1 = sim1.simulate(0.0, 0.0, false, null, null); // No adjustment

      final sim2 = Simulate(accounts, [], [], [], testUser);
      final result2 = sim2.simulate(0.0, 0.02, false, null, null); // +2% rate adjustment

      expect(result1, isNotNull);
      expect(result2, isNotNull);
      // With rate adjustment, values should be higher
      expect(result2!.accountMap[0][5], greaterThan(result1!.accountMap[0][5]));
    });

    test('simulate with age-based dates', () {
      incomes = [
        Income(
          id: 1,
          name: 'State Pension',
          amount: 800.0,
          intoId: 2,
          startAt: AgeOrDate(age: 67), // Starts at age 67
          rate: 0.02,
        ),
      ];

      final sim = Simulate(accounts, incomes, outgoings, transfers, testUser);
      final result = sim.simulate(0.0, 0.0, false, null, null);
      expect(result, isNotNull);
    });
  });

  group('Simulate.isInRange', () {
    late User testUser;

    setUp(() {
      testUser = User(id: 1, username: 'test', dob: DateTime(1980, 1, 1));
    });

    test('returns true when startAt/endAt are null', () {
      final sim = Simulate([], [], [], [], testUser);
      final result = sim.isInRange(
        DateTime(2025, 1, 1),
        AgeOrDate(), // both null
        null,
      );
      expect(result, true);
    });

    test('returns false when before start date', () {
      final sim = Simulate([], [], [], [], testUser);
      final result = sim.isInRange(
        DateTime(2020, 1, 1), // earliest
        AgeOrDate(date: DateTime(2025, 1, 1)), // starts 2025
        null,
      );
      expect(result, false);
    });

    test('returns true when in range', () {
      final sim = Simulate([], [], [], [], testUser);
      final result = sim.isInRange(
        DateTime(2027, 1, 1),
        AgeOrDate(date: DateTime(2025, 1, 1)),
        AgeOrDate(date: DateTime(2030, 1, 1)),
      );
      expect(result, true);
    });

    test('returns false when after end date', () {
      final sim = Simulate([], [], [], [], testUser);
      final result = sim.isInRange(
        DateTime(2035, 1, 1),
        AgeOrDate(date: DateTime(2025, 1, 1)),
        AgeOrDate(date: DateTime(2030, 1, 1)), // ends 2030
      );
      expect(result, false);
    });
  });

  group('Transaction', () {
    test('creates transaction with correct fields', () {
      final income = Income(
        id: 1,
        name: 'Test',
        amount: 100.0,
        intoId: 1,
        startAt: AgeOrDate(date: DateTime(2025)),
        rate:2.5,
      );
      final trans = Transaction(income, 1, 100.0, 2.5);
      expect(trans.id, 1);
      expect(trans.target, 100.0);
      expect(trans.source, income);
      expect(trans.use, false);
    });
  });
}
