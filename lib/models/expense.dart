import 'package:flutter/material.dart';

enum ExpenseCategory { food, study, travel, gear, entertainment }

extension ExpenseCategoryX on ExpenseCategory {
  String get label => switch (this) {
        ExpenseCategory.food => 'Food',
        ExpenseCategory.study => 'Study',
        ExpenseCategory.travel => 'Travel',
        ExpenseCategory.gear => 'Gear',
        ExpenseCategory.entertainment => 'Entertainment',
      };

  Color get color => switch (this) {
        ExpenseCategory.food => const Color(0xFFEF6C57),
        ExpenseCategory.study => const Color(0xFF4C8BF5),
        ExpenseCategory.travel => const Color(0xFF2BB673),
        ExpenseCategory.gear => const Color(0xFFF2A93B),
        ExpenseCategory.entertainment => const Color(0xFF9B6BE8),
      };

  IconData get icon => switch (this) {
        ExpenseCategory.food => Icons.restaurant,
        ExpenseCategory.study => Icons.menu_book,
        ExpenseCategory.travel => Icons.directions_bus,
        ExpenseCategory.gear => Icons.devices_other,
        ExpenseCategory.entertainment => Icons.movie,
      };
}

class Expense {
  final int? id;
  final String merchant;
  final int amountVnd; // stored as whole VND
  final DateTime date;
  final ExpenseCategory category;
  final String? thumbnailPath;
  final String? note;

  const Expense({
    this.id,
    required this.merchant,
    required this.amountVnd,
    required this.date,
    required this.category,
    this.thumbnailPath,
    this.note,
  });

  Expense copyWith({
    int? id,
    String? merchant,
    int? amountVnd,
    DateTime? date,
    ExpenseCategory? category,
    String? thumbnailPath,
    String? note,
  }) =>
      Expense(
        id: id ?? this.id,
        merchant: merchant ?? this.merchant,
        amountVnd: amountVnd ?? this.amountVnd,
        date: date ?? this.date,
        category: category ?? this.category,
        thumbnailPath: thumbnailPath ?? this.thumbnailPath,
        note: note ?? this.note,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'merchant': merchant,
        'amount_vnd': amountVnd,
        'date': date.millisecondsSinceEpoch,
        'category': category.name,
        'thumbnail_path': thumbnailPath,
        'note': note,
      };

  factory Expense.fromMap(Map<String, Object?> m) => Expense(
        id: m['id'] as int?,
        merchant: m['merchant'] as String,
        amountVnd: m['amount_vnd'] as int,
        date: DateTime.fromMillisecondsSinceEpoch(m['date'] as int),
        category: ExpenseCategory.values.byName(m['category'] as String),
        thumbnailPath: m['thumbnail_path'] as String?,
        note: m['note'] as String?,
      );
}
