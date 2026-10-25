# OCR Expense Tracker & Receipt Parser

Flutter app that scans paper receipts **fully offline** (Tesseract OCR), extracts the
total, date and merchant with a custom regex heuristic parser, stores expenses in SQLite, and visualises
them with hand-drawn `CustomPainter` charts (no chart libraries).

## Features (checklist)

- [ ] Live camera viewfinder / crop overlay: **removed on Linux** (no `camera` plugin for desktop); image import via file chooser instead
- [x] On-device OCR with Tesseract (no network, no cloud cost)
- [x] Heuristic parser: totals (`150,000 VND`, `150.000 đ`, `1.250.000`), dates (`DD/MM/YYYY`, `DD-MM-YY`), merchant, auto category guess
- [x] Interactive review screen: every field editable before saving
- [x] SQLite persistence (`sqflite_common_ffi`), categories: Food, Study, Travel, Gear, Entertainment
- [x] Receipt thumbnails cached in the app documents directory
- [x] Animated donut chart (tap a slice to highlight) via `CustomPainter`
- [x] Animated weekly bar chart (tap a bar to see its value) via `CustomPainter`
- [x] Edit / swipe-to-delete transactions
- [x] Unit tests for the parser

## Architecture

```
lib/
  main.dart                    app entry, theme
  models/expense.dart          Expense + ExpenseCategory (label, colour, icon)
  data/
    expense_database.dart      sqflite CRUD
    expense_store.dart         ChangeNotifier state + aggregations for charts
  services/
    receipt_parser.dart        pure-Dart regex heuristics (unit-testable)
    ocr_service.dart           Tesseract CLI wrapper -> raw text -> parser
    image_service.dart         crop to frame, thumbnail caching
  screens/
    home_screen.dart           Insights (charts) + Transactions tabs
    capture_screen.dart        image import (file chooser)
    review_screen.dart         OCR results, manual edit, save
  widgets/
    donut_chart.dart           CustomPainter donut + animation + hit testing
    weekly_bar_chart.dart      CustomPainter bars + animation + selection
test/receipt_parser_test.dart
```

Flow: `CaptureScreen` -> crop -> `ReviewScreen` (runs `OcrService` -> `ReceiptParser`) -> user edits -> `ExpenseStore.add` -> SQLite -> charts rebuild.

## Setup (Fedora Workstation, Linux desktop)

Everything runs locally; no cloud service, no proprietary SDK is required by the app.

```bash
# Build toolchain for Flutter Linux desktop
sudo dnf install clang cmake ninja-build pkgconf-pkg-config gtk3-devel
# Runtime: OCR engine (Apache-2.0) + Vietnamese model, SQLite
sudo dnf install tesseract tesseract-langpack-vie tesseract-langpack-eng sqlite-libs
# Optional: silences the `eglinfo` warning in `flutter doctor`
sudo dnf install egl-utils        # check with: dnf provides '*/eglinfo'

cd ocr_expense_tracker
flutter pub get
flutter analyze && flutter test
flutter run -d linux
```

Android SDK and Chrome are **not** needed for desktop builds.

### Linux-specific design choices
| Concern | Before (mobile only) | Now |
|---|---|---|
| OCR | Google ML Kit (proprietary, Android/iOS only) | `tesseract` CLI (Apache-2.0), `vie+eng`, `--psm 6` |
| Database | `sqflite` (no Linux support) | `sqflite_common_ffi` + system `libsqlite3` |
| Input | `camera` plugin (no Linux support) | native file chooser via `image_picker_linux` |

## Licences
Tesseract, its traineddata and Leptonica: Apache-2.0 / BSD-2. SQLite: public domain.
`sqflite_common_ffi`, `sqlite3`, `path`, `path_provider`, `image`, `intl`, `image_picker`: BSD/MIT-style.
Flutter and Dart: BSD-3-Clause (note the SDK downloads prebuilt engine binaries; build from source if you need a fully source-built toolchain).

## Parser heuristics

1. **Total**: normalise text (strip Vietnamese diacritics, lowercase). Find lines containing `tong cong`, `thanh toan`, `total`, ...
   and take the largest amount on that line (or the next line if OCR wrapped it). Lines such as `tien khach dua`, `tien thua`, `cash`, `VAT` are ignored.
   Fallback: largest plausible amount (1,000 - 100,000,000 VND).
2. **Date**: first valid `DD/MM/YYYY` (also `-` and `.` separators, 2-digit years); rejects impossible dates (31/02) and future dates.
3. **Merchant**: first of the top 6 lines that is mostly letters and is not an address / phone / "HOA DON" header.
4. **Category**: keyword scoring against merchant names (Coopmart, Grab, Fahasa, CGV, ...).

Extend the keyword lists in `receipt_parser.dart` for more merchants.

## Known limitations

- Printed thermal receipts work best; crumpled or faded paper reduces accuracy (hence the manual review step).
- Vietnamese accuracy depends on the Tesseract `vie` model and image quality; the parser strips diacritics before matching to compensate. Not yet measured on real receipts.
- The weekly chart shows the last 7 days; the donut shows the current month.
