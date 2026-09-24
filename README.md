# CESA DUES System

The CESA DUES system is a comprehensive monorepo designed to manage and track departmental dues for the Computer Engineering Students' Association (CESA). It provides a robust, scalable, and secure platform catering to both students and departmental administrators.

## System Architecture

The project is structured as a monorepo containing three main parts:
- **`cesa_dues_core`**: The shared engine. Contains all Riverpod repositories, Firestore data models, serializers, and core UI theme components.
- **`cesa_dues_student`**: The student-facing Flutter application designed for accessibility, optimized for low-end devices and slow network conditions.
- **`cesa_dues_admin`**: The administrative Flutter application used by departmental staff (e.g., HOD, Financial Secretary) for tracking payments and managing student records.
- **`functions/`**: The Firebase Cloud Functions backend written in TypeScript handling webhooks, payment verification, and automated tasks.
- **`firebase/`**: Infrastructure-as-code definitions including `firestore.rules` and `firestore.indexes.json`.

## Features

- **Zero-Trust Payments**: Payments are securely verified via a backend webhook using Paystack. The Firestore rules prevent direct client writes to the payment records.
- **Admin Passwordless Authentication**: Staff and administrators authenticate securely via Email Link (OTP), eliminating the need to manage static passwords.
- **Resilient Architecture**: Built with Riverpod for state management, Firebase for real-time data and authentication, and GoRouter for reliable navigation.
- **Offline Persistence**: The mobile apps have offline persistence enabled, allowing users to view cached data even with poor internet connectivity.

## Repository Structure

- `/cesa_dues_student/` - Source code for the student app
- `/cesa_dues_admin/` - Source code for the admin app
- `/cesa_dues_core/` - Shared core library
- `/functions/` - Cloud functions
- `/Releases/` - Compiled APKs for direct installation

## Deployment

### Mobile Applications
Compiled APKs for both the student and admin applications are available in the `Releases/` directory.

To build the applications from source:
```bash
# Student App
cd cesa_dues_student
flutter build apk --release --split-per-abi

# Admin App
cd cesa_dues_admin
flutter build apk --release --split-per-abi
```

### Backend Setup
1. Initialize a Firebase project and upgrade to the Blaze plan.
2. Deploy Firestore Rules and Indexes: `firebase deploy --only firestore`
3. Set Paystack Secret Key: `firebase functions:config:set paystack.secret="sk_live_YOUR_KEY"`
4. Deploy Cloud Functions:
   ```bash
   cd functions
   npm install
   npm run build
   firebase deploy --only functions
   ```
