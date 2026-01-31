import 'package:test/test.dart';
import 'package:shared/models/ageOrDate.dart';
import 'package:shared/models/user.dart';
import 'package:shared/models/account.dart';
import 'package:shared/models/account_type.dart';
import 'package:shared/models/income.dart';
import 'package:shared/models/outgoing.dart';
import 'package:shared/models/transfer.dart';
import 'package:shared/models/base.dart';
import 'package:shared/models/simulation_result.dart';

void main() {
  // ============================================================
  // AgeOrDate Tests
  // ============================================================
  group('AgeOrDate', () {
    test('fromString parses date correctly', () {
      final aod = AgeOrDate.fromString('2025-01-15');
      expect(aod.date, isNotNull);
      expect(aod.date!.year, 2025);
      expect(aod.date!.month, 1);
      expect(aod.date!.day, 15);
      expect(aod.age, isNull);
    });

    test('fromString parses age correctly', () {
      final aod = AgeOrDate.fromString('65');
      expect(aod.age, 65);
      expect(aod.date, isNull);
    });

    test('fromString handles null', () {
      final aod = AgeOrDate.fromString(null);
      expect(aod.age, isNull);
      expect(aod.date, isNull);
    });

    test('fromString handles 3-digit age', () {
      final aod = AgeOrDate.fromString('100');
      expect(aod.age, 100);
    });

    test('fromJson with date', () {
      final aod = AgeOrDate.fromJson({'date': '2025-06-01T00:00:00.000', 'age': null});
      expect(aod.date, isNotNull);
      expect(aod.date!.year, 2025);
      expect(aod.age, isNull);
    });

    test('fromJson with age', () {
      final aod = AgeOrDate.fromJson({'date': null, 'age': 70});
      expect(aod.age, 70);
      expect(aod.date, isNull);
    });

    test('toJson with date', () {
      final aod = AgeOrDate(date: DateTime(2025, 3, 15));
      final json = aod.toJson();
      expect(json['date'], contains('2025-03-15'));
      expect(json['age'], isNull);
    });

    test('toJson with age', () {
      final aod = AgeOrDate(age: 67);
      final json = aod.toJson();
      expect(json['age'], 67);
      expect(json['date'], isNull);
    });

    test('toString with date', () {
      final aod = AgeOrDate(date: DateTime(2025, 1, 5));
      expect(aod.toString(), '2025-01-05');
    });

    test('toString with age', () {
      final aod = AgeOrDate(age: 55);
      expect(aod.toString(), '55');
    });

    test('toString with null', () {
      final aod = AgeOrDate();
      expect(aod.toString(), 'null');
    });

    test('roundtrip JSON serialization', () {
      final original = AgeOrDate(date: DateTime(2030, 12, 25));
      final json = original.toJson();
      final restored = AgeOrDate.fromJson(json);
      expect(restored.date!.year, original.date!.year);
      expect(restored.date!.month, original.date!.month);
      expect(restored.date!.day, original.date!.day);
    });
  });

  // ============================================================
  // Base Tests
  // ============================================================
  group('Base', () {
    test('fromJson creates Base correctly', () {
      final json = {'id': 1, 'name': 'Test', 'amount': 1000.0, 'rate': 0.05};
      final base = Base.fromJson(json);
      expect(base.id, 1);
      expect(base.name, 'Test');
      expect(base.amount, 1000.0);
      expect(base.rate, 0.05);
    });

    test('fromJson handles missing rate', () {
      final json = {'id': 2, 'name': 'NoRate', 'amount': 500.0};
      final base = Base.fromJson(json);
      expect(base.rate, 0.0);
    });

    test('toJson serializes correctly', () {
      final base = Base(id: 3, name: 'Savings', amount: 2000.0, rate: 0.03);
      final json = base.toJson();
      expect(json['id'], 3);
      expect(json['name'], 'Savings');
      expect(json['amount'], 2000.0);
      expect(json['rate'], 0.03);
    });

    test('copyWith creates modified copy', () {
      final base = Base(id: 1, name: 'Original', amount: 100.0);
      final copy = base.copyWith(name: 'Modified', amount: 200.0);
      expect(copy.id, 1);
      expect(copy.name, 'Modified');
      expect(copy.amount, 200.0);
    });

    test('fromDb maps columns correctly', () {
      final row = {'id': 5, 'name': 'FromDb', 'amount': 750.0, 'rate': 0.02};
      final base = Base.fromDb(row);
      expect(base.id, 5);
      expect(base.name, 'FromDb');
    });
  });

  // ============================================================
  // AccountType Tests
  // ============================================================
  group('AccountType', () {
    test('fromId returns pension for 0', () {
      expect(AccountType.fromId(0), AccountType.pension);
    });

    test('fromId returns savings for 1', () {
      expect(AccountType.fromId(1), AccountType.savings);
    });

    test('fromId returns current for 2', () {
      expect(AccountType.fromId(2), AccountType.current);
    });

    test('fromId returns pension for null', () {
      expect(AccountType.fromId(null), AccountType.pension);
    });

    test('id property returns correct values', () {
      expect(AccountType.pension.id, 0);
      expect(AccountType.savings.id, 1);
      expect(AccountType.current.id, 2);
    });
  });

  // ============================================================
  // User Tests
  // ============================================================
  group('User Model', () {
    test('fromJson handles int isAdmin/isLocked', () {
      final json = {
        'id': 1,
        'username': 'test',
        'dob': '1990-01-01',
        'isadmin': 1,
        'islocked': 0
      };
      final user = User.fromJson(json);
      expect(user.isAdmin, true);
      expect(user.isLocked, false);
      expect(user.password, null);
    });

    test('fromJson handles bool isAdmin/isLocked', () {
      final json = {
        'id': 2,
        'username': 'user2',
        'dob': '1985-05-15',
        'isadmin': false,
        'islocked': true
      };
      final user = User.fromJson(json);
      expect(user.isAdmin, false);
      expect(user.isLocked, true);
    });

    test('toJson includes password if set', () {
      final user = User(username: 'test', dob: DateTime(1990), password: 'secret', isAdmin: true);
      final json = user.toJson();
      expect(json['password'], 'secret');
      expect(json['isadmin'], 1);
    });

    test('toJson excludes null password', () {
      final user = User(username: 'test', dob: DateTime(1990));
      final json = user.toJson();
      expect(json.containsKey('password'), false);
    });

    test('copyWith creates modified user', () {
      final user = User(id: 1, username: 'old', dob: DateTime(1990));
      final copy = user.copyWith(username: 'new');
      expect(copy.username, 'new');
      expect(copy.id, 1);
    });
  });

  // ============================================================
  // Account Tests
  // ============================================================
  group('Account Model', () {
    test('fromJson maps AccountType correctly', () {
      final json = {
        'id': 1,
        'name': 'Pension',
        'amount': 100000.0,
        'isType': 0,
        'amountAt': {'date': '2025-01-01T00:00:00.000', 'age': null},
        'rate': 0.05
      };
      final acc = Account.fromJson(json);
      expect(acc.type, AccountType.pension);
      expect(acc.amount, 100000.0);
    });

    test('fromJson handles missing type (defaults to pension)', () {
      final json = {
        'id': 1,
        'name': 'Default',
        'amount': 50000.0,
        'amountAt': {'date': '2025-01-01T00:00:00.000', 'age': null},
      };
      final acc = Account.fromJson(json);
      expect(acc.type, AccountType.pension);
    });

    test('toJson serializes correctly', () {
      final acc = Account(
        id: 1,
        name: 'Test Pot',
        amount: 25000.0,
        type: AccountType.savings,
        amountAt: AgeOrDate(date: DateTime(2025, 6, 1)),
        rate: 0.04,
      );
      final json = acc.toJson();
      expect(json['isType'], 1);
      expect(json['name'], 'Test Pot');
    });

    test('copyWith creates modified account', () {
      final acc = Account(
        id: 1,
        name: 'Original',
        amount: 1000.0,
        type: AccountType.pension,
        amountAt: AgeOrDate(date: DateTime(2025)),
      );
      final copy = acc.copyWith(name: 'Modified', amount: 2000.0);
      expect(copy.name, 'Modified');
      expect(copy.amount, 2000.0);
      expect(copy.id, 1);
    });
  });

  // ============================================================
  // Income Tests
  // ============================================================
  group('Income Model', () {
    test('serialization roundtrip', () {
      final income = Income(
        name: 'Salary',
        amount: 3000.0,
        intoId: 1,
        startAt: AgeOrDate.fromString('2025-01-01'),
        endAt: AgeOrDate.fromString('2050-01-01'),
        rate: 0.02,
      );
      final json = income.toJson();
      final restored = Income.fromJson(json);
      expect(restored.name, 'Salary');
      expect(restored.amount, 3000.0);
      expect(restored.intoId, 1);
      expect(restored.rate, 0.02);
    });

    test('handles null endAt', () {
      final income = Income(
        name: 'Pension',
        amount: 500.0,
        intoId: 2,
        startAt: AgeOrDate(age: 67),
      );
      final json = income.toJson();
      expect(json['endAt'], isNull);
      final restored = Income.fromJson(json);
      expect(restored.endAt, isNull);
    });

    test('copyWith creates modified income', () {
      final income = Income(
        name: 'Work',
        amount: 2000.0,
        intoId: 1,
        startAt: AgeOrDate(date: DateTime(2025)),
      );
      final copy = income.copyWith(amount: 2500.0);
      expect(copy.amount, 2500.0);
      expect(copy.name, 'Work');
    });
  });

  // ============================================================
  // Outgoing Tests
  // ============================================================
  group('Outgoing Model', () {
    test('serialization roundtrip', () {
      final outgoing = Outgoing(
        name: 'Rent',
        amount: 1500.0,
        fromId: 2,
        startAt: AgeOrDate(date: DateTime(2025)),
        rate: 0.03,
      );
      final json = outgoing.toJson();
      final restored = Outgoing.fromJson(json);
      expect(restored.name, 'Rent');
      expect(restored.fromId, 2);
    });

    test('handles null endAt', () {
      final outgoing = Outgoing(
        name: 'Bills',
        amount: 200.0,
        fromId: 1,
        startAt: AgeOrDate(date: DateTime(2025)),
      );
      expect(outgoing.endAt, isNull);
    });

    test('copyWith creates modified outgoing', () {
      final outgoing = Outgoing(
        name: 'Food',
        amount: 500.0,
        fromId: 1,
        startAt: AgeOrDate(date: DateTime(2025)),
      );
      final copy = outgoing.copyWith(amount: 600.0);
      expect(copy.amount, 600.0);
    });
  });

  // ============================================================
  // Transfer Tests
  // ============================================================
  group('Transfer Model', () {
    test('serialization roundtrip', () {
      final transfer = Transfer(
        name: 'Monthly Drawdown',
        amount: 1000.0,
        fromId: 1,
        intoId: 2,
        startAt: AgeOrDate(age: 60),
        rate: 0.02,
      );
      final json = transfer.toJson();
      final restored = Transfer.fromJson(json);
      expect(restored.name, 'Monthly Drawdown');
      expect(restored.fromId, 1);
      expect(restored.intoId, 2);
    });

    test('toJson includes fromId and intoId', () {
      final transfer = Transfer(
        name: 'Save',
        amount: 500.0,
        fromId: 2,
        intoId: 3,
        startAt: AgeOrDate(date: DateTime(2025)),
      );
      final json = transfer.toJson();
      expect(json['fromId'], 2);
      expect(json['intoId'], 3);
    });

    test('copyWith creates modified transfer', () {
      final transfer = Transfer(
        name: 'Original',
        amount: 100.0,
        fromId: 1,
        intoId: 2,
        startAt: AgeOrDate(date: DateTime(2025)),
      );
      final copy = transfer.copyWith(amount: 200.0, name: 'Modified');
      expect(copy.amount, 200.0);
      expect(copy.name, 'Modified');
      expect(copy.fromId, 1);
    });
  });

  // ============================================================
  // SimulationResult Tests
  // ============================================================
  group('SimulationResult', () {
    test('fromJson parses all fields', () {
      final json = {
        'sumPotMin': 0.0,
        'sumPotMax': 500000.0,
        'accountMin': 0.0,
        'accountMax': 50000.0,
        'xAxisMin': 45.0,
        'xAxisMax': 120.0,
        'name': ['Pot 1', 'Pot 2'],
        'sum': [100000.0, 150000.0],
        'income': [20000.0, 25000.0],
        'account': [[100000.0, 110000.0], [50000.0, 55000.0]],
        'monteMin': [90000.0, 95000.0],
        'monteMax': [200000.0, 220000.0],
        'age': [45.0, 46.0],
      };
      final result = SimulationResult.fromJson(json);
      expect(result.pensionMax, 500000.0);
      expect(result.nameList.length, 2);
      expect(result.accountMap.length, 2);
    });

    test('toJson serializes correctly', () {
      final result = SimulationResult(
        ageList: [50],
        pensionMin: 0,
        pensionMax: 100000,
        accountMin: 0,
        accountMax: 30000,
        ageMin: 50,
        ageMax: 100,
        nameList: ['Test'],
        sumList: [50000],
        incomeList: [15000],
        outgoingList: [12000],
        accountMap: [[50000]],
        monteMinList: [40000],
        monteMaxList: [60000],
        intoPensionList: [3400],
      );
      final json = result.toJson();
      expect(json['pensionMax'], 100000);
      expect(json['name'], ['Test']);
    });

    test('handles optional montePath', () {
      final json = {
        'pensionMin': 0.0,
        'pensionMax': 100.0,
        'accountMin': 0.0,
        'accountMax': 10.0,
        'ageMin': 0.0,
        'ageMax': 10.0,
        'name': ['A'],
        'sum': [50.0],
        'income': [5.0],
        'account': [[50.0]],
        'monteMin': [40.0],
        'monteMax': [60.0],
        'age': [50.0],
        'montePath': [[55.0, 60.0], [45.0, 50.0]],
      };
      final result = SimulationResult.fromJson(json);
      expect(result.montePath, isNotNull);
      expect(result.montePath!.length, 2);
    });

    test('toJson excludes montePath when null', () {
      final result = SimulationResult(
        pensionMin: 0, pensionMax: 100,
        accountMin: 0, accountMax: 10,
        ageMin: 0, ageMax: 10,
        nameList: [], sumList: [], incomeList: [], outgoingList: [],
        accountMap: [], monteMinList: [], monteMaxList: [],
        ageList: [], intoPensionList: [],
      );
      final json = result.toJson();
      expect(json.containsKey('montePath'), false);
    });
  });
}
