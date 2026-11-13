import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
  RulesTestEnvironment,
} from "@firebase/rules-unit-testing";
import { ref, uploadBytes, getBytes } from "firebase/storage";
import * as fs from "fs";
import * as path from "path";

let env: RulesTestEnvironment;

const read = (f: string) => fs.readFileSync(path.resolve(__dirname, "../../", f), "utf8");

// Authenticated contexts
const alice = () => env.authenticatedContext("uid-alice", { email: "alice@st.uenr.edu.gh" });
const bob = () => env.authenticatedContext("uid-bob", { email: "bob@st.uenr.edu.gh" });
const hod = () => env.authenticatedContext("uid-hod", { admin: true, role: "hod" });
const finsec = () => env.authenticatedContext("uid-fin", { admin: true, role: "financial_secretary" });
const anon = () => env.unauthenticatedContext();

beforeAll(async () => {
  env = await initializeTestEnvironment({
    projectId: "aces-dues-test",
    firestore: { rules: read("firestore.rules") },
    storage: { rules: read("storage.rules") },
  });
});
afterAll(async () => env.cleanup());

beforeEach(async () => {
  await env.clearFirestore();
  await env.clearStorage();
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await db.doc("students/ACES001").set({
      indexNumber: "ACES001", fullName: "Alice A", programme: "BSc. Computer Engineering", level: 200,
      academicYear: "2025/2026", linkedUid: "uid-alice", email: "alice@st.uenr.edu.gh", verificationStatus: "verified",
    });
    await db.doc("students/ACES002").set({
      indexNumber: "ACES002", fullName: "Bob B", programme: "BSc. Computer Engineering", level: 100,
      academicYear: "2025/2026", linkedUid: "uid-bob", email: "bob@st.uenr.edu.gh", verificationStatus: "pending",
    });
    await db.doc("students/ACES003").set({
      indexNumber: "ACES003", fullName: "Carol C", programme: "BSc. Computer Engineering", level: 0,
      academicYear: "2025/2026", linkedUid: null, verificationStatus: "unverified",
    });
    await db.doc("dues/d1").set({ name: "Annual Dues", amount: 15000, academicYear: "2025/2026", applicableLevels: [100, 200], status: "active" });
    await db.doc("payments/p-alice").set({ studentId: "ACES001", status: "successful", amount: 15000 });
    await db.doc("payments/p-bob").set({ studentId: "ACES002", status: "pending", amount: 15000 });
    await db.doc("receipts/r-alice").set({ studentId: "ACES001", amount: 15000 });
    await db.doc("notifications/n-all").set({ title: "Hi", body: "b", targetAudience: "all", academicYear: "2025/2026", isRead: false });
    await db.doc("notifications/n-l200").set({ title: "L200", body: "b", targetAudience: "level_200", academicYear: "2025/2026", isRead: false });
    await db.doc("notifications/n-alice").set({ title: "Paid", body: "b", targetAudience: "personal", studentId: "ACES001", academicYear: "2025/2026", isRead: false });
    await db.doc("notifications/n-bob").set({ title: "Paid", body: "b", targetAudience: "personal", studentId: "ACES002", academicYear: "2025/2026", isRead: false });
    await db.doc("auditLogs/a1").set({ action: "payment_verified" });
    await db.doc("admin_otps/x@y.z").set({ otpHash: "h" });
  });
});

describe("students", () => {
  it("lets a student read their own record by id and by uid query", async () => {
    const db = alice().firestore();
    await assertSucceeds(db.doc("students/ACES001").get());
    await assertSucceeds(db.collection("students").where("linkedUid", "==", "uid-alice").limit(1).get());
  });
  it("lets a student find their record by their own e-mail", async () => {
    await assertSucceeds(alice().firestore().collection("students").where("email", "==", "alice@st.uenr.edu.gh").limit(1).get());
  });
  it("blocks reading another student's linked record", async () => {
    await assertFails(alice().firestore().doc("students/ACES002").get());
  });
  it("lets a student look up an unclaimed roster record and a missing one during onboarding", async () => {
    const db = alice().firestore();
    await assertSucceeds(db.doc("students/ACES003").get());
    await assertSucceeds(db.doc("students/NOPE999").get());
  });
  it("blocks students from listing the whole roster; admins can", async () => {
    await assertFails(alice().firestore().collection("students").get());
    await assertFails(anon().firestore().collection("students").get());
    await assertSucceeds(hod().firestore().collection("students").get());
  });
  it("lets a student create their own pending record but not a verified or foreign one", async () => {
    const base = { indexNumber: "NEW1", fullName: "N", programme: "BSc. Computer Engineering", level: 100, academicYear: "2025/2026", email: "a@b.c" };
    const db = alice().firestore();
    await assertSucceeds(db.doc("students/NEW1").set({ ...base, linkedUid: "uid-alice", verificationStatus: "pending" }));
    await assertFails(db.doc("students/NEW2").set({ ...base, linkedUid: "uid-alice", verificationStatus: "verified" }));
    await assertFails(db.doc("students/NEW3").set({ ...base, linkedUid: "uid-bob", verificationStatus: "pending" }));
  });
  it("lets a student claim an unclaimed record, but not a claimed one", async () => {
    await assertSucceeds(alice().firestore().doc("students/ACES003").update({ linkedUid: "uid-alice", email: "alice@st.uenr.edu.gh", fullName: "Carol C", level: 300 }));
    await assertFails(alice().firestore().doc("students/ACES002").update({ linkedUid: "uid-alice" }));
  });
  it("blocks a student from self-verifying, re-opening a verified record, or changing their level", async () => {
    const bobDb = bob().firestore();
    await assertFails(bobDb.doc("students/ACES002").update({ verificationStatus: "verified" }));
    await assertFails(alice().firestore().doc("students/ACES001").update({ verificationStatus: "pending" }));
    await assertFails(alice().firestore().doc("students/ACES001").update({ level: 400 }));
    await assertSucceeds(bobDb.doc("students/ACES002").update({ fcmToken: "tok", updatedAt: new Date() }));
  });
  it("allows only the Financial Secretary to write the roster", async () => {
    await assertSucceeds(finsec().firestore().doc("students/ACES001").update({ verificationStatus: "verified", level: 300 }));
    await assertFails(hod().firestore().doc("students/ACES002").update({ verificationStatus: "verified" }));
  });
});

