# ACES DUES: Handoff and Deployment Guide

ACES DUES is the dues system of the Association of Computer Engineering Students, UENR. This file
is the checklist for taking it to production and records what was verified.

## Architecture

* `cesa_dues_core`: shared models, repositories and constants.
* `cesa_dues_student`: students' app. `cesa_dues_admin`: Financial Secretary and HOD app.
* `functions/`: Cloud Functions for admin login, Paystack, ID verification and push notifications.
* `firestore.rules`, `storage.rules`: security rules. Tests are in `functions/test`.

## Deployment checklist

### 1. Configure the backend
1. Copy `functions/.env.example` to `functions/.env` and set the real e-mails:
   ```
   ADMIN_HOD_EMAILS=hod@...
   ADMIN_FINSEC_EMAILS=finsec@...
   ```
   An e-mail on neither list cannot sign in to the admin app.
2. Set secrets (Blaze plan required):
   ```bash
   firebase functions:secrets:set PAYSTACK_SECRET_KEY
   firebase functions:secrets:set CLEANUP_TOKEN   # optional; omit to keep cleanDatabase disabled
   ```
3. Install the **Trigger Email from Firestore** extension and point it at the `mail` collection.
   Admin one-time codes are delivered through it.
4. Enable Authentication providers: **Google** (students). Admins use custom tokens issued by the
   `verifyAdminLogin` function, so no password or e-mail-link provider is needed.
5. Enable the Cloud Vision API if you want automatic ID reading. Without it, every ID goes to
   manual approval.

### 2. Deploy
```bash
cd functions && npm install && npm run build && cd ..
firebase deploy --only firestore,storage,functions
```
The rules now reject anonymous and cross-student access. Ship the new app builds together with, or
before, the rules; older builds read notifications and upload ID photos in ways the new rules
refuse.

### 3. Paystack
Set the webhook URL in the Paystack dashboard to the deployed `webhookPaystack` function.

### 4. Seed and configure dues
`cd functions && node seed.js` creates two **placeholder** dues. Set the real amounts in the admin
app (Dues) and archive the placeholders.

### 5. Build the apps
```bash
cd cesa_dues_student && flutter build apk --release --split-per-abi
cd ../cesa_dues_admin && flutter build apk --release --split-per-abi
```
Create `android/key.properties` for release signing in each app (not committed). For web:
`flutter build web --release`, then `firebase deploy --only hosting`.

### 6. Publish
Publish the new APKs as a GitHub release; the existing release holds the old Civil-branded builds.

## Roles

| Role | Can do |
|---|---|
| Student | Own profile, ID upload, pay dues, view own receipts and messages |
| Financial Secretary | Manage roster, approve IDs, create dues, send announcements, reports |
| Head of Department | Read-only view of students, dues and reports |

## Maintenance
* Change a name or wording: `cesa_dues_core/lib/src/constants/app_constants.dart` and
  `functions/src/brand.ts`.
* Change colours: `app/theme/app_colors.dart` in each app.
* Change data structures: models in `cesa_dues_core/lib/src/models`, then update the rules and
  `functions/test/firestore.rules.test.ts`.

## Verification log (2026-11-12)

Run in a cloud build container with Flutter 3.50.0 and Node 22.

| Check | Result |
|---|---|
| `flutter analyze` (whole workspace) | No errors. 117 info and warning findings remain, all in code that predates this change (it was 124 before). |
| Dart widget and unit tests: student, admin, core | All pass |
| `tsc` type-check of `functions/` | Clean |
| Security rules tests against the Firestore and Storage emulators | 22 of 22 pass |
| `flutter build web --release`, student and admin | Both build successfully |
| Student login screen rendered with real fonts in a Flutter test | Crest, navy gradient, text and footer display correctly |

**Not verified:**
* Nothing was run against live Firebase, Paystack, Cloud Vision or the e-mail extension. The
  payment, ID-verification and admin-login functions compile and their rules are tested, but their
  runtime behaviour has not been exercised end to end.
* Android APKs were not built (no Android SDK in the build container).
* Only the student login screen was viewed visually. The other screens and the admin app were
  recoloured and rebuilt but not looked at, because the web apps cannot start in the build
  container (the Firebase web SDK loads from a blocked CDN) and no device was available.
* UENR, ELEESA and GESA web pages could not be opened from the build container, so department and
  association facts come from search summaries and should be confirmed.
