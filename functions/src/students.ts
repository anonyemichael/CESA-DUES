import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import vision from "@google-cloud/vision";
import { requireUser, setCors, studentForUid } from "./auth";

if (!admin.apps.length) {
  admin.initializeApp();
}
const db = admin.firestore();

/**
 * verifyStudentIdOcr
 *
 * Reads the signed-in student's own ID-card photo from Cloud Storage and runs
 * Cloud Vision OCR. The student is auto-verified ONLY when their index number is
 * found on the card. Anything else (unreadable photo, Vision unavailable, index
 * not found) is sent to the Financial Secretary for manual approval; it is never
 * auto-approved.
 */
export const verifyStudentIdOcr = functions.https.onRequest(async (req, res) => {
  setCors(res);
  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return;
  }

  try {
    const user = await requireUser(req, res);
    if (!user) return;

    const student = await studentForUid(user.uid);
    if (!student) {
      res.status(200).json({ data: { success: false, verified: false, reason: "No student profile is linked to this account." } });
      return;
    }
    const indexNumber = student.id;
    const body = req.body?.data || req.body || {};
    const imageUrl = String(body.imageUrl || "");
    const storagePath = `idCards/${user.uid}/id_photo.jpg`;

    let imageBuffer: Buffer;
    try {
      [imageBuffer] = await admin.storage().bucket().file(storagePath).download();
    } catch {
      res.status(200).json({ data: { success: false, verified: false, reason: "We could not find your uploaded ID photo. Please upload it again." } });
      return;
    }

    let verified = false;
    let method = "cloud_vision_ocr";
    let ocrPreview = "";
    try {
      const client = new vision.ImageAnnotatorClient();
      const [result] = await client.textDetection({ image: { content: imageBuffer } });
      const text = (result.textAnnotations?.[0]?.description || "").toUpperCase();
      ocrPreview = text.substring(0, 200);
      const clean = (s: string) => s.replace(/[\s\-_/.]/g, "");
      verified = clean(text).includes(clean(indexNumber));
    } catch (visionErr: any) {
      console.warn("Cloud Vision unavailable, routing to manual review:", visionErr.message);
      method = "manual_review_vision_unavailable";
    }

    const update: Record<string, unknown> = {
      verificationStatus: verified ? "verified" : "pending",
      idCardPath: storagePath,
      verificationMethod: method,
      ocrDetectedTextPreview: ocrPreview,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };
    if (imageUrl.startsWith("https://firebasestorage.googleapis.com/")) update.idCardUrl = imageUrl;
    if (verified) update.verifiedAt = admin.firestore.FieldValue.serverTimestamp();
    await db.collection("students").doc(indexNumber).set(update, { merge: true });

    await db.collection("auditLogs").add({
      actor: indexNumber,
      actorRole: "student",
      action: verified ? "student_verified" : "student_modified",
      target: indexNumber,
      targetType: "student",
      metadata: { method, autoVerified: verified },
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });

    if (verified) {
      res.status(200).json({ data: { success: true, verified: true, message: "Student ID verified." } });
    } else {
      res.status(200).json({
        data: {
          success: true,
          verified: false,
          pending: true,
          reason: "We could not confirm your index number automatically. Your ID was sent to the department for manual approval.",
        },
      });
    }
  } catch (error: any) {
    console.error("verifyStudentIdOcr error:", error);
    res.status(200).json({ data: { success: false, verified: false, reason: "Verification failed. Please try again." } });
  }
});
