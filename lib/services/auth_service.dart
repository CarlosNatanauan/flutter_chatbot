import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static final _auth = FirebaseAuth.instance;
  static final _googleSignIn = GoogleSignIn();

  static User? get currentUser => _auth.currentUser;

  static Future<UserCredential?> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      // 🔐 Store user info in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final user = userCredential.user;

      if (user != null) {
        await prefs.setString('uid', user.uid);
        await prefs.setString('name', user.displayName ?? '');
        await prefs.setString('email', user.email ?? '');
        await prefs.setString('photoUrl', user.photoURL ?? '');

        print('✅ User info saved to SharedPreferences');
        print('Name: ${user.displayName}');
        print('Email: ${user.email}');
        print('UID: ${user.uid}');
      }

      return userCredential;
    } catch (e) {
      print('Google Sign-In error: $e');
      return null;
    }
  }

static Future<void> signOut() async {
  try {
    await _auth.signOut();
    await _googleSignIn.disconnect(); // Force account picker next time
    await _googleSignIn.signOut();

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Clear stored user data

    print('🔓 User fully signed out and data cleared');
  } catch (e) {
    print('Sign-out error: $e');
  }
}

}
