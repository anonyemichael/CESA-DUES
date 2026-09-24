import { assertFails, assertSucceeds, initializeTestEnvironment, RulesTestEnvironment } from "@firebase/rules-unit-testing";
import * as fs from "fs";
import * as path from "path";

let testEnv: RulesTestEnvironment;

beforeAll(async () => {
  // Load the rules file
  const rulesPath = path.resolve(__dirname, "../../firestore.rules");
  const rules = fs.readFileSync(rulesPath, "utf8");

  // Initialize test environment
  testEnv = await initializeTestEnvironment({
    projectId: "cesa-dues-test",
    firestore: {
      rules,
    },
  });
});

afterAll(async () => {
  await testEnv.cleanup();
});

beforeEach(async () => {
  await testEnv.clearFirestore();
});

describe("Firestore Security Rules", () => {
  
  it("should allow a student to read their own profile", async () => {
    const studentDb = testEnv.authenticatedContext("student123", { email: "student@uenr.gh" }).firestore();
    const profileRef = studentDb.collection("students").doc("student123");
    await assertSucceeds(profileRef.get());
  });

  it("should deny a student from reading another student's profile", async () => {
    const studentDb = testEnv.authenticatedContext("student123", { email: "student@uenr.gh" }).firestore();
    const otherProfileRef = studentDb.collection("students").doc("student456");
    await assertFails(otherProfileRef.get());
  });

  it("should allow a Financial Secretary to read any profile", async () => {
    const finSecDb = testEnv.authenticatedContext("finsec123", { role: "financial_secretary", admin: true }).firestore();
    const studentProfileRef = finSecDb.collection("students").doc("student456");
    await assertSucceeds(studentProfileRef.get());
  });

  it("should allow a student to create a pending payment for themselves", async () => {
    const studentDb = testEnv.authenticatedContext("student123", { email: "student@uenr.gh" }).firestore();
    const paymentRef = studentDb.collection("payments").doc("pay123");
    
    await assertSucceeds(paymentRef.set({
      studentId: "student123",
      status: "pending",
      amount: 5000
    }));
  });

  it("should deny a student from creating a successful payment directly", async () => {
    const studentDb = testEnv.authenticatedContext("student123", { email: "student@uenr.gh" }).firestore();
    const paymentRef = studentDb.collection("payments").doc("pay123");
    
    await assertFails(paymentRef.set({
      studentId: "student123",
      status: "successful", // Client cannot set this!
      amount: 5000
    }));
  });

  it("should deny client writes to the receipts collection", async () => {
    const studentDb = testEnv.authenticatedContext("student123", { email: "student@uenr.gh" }).firestore();
    const receiptRef = studentDb.collection("receipts").doc("rec123");
    await assertFails(receiptRef.set({ studentId: "student123" }));

    const finSecDb = testEnv.authenticatedContext("finsec123", { role: "financial_secretary", admin: true }).firestore();
    const finSecReceiptRef = finSecDb.collection("receipts").doc("rec456");
    await assertFails(finSecReceiptRef.set({ studentId: "student456" })); // Admins can't write receipts directly either
  });

});
