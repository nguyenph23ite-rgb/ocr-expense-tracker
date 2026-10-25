# OCR Expense Tracker

A Flutter desktop app for extracting expense details from receipt images and tracking expenses locally.

## Features

- Offline OCR with Tesseract
- Regex-based extraction of merchant, date, and total amount
- Review and edit extracted details before saving
- Local SQLite storage and expense categories
- Donut and weekly spending charts built with `CustomPainter`

## Requirements

- Flutter SDK
- Tesseract OCR with English and Vietnamese language data
- Linux desktop build dependencies

On Fedora:

```bash
sudo dnf install clang cmake ninja-build pkgconf-pkg-config gtk3-devel \
  tesseract tesseract-langpack-eng tesseract-langpack-vie
```

## Run

```bash
flutter pub get
flutter run -d linux
```

## Test

```bash
flutter analyze
flutter test
```
