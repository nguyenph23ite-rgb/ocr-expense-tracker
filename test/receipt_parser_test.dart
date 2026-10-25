import 'package:flutter_test/flutter_test.dart';
import 'package:ocr_expense_tracker/models/expense.dart';
import 'package:ocr_expense_tracker/services/receipt_parser.dart';

void main() {
  final parser = ReceiptParser();

  test('parses dot-separated total with đ suffix', () {
    const text = '''
SIEU THI COOPMART
Dia chi: 123 Nguyen Van Linh
Ngay: 15/10/2026 18:42
Sua tuoi        32.000
Banh mi         18.000
TONG CỘNG       150.000 đ
Tien khach dua  200.000
Tien thua        50.000
''';
    final r = parser.parse(text);
    expect(r.totalVnd, 150000);
    expect(r.date, DateTime(2026, 10, 15));
    expect(r.merchant, 'Sieu Thi Coopmart');
    expect(r.suggestedCategory, ExpenseCategory.food);
  });

  test('parses comma-separated total with VND suffix', () {
    const text = 'HIGHLANDS COFFEE\n05-09-2026\nTotal 1,250,000 VND\nCash 1,300,000';
    final r = parser.parse(text);
    expect(r.totalVnd, 1250000);
    expect(r.date, DateTime(2026, 9, 5));
  });

  test('falls back to largest amount when no keyword', () {
    const text = 'NHA SACH FAHASA\n20/10/2026\nSach       85.000\nBut        15.000\n100.000';
    final r = parser.parse(text);
    expect(r.totalVnd, 100000);
    expect(r.suggestedCategory, ExpenseCategory.study);
  });

  test('amount wrapped to next line', () {
    const text = 'GRAB\nTong tien\n68.000';
    expect(parser.parse(text).totalVnd, 68000);
  });

  test('rejects impossible dates', () {
    const text = 'SHOP\n31/02/2026\nTong cong 50.000';
    expect(parser.parse(text).date, isNull);
  });

  test('two-digit year', () {
    const text = 'SHOP\n03/11/25\nTong cong 50.000';
    expect(parser.parse(text).date, DateTime(2025, 11, 3));
  });

  test('missing everything returns nulls', () {
    final r = parser.parse('');
    expect(r.totalVnd, isNull);
    expect(r.date, isNull);
    expect(r.merchant, isNull);
  });
}
