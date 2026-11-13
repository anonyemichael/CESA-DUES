# ACES DUES: Rebrand and Completion Plan

_Association of Computer Engineering Students (ACES), University of Energy and Natural Resources (UENR), Sunyani_
_Last updated: 2026-11-12_

This document records how the dues system, originally branded for UENR's **Civil** Engineering
association, was redesigned for **UENR Computer Engineering students**, and which unfinished or
unsafe parts of the code were closed in the same pass.

---

## 1. Research

### 1.1 What was found

| Question | Finding | Source |
|---|---|---|
| Who owns BSc Computer Engineering at UENR? | The **Department of Electrical & Computer Engineering**, School of Engineering, UENR, Sunyani. It also offers BSc Electrical & Electronic Engineering. | [UENR academic departments](https://uenr.edu.gh/academic-departments-and-programmes/) |
| Which student body represents Computer Engineering students? | **ACES**, the *Association of Computer Engineering Students*, founded 2021. Its crest was supplied by the project owner and is the identity used here. A separate, older body, **ELEESA** (electrical and electronics students, est. 2014), also lists computer engineers among its members. | Crest image from the owner; [ELEESA page](https://soe.uenr.edu.gh/student-association/eleesa/) |
| What does "CESA" mean on campus? | **Civil** Engineering Students' Association. This is why the old code said "Civil", and it is the reason the name was changed to ACES rather than reinterpreted. | [GESA-UENR: CESA](https://gesauenr.com/clubs/cesa) |
| UENR identity | Crest of a shield, a globe carrying the African Energy Symbol, and a river. UENR describes its colours as yellow, green and brown (resource conservation) with a blue globe. Motto: "Knowledge, Integrity, Impact". | [UENR about us](https://uenr.edu.gh/about-us/) |

### 1.2 Limits of this research

* The build environment blocks the UENR, ELEESA, GESA and Wikipedia hosts, so pages could not be
  opened directly. Facts above come from search-result summaries and should be confirmed with the
  department before being printed anywhere official.
* No published hex codes or brand guide exist for UENR. The colours used by the apps are
  **sampled from the ACES crest itself**, not from the university.
* No logo file could be downloaded. The ACES crest the owner attached is the only logo asset used.

---

## 2. Identity decisions

| Item | Decision |
|---|---|
| Product name | **ACES DUES** |
| Association | Association of Computer Engineering Students (ACES), UENR |
| Programme | BSc. Computer Engineering |
| Department line | Department of Electrical & Computer Engineering, UENR, Sunyani |
| Receipt and payment prefix | `ACES-<year>-<8 hex>`. Receipts issued earlier with the `CESA` prefix stay valid. |
| Package ids, Firebase project, collections | **Unchanged** (`com.cesadues.*`, `cesa-dues-9a267`). Renaming them would break existing installs, Google sign-in and data, and nothing user-facing depends on them. |

Every identity string now comes from one file,
`cesa_dues_core/lib/src/constants/app_constants.dart` (and `functions/src/brand.ts` for the
backend). Renaming the association later means editing those two files.

---

## 3. Visual identity

### 3.1 Logo

The supplied ACES crest (navy gear, laptop with cursor and two cogs, "ACES 2021", "UENR") is used
unchanged as the logo. Processing applied:

* background cleaned to pure white and cropped square;
* a small third-party credit watermark in the bottom-right corner **was removed** so it does not
  appear in the app. Restore it or credit the designer if the owner wants that.

Generated from it: app logo (`assets/images/logo.png`), Android launcher icons for every density
including the adaptive foreground, web icons (192, 512, maskable), and the favicon, for both apps.
The master file is `branding/aces_logo.png`.

The crest has a white background, so it is shown on white or inside a circular badge. For a
transparent or vector version, ask the designer for the original file.

### 3.2 Palette (sampled from the crest)

| Token | Hex | Use |
|---|---|---|
| `primary` ACES navy | `#0A2A52` | Buttons, headers, nav, brand marks. The crest samples at about `#082850`. |
| `primaryLight` | `#163D73` | Gradients, hover |
| `primaryDark` | `#061B36` | Pressed states, dark gradients |
| `textPrimary` | `#0B1F3A` | Headlines and body |
| `accent` | `#1E40AF` | Links and secondary actions (unchanged) |
| `gold` | `#F59E0B` | Small highlights only (unchanged) |
| Surfaces | `#F8FAFC` canvas, `#FFFFFF` cards | Unchanged |
| Status | green `#047857`, amber `#B45309`, red `#B91C1C` | Paid, pending, unpaid. Always paired with an icon or label. |

The earlier slate-navy `#0F172A` family was remapped to the crest navy across both apps, and the
web manifests no longer use the default Flutter blue.

---

## 4. What changed

### Shared core
* New identity constants (name, association, department, school, university, campus, motto,
  programme, receipt prefix, footer).
* Roster defaults no longer say "Civil".
* The client-side `mockPayment`, which wrote receipts from the phone, was removed.
* Notifications are read with two scoped queries (broadcasts for the student's audiences, and
  messages addressed to the student) so the new security rules can verify them.
* ID photos are stored at `idCards/<uid>/id_photo.jpg`.

### Student app
* New palette and logo; login, home, profile, onboarding, dues, receipts and QR screens reworded.
* Removed dead code: a simulated ID scanner that referred to KNUST, a simulated checkout dialog,
  and an unused register screen.
* The invented "GHS 150 annual dues" shown when none were published is gone; an empty state is
  shown instead.
* Payment and ID calls send the signed-in user's Firebase ID token.
* An ID that cannot be read automatically is reported as "sent for manual approval".

### Admin app
* New palette and logo; HOD and Financial Secretary dashboards, login, role selection, import
  default programme, report names and scanner messages updated.
* Login no longer pre-fills a personal e-mail address or shows a test code.
* One-time codes are checked only by the Cloud Function. The client-side `123456` code, the
  Firestore OTP fallback and the anonymous-sign-in fallback were removed.

### Backend
* **Firestore and Storage rules** were fully open (`allow read, write: if true`). They now enforce:
  students see only their own record, payments, receipts and messages; payments, receipts, audit
  logs and OTPs are server-written only; the Head of Department is read-only; only the Financial
  Secretary edits the roster, dues and announcements; ID photos are private to the student and
  admins.
* **Admin login:** allow-lists come from `ADMIN_HOD_EMAILS` and `ADMIN_FINSEC_EMAILS`; any other
  e-mail is refused (previously any e-mail became Financial Secretary). Codes are stored hashed,
  expire after 15 minutes, allow 5 attempts, and can be re-requested after 60 seconds. The master
  code `123456` and the `debugOtp` response field were removed.
* **Payments:** callers must be signed in; the student, amount and dues are read from Firestore,
  not from the request; the student must have a verified ID and must not have paid already; the
  Paystack amount and currency are checked; receipts are issued exactly once even if the webhook
  and the verify call race; webhook signatures are checked against the raw body. The hard-coded
  secret fallback and the fake checkout URL used when Paystack failed were removed.
* **ID verification:** reads the photo from Storage (no arbitrary URL fetch), requires sign-in, and
  auto-approves only when the student's index number is found on the card. Anything else goes to
  manual review. Previously an unreadable photo, or any photo containing the word "student", was
  approved.
* `cleanDatabase`, which wiped payments on any request, now needs POST plus a secret token and is
  disabled unless `CLEANUP_TOKEN` is set.
* Payment notifications now show cedis, not pesewas. Notification triggers that existed but were
  never exported are now deployed.
* Seed script and email copy rebranded.

---

## 5. Still manual (needs the Firebase console or the department)

1. Create `functions/.env` from `functions/.env.example` with the real HOD and Financial Secretary
   e-mails.
2. Set secrets: `firebase functions:secrets:set PAYSTACK_SECRET_KEY` (and optionally
   `CLEANUP_TOKEN`).
3. Install the **Trigger Email from Firestore** extension, or admins will never receive codes.
4. Deploy: `firebase deploy --only firestore,storage,functions`. Deploying rules locks out any
   client that still relies on open access, so release the new app builds first or together.
5. In Paystack, point the webhook at the deployed `webhookPaystack` URL.
6. Replace the placeholder dues amounts (seed script) with the real ones, then set real dues in
   the admin app.
7. Confirm the association and department wording with the ACES executive and the department.
8. The GitHub release linked in the README still contains the old Civil-branded APKs. Rebuild and
   publish new ones.
9. Release signing (`key.properties`) is unchanged and still needed.

---

## 6. Verification

See "Verification log" in `HANDOFF.md` for exactly what was compiled and tested, and what was not.
