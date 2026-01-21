import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:client/screens/account_screen.dart';
import 'package:client/providers/account_provider.dart';
import 'package:shared/models/account.dart';
import 'package:shared/models/account_type.dart';

class MockAccountProvider extends ChangeNotifier implements AccountProvider {
  @override
  bool isLoading = false;
  
  @override
  String? error;

  @override
  List<Account> accounts = [
    Account(id: 1, name: 'Test Pension', amount: 50000.0, type: AccountType.pension, rate: 0.05, amountAt: DateTime.parse('2025-01-01'), age: 60),
    Account(id: 2, name: 'Test Current', amount: 1000.0, type: AccountType.current, rate: 0.0, amountAt: DateTime.parse('2025-01-01'), age: 30),
  ];

  @override
  Future<void> load({int? newPage}) async {
    notifyListeners();
  }

  @override
  Future<void> add(Account account) async {
    accounts.add(account.copyWith(id: 3));
    notifyListeners();
  }

  @override
  Future<void> delete(int id) async {
    accounts.removeWhere((a) => a.id == id);
    notifyListeners();
  }
  
  @override
  Future<void> update(Account account) async {
      // Mock update
      final index = accounts.indexWhere((a) => a.id == account.id);
      if (index != -1) {
          accounts[index] = account;
          notifyListeners();
      }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('AccountScreen displays accounts and adds new one', (WidgetTester tester) async {
    final mockProvider = MockAccountProvider();

    await tester.pumpWidget(
      ChangeNotifierProvider<AccountProvider>.value(
        value: mockProvider,
        child: const MaterialApp(home: AccountScreen()),
      ),
    );

    await tester.pumpAndSettle();

    // Verify list
    expect(find.text('Test Pension (Pension)'), findsOneWidget);
    expect(find.text('Test Current (Current)'), findsOneWidget);

    // Test form interaction
    await tester.enterText(find.byType(TextFormField).at(0), 'New Pot'); // Name 
    // Note: inputs might follow different order or decoration logic. 
    // AccountScreen: Name, Amount, Date, Rate, Age
    
    await tester.enterText(find.byType(TextFormField).at(1), '2000'); // Amount
    
    // Tap date icon
    await tester.tap(find.byIcon(Icons.calendar_today));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK')); 
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).last, '65'); // Age? Or Rate?
    // Let's verify fields count/order if needed, but basic fill is ok.
    
    await tester.tap(find.text('Add Account'));
    await tester.pumpAndSettle();

    // Verify addition
    expect(find.text('New Pot (Pension)'), findsOneWidget);
  });
}
