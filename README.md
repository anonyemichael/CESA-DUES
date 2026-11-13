# ACES DUES

Dues management for the **Association of Computer Engineering Students (ACES)**, Department of
Electrical & Computer Engineering, School of Engineering, University of Energy and Natural
Resources (UENR), Sunyani.

Students pay association dues with mobile money or card, get a digital receipt and a QR clearance
pass. The Financial Secretary manages the roster, dues, announcements and reports. The Head of
Department has a read-only view.

> Design, research and the full change list are in
> [`docs/UENR_COMPUTER_ENGINEERING_PLAN.md`](docs/UENR_COMPUTER_ENGINEERING_PLAN.md).
> Deployment steps and the verification log are in [`HANDOFF.md`](HANDOFF.md).

## Structure

| Path | What it is |
|---|---|
| `cesa_dues_core/` | Shared package: models, repositories, constants (all brand strings live in `app_constants.dart`). |
| `cesa_dues_student/` | Student app (Flutter: Android and web). |
| `cesa_dues_admin/` | Admin app for the Financial Secretary and HOD (Flutter: Android and web). |
| `functions/` | Firebase Cloud Functions (TypeScript): admin login, Paystack payments, ID verification, notifications. |
| `firestore.rules`, `storage.rules` | Security rules, covered by `functions/test`. |
| `branding/` | Master ACES logo. |

Folder, package and Firebase project names still say `cesa_dues`; they were kept so existing
installs, Google sign-in and data keep working.

## Identity

* Logo: the ACES crest in `branding/aces_logo.png`.
* Colours: crest navy `#0A2A52` on white, with the semantic green, amber and red for payment status.
* Receipts and references: `ACES-<year>-<id>`.

## Security model

* Students sign in with Google and can see only their own record, payments, receipts and messages.
* Admins sign in with an e-mailed one-time code. Only e-mails listed in the function settings can
  sign in; the Head of Department is read-only.
* Payments and receipts are written only by Cloud Functions after Paystack confirms the amount.
* ID photos are private to the student and admins. A student ID is auto-verified only when the
  index number is read from the card; otherwise it waits for the Financial Secretary.

## Develop

```bash
flutter pub get                       # from the repo root (Dart workspace)
flutter analyze
(cd cesa_dues_student && flutter test)
(cd cesa_dues_admin && flutter test)

cd functions
npm install
npm run build                         # type-check and compile
npm run test:rules                    # security rules against the Firebase emulators
```

## Build and deploy

See [`HANDOFF.md`](HANDOFF.md). In short: configure `functions/.env` and the Paystack secret,
install the Trigger Email extension, then `firebase deploy --only firestore,storage,functions`
and build the two apps.

## Releases

The GitHub release page still holds the earlier Civil-branded APKs. Build new ones with
`flutter build apk --release --split-per-abi` in each app and publish them as a new release.