describe("dues", () => {
  it("is readable by signed-in users only and writable only by the Financial Secretary", async () => {
    await assertSucceeds(alice().firestore().doc("dues/d1").get());
    await assertFails(anon().firestore().doc("dues/d1").get());
    await assertFails(alice().firestore().doc("dues/d1").update({ amount: 1 }));
    await assertFails(hod().firestore().doc("dues/d1").update({ amount: 1 }));
    await assertSucceeds(finsec().firestore().doc("dues/d1").update({ amount: 16000 }));
  });
});

describe("payments and receipts", () => {
  it("lets a student read only their own payments and receipts", async () => {
    const db = alice().firestore();
    await assertSucceeds(db.collection("payments").where("studentId", "==", "ACES001").get());
    await assertSucceeds(db.doc("receipts/r-alice").get());
    await assertFails(db.doc("payments/p-bob").get());
    await assertFails(db.collection("payments").get());
  });
  it("lets admins read everything", async () => {
    await assertSucceeds(hod().firestore().collection("payments").get());
    await assertSucceeds(finsec().firestore().doc("receipts/r-alice").get());
  });
  it("blocks every client write, including admins", async () => {
    for (const db of [alice().firestore(), hod().firestore(), finsec().firestore()]) {
      await assertFails(db.doc("payments/new").set({ studentId: "ACES001", status: "pending", amount: 1 }));
      await assertFails(db.doc("payments/p-bob").update({ status: "successful" }));
      await assertFails(db.doc("receipts/new").set({ studentId: "ACES001" }));
    }
  });
});

describe("notifications", () => {
  it("lets a student read scoped broadcast and personal queries", async () => {
    const db = alice().firestore();
    await assertSucceeds(db.collection("notifications").where("targetAudience", "in", ["all", "level_200"]).get());
    await assertSucceeds(db.collection("notifications").where("studentId", "==", "ACES001").get());
  });
  it("blocks unscoped reads and other students' messages", async () => {
    const db = alice().firestore();
    await assertFails(db.collection("notifications").get());
    await assertFails(db.collection("notifications").where("studentId", "==", "ACES002").get());
    await assertFails(db.doc("notifications/n-bob").get());
  });
  it("lets a student mark their own message read, nothing else", async () => {
    const db = alice().firestore();
    await assertSucceeds(db.doc("notifications/n-alice").update({ isRead: true }));
    await assertFails(db.doc("notifications/n-alice").update({ title: "hacked" }));
    await assertFails(db.doc("notifications/n-bob").update({ isRead: true }));
  });
  it("lets only the Financial Secretary publish", async () => {
    const doc = { title: "t", body: "b", targetAudience: "all", academicYear: "2025/2026" };
    await assertSucceeds(finsec().firestore().doc("notifications/new").set(doc));
    await assertFails(hod().firestore().doc("notifications/new2").set(doc));
    await assertFails(alice().firestore().doc("notifications/new3").set(doc));
  });
});

describe("server-only collections", () => {
  it("hides audit logs from students and OTPs from everyone", async () => {
    await assertFails(alice().firestore().doc("auditLogs/a1").get());
    await assertSucceeds(hod().firestore().doc("auditLogs/a1").get());
    await assertFails(finsec().firestore().doc("auditLogs/new").set({ action: "x" }));
    for (const db of [alice().firestore(), hod().firestore(), finsec().firestore(), anon().firestore()]) {
      await assertFails(db.doc("admin_otps/x@y.z").get());
      await assertFails(db.doc("mail/m1").set({ to: "a@b.c" }));
    }
  });
});

describe("storage: ID photos", () => {
  const bytes = new Uint8Array([1, 2, 3]);
  const jpeg = { contentType: "image/jpeg" };
  const own = "idCards/uid-alice/id_photo.jpg";

  it("lets a student upload and read only their own ID photo", async () => {
    const s = alice().storage();
    await assertSucceeds(uploadBytes(ref(s, own), bytes, jpeg));
    await assertSucceeds(getBytes(ref(s, own)));
    await assertFails(uploadBytes(ref(s, "idCards/uid-bob/id_photo.jpg"), bytes, jpeg));
  });
  it("rejects non-images and files over 5 MB", async () => {
    const s = alice().storage();
    await assertFails(uploadBytes(ref(s, own), bytes, { contentType: "text/html" }));
    await assertFails(uploadBytes(ref(s, own), new Uint8Array(5 * 1024 * 1024 + 1), jpeg));
  });
  it("lets admins read photos but not other students or strangers", async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      await uploadBytes(ref(ctx.storage(), own), bytes, jpeg);
    });
    await assertSucceeds(getBytes(ref(hod().storage(), own)));
    await assertFails(getBytes(ref(bob().storage(), own)));
    await assertFails(getBytes(ref(anon().storage(), own)));
  });
  it("blocks any other path", async () => {
    await assertFails(uploadBytes(ref(alice().storage(), "students/ACES001/id_photo.jpg"), bytes, jpeg));
  });
});
