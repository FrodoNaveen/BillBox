# BillBox

Keep your bills, warranties and important documents in one place — and get reminded before anything expires.

**Capture once → get reminded at the right time → find it in seconds.**

## The problem

"I had it somewhere, and I forgot when it expires."

People lose purchase bills before a warranty claim, and miss renewals for insurance, the pollution certificate (PUC), their licence, passport and rent agreement. BillBox is an offline-first Flutter app that fixes this with a photo, some OCR and a few well-timed notifications.

## Who it's for

| User | What they track |
| --- | --- |
| Working professional | Gadget bills and warranty alerts; PAN/Aadhaar/passport for KYC; insurance and tax-filing reminders |
| Homemaker | Appliance bills (fridge, AC, washing machine); AC service, purifier filter and gas booking reminders; kids' fee receipts and vaccination records |
| Vehicle owner | Insurance, PUC and service reminders; RC and licence on the phone; tyre and battery warranties |
| Elderly parents (managed by their children) | Pension papers, health policies, FD maturity dates |
| Tenant / landlord | Rent agreement (usually 11 months) expiry reminders; tenant documents |
| Freelancer / small shop owner | GST invoices; shop, trade and FSSAI licences; AMC and domain renewals |
| Student | Marksheets and certificates; exam and scholarship deadlines |

## MVP scope (v1)

1. **Add item** — take a photo or pick from the gallery, with title, category, purchase/issue date and expiry/warranty-end date
2. **OCR auto-fill** — on-device text recognition suggests the date, amount and store/product; the user confirms or edits
3. **Reminders** — local notifications before expiry (default 30 days, 7 days and 1 day before; configurable)
4. **Home dashboard** — "Expiring soon" on top, then all items grouped by category
5. **Search and filter** — by title, category and OCR text
6. **Item detail** — full-screen image viewer, edit, delete, share image

**Categories:** Electronics · Appliances · Vehicle · Identity Docs · Insurance · Home/Rent · Health · Education · Business · Other

## Later (not in v1)

- Cloud backup (AWS S3) and sign-in
- Family/shared vault with shared reminders
- Recurring items (AC service every 6 months, gas booking)
- Multiple language UI (Tamil, Hindi)
- App lock (PIN/biometric)
- Export to PDF

## Tech stack

| Area | Choice |
| --- | --- |
| Framework | Flutter (Dart), Android first, iOS later |
| State management | Provider |
| Local database | sqflite / Drift — offline-first, no backend in v1 |
| OCR | `google_mlkit_text_recognition` (on-device) |
| Camera / gallery | `image_picker` |
| Notifications | `flutter_local_notifications` + `timezone` |
| Image storage | App documents directory via `path_provider` |

### Architecture

Feature-first folders with a repository layer between the UI and the database:

```
lib/
  core/                 # shared utilities, theme, constants
  features/
    items/              # add, list, detail, edit
    reminders/          # scheduling and notification handling
```

## Getting started

Requires the Flutter SDK (Dart `^3.9.0`).

```bash
flutter pub get
flutter run
```

## Status

Early development — initial Flutter project set up, features landing one at a time.
