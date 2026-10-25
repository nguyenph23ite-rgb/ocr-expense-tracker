# Mini-Project 3 Report Outline (2-4 pages) — fill in with your own screenshots

**Title:** OCR Expense Tracker & Receipt Parser (Flutter & Dart)
**Student:** <name> · <ID> · <class> · **Repo:** <url> · **Demo:** <url or video link>

## 1. Feature checklist (table)
| Requirement | Status | Where |
|---|---|---|
| Camera viewfinder, flash, tap focus, crop frame | Done | `capture_screen.dart` |
| On-device ML Kit OCR | Done | `ocr_service.dart` |
| Regex parser: total / date / merchant | Done | `receipt_parser.dart` |
| Interactive review & edit | Done | `review_screen.dart` |
| SQLite + 5 categories | Done | `expense_database.dart` |
| Thumbnail caching | Done | `image_service.dart` |
| Animated donut + weekly bar (CustomPainter) | Done | `widgets/` |

## 2. Architecture
- Insert the layer diagram: UI (screens/widgets) -> ExpenseStore (ChangeNotifier) -> ExpenseDatabase (sqflite); services: OcrService, ReceiptParser, ImageService.
- Explain why ReceiptParser is pure Dart (unit-testable without the camera).

## 3. Receipt parsing approach
- Diacritic normalisation, keyword anchoring for totals, ignore-list, fallback to largest amount.
- Date validation rules. Merchant selection rule. Category scoring.
- Table of 5-6 test receipts: input snippet, expected, result. (Run `flutter test`.)

## 4. CustomPainter charts
- Donut: arc drawing, clockwise reveal animation, tap hit-testing with atan2.
- Bar chart: nice-max axis scaling, animated heights, tap selection.

## 5. Screenshots (6 recommended)
Home/Insights, Transactions, Camera with frame, Review (after OCR), Edit, Donut with selected slice.

## 6. Challenges & limitations
Vietnamese diacritics in ML Kit Latin model, glare/crumple, thousands separators (`.` vs `,`), future work (VAT lines, line items, export CSV).

## 7. Measured OCR time
Report the "OCR finished in N ms" values shown in the review screen on your device (the brief targets sub-100 ms; real timing depends on the phone and image size — report your measured numbers honestly).
