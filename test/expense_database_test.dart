import 'package:flutter_test/flutter_test.dart';
import 'package:ocr_expense_tracker/data/expense_database.dart';
import 'package:ocr_expense_tracker/data/expense_store.dart';
import 'package:ocr_expense_tracker/models/expense.dart';

Expense _e(String m, int amt, DateTime d, ExpenseCategory c) =>
    Expense(merchant: m, amountVnd: amt, date: d, category: c);

void main() {
  late ExpenseDatabase db;
  late ExpenseStore store;

  setUp(() {
    db = ExpenseDatabase.inMemory();
    store = ExpenseStore(database: db);
  });
  tearDown(() => db.close());

  test('insert, edit, delete round trip', () async {
    await store.add(_e('A', 1000, DateTime(2026, 10, 1), ExpenseCategory.food));
    expect(store.expenses.single.merchant, 'A');
    final saved = store.expenses.single;
    expect(saved.id, isNotNull);

    await store.edit(Expense(
        id: saved.id,
        merchant: 'B',
        amountVnd: 2000,
        date: saved.date,
        category: ExpenseCategory.travel));
    expect(store.expenses.single.merchant, 'B');
    expect(store.expenses.single.category, ExpenseCategory.travel);

    await store.remove(store.expenses.single);
    expect(store.expenses, isEmpty);
  });

  test('aggregations for charts', () async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day, 12);
    await store.add(_e('A', 100000, today, ExpenseCategory.food));
    await store.add(_e('B', 50000, today, ExpenseCategory.food));
    await store.add(_e('C', 30000, today, ExpenseCategory.gear));
    await store.add(_e('Old', 999000,
        today.subtract(const Duration(days: 30)), ExpenseCategory.food));

    final cats = store.totalsByCategory(
        from: today.subtract(const Duration(days: 1)),
        to: today.add(const Duration(days: 1)));
    expect(cats[ExpenseCategory.food], 150000);
    expect(cats[ExpenseCategory.gear], 30000);

    final week = store.last7Days();
    expect(week.length, 7);
    expect(week.last.value, 180000);
    expect(week.first.value, 0);
  });
}
