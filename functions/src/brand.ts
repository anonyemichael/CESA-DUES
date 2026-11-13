import * as crypto from "crypto";

/**
 * Single place for every identity string used by the Cloud Functions.
 * Keep in sync with cesa_dues_core/lib/src/constants/app_constants.dart.
 */
export const BRAND = {
  appName: "ACES DUES",
  organization: "ACES",
  associationFullName: "Association of Computer Engineering Students",
  universityShort: "UENR",
  receiptPrefix: "ACES",
  studentEmailDomain: "st.uenr.edu.gh",
  programmeName: "BSc. Computer Engineering",
  defaultStudentName: "Computer Engineering Student",
  currency: "GHS",
} as const;

/** e.g. ACES-2026-1A2B3C4D — used for receipt ids and payment references. */
export const newReference = (): string =>
  `${BRAND.receiptPrefix}-${new Date().getFullYear()}-${crypto.randomBytes(4).toString("hex").toUpperCase()}`;
