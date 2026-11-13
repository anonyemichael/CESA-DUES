/**
 * Seeds sample dues and a welcome announcement for ACES DUES.
 *
 * Usage (needs Application Default Credentials for the project):
 *   cd functions && node seed.js
 *
 * The amounts below are PLACEHOLDERS. The Financial Secretary should set the real
 * dues in the admin app (Dues -> Add) before students start paying.
 */
const admin = require('firebase-admin');

const PROJECT_ID = process.env.GCLOUD_PROJECT || 'cesa-dues-9a267';
process.env.GCLOUD_PROJECT = PROJECT_ID;
process.env.GOOGLE_CLOUD_PROJECT = PROJECT_ID;

if (!admin.apps.length) {
  admin.initializeApp({ projectId: PROJECT_ID });
}

const db = admin.firestore();
const ACADEMIC_YEAR = '2025/2026';

async function seed() {
  console.log(`Seeding sample dues and announcement into ${PROJECT_ID}...`);

  const dues = [
    {
      id: 'dues_2025_2026_annual',
      name: 'ACES Annual Association Dues (2025/2026)',
      amount: 12000, // GHS 120.00 in pesewas (placeholder)
      description: 'Annual dues for all Computer Engineering students of the Association of Computer Engineering Students (ACES), UENR.',
    },
    {
      id: 'dues_2025_2026_souvenir',
      name: 'ACES Souvenir & Association Wear',
      amount: 8000, // GHS 80.00 in pesewas (placeholder)
      description: 'Official ACES branded wear and ID lanyard.',
    },
  ];

  for (const d of dues) {
    await db.collection('dues').doc(d.id).set({
      ...d,
      academicYear: ACADEMIC_YEAR,
      applicableLevels: [100, 200, 300, 400],
      status: 'active',
      deadline: admin.firestore.Timestamp.fromDate(new Date('2026-12-31T23:59:59Z')),
      version: 1,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
    console.log(`Seeded dues: ${d.name}`);
  }

  await db.collection('notifications').doc('notif_welcome_2025').set({
    title: 'Welcome to ACES DUES',
    body: 'Welcome to the official dues portal of the Association of Computer Engineering Students, UENR. Verify your student ID to pay dues and get your digital clearance pass.',
    type: 'announcement',
    targetAudience: 'all',
    academicYear: ACADEMIC_YEAR,
    isRead: false,
    sentAt: admin.firestore.FieldValue.serverTimestamp(),
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  }, { merge: true });
  console.log('Seeded welcome announcement');

  console.log('Seeding complete.');
  process.exit(0);
}

seed().catch((err) => {
  console.error('Seeding error:', err);
  process.exit(1);
});
