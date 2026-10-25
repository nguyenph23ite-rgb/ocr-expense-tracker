import '../models/expense.dart';

/// Result of parsing raw OCR text. Any field may be null if not found.
class ParsedReceipt {
  final int? totalVnd;
  final DateTime? date;
  final String? merchant;
  final ExpenseCategory suggestedCategory;

  const ParsedReceipt({
    this.totalVnd,
    this.date,
    this.merchant,
    this.suggestedCategory = ExpenseCategory.food,
  });
}

/// Pure-Dart heuristic parser (no Flutter/ML Kit dependency => unit-testable).
class ReceiptParser {
  // Keywords that usually sit on the grand-total line (accent-stripped, lowercase).
  static const _totalKeywords = [
    'tong cong',
    'tong tien',
    'tong thanh toan',
    'thanh toan',
    'tong so tien',
    'total',
    'grand total',
    'amount due',
    'phai tra',
  ];

  // Lines to ignore when hunting for the total.
  static const _ignoreKeywords = [
    'tien khach dua',
    'tien thua',
    'tien mat',
    'cash',
    'change',
    'vat',
    'thue',
    'giam gia',
    'discount',
  ];

  // Money: 150,000 | 150.000 | 1.250.000 | 150000 with optional currency suffix.
  static final _money = RegExp(
    r'(?<![\d.,])(\d{1,3}(?:[.,]\d{3})+|\d{4,9})(?![\d])\s*(?:vnd|vnđ|đ|d|₫)?',
    caseSensitive: false,
  );

  // Dates: DD/MM/YYYY, DD-MM-YYYY, DD.MM.YYYY, also 2-digit years.
  static final _date = RegExp(r'\b(\d{1,2})[/\-.](\d{1,2})[/\-.](\d{4}|\d{2})\b');

  ParsedReceipt parse(String rawText) {
    final lines = rawText
        .split(RegExp(r'\r?\n'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    final merchant = _findMerchant(lines);
    return ParsedReceipt(
      totalVnd: _findTotal(lines),
      date: _findDate(rawText),
      merchant: merchant,
      suggestedCategory: _guessCategory('${merchant ?? ''}\n$rawText'),
    );
  }

  // ---------------------------------------------------------------- total

  int? _findTotal(List<String> lines) {
    // Pass 1: amounts on (or just after) a "total" keyword line.
    for (var i = 0; i < lines.length; i++) {
      final norm = stripDiacritics(lines[i]).toLowerCase();
      if (_ignoreKeywords.any(norm.contains)) continue;
      if (!_totalKeywords.any(norm.contains)) continue;

      final onLine = _amountsIn(lines[i]);
      if (onLine.isNotEmpty) return onLine.reduce((a, b) => a > b ? a : b);

      // Amount sometimes wrapped to the next line by OCR.
      if (i + 1 < lines.length) {
        final next = _amountsIn(lines[i + 1]);
        if (next.isNotEmpty) return next.first;
      }
    }

    // Pass 2 fallback: the largest plausible amount on the receipt.
    final all = <int>[];
    for (final l in lines) {
      final norm = stripDiacritics(l).toLowerCase();
      if (_ignoreKeywords.any(norm.contains)) continue;
      all.addAll(_amountsIn(l));
    }
    if (all.isEmpty) return null;
    return all.reduce((a, b) => a > b ? a : b);
  }

  List<int> _amountsIn(String line) {
    final out = <int>[];
    // Skip lines that look like phone numbers or pure dates.
    if (_date.hasMatch(line) && !RegExp(r'[.,]\d{3}\b').hasMatch(line)) {
      return out;
    }
    for (final m in _money.allMatches(line)) {
      final digits = m.group(1)!.replaceAll(RegExp(r'[.,]'), '');
      final v = int.tryParse(digits);
      // Plausible receipt range: 1,000 VND .. 100,000,000 VND.
      if (v != null && v >= 1000 && v <= 100000000) out.add(v);
    }
    return out;
  }

  // ----------------------------------------------------------------- date

  DateTime? _findDate(String text) {
    for (final m in _date.allMatches(text)) {
      final d = int.parse(m.group(1)!);
      final mo = int.parse(m.group(2)!);
      var y = int.parse(m.group(3)!);
      if (y < 100) y += 2000;
      if (mo < 1 || mo > 12 || d < 1 || d > 31) continue;
      final dt = DateTime(y, mo, d);
      if (dt.month != mo) continue; // e.g. 31/02 rolled over
      if (y < 2000 || dt.isAfter(DateTime.now().add(const Duration(days: 1)))) {
        continue;
      }
      return dt;
    }
    return null;
  }

  // ------------------------------------------------------------- merchant

  String? _findMerchant(List<String> lines) {
    // Merchant name is almost always in the first few lines, mostly letters.
    for (final l in lines.take(6)) {
      final norm = stripDiacritics(l).toLowerCase();
      if (norm.length < 3) continue;
      if (RegExp(r'^(hoa don|phieu|receipt|invoice|bill|ban hang)').hasMatch(norm)) {
        continue;
      }
      if (RegExp(r'(dia chi|address|dt:|tel|sdt|mst|ma so thue|www\.|http)').hasMatch(norm)) {
        continue;
      }
      final letters = RegExp(r'[A-Za-zÀ-ỹ]').allMatches(l).length;
      if (letters / l.length < 0.6) continue; // mostly digits/symbols => skip
      return _titleCase(l);
    }
    return null;
  }

  String _titleCase(String s) => s
      .split(' ')
      .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1).toLowerCase())
      .join(' ');

