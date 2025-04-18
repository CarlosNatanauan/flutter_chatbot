import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chatbot/theme/colors.dart';
import 'package:sign_button/sign_button.dart';
import '../services/auth_service.dart';
import 'fetching_screen.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

Future<void> _handleGoogleSignIn(BuildContext context) async {
  final userCred = await AuthService.signInWithGoogle();

  if (userCred != null && context.mounted) {
    final user = userCred.user!;
    final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);

    // ✅ DEBUG LOGS + DOC CREATION
    print('🔥 Signed in as ${user.email}');
    print('📄 Ensuring Firestore document for UID: ${user.uid}');

    await docRef.set({
      'email': user.email,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    print('✅ User doc written!');

    // 🧭 Only navigate after Firestore is ready
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const FetchingScreen()),
    );
  }
}




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkNavy,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo and title stacked tightly
                Column(
                  children: [
                    Image.asset(
                      'assets/images/logo/app_logo_v3_notext.png',
                      height: 260,
                    ),
                    const Text(
                      "Welcome to USAP AI",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                Text(
                  "Your Gemini-powered chat companion",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.lightAquaText.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 48),

                // Google Sign-In Button
                SignInButton(
                  buttonType: ButtonType.google,
                  buttonSize: ButtonSize.large,
                  onPressed: () => _handleGoogleSignIn(context),
                  btnText: 'Continue with Google',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
