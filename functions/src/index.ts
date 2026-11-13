import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import * as crypto from "crypto";
import { BRAND } from "./brand";

if (!admin.apps.length) {
  admin.initializeApp();
}
const db = admin.firestore();

const OTP_TTL_MS = 15 * 60 * 1000;
const OTP_RESEND_COOLDOWN_MS = 60 * 1000;
const OTP_MAX_ATTEMPTS = 5;

type AdminRole = "hod" | "financial_secretary";

const parseList = (value?: string): string[] =>
  (value || "").split(",").map((s) => s.trim().toLowerCase()).filter(Boolean);

/**
 * Admin allow-lists come from the environment (functions/.env), comma separated:
 *   ADMIN_HOD_EMAILS=hod@uenr.edu.gh
 *   ADMIN_FINSEC_EMAILS=finsec@example.com
 * An e-mail that is on neither list can never sign in.
 */
const resolveRole = (email: string, requested?: string): AdminRole | null => {
  const isHod = parseList(process.env.ADMIN_HOD_EMAILS).includes(email);
  const isFinsec = parseList(process.env.ADMIN_FINSEC_EMAILS).includes(email);
  if (isHod && isFinsec) {
    return requested === "financial_secretary" ? "financial_secretary" : "hod";
  }
  if (isHod) return "hod";
  if (isFinsec) return "financial_secretary";
  return null;
};

const hashOtp = (email: string, otp: string): string =>
  crypto.createHash("sha256").update(`${email}:${otp}`).digest("hex");

const safeEqual = (a: string, b: string): boolean => {
  const ba = Buffer.from(a);
  const bb = Buffer.from(b);
  return ba.length === bb.length && crypto.timingSafeEqual(ba, bb);
};

export const requestAdminLogin = functions.https.onCall(async (data) => {
  const email = String(data?.email || "").toLowerCase().trim();
  if (!email) {
    throw new functions.https.HttpsError("invalid-argument", "Email is required.");
  }

  const role = resolveRole(email, data?.role);
  if (!role) {
    throw new functions.https.HttpsError("permission-denied", "This e-mail is not authorised for admin access.");
  }

  const ref = db.collection("admin_otps").doc(email);
  const existing = await ref.get();
  if (existing.exists && Date.now() - (existing.data()?.createdAtMs || 0) < OTP_RESEND_COOLDOWN_MS) {
    throw new functions.https.HttpsError("resource-exhausted", "Please wait a minute before requesting another code.");
  }

  const otp = String(crypto.randomInt(100000, 1000000));
  await ref.set({
    otpHash: hashOtp(email, otp),
    role,
    attempts: 0,
    expiresAt: admin.firestore.Timestamp.fromMillis(Date.now() + OTP_TTL_MS),
    createdAtMs: Date.now(),
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  // Delivered by the "Trigger Email from Firestore" extension (see HANDOFF.md).
  await db.collection("mail").add({
    to: email,
    message: {
      subject: `${BRAND.appName} admin login code`,
      text: `Your ${BRAND.appName} admin login code is ${otp}. It expires in 15 minutes. If you did not request it, ignore this e-mail.`,
      html: `<h2>${BRAND.appName} admin login</h2>` +
        `<p>${BRAND.associationFullName}, ${BRAND.universityShort}</p>` +
        `<p>Your login code is <strong style="font-size:20px;letter-spacing:2px">${otp}</strong></p>` +
        "<p>It expires in 15 minutes. If you did not request it, ignore this e-mail.</p>",
    },
  });

  return { success: true, message: "A login code has been e-mailed to you." };
});

export const verifyAdminLogin = functions.https.onCall(async (data) => {
  const email = String(data?.email || "").toLowerCase().trim();
  const otp = String(data?.otp || "").trim();
  if (!email || !otp) {
    throw new functions.https.HttpsError("invalid-argument", "Email and code are required.");
  }

  const ref = db.collection("admin_otps").doc(email);
  const outcome = await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) return { ok: false as const, code: "missing" };
    const d = snap.data()!;
    if (d.expiresAt.toMillis() < Date.now()) {
      tx.delete(ref);
      return { ok: false as const, code: "expired" };
    }
    if ((d.attempts || 0) >= OTP_MAX_ATTEMPTS) {
      tx.delete(ref);
      return { ok: false as const, code: "locked" };
    }
    if (!safeEqual(d.otpHash, hashOtp(email, otp))) {
      tx.update(ref, { attempts: (d.attempts || 0) + 1 });
      return { ok: false as const, code: "wrong" };
    }
    tx.delete(ref);
    return { ok: true as const, role: d.role as AdminRole };
  });

  if (!outcome.ok) {
    const messages: Record<string, string> = {
      missing: "No pending login request. Please request a new code.",
      expired: "That code has expired. Please request a new one.",
      locked: "Too many wrong attempts. Please request a new code.",
      wrong: "Incorrect code. Please check and try again.",
    };
    throw new functions.https.HttpsError("permission-denied", messages[outcome.code]);
  }

  // Re-check the allow-list: access may have been revoked since the code was issued.
  const role = resolveRole(email, outcome.role);
  if (!role) {
    throw new functions.https.HttpsError("permission-denied", "This e-mail is not authorised for admin access.");
  }

  let userRecord: admin.auth.UserRecord;
  try {
    userRecord = await admin.auth().getUserByEmail(email);
  } catch (error: any) {
    if (error.code === "auth/user-not-found") {
      userRecord = await admin.auth().createUser({ email, emailVerified: true });
    } else {
      throw new functions.https.HttpsError("internal", "Error accessing admin account.");
    }
  }

  await admin.auth().setCustomUserClaims(userRecord.uid, { role, admin: true });
  const token = await admin.auth().createCustomToken(userRecord.uid, { role, admin: true });

  await db.collection("auditLogs").add({
    actor: email,
    actorRole: role,
    action: "admin_login",
    target: email,
    targetType: "admin",
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  });

  return { success: true, token, role };
});

export * from "./payments";
export * from "./students";
export * from "./notifications";

/**
 * One-off maintenance endpoint that wipes payments, notifications and audit logs
 * and resets the roster. Disabled unless a CLEANUP_TOKEN secret is configured, and
 * then only callable with POST + header `x-cleanup-token`.
 */
export const cleanDatabase = functions
  .runWith({ secrets: ["CLEANUP_TOKEN"] })
  .https.onRequest(async (req, res) => {
    const expected = process.env.CLEANUP_TOKEN;
    const supplied = String(req.headers["x-cleanup-token"] || "");
    if (req.method !== "POST" || !expected || !safeEqual(expected, supplied)) {
      res.status(403).json({ error: "Forbidden" });
      return;
    }
    try {
      const studentsSnap = await db.collection("students").get();
      let resetStudents = 0;
      for (const doc of studentsSnap.docs) {
        const d = doc.data();
        await doc.ref.set({
          indexNumber: d.indexNumber || doc.id,
          fullName: d.fullName || BRAND.defaultStudentName,
          level: d.level || 100,
          academicYear: d.academicYear || "2025/2026",
          programme: d.programme || BRAND.programmeName,
          linkedUid: null,
          verificationStatus: "unverified",
          createdAt: d.createdAt || admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        resetStudents++;
      }

      const cleared: Record<string, number> = {};
      for (const name of ["payments", "receipts", "notifications", "auditLogs"]) {
        const snap = await db.collection(name).get();
        for (const doc of snap.docs) await doc.ref.delete();
        cleared[name] = snap.size;
      }
      res.json({ success: true, resetStudents, cleared });
    } catch (err: any) {
      res.status(500).json({ error: err.message });
    }
  });
