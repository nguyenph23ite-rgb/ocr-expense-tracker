import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ocr_expense_tracker/services/ocr_service.dart';

void main() {
  test('prefers Vietnamese + English when both installed', () {
    expect(OcrService.chooseLanguages(['eng', 'osd', 'vie', '']), 'vie+eng');
  });
  test('falls back to English only', () {
    expect(OcrService.chooseLanguages(['eng', 'osd']), 'eng');
  });
  test('returns null when no usable language', () {
    expect(OcrService.chooseLanguages(['osd', '']), isNull);
  });
  test('reports a clear error when the binary is missing', () async {
    final svc = OcrService(executable: '/nonexistent/tesseract');
    expect(svc.scan(File('receipt.png')), throwsA(isA<OcrException>()));
  });
}
