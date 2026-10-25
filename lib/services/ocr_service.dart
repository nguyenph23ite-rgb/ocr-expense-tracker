import 'dart:io';

import 'receipt_parser.dart';

class OcrResult {
  final String rawText;
  final ParsedReceipt parsed;
  final Duration elapsed;
  const OcrResult(this.rawText, this.parsed, this.elapsed);
}

/// Thrown when Tesseract is missing or fails; the message is user-facing.
class OcrException implements Exception {
  final String message;
  const OcrException(this.message);
  @override
  String toString() => message;
}

/// Offline OCR through the system `tesseract` binary (Apache-2.0).
///
/// Nothing leaves the machine. Install on Fedora with:
///   sudo dnf install tesseract tesseract-langpack-vie
class OcrService {
  OcrService({this.executable = 'tesseract'});

  final String executable;
  final _parser = ReceiptParser();

  /// Picks the language argument: Vietnamese + English when available,
  /// otherwise whatever subset is installed. Returns null if neither exists.
  static String? chooseLanguages(Iterable<String> installed) {
    final set = installed.map((e) => e.trim()).toSet();
    final wanted = [
      if (set.contains('vie')) 'vie',
      if (set.contains('eng')) 'eng',
    ];
    return wanted.isEmpty ? null : wanted.join('+');
  }

  Future<List<String>> _installedLanguages() async {
    final ProcessResult r;
    try {
      r = await Process.run(executable, ['--list-langs']);
    } on ProcessException {
      throw const OcrException(
          'Tesseract not found. Install it: sudo dnf install tesseract tesseract-langpack-vie');
    }
    if (r.exitCode != 0) {
      throw OcrException('tesseract --list-langs failed: ${r.stderr}');
    }
    // First line is a header ("List of available languages ...").
    return (r.stdout as String).split('\n').skip(1).toList();
  }

  Future<OcrResult> scan(File image) async {
    final sw = Stopwatch()..start();
    final lang = chooseLanguages(await _installedLanguages());
    if (lang == null) {
      throw const OcrException(
          'No Tesseract language data. Install: sudo dnf install tesseract-langpack-vie tesseract-langpack-eng');
    }
    // --psm 6: assume a uniform block of text (one visual row per line),
    // which suits receipts. Arguments are passed as a list: no shell involved.
    final r = await Process.run(
        executable, [image.path, 'stdout', '-l', lang, '--psm', '6']);
    if (r.exitCode != 0) {
      throw OcrException('Tesseract failed: ${r.stderr}');
    }
    final raw = r.stdout as String;
    sw.stop();
    return OcrResult(raw, _parser.parse(raw), sw.elapsed);
  }

  void dispose() {}
}
