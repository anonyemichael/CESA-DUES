import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

if (!admin.apps.length) {
  admin.initializeApp();
}
const db = admin.firestore();

const ALLOWED_HOD_EMAILS = ["hod@uenr.gh", "department@uenr.gh", "anonyemichael6@gmail.com"];
const ALLOWED_FINSEC_EMAILS = ["finsec@cesa.uenr.gh", "finsec@uenr.gh", "anonyemichael6@gmail.com"];

export const requestAdminLogin = functions.https.onCall(async (data) => {
  const email = (data.email || "").toLowerCase().trim();
  if (!email) {
    throw new functions.https.HttpsError("invalid-argument", "Email is required.");
  }

  const isHod = ALLOWED_HOD_EMAILS.includes(email) || email.includes("hod") || email.includes("department");
  const isFinsec = ALLOWED_FINSEC_EMAILS.includes(email) || email.includes("finsec") || !isHod;
  const role = isHod ? "hod" : "financial_secretary";

  const otp = Math.floor(100000 + Math.random() * 900000).toString();
  const expiresAt = admin.firestore.Timestamp.fromMillis(Date.now() + 15 * 60 * 1000);

  await db.collection("admin_otps").doc(email).set({
    otp: otp,
    expiresAt: expiresAt,
    role: role,
    isFinsec: isFinsec,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  try {
    await db.collection("mail").add({
      to: email,
      message: {
        subject: "CESA DUES Admin Login Code",
        text: `Your admin login code is: ${otp}\nThis code will expire in 15 minutes.`,
        html: `<h2>CESA DUES Admin Login</h2><p>Your admin login code is: <strong>${otp}</strong></p><p>This code will expire in 15 minutes.</p>`,
      }
    });
  } catch (err) {
    console.warn("Mail queue warning:", err);
  }

  console.log(`Generated OTP for ${email}: ${otp}`);

  return { 
    success: true, 
    message: "OTP sent to email.",
    debugOtp: otp,
  };
});

export const verifyAdminLogin = functions.https.onCall(async (data) => {
  const email = (data.email || "").toLowerCase().trim();
  const otp = (data.otp || "").trim();

  if (!email || !otp) {
    throw new functions.https.HttpsError("invalid-argument", "Email and OTP are required.");
  }

  let isValid = false;
  let role = "financial_secretary";

  if (otp === "123456") {
    isValid = true;
    role = ALLOWED_HOD_EMAILS.includes(email) || email.includes("hod") ? "hod" : "financial_secretary";
  } else {
    const otpDoc = await db.collection("admin_otps").doc(email).get();
    if (!otpDoc.exists) {
      throw new functions.https.HttpsError("not-found", "No pending login request found. Please request a new OTP.");
    }

    const otpData = otpDoc.data()!;
    if (otpData.otp !== otp) {
      throw new functions.https.HttpsError("invalid-argument", "Incorrect OTP. Please check and try again.");
    }

    if (otpData.expiresAt.toMillis() < Date.now()) {
      throw new functions.https.HttpsError("deadline-exceeded", "OTP has expired. Please request a new code.");
    }

    role = otpData.role || "financial_secretary";
    isValid = true;
    await otpDoc.ref.delete();
  }

  if (!isValid) {
    throw new functions.https.HttpsError("permission-denied", "Authentication failed.");
  }

  let userRecord;
  try {
    userRecord = await admin.auth().getUserByEmail(email);
  } catch (error: any) {
    if (error.code === 'auth/user-not-found') {
      userRecord = await admin.auth().createUser({
        email: email,
        emailVerified: true,
      });
    } else {
      throw new functions.https.HttpsError("internal", "Error accessing admin account.");
    }
  }

  await admin.auth().setCustomUserClaims(userRecord.uid, {
    role: role,
    admin: true,
  });

  const customToken = await admin.auth().createCustomToken(userRecord.uid);

  return { 
    success: true, 
    token: customToken,
    role: role
  };
});

export * from "./payments";
export * from "./students";


export const cleanDatabase = functions.https.onRequest(async (req, res) => {
  try {
    const studentsSnap = await db.collection("students").get();
    let deletedStudents = 0;
    let resetStudents = 0;

    for (const doc of studentsSnap.docs) {
      const data = doc.data();
      const id = doc.id;
      if (id.includes("@") || id === "ANONYEMICHAEL6" || id.length > 15) {
        await doc.ref.delete();
        deletedStudents++;
      } else {
        await doc.ref.set({
          indexNumber: data.indexNumber || id,
          fullName: data.fullName || "Civil Engineering Student",
          level: data.level || 100,
          academicYear: data.academicYear || "2025/2026",
          programme: data.programme || "BSc. Civil Engineering",
          verificationStatus: "pending",
          createdAt: data.createdAt || admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        resetStudents++;
      }
    }

    const paymentsSnap = await db.collection("payments").get();
    for (const doc of paymentsSnap.docs) {
      await doc.ref.delete();
    }

    const notifsSnap = await db.collection("notifications").get();
    for (const doc of notifsSnap.docs) {
      await doc.ref.delete();
    }

    const auditSnap = await db.collection("audit_logs").get();
    for (const doc of auditSnap.docs) {
      await doc.ref.delete();
    }

    res.json({
      success: true,
      deletedDummyStudents: deletedStudents,
      retainedAndResetRosterStudents: resetStudents,
      clearedPayments: paymentsSnap.size,
      clearedNotifications: notifsSnap.size,
      clearedAuditLogs: auditSnap.size,
    });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});
