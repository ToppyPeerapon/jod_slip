# จดสลิป (JodSlip)

บันทึกรายรับ–รายจ่ายจากสลิปโอนเงิน · Track income and expenses from Thai bank transfer slips.

- 🇹🇭 Thai-first UI (Buddhist-year dates, ฿ formatting), English as secondary language
- 📷 Scan slips from Photos (multi-select) or the camera
- 🔒 100% on-device: Apple Vision OCR (Thai + English) + QR reading, SQLite storage — slips never leave the phone
- 🔁 Duplicate detection via the slip's transaction reference (from the slip mini-QR or OCR)
- ↔️ Income vs expense is inferred by matching **your names** (Settings) against the slip's sender/receiver

## Requirements

| Tool | Notes |
|---|---|
| Flutter 3.47+ | `brew install --cask flutter` |
| Xcode 26+ | From the App Store, then `sudo xcode-select -s /Applications/Xcode.app` and `sudo xcodebuild -runFirstLaunch` |
| CocoaPods or SwiftPM | Flutter uses SwiftPM by default; CocoaPods is a fallback (`brew install cocoapods`) |
| iOS 18+ device/simulator | Needed for **Thai** OCR in Apple Vision; older iOS falls back to English-only OCR |

## Run

```bash
flutter pub get
flutter run            # pick an iOS simulator or a connected iPhone
flutter test           # unit + widget tests
flutter analyze
```

## Project structure

```
lib/
  main.dart                     # opens DB/prefs, wires ProviderScope overrides
  app.dart                      # MaterialApp, theme, Thai/English localization
  l10n/app_th.arb               # Thai strings (template) – app_en.arb for English
  core/
    bank/thai_bank.dart         # bank codes + keyword detection
    database/app_database.dart  # SQLite schema & migrations
    formatting/                 # ฿ amounts, Buddhist-year dates, amount input
  features/
    slip_scan/
      domain/                   # PURE DART, fully unit tested
        slip_parser.dart        #   OCR lines → amount/date/parties/bank/ref
        thai_date_parser.dart   #   "12 ต.ค. 69 14:30 น." → DateTime
        slip_qr_payload.dart    #   slip mini-QR (TLV) → transaction ref
        text_line_grouper.dart  #   OCR blocks → visual rows
        transaction_type_resolver.dart  # income vs expense by owner names
        slip_draft.dart         #   a scanned slip awaiting review
      data/                     # SlipRecognizer (OCR abstraction), image store
      application/              # SlipImportController: scan → review → save
      presentation/             # scan sheet, review screen
    transactions/               # model, repository (sqflite), home, form
    settings/                   # owner names, language
packages/
  slip_ocr/                     # local Flutter plugin: native OCR + QR
    ios/.../SlipOcrPlugin.swift #   Apple Vision implementation
```

Money is stored as integer **satang** (1 ฿ = 100 satang) to avoid floating-point errors.

## How slip reading works

1. `slip_ocr` (native) returns text blocks with bounding boxes plus any QR payloads.
2. `groupIntoLines` merges blocks on the same visual row so "จำนวน:" and "1,500.00 บาท" end up on one line.
3. `SlipParser` extracts the fields with bank-agnostic heuristics (labelled amounts, fee/balance exclusion, Thai month abbreviations, titled names, etc.).
4. The slip mini-QR (Bank of Thailand format) gives a reliable transaction ref + sending bank when present.
5. The user reviews every draft before saving; drafts missing an amount or already saved are flagged.

To support a new slip layout, add its OCR lines as a case in `test/features/slip_scan/domain/slip_parser_test.dart` first, then adjust the parser.

## Android (planned)

The app code is platform-neutral; only `packages/slip_ocr` needs an Android implementation:

1. `flutter create --template=plugin --platforms=android .` inside `packages/slip_ocr`
2. Implement the same `recognize` method channel contract (`{blocks: [{text,left,top,width,height}], barcodes: [String]}`, normalised top-left boxes).
   - QR: ML Kit Barcode Scanning
   - Thai text: ML Kit Text Recognition does **not** support Thai — use Tesseract (`tha` traineddata) or a server-side OCR
3. Add camera/photo permissions to `AndroidManifest.xml`.

## Ideas / next steps

- Auto-import new slips from the banking app's Photos album
- Charts by category, monthly budgets
- Export CSV / Excel
- iCloud backup / cloud sync
