import 'package:test/test.dart';
import 'package:shared/models/ageOrDate.dart';
import 'package:shared/models/user.dart';
import 'package:shared/models/account.dart';
import 'package:shared/models/account_type.dart';
import 'package:shared/models/income.dart';
import 'package:shared/models/outgoing.dart';
import 'package:shared/models/transfer.dart';

void main() {
  group('User Model', () {
    test('fromJson handles int/bool isAdmin/isLocked', () {
      final json = {
        'id': 1,
        'username': 'test',
        'dob': '1990-01-01',
        'isadmin': 1, // int from sqlite
        'islocked': false // bool from elsewhere?
      };
      final user = User.fromJson(json);
      expect(user.isAdmin, true);
      expect(user.isLocked, false);
      expect(user.password, null); // Password not parsed
    });

    test('toJson includes password if set', () {
      final user = User(username: 'test', dob: DateTime(1990), password: 'pw', isAdmin: true);
      final json = user.toJson();
      expect(json['password'], 'pw');
      expect(json['isadmin'], 1);
    });
  });

  group('Account Model', () {
    test('fromJson maps AccountType correctly', () {
      final json = {
        'id': 1,
        'name': 'Pension',
        'amount': 100.0,
        'istype': 0, // Pension
        'amountat': '2025-01-01',
        'rate': 0.05
      };
      final acc = Account.fromJson(json);
      expect(acc.type, AccountType.pension);
      expect(acc.amount, 100.0);
    });

    test('fromJson handles missing type defaulting', () {
      final json = {
        'id': 1,
        'name': 'Pension',
        'amount': 100.0,
        'amountat': '2025-01-01',
      };
      final acc = Account.fromJson(json);
      expect(acc.type, AccountType.pension); // Default
    });
  });
  
  // Basic checks for other models to ensure keys match
  test('Income Model serialization', () {
     final i = Income(name: 'Work', amount: 50.0, intoId: 1, startAt: AgeOrDate.fromString('2025-01-01'), rate: 0.1);
     expect(i.toJson()['amount'], 50.0);
     final i2 = Income.fromJson(i.toJson());
     expect(i2.name, 'Work');
  });

  test('Outgoing Model serialization', () {
     final o = Outgoing(name: 'Rent', amount: 500.0, fromId: 1, startAt: AgeOrDate.fromString('2025-01-01'), rate:0.1);
     expect(o.toJson()['name'], 'Rent');
     final o2 = Outgoing.fromJson(o.toJson());
     expect(o2.amount, 500.0);
  });
  
  test('Transfer Model serialization', () {
     final t = Transfer(name: 'Save', amount: 100.0, fromId: 1, intoId: 2, startAt: AgeOrDate.fromString('2020-01-01'), rate:0.1);
     expect(t.toJson()['fromid'], 1);
     final t2 = Transfer.fromJson(t.toJson());
     expect(t2.intoId, 2);
  });
}