  // ------------------------------------------------------------- category

  ExpenseCategory _guessCategory(String text) {
    final t = stripDiacritics(text).toLowerCase();
    const rules = <ExpenseCategory, List<String>>{
      ExpenseCategory.food: [
        'coop', 'winmart', 'bach hoa', 'circle k', 'family mart', 'highlands',
        'starbucks', 'pho', 'com ', 'cafe', 'coffee', 'tra sua', 'restaurant',
        'quan an', 'kfc', 'lotte', 'bigc', 'go!', 'aeon', 'mart',
      ],
      ExpenseCategory.study: [
        'nha sach', 'fahasa', 'book', 'van phong pham', 'stationery',
        'photocopy', 'in an', 'hoc phi', 'course',
      ],
      ExpenseCategory.travel: [
        'grab', 'be group', 'xanh sm', 'taxi', 'xe buyt', 'bus', 've tau',
        'vietnam airlines', 'vietjet', 'xang', 'petrolimex',
      ],
      ExpenseCategory.gear: [
        'the gioi di dong', 'fpt shop', 'dien may', 'cellphones', 'laptop',
        'phu kien', 'apple', 'samsung', 'logitech',
      ],
      ExpenseCategory.entertainment: [
        'cgv', 'lotte cinema', 'galaxy cinema', 'bhd', 'cinema', 'karaoke',
        'game', 'netflix', 'spotify', 'steam',
      ],
    };
    ExpenseCategory best = ExpenseCategory.food;
    var bestScore = 0;
    rules.forEach((cat, words) {
      final score = words.where(t.contains).length;
      if (score > bestScore) {
        bestScore = score;
        best = cat;
      }
    });
    return best;
  }

  // ---------------------------------------------------------------- utils

  /// Removes Vietnamese diacritics so "TỔNG CỘNG" matches "tong cong".
  static String stripDiacritics(String s) {
    const from =
        'àáảãạăằắẳẵặâầấẩẫậèéẻẽẹêềếểễệìíỉĩịòóỏõọôồốổỗộơờớởỡợùúủũụưừứửữựỳýỷỹỵđ'
        'ÀÁẢÃẠĂẰẮẲẴẶÂẦẤẨẪẬÈÉẺẼẸÊỀẾỂỄỆÌÍỈĨỊÒÓỎÕỌÔỒỐỔỖỘƠỜỚỞỠỢÙÚỦŨỤƯỪỨỬỮỰỲÝỶỸỴĐ';
    const to =
        'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd'
        'AAAAAAAAAAAAAAAAAEEEEEEEEEEEIIIIIOOOOOOOOOOOOOOOOOUUUUUUUUUUUYYYYYD';
    final buf = StringBuffer();
    for (final ch in s.runes) {
      final c = String.fromCharCode(ch);
      final i = from.indexOf(c);
      buf.write(i >= 0 ? to[i] : c);
    }
    return buf.toString();
  }
}
