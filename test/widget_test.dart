import 'package:flutter_test/flutter_test.dart';
import 'package:ocr_expense_tracker/data/expense_database.dart';
import 'package:ocr_expense_tracker/data/expense_store.dart';
import 'package:ocr_expense_tracker/main.dart';
import 'package:ocr_expense_tracker/models/expense.dart';

void main() {
  testWidgets('home screen shows empty state then a saved expense',
      (tester) async {
    final db = ExpenseDatabase.inMemory();
    final store = ExpenseStore(database: db);
    // sqflite_common_ffi performs real async I/O, so run outside fake async.
    await tester.runAsync(store.load);

    await tester.pumpWidget(ExpenseApp(store: store));
    expect(find.text('Expense Tracker'), findsOneWidget);

    await tester.tap(find.text('Transactions'));
    await tester.pumpAndSettle();
    expect(find.textContaining('No expenses yet'), findsOneWidget);

    await tester.runAsync(() => store.add(Expense(
          merchant: 'Coopmart',
          amountVnd: 150000,
          date: DateTime.now(),
          category: ExpenseCategory.food,
        )));
    await tester.pumpAndSettle();
    expect(find.text('Coopmart'), findsOneWidget);
    expect(find.textContaining('150'), findsWidgets);

    await tester.runAsync(db.close);
  });
}
