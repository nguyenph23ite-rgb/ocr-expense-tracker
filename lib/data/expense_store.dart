import 'package:flutter/foundation.dart';

import '../models/expense.dart';
import 'expense_database.dart';

/// App-wide state holder. UI listens via ListenableBuilder.
class ExpenseStore extends ChangeNotifier {
  ExpenseStore({ExpenseDatabase? database})
      : _db = database ?? ExpenseDatabase.instance;
  final ExpenseDatabase _db;
  List<Expense> expenses = [];

  Future<void> load() async {
    expenses = await _db.all();
    notifyListeners();
  }

  Future<void> add(Expense e) async {
    await _db.insert(e);
    await load();
  }

  Future<void> edit(Expense e) async {
    await _db.update(e);
    await load();
  }

  Future<void> remove(Expense e) async {
    if (e.id != null) await _db.delete(e.id!);
    await load();
  }

  /// Total per category (for the donut chart).
  Map<ExpenseCategory, int> totalsByCategory({DateTime? from, DateTime? to}) {
    final map = {for (final c in ExpenseCategory.values) c: 0};
    for (final e in expenses) {
      if (from != null && e.date.isBefore(from)) continue;
      if (to != null && !e.date.isBefore(to)) continue;
      map[e.category] = map[e.category]! + e.amountVnd;
    }
    return map;
  }

  /// Spending for each of the last 7 days, oldest first (for the bar chart).
  List<MapEntry<DateTime, int>> last7Days() {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day)
        .subtract(const Duration(days: 6));
    return List.generate(7, (i) {
      final day = start.add(Duration(days: i));
      final next = day.add(const Duration(days: 1));
      final sum = expenses
          .where((e) => !e.date.isBefore(day) && e.date.isBefore(next))
          .fold<int>(0, (s, e) => s + e.amountVnd);
      return MapEntry(day, sum);
    });
  }
}
