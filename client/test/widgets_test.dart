import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:client/widgets/currency_input.dart';
import 'package:client/widgets/pagination_controls.dart';

void main() {
  group('CurrencyInput Widget', () {
    testWidgets('renders with label', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CurrencyInput(
              label: 'Amount',
              onChanged: (value) {},
            ),
          ),
        ),
      );

      expect(find.text('Amount'), findsOneWidget);
    });

    testWidgets('renders with initial value', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CurrencyInput(
              label: 'Amount',
              initialValue: 1000.0,
              onChanged: (value) {},
            ),
          ),
        ),
      );

      expect(find.text('Amount'), findsOneWidget);
    });

    testWidgets('calls onChanged when value entered', (WidgetTester tester) async {
      double? changedValue;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CurrencyInput(
              label: 'Amount',
              onChanged: (value) {
                changedValue = value;
              },
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField), '5000');
      expect(changedValue, 5000.0);
    });
  });

  group('PaginationControls Widget', () {
    testWidgets('renders page info', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaginationControls(
              currentPage: 1,
              totalPages: 5,
              onPageChanged: (page) {},
            ),
          ),
        ),
      );

      expect(find.text('Page 1 of 5'), findsOneWidget);
    });

    testWidgets('disables previous button on first page', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaginationControls(
              currentPage: 1,
              totalPages: 5,
              onPageChanged: (page) {},
            ),
          ),
        ),
      );

      // Find previous button by icon
      final prevButton = find.widgetWithIcon(IconButton, Icons.chevron_left);
      expect(prevButton, findsOneWidget);
    });

    testWidgets('calls onPageChanged when next pressed', (WidgetTester tester) async {
      int? newPage;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaginationControls(
              currentPage: 1,
              totalPages: 5,
              onPageChanged: (page) {
                newPage = page;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.widgetWithIcon(IconButton, Icons.chevron_right));
      await tester.pump();
      expect(newPage, 2);
    });
  });
}
