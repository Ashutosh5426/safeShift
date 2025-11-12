import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  /// Use the singleton instance
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String?> signInWithGoogle() async {
    try {
      /// Initialize Google Sign-In
      await _googleSignIn.initialize();

      /// Start the authentication flow
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();

      /// Get authentication tokens
      final GoogleSignInAuthentication googleAuth =
      googleUser.authentication;

      /// Create credential - ONLY use idToken in newer versions
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        /// accessToken is no longer available in GoogleSignInAuthentication
      );

      /// Sign in to Firebase
      final UserCredential userCredential =
      await _auth.signInWithCredential(credential);

      // return userCredential.user;
      return credential.idToken;
    } catch (e) {
      print('Google Sign-In Error: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  Stream<User?> get userStream => _auth.authStateChanges();
}