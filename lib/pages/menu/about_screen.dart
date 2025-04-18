import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/colors.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

void _launchGitHub() async {
  final uri = Uri.parse('https://github.com/CarlosNatanauan');

  try {
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $uri');
    }
  } catch (e) {
    debugPrint('Launch error: $e');
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkNavy,
      appBar: AppBar(
        backgroundColor: AppColors.coolTeal,
        title: const Text("About"),
        leading: const BackButton(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        children: [
          Center(
            child: Column(
              children: [
                Image.asset(
                  'assets/images/logo/app_logo_v3_notext.png',
                  height: 160,
                ),
                const Text(
                  "USAP AI",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Version 1.0.0",
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.lightAquaText,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),

          const Text(
            "About the App",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "USAP AI is your personal chatbot companion built using Gemini, Firebase, and Flutter. "
            "Talk, learn, explore — wherever you are.",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 30),

          const Text(
            "Acknowledgements",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "This app is powered by Flutter and Firebase.\nDesigned with ❤️ for curious minds.",
            style: TextStyle(
              color: AppColors.lightAquaText,
              fontSize: 14,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 30),

          const Text(
            "Developer",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),

          GestureDetector(
            onTap: _launchGitHub,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.deepPurple.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.code, color: AppColors.lightAquaText, size: 22),
                  const SizedBox(width: 12),
                  Text(
                    "Carlos Natanauan",
                    style: TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.open_in_new, color: AppColors.lightAquaText, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
