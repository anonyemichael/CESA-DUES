import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import axios from "axios";
import * as crypto from "crypto";
import { BRAND, newReference } from "./brand";
import { requireUser, setCors, studentForUid } from "./auth";

if (!admin.apps.length) {
  admin.initializeApp();
}
const db = admin.firestore();

/** Paystack secret comes only from the PAYSTACK_SECRET_KEY secret; there is no fallback. */
const paystackSecret = (): string => {
  const key = process.env.PAYSTACK_SECRET_KEY;
  if (!key) throw new Error("PAYSTACK_SECRET_KEY is not configured.");
  return key;
};

const paymentSecrets = functions.runWith({ secrets: ["PAYSTACK_SECRET_KEY"] });

/**
 * Marks a payment successful and issues its receipt exactly once. Safe to call
 * from both the webhook and the verify endpoint at the same time.
 */
const finalizeSuccessfulPayment = async (
  paymentRef: FirebaseFirestore.DocumentReference,
  reference: string,
  via: "webhook" | "verify"
): Promise<{ receiptId: string; alreadyDone: boolean }> => {
  return db.runTransaction(async (tx) => {
    const snap = await tx.get(paymentRef);
    const p = snap.data();
    if (!p) throw new Error("Payment record disappeared.");
    if (p.status === "successful" && p.receiptId) {
      return { receiptId: p.receiptId as string, alreadyDone: true };
    }

    const receiptId = newReference();
    const now = admin.firestore.FieldValue.serverTimestamp();

    tx.update(paymentRef, {
      status: "successful",
      receiptId,
      verifiedAt: now,
      confirmedAt: now,
      updatedAt: now,
    });
    tx.set(db.collection("receipts").doc(receiptId), {
      id: receiptId,
      paymentId: paymentRef.id,
      studentId: p.studentId,
      studentName: p.studentName || p.studentId,
      studentLevel: p.studentLevel || 100,
      duesId: p.duesId,
      duesName: p.duesName || `${BRAND.organization} Dues`,
      academicYear: p.academicYear,
      amount: p.amount,
      currency: BRAND.currency,
      gateway: "paystack",
      transactionReference: reference,
      createdAt: now,
    });
    tx.set(db.collection("notifications").doc(), {
      title: "Payment Successful",
      body: `Your payment for ${p.duesName || "dues"} was received. Receipt: ${receiptId}`,
      type: "payment_confirmation",
      targetAudience: "personal",
      studentId: p.studentId,
      academicYear: p.academicYear,
      isRead: false,
      sentAt: now,
      createdAt: now,
    });
    tx.set(db.collection("auditLogs").doc(), {
      actor: p.studentId,
      actorRole: "student",
      action: "payment_verified",
      target: paymentRef.id,
      targetType: "payment",
      metadata: { receiptId, reference, amount: p.amount, via },
      timestamp: now,
    });
    return { receiptId, alreadyDone: false };
  });
};

/**
 * webhookPaystack — Paystack calls this on every charge event. The HMAC is checked
 * against the raw request body, and the charged amount must match the payment.
 */
export const webhookPaystack = paymentSecrets.https.onRequest(async (req, res) => {
  const signature = String(req.headers["x-paystack-signature"] || "");
  const raw = (req as any).rawBody as Buffer | undefined;
  const expected = crypto.createHmac("sha512", paystackSecret()).update(raw || JSON.stringify(req.body)).digest("hex");
  const ok = signature.length === expected.length &&
    crypto.timingSafeEqual(Buffer.from(signature), Buffer.from(expected));
  if (!ok) {
    res.status(401).send("Invalid signature");
    return;
  }

  const event = req.body;
  if (event?.event === "charge.success") {
    const data = event.data;
    const q = await db.collection("payments").where("gatewayReference", "==", data.reference).limit(1).get();
    if (q.empty) {
      res.status(404).send("Payment not found");
      return;
    }
    const doc = q.docs[0];
    const p = doc.data();
    if (data.amount !== p.amount || data.currency !== BRAND.currency) {
      console.error(`Amount mismatch for ${data.reference}: paid ${data.amount} ${data.currency}, expected ${p.amount}`);
      await doc.ref.update({ status: "failed", failureReason: "amount_mismatch", updatedAt: admin.firestore.FieldValue.serverTimestamp() });
      res.status(200).send("Amount mismatch recorded");
      return;
    }
    await finalizeSuccessfulPayment(doc.ref, data.reference, "webhook");
  }
  res.status(200).send("Webhook processed");
});

/**
 * initializePaystackPaymentHttp — starts a Paystack checkout for the signed-in,
 * ID-verified student. The student, amount and dues come from Firestore, never from
 * the request body.
 */
