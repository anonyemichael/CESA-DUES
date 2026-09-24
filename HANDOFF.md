# CESA DUES - System Handoff & Deployment Guide

Congratulations! The CESA DUES monorepo has been fully developed, tested, and polished. This document serves as the final technical handoff for deploying the system to production.

## System Architecture Review
- **`cesa_dues_core`**: The shared engine. Contains all Riverpod repositories, Firestore data models, serializers, and core UI theme components.
- **`cesa_dues_student`**: The student-facing Flutter application.
- **`cesa_dues_admin`**: The departmental staff (HOD & Financial Secretary) application.
- **`functions/`**: The Firebase Cloud Functions backend written in TypeScript.
- **`firebase/`**: The infrastructure-as-code definitions (`firestore.rules`, `firestore.indexes.json`).

## Deployment Checklist

### 1. Firebase Backend Deployment
1. **Initialize Firebase Project**:
   Ensure you have created a Firebase project in the console and upgraded it to the **Blaze (Pay-as-you-go)** plan (required for Cloud Functions and Node.js 20).
2. **Deploy Security Rules and Indexes**:
   ```bash
   firebase deploy --only firestore
   ```
3. **Configure Environment Variables**:
   Set your Paystack Secret Key in Cloud Functions:
   ```bash
   firebase functions:config:set paystack.secret="sk_live_YOUR_KEY"
   ```
4. **Deploy Cloud Functions**:
   ```bash
   cd functions
   npm install
   npm run build
   firebase deploy --only functions
   ```

### 2. Mobile Apps Deployment
Both apps (`cesa_dues_student` and `cesa_dues_admin`) are built for Android, targeting low-end devices and slow networks (persistence enabled).

1. **Android Signing**:
   Configure your `key.properties` file in the `android/` directory of both apps for release signing.
2. **Student App Build**:
   ```bash
   cd cesa_dues_student
   flutter build apk --release --split-per-abi
   # OR for Google Play:
   flutter build appbundle --release
   ```
3. **Admin App Build**:
   ```bash
   cd cesa_dues_admin
   flutter build apk --release --split-per-abi
   ```

## Production Security Notes
- **Zero-Trust Payments**: The `firestore.rules` is configured strictly so that `payments` cannot be written to by clients. Always rely on the Cloud Functions webhook to verify Paystack events.
- **Admin Authentication**: Admins log in via passwordless Email Link (OTP). Ensure your Firebase project's Authentication settings have "Email link (passwordless sign-in)" enabled.

## Code Maintenance
- To make changes to database structures, modify the models in `cesa_dues_core/lib/src/models`. Both apps will automatically inherit the changes when you run `flutter pub get`.
- Cloud functions are located in `functions/src/`. You can expand the webhook logic in `index.ts` to support more advanced gateway features (like Hubtel) in the future.

---
*Built with Riverpod, Firebase, GoRouter, and a focus on resilience.*
