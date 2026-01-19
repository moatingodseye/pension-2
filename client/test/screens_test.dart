import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:client/screens/transfer_screen.dart';
import 'package:client/screens/income_screen.dart';
import 'package:client/screens/outgoing_screen.dart';
import 'package:client/providers/account_provider.dart';
import 'package:client/providers/income_provider.dart';
import 'package:client/providers/outgoing_provider.dart';
import 'package:client/providers/transfer_provider.dart';
import 'package:shared/models/account.dart';
import 'package:shared/models/account_type.dart';
import 'package:shared/models/income.dart';
import 'package:shared/models/outgoing.dart';
import 'package:shared/models/transfer.dart';

// Mocks
class MockAccountProvider extends ChangeNotifier implements AccountProvider {
  @override
  List<Account> accounts = [
    Account(id: 1, name: 'Pension Pot', amount: 50000.0, type: AccountType.pension, rate: 0.05, amountAt: DateTime.now()),
    Account(id: 2, name: 'Bank', amount: 1000.0, type: AccountType.current, rate: 0.0, amountAt: DateTime.now()),
  ];
  @override bool isLoading = false;
  @override String? error;
  @override Future<void> load() async { notifyListeners(); }
  @override dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class MockIncomeProvider extends ChangeNotifier implements IncomeProvider {
  @override List<Income> incomes = [];
  @override bool isLoading = false;
  @override String? error;
  @override Future<void> load() async { notifyListeners(); }
  @override Future<void> add(Income i) async { 
      incomes.add(i.copyWith(id: 1)); 
      notifyListeners(); 
  }
  @override dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class MockOutgoingProvider extends ChangeNotifier implements OutgoingProvider {
  @override List<Outgoing> outgoings = [];
  @override bool isLoading = false;
  @override String? error;
  @override Future<void> load() async { notifyListeners(); }
  @override Future<void> add(Outgoing o) async { 
      outgoings.add(o.copyWith(id: 1)); 
      notifyListeners(); 
  }
  @override dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class MockTransferProvider extends ChangeNotifier implements TransferProvider {
  @override List<Transfer> transfers = [];
  @override bool isLoading = false;
  @override String? error;
  @override Future<void> load() async { notifyListeners(); }
  @override Future<void> add(Transfer t) async { 
      transfers.add(t.copyWith(id: 1)); 
      notifyListeners(); 
  }
  @override dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

void main() {
  group('Other Screens Tests', () {
    late MockAccountProvider mockAcc;
    late MockIncomeProvider mockInc;
    late MockOutgoingProvider mockOut;
    late MockTransferProvider mockTr;

    setUp(() {
      mockAcc = MockAccountProvider();
      mockInc = MockIncomeProvider();
      mockOut = MockOutgoingProvider();
      mockTr = MockTransferProvider();
    });

    testWidgets('TransferScreen adds transfer', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AccountProvider>.value(value: mockAcc),
            ChangeNotifierProvider<TransferProvider>.value(value: mockTr),
          ],
          child: const MaterialApp(home: TransferScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add Transfer'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'Test Transfer'); 
      
      // Select From Account (Dropdown)
      // Implementation detail: Dropdown might need to be found by key or type
      await tester.tap(find.byType(DropdownButtonFormField).first); 
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pension Pot').last);
      await tester.pumpAndSettle();

      // Select To Account (Dropdown)
       await tester.tap(find.byType(DropdownButtonFormField).last); 
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bank').last);
      await tester.pumpAndSettle();
      
      await tester.enterText(find.byType(TextFormField).at(1), '100'); // Amount
      
      // Date
      await tester.tap(find.byIcon(Icons.calendar_today).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      
      expect(find.text('Test Transfer'), findsOneWidget);
    });

    testWidgets('IncomeScreen adds income', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AccountProvider>.value(value: mockAcc),
            ChangeNotifierProvider<IncomeProvider>.value(value: mockInc),
          ],
          child: const MaterialApp(home: IncomeScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add Income'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'Salary');
      await tester.enterText(find.byType(TextFormField).at(1), '2000');
      
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Salary'), findsOneWidget);
    });

    testWidgets('OutgoingScreen adds outgoing', (WidgetTester tester) async {
       await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AccountProvider>.value(value: mockAcc),
            ChangeNotifierProvider<OutgoingProvider>.value(value: mockOut),
          ],
          child: const MaterialApp(home: OutgoingScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add Outgoing'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'Rent');
      await tester.enterText(find.byType(TextFormField).at(1), '1000');
      
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Rent'), findsOneWidget);
    });
  });
}
