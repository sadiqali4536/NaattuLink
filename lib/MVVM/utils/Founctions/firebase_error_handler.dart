import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// A utility class to convert Firebase and Firestore exceptions into clean,
/// user-friendly text messages, avoiding raw codes or stack traces in UI/logs.
class FirebaseErrorHandler {
  /// Maps a Firebase exception to a clean, user-friendly message.
  static String getReadableErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          return "Please enter a valid email address.";
        case 'user-disabled':
          return "This account has been disabled. Please contact support.";
        case 'user-not-found':
          return "No account found with this email.";
        case 'wrong-password':
        case 'invalid-credential':
          return "Invalid email or password.";
        case 'email-already-in-use':
          return "This email address is already in use by another account.";
        case 'weak-password':
          return "The password provided is too weak.";
        case 'operation-not-allowed':
          return "This operation is not allowed. Please contact support.";
        case 'too-many-requests':
          return "Too many requests. Please try again later.";
        case 'network-request-failed':
          return "Network connection failed. Please check your internet connection.";
        default:
          return error.message ?? "An authentication error occurred. Please try again.";
      }
    } else if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return "Access denied. You do not have permission to perform this action.";
        case 'unavailable':
          return "The database service is temporarily unavailable. Please try again later.";
        case 'not-found':
          return "The requested resource was not found.";
        case 'already-exists':
          return "The resource already exists.";
        case 'aborted':
          return "The operation was aborted. Please try again.";
        default:
          return error.message ?? "A database error occurred. Please try again.";
      }
    }
    
    // Return a clean fallback for other exceptions
    final errorString = error.toString();
    if (errorString.contains("cloud_firestore/unavailable")) {
      return "The database service is temporarily unavailable. Please try again later.";
    } else if (errorString.contains("permission-denied")) {
      return "Access denied. You do not have permission to perform this action.";
    }
    
    return "An unexpected error occurred. Please try again.";
  }
}