export const initializePaystackPaymentHttp = paymentSecrets.https.onRequest(async (req, res) => {
  setCors(res);
  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return;
  }
  const fail = (reason: string): void => {
    res.status(200).json({ data: { success: false, reason } });
  };

  try {
    const user = await requireUser(req, res);
    if (!user) return;

    const body = req.body?.data || req.body || {};
    const duesId = String(body.duesId || "");
    if (!duesId) return fail("Dues ID is required.");

    const student = await studentForUid(user.uid);
    if (!student) return fail("No student profile is linked to this account.");
    if (student.data.verificationStatus !== "verified") {
      return fail("Please verify your student ID before paying dues.");
    }

    const duesDoc = await db.collection("dues").doc(duesId).get();
    const dues = duesDoc.data();
    if (!dues || dues.status !== "active") return fail("These dues are not open for payment.");
    const levels: number[] = dues.applicableLevels || [];
    if (levels.length > 0 && !levels.includes(student.data.level)) {
      return fail("These dues do not apply to your level.");
    }

    const already = await db.collection("payments")
      .where("studentId", "==", student.id)
      .where("duesId", "==", duesId)
      .where("status", "==", "successful").limit(1).get();
    if (!already.empty) return fail("You have already paid these dues.");

    const email = student.data.email || user.email || `${student.id.toLowerCase()}@${BRAND.studentEmailDomain}`;
    const reference = newReference();

    let authorizationUrl: string;
    let accessCode: string;
    try {
      const r = await axios.post(
        "https://api.paystack.co/transaction/initialize",
        {
          email,
          amount: dues.amount,
          currency: BRAND.currency,
          reference,
          callback_url: "https://cesa-dues-9a267.web.app/payment-success",
          metadata: {
            custom_fields: [
              { display_name: "Student Index", variable_name: "student_index", value: student.id },
              { display_name: "Dues Title", variable_name: "dues_title", value: dues.name },
            ],
          },
        },
        { headers: { Authorization: `Bearer ${paystackSecret()}` }, timeout: 15000 }
      );
      authorizationUrl = r.data.data.authorization_url;
      accessCode = r.data.data.access_code;
    } catch (e: any) {
      console.error("Paystack initialize failed:", e.response?.data || e.message);
      return fail("Could not start the payment. Please try again shortly.");
    }

    const paymentId = `pay_${Date.now()}_${crypto.randomBytes(3).toString("hex")}`;
    const now = admin.firestore.FieldValue.serverTimestamp();
    await db.collection("payments").doc(paymentId).set({
      id: paymentId,
      studentId: student.id,
      studentName: student.data.fullName || student.id,
      studentLevel: student.data.level || 100,
      duesId,
      duesName: dues.name,
      academicYear: dues.academicYear,
      amount: dues.amount,
      currency: BRAND.currency,
      status: "pending",
      gatewayProvider: "paystack",
      gatewayReference: reference,
      accessCode,
      authorizationUrl,
      initiatedAt: now,
      createdAt: now,
      updatedAt: now,
    });

    res.status(200).json({
      data: {
        success: true,
        paymentId,
        reference,
        authorizationUrl,
        amount: dues.amount,
        currency: BRAND.currency,
        duesTitle: dues.name,
      },
    });
  } catch (err: any) {
    console.error("initializePaystackPaymentHttp error:", err);
    fail("Failed to initialise checkout.");
  }
});

/**
 * verifyPaystackPaymentHttp — asks Paystack whether the caller's own payment
 * succeeded and, if so, issues the receipt.
 */
export const verifyPaystackPaymentHttp = paymentSecrets.https.onRequest(async (req, res) => {
  setCors(res);
  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return;
  }
  const fail = (reason: string): void => {
    res.status(200).json({ data: { success: false, verified: false, reason } });
  };

  try {
    const user = await requireUser(req, res);
    if (!user) return;

    const reference = String((req.body?.data || req.body || {}).reference || "");
    if (!reference) return fail("Payment reference is required.");

    const student = await studentForUid(user.uid);
    const q = await db.collection("payments").where("gatewayReference", "==", reference).limit(1).get();
    if (!student || q.empty || q.docs[0].data().studentId !== student.id) {
      return fail("Payment record not found.");
    }
    const doc = q.docs[0];
    const p = doc.data();

    if (p.status === "successful") {
      res.status(200).json({ data: { success: true, verified: true, receiptId: p.receiptId, message: "Payment already verified." } });
      return;
    }

    let paid = false;
    try {
      const v = await axios.get(`https://api.paystack.co/transaction/verify/${encodeURIComponent(reference)}`, {
        headers: { Authorization: `Bearer ${paystackSecret()}` },
        timeout: 15000,
      });
      const d = v.data?.data;
      paid = d?.status === "success" && d?.amount === p.amount && d?.currency === BRAND.currency;
    } catch (e: any) {
      console.error("Paystack verify failed:", e.response?.data || e.message);
    }

    if (!paid) {
      res.status(200).json({ data: { success: true, verified: false, message: "Payment is still pending or incomplete." } });
      return;
    }

    const { receiptId } = await finalizeSuccessfulPayment(doc.ref, reference, "verify");
    res.status(200).json({
      data: { success: true, verified: true, receiptId, message: `Payment verified and your official ${BRAND.organization} receipt was issued.` },
    });
  } catch (err: any) {
    console.error("verifyPaystackPaymentHttp error:", err);
    fail("Failed to verify the transaction.");
  }
});
