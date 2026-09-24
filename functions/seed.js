const admin = require('firebase-admin');

process.env.GCLOUD_PROJECT = 'cesa-dues-9a267';
process.env.GOOGLE_CLOUD_PROJECT = 'cesa-dues-9a267';

if (!admin.apps.length) {
  admin.initializeApp({
    projectId: 'cesa-dues-9a267'
  });
}

const db = admin.firestore();

async function seed() {
  console.log('Seeding initial Dues and Announcements into Firestore (cesa-dues-9a267)...');
  
  // 1. Seed Dues
  const dues1 = {
    id: 'dues_2025_2026_annual',
    name: 'CESA Departmental Annual Dues (2025/2026)',
    amount: 12000, // GHS 120.00 in pesewas
    academicYear: '2025/2026',
    applicableLevels: [100, 200, 300, 400],
    description: 'Mandatory annual dues for all Computer Engineering students for the 2025/2026 academic year.',
    status: 'active',
    deadline: admin.firestore.Timestamp.fromDate(new Date('2026-12-31T23:59:59Z')),
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  };

  const dues2 = {
    id: 'dues_2025_2026_souvenir',
    name: 'CESA Souvenir & Departmental Lacoste',
    amount: 8000, // GHS 80.00 in pesewas
    academicYear: '2025/2026',
    applicableLevels: [100, 200, 300, 400],
    description: 'Official customized CESA Departmental Lacoste shirt and custom ID lanyard.',
    status: 'active',
    deadline: admin.firestore.Timestamp.fromDate(new Date('2026-12-31T23:59:59Z')),
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  };

  await db.collection('dues').doc(dues1.id).set(dues1);
  console.log('Seeded Dues 1: Annual Dues');

  await db.collection('dues').doc(dues2.id).set(dues2);
  console.log('Seeded Dues 2: Souvenir Dues');

  // 2. Seed Welcome Announcement
  const notif = {
    id: 'notif_welcome_2025',
    title: 'Welcome to CESA Dues Portal',
    message: 'Welcome to the official Computer Engineering Students Association Dues & Verification Portal. Please complete your ID verification to make dues payments and access your digital ID card.',
    targetAudience: 'all',
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  };

  await db.collection('notifications').doc(notif.id).set(notif);
  console.log('Seeded Welcome Notification');

  console.log('Seeding complete!');
  process.exit(0);
}

seed().catch(err => {
  console.error('Seeding error:', err);
  process.exit(1);
});
