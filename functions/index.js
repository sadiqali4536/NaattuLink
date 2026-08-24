const { onCall, HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

admin.initializeApp();

exports.securePasswordReset = onCall(async (request) => {
  const data = request.data;
  const email = data.email?.toLowerCase().trim();
  const otp = data.otp;
  const newPassword = data.newPassword;

  if (!email || !otp || !newPassword) {
    throw new HttpsError("invalid-argument", "Missing required fields.");
  }

  const db = admin.firestore();

  try {
    // 1. Verify OTP
    const otpDocRef = db.collection("password_reset_otps").doc(email);
    const otpDoc = await otpDocRef.get();

    if (!otpDoc.exists) {
      throw new HttpsError("not-found", "OTP not found or expired.");
    }

    const otpData = otpDoc.data();
    
    // Check if OTP matches
    if (otpData.otp !== otp) {
      throw new HttpsError("permission-denied", "Incorrect OTP.");
    }

    // Check expiration
    const expiresAt = otpData.expiresAt.toDate();
    if (new Date() > expiresAt) {
      throw new HttpsError("failed-precondition", "OTP has expired.");
    }

    // 2. Update Firebase Auth Password
    // Find the user first to get their UID
    const userRecord = await admin.auth().getUserByEmail(email);
    
    await admin.auth().updateUser(userRecord.uid, {
      password: newPassword,
    });

    // 3. Delete the OTP document so it cannot be reused
    await otpDocRef.delete();

    // 4. (Optional) We stop saving the plain-text password to the custom collection
    // as per the recommendation to make Firebase Auth the single source of truth.
    // If you ever need to clean up old plain-text passwords, you could do it here:
    // await db.collection(otpData.collectionName).doc(otpData.documentId).update({
    //   password: admin.firestore.FieldValue.delete(),
    // });

    return { success: true, message: "Password updated successfully." };

  } catch (error) {
    console.error("Error in securePasswordReset:", error);
    
    if (error instanceof HttpsError) {
      throw error;
    }
    
    // Handle Firebase Auth errors (e.g. user not found)
    if (error.code === 'auth/user-not-found') {
       throw new HttpsError("not-found", "User not found in Authentication.");
    }

    throw new HttpsError("internal", "An error occurred while resetting the password.");
  }
});
