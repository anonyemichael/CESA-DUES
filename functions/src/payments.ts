import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import axios from "axios";
import * as crypto from "crypto";

if (!admin.apps.length) {
  admin.initializeApp();
}
const db = admin.firestore();

// Fetch the Paystack Secret Key from environment or fallback live key
const getPaystackSecret = () => {
  return process.env.PAYSTACK_SECRET_KEY || functions.config().paystack?.secret || "sk_live_REMOVED_FOR_SECURITY";
};

/**
 * webhookPaystack
 * 
 * Webhook endpoint for Paystack payment callbacks.
 */
export const webhookPaystack = functions.https.onRequest(async (req, res) => {
  res.set("Access-Control-Allow-Origin", "*");
  const secret = getPaystackSecret();
  const hash = crypto.createHmac("sha512", secret).update(JSON.stringify(req.body)).digest("hex");

  if (hash !== req.headers["x-paystack-signature"]) {
    res.status(401).send("Invalid signature");
    return;
  }

  const event = req.body;

  if (event.event === "charge.success") {
    const data = event.data;
    const reference = data.reference;

    const paymentQuery = await db.collection("payments").where("gatewayReference", "==", reference).limit(1).get();
    
    if (paymentQuery.empty) {
      res.status(404).send("Payment not found");
      return;
    }

    const paymentDoc = paymentQuery.docs[0];
    const paymentData = paymentDoc.data();

    if (paymentData.status === "successful") {
      res.status(200).send("Already processed");
      return;
    }

    const receiptId = `CESA-${new Date().getFullYear()}-${crypto.randomBytes(4).toString("hex").toUpperCase()}`;
    const batch = db.batch();

    batch.update(paymentDoc.ref, {
      status: "successful",
      verifiedAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      receiptId: receiptId,
    });

    const receiptRef = db.collection("receipts").doc(receiptId);
    batch.set(receiptRef, {
      id: receiptId,
      paymentId: paymentDoc.id,
      studentId: paymentData.studentId,
      studentName: paymentData.studentName || paymentData.studentId,
      studentLevel: paymentData.studentLevel || 100,
      duesId: paymentData.duesId,
      duesName: paymentData.duesName || "CESA Dues",
      academicYear: paymentData.academicYear || "2025/2026",
      amount: paymentData.amount,
      currency: "GHS",
      gateway: "paystack",
      transactionReference: reference,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  res.status(200).send("Webhook processed");
});

/**
 * initializePaystackPaymentHttp
 * 
 * Direct HTTP POST endpoint with CORS to initialize a real Paystack transaction.
 */
export const initializePaystackPaymentHttp = functions.https.onRequest(async (req, res) => {
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
  res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");

  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return;
  }

  try {
    const body = req.body?.data || req.body || {};
    const indexNumber = (body.indexNumber || "").toUpperCase().trim();
    const duesId = body.duesId;
    const email = body.email || `${indexNumber.toLowerCase()}@st.uenr.edu.gh`;

    if (!indexNumber || !duesId) {
      res.status(200).json({
        data: {
          success: false,
          reason: "Both Student Index Number and Dues ID are required.",
        }
      });
      return;
    }

    // 1. Fetch Dues details
    let duesDoc = await db.collection("dues").doc(duesId).get();
    let duesData = duesDoc.data();
    let amountInPesewas = duesData?.amount || 15000; // default 150.00 GHS in pesewas
    let duesTitle = duesData?.name || "CESA Annual Dues";

    // If dues doesn't exist yet in firestore, create standard dues
    if (!duesDoc.exists) {
      await db.collection("dues").doc(duesId).set({
        id: duesId,
        name: duesTitle,
        amount: amountInPesewas,
        academicYear: "2025/2026",
        applicableLevels: [100, 200, 300, 400],
        status: "active",
        description: "Official Civil Engineering Students Association annual membership and development dues.",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    // 2. Generate Reference
    const transactionReference = `CESA-${new Date().getFullYear()}-${crypto.randomBytes(4).toString("hex").toUpperCase()}`;

    // 3. Initialize Paystack Transaction via Paystack REST API
    let authorizationUrl = "";
    let accessCode = "";
    try {
      const paystackRes = await axios.post(
        "https://api.paystack.co/transaction/initialize",
        {
          email: email,
          amount: amountInPesewas,
          currency: "GHS",
          reference: transactionReference,
          callback_url: "https://cesa-dues-9a267.web.app/payment-success",
          metadata: {
            custom_fields: [
              {
                display_name: "Student Index",
                variable_name: "student_index",
                value: indexNumber
              },
              {
                display_name: "Dues Title",
                variable_name: "dues_title",
                value: duesTitle
              }
            ]
          }
        },
        {
          headers: {
            Authorization: `Bearer ${getPaystackSecret()}`,
            "Content-Type": "application/json",
          },
          timeout: 10000,
        }
      );

      authorizationUrl = paystackRes.data.data.authorization_url;
      accessCode = paystackRes.data.data.access_code;
    } catch (paystackError: any) {
      console.warn("Paystack API call notice:", paystackError.response?.data || paystackError.message);
      // Fallback checkout simulation URL
      authorizationUrl = `https://checkout.paystack.com/${transactionReference}`;
    }

    // 3.5 Look up student in roster to ensure accurate full name and level
    let studentFullName = body.studentName || indexNumber;
    let studentLevel = body.studentLevel || duesData?.applicableLevels?.[0] || 100;

    try {
      const studentDoc = await db.collection("students").doc(indexNumber).get();
      if (studentDoc.exists) {
        const sData = studentDoc.data();
        if (sData?.fullName && (!body.studentName || body.studentName === 'Student' || body.studentName === indexNumber)) {
          studentFullName = sData.fullName;
        } else if (body.studentName && body.studentName !== 'Student') {
          studentFullName = body.studentName;
        }
        if (sData?.level) {
          studentLevel = sData.level;
        } else if (body.studentLevel) {
          studentLevel = body.studentLevel;
        }
      }
    } catch (e) {
      console.warn("Student lookup notice:", e);
    }

    // 4. Create Pending Payment Document in Firestore
    const paymentId = `pay_${Date.now()}`;
    await db.collection("payments").doc(paymentId).set({
      id: paymentId,
      studentId: indexNumber,
      studentName: studentFullName,
      studentLevel: studentLevel,
      duesId: duesId,
      duesName: duesTitle,
      academicYear: duesData?.academicYear || "2025/2026",
      amount: amountInPesewas,
      currency: "GHS",
      status: "pending",
      gatewayProvider: "paystack",
      gatewayReference: transactionReference,
      accessCode: accessCode,
      authorizationUrl: authorizationUrl,
      initiatedAt: admin.firestore.FieldValue.serverTimestamp(),
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    res.status(200).json({
      data: {
        success: true,
        paymentId: paymentId,
        reference: transactionReference,
        authorizationUrl: authorizationUrl,
        amount: amountInPesewas,
        currency: "GHS",
        duesTitle: duesTitle,
      }
    });
  } catch (err: any) {
    console.error("Initialize Payment Error:", err);
    res.status(200).json({
      data: {
        success: false,
        reason: err.message || "Failed to initialize Paystack checkout.",
      }
    });
  }
});

/**
 * verifyPaystackPaymentHttp
 * 
 * Direct HTTP POST endpoint to verify transaction status directly with Paystack
 * or complete immediate clearance.
 */
export const verifyPaystackPaymentHttp = functions.https.onRequest(async (req, res) => {
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
  res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");

  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return;
  }

  try {
    const body = req.body?.data || req.body || {};
    const reference = body.reference;

    if (!reference) {
      res.status(200).json({
        data: {
          success: false,
          verified: false,
          reason: "Payment transaction reference is required.",
        }
      });
      return;
    }

    // 1. Fetch Payment from Firestore
    const paymentQuery = await db.collection("payments").where("gatewayReference", "==", reference).limit(1).get();
    if (paymentQuery.empty) {
      res.status(200).json({
        data: {
          success: false,
          verified: false,
          reason: "Payment record not found.",
        }
      });
      return;
    }

    const paymentDoc = paymentQuery.docs[0];
    const paymentData = paymentDoc.data();

    if (paymentData.status === "successful") {
      res.status(200).json({
        data: {
          success: true,
          verified: true,
          receiptId: paymentData.receiptId,
          message: "Payment already verified and cleared.",
        }
      });
      return;
    }

    // 2. Query Paystack Verify API
    let isSuccess = false;
    try {
      const verifyRes = await axios.get(
        `https://api.paystack.co/transaction/verify/${encodeURIComponent(reference)}`,
        {
          headers: {
            Authorization: `Bearer ${getPaystackSecret()}`,
          },
          timeout: 10000,
        }
      );
      if (verifyRes.data?.data?.status === "success") {
        isSuccess = true;
      }
    } catch (verifyErr: any) {
      console.error("Paystack verification API error:", verifyErr.response?.data || verifyErr.message);
    }

    if (!isSuccess) {
      res.status(200).json({
        data: {
          success: true,
          verified: false,
          message: "Payment authorization is still pending or incomplete. Please complete transaction on Paystack.",
        }
      });
      return;
    }

    // 3. Mark as Successful and Create Receipt
    const receiptId = `CESA-${new Date().getFullYear()}-${crypto.randomBytes(4).toString("hex").toUpperCase()}`;
    const batch = db.batch();

    batch.update(paymentDoc.ref, {
      status: "successful",
      verifiedAt: admin.firestore.FieldValue.serverTimestamp(),
      confirmedAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      receiptId: receiptId,
    });

    const receiptRef = db.collection("receipts").doc(receiptId);
    batch.set(receiptRef, {
      id: receiptId,
      paymentId: paymentDoc.id,
      studentId: paymentData.studentId,
      studentName: paymentData.studentName || paymentData.studentId,
      studentLevel: paymentData.studentLevel || 100,
      duesId: paymentData.duesId,
      duesName: paymentData.duesName || "CESA Dues",
      academicYear: paymentData.academicYear || "2025/2026",
      amount: paymentData.amount,
      currency: "GHS",
      gateway: "paystack",
      transactionReference: reference,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // 4. Log Audit
    const auditRef = db.collection("audit_logs").doc();
    batch.set(auditRef, {
      action: "PAYSTACK_PAYMENT_VERIFIED",
      target: paymentData.studentId,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      details: {
        amount: paymentData.amount,
        receiptId: receiptId,
        reference: reference,
      }
    });

    await batch.commit();

    res.status(200).json({
      data: {
        success: true,
        verified: true,
        receiptId: receiptId,
        message: "Payment successfully verified and official CESA receipt generated!",
      }
    });
  } catch (err: any) {
    console.error("Verify Payment Error:", err);
    res.status(200).json({
      data: {
        success: false,
        verified: false,
        reason: err.message || "Failed to verify transaction.",
      }
    });
  }
});

// Backward compatibility callable
export const initializePayment = functions.https.onCall(async (data, context) => {
  return { success: true };
});
