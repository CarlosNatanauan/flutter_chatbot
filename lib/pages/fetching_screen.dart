import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chatbot/pages/menu/drawer_wrapper.dart';
import 'package:flutter_chatbot/theme/colors.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class FetchingScreen extends StatefulWidget {
  const FetchingScreen({super.key});

  @override
  State<FetchingScreen> createState() => _FetchingScreenState();
}

class _FetchingScreenState extends State<FetchingScreen> {
@override
void initState() {
  super.initState();
  final user = FirebaseAuth.instance.currentUser;
print('✅ Current user UID: ${user?.uid}');

  Future.delayed(const Duration(seconds: 2), () {
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) =>  DrawerWrapper()),
    );
  });
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkNavy,
      body: SafeArea(
        child: Align(
          alignment: const Alignment(0, -0.5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Big centered logo
              Image.asset(
                'assets/images/logo/app_logo_v3.png',
                height: 350,
              ),

              // Loading animation
              LoadingAnimationWidget.beat(
                color: AppColors.lightAquaText,
                size: 70,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
