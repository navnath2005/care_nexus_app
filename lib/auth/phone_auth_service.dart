import 'package:firebase_auth/firebase_auth.dart';

class PhoneAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> sendOTP(
    String phoneNumber,
    Function(String verificationId) codeSent,
    Function(String error) onError, // Added error callback
  ) async {
    try {
      // Basic validation: Ensure it starts with '+' and has enough digits
      if (!phoneNumber.startsWith('+') || phoneNumber.length < 10) {
        onError("Invalid format. Use +[CountryCode][Number]");
        return;
      }

      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          onError(e.message ?? "Verification Failed");
        },
        codeSent: (String verificationId, int? resendToken) {
          codeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      onError(e.toString());
    }
  }

  Future<UserCredential> verifyOTP(String verificationId, String otp) async {
    PhoneAuthCredential credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: otp,
    );
    return await _auth.signInWithCredential(credential);
  }
}
