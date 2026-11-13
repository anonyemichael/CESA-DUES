import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

if (!admin.apps.length) {
  admin.initializeApp();
}
const db = admin.firestore();

export const setCors = (res: functions.Response): void => {
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "POST, OPTIONS");
  res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");
};

/**
 * Verifies the Firebase ID token sent as `Authorization: Bearer <token>`.
 * Replies 401 and returns null when it is missing or invalid.
 */
export const requireUser = async (
  req: functions.https.Request,
  res: functions.Response
): Promise<admin.auth.DecodedIdToken | null> => {
  const header = req.headers.authorization || "";
  const match = /^Bearer (.+)$/.exec(header);
  if (!match) {
    res.status(401).json({ data: { success: false, reason: "Please sign in and try again." } });
    return null;
  }
  try {
    return await admin.auth().verifyIdToken(match[1]);
  } catch {
    res.status(401).json({ data: { success: false, reason: "Your session has expired. Please sign in again." } });
    return null;
  }
};

export interface LinkedStudent {
  id: string;
  data: FirebaseFirestore.DocumentData;
}

/** The roster record whose `linkedUid` is this Firebase user, or null. */
export const studentForUid = async (uid: string): Promise<LinkedStudent | null> => {
  const snap = await db.collection("students").where("linkedUid", "==", uid).limit(1).get();
  if (snap.empty) return null;
  return { id: snap.docs[0].id, data: snap.docs[0].data() };
};
