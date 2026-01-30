import 'package:flutter_test/flutter_test.dart';
import 'package:client/providers/account_provider.dart';
import 'package:client/providers/auth_provider.dart';
import 'package:client/providers/income_provider.dart';
import 'package:client/providers/outgoing_provider.dart';
import 'package:client/providers/transfer_provider.dart';

void main() {
  group('AccountProvider', () {
    test('initial state is correct', () {
      final provider = AccountProvider();
      expect(provider.accounts, isEmpty);
      expect(provider.isLoading, false);
      expect(provider.error, isNull);
      expect(provider.page, 1);
      expect(provider.limit, 20);
      expect(provider.totalCount, 0);
    });

    test('is a ChangeNotifier', () {
      final provider = AccountProvider();
      expect(provider, isA<AccountProvider>());
    });
  });

  group('AuthProvider', () {
    test('initial state is correct', () {
      final provider = AuthProvider();
      expect(provider.isLoggedIn, false);
      expect(provider.isLoading, false);
    });

    test('is a ChangeNotifier', () {
      final provider = AuthProvider();
      expect(provider, isA<AuthProvider>());
    });
  });

  group('IncomeProvider', () {
    test('initial state is correct', () {
      final provider = IncomeProvider();
      expect(provider.incomes, isEmpty);
      expect(provider.isLoading, false);
      expect(provider.error, isNull);
    });

    test('is a ChangeNotifier', () {
      final provider = IncomeProvider();
      expect(provider, isA<IncomeProvider>());
    });
  });

  group('OutgoingProvider', () {
    test('initial state is correct', () {
      final provider = OutgoingProvider();
      expect(provider.outgoings, isEmpty);
      expect(provider.isLoading, false);
      expect(provider.error, isNull);
    });

    test('is a ChangeNotifier', () {
      final provider = OutgoingProvider();
      expect(provider, isA<OutgoingProvider>());
    });
  });

  group('TransferProvider', () {
    test('initial state is correct', () {
      final provider = TransferProvider();
      expect(provider.transfers, isEmpty);
      expect(provider.isLoading, false);
      expect(provider.error, isNull);
    });

    test('is a ChangeNotifier', () {
      final provider = TransferProvider();
      expect(provider, isA<TransferProvider>());
    });
  });
}
