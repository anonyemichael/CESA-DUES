import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

// Triggered when a payment document is created or updated
export const sendPaymentNotification = functions.firestore
  .document('payments/{paymentId}')
  .onWrite(async (change, context) => {
    const after = change.after.data();
    const before = change.before.data();

    // Only proceed if status changed to 'successful'
    if (!after || after.status !== 'successful') {
      return null;
    }
    if (before && before.status === 'successful') {
      return null; // Already sent
    }

    const indexNumber = after.studentId;

    // Get the student's FCM token
    const studentQuery = await admin.firestore().collection('students').where('indexNumber', '==', indexNumber).limit(1).get();
    
    if (studentQuery.empty) return null;
    
    const student = studentQuery.docs[0].data();
    const fcmToken = student.fcmToken;

    if (!fcmToken) {
      console.log(`No FCM token for student ${indexNumber}`);
      return null;
    }

    const payload = {
      notification: {
        title: 'Payment Successful! 🎉',
        body: `Your payment of GHS ${after.amount} was received successfully.`,
      },
      data: {
        type: 'PAYMENT_RECEIPT',
        paymentId: context.params.paymentId,
      }
    };

    try {
      await admin.messaging().send({
        token: fcmToken,
        notification: payload.notification,
        data: payload.data,
      });
      console.log(`Sent payment notification to ${indexNumber}`);
    } catch (error) {
      console.error(`Error sending notification to ${indexNumber}:`, error);
    }
    return null;
  });

// Triggered when a student document is updated
export const sendVerificationNotification = functions.firestore
  .document('students/{studentId}')
  .onUpdate(async (change, context) => {
    const after = change.after.data();
    const before = change.before.data();

    // Only proceed if verificationStatus changed to 'verified'
    if (before.verificationStatus === after.verificationStatus || after.verificationStatus !== 'verified') {
      return null;
    }

    const fcmToken = after.fcmToken;

    if (!fcmToken) {
      console.log(`No FCM token for verified student ${after.indexNumber}`);
      return null;
    }

    const payload = {
      notification: {
        title: 'ID Verified! ✅',
        body: `Your CESA student identity has been verified. You can now pay your dues.`,
      },
      data: {
        type: 'VERIFICATION_SUCCESS',
      }
    };

    try {
      await admin.messaging().send({
        token: fcmToken,
        notification: payload.notification,
        data: payload.data,
      });
      console.log(`Sent verification notification to ${after.indexNumber}`);
    } catch (error) {
      console.error(`Error sending notification to ${after.indexNumber}:`, error);
    }
    return null;
  });
