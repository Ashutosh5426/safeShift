import 'package:firebase_auth/firebase_auth.dart';
import 'package:frontend/core/app/di/injections.dart';
import 'package:frontend/core/app/state/app_state.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  AuthService._();
  static AuthService get instance => AuthService._();

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String?> signInWithGoogle() async {
    try {
      await _googleSignIn.initialize(
        clientId: getIt<AppState>().iosClientId,
        serverClientId: getIt<AppState>().serverClientId,
      );

      /// Start the authentication flow
      final GoogleSignInAccount googleUser =
      await _googleSignIn.authenticate();

      final googleAuth = googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);

      return googleAuth.idToken;

    } catch (e) {
      print("Google Sign-In Error: $e");
      return null;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  Stream<User?> get userStream => _auth.authStateChanges();
}