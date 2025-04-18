import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_chatbot/pages/menu/settings_screen.dart';
import 'package:flutter_chatbot/services/chat_service.dart'; // 👈 for setting active conversation
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';
import '../../theme/colors.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Material(
      color: AppColors.darkNavy,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  ChatService.resetConversation();
                  ZoomDrawer.of(context)?.close();
                },
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.coolTeal.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        "Start new Chat",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Icon(Icons.create_outlined,
                          color: Colors.white, size: 20),
                    ],
                  ),
                ),
              ),

              const Text(
                "Conversations",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // Scrollable conversations
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(user?.uid)
                      .collection('conversations')
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Text(
                        'No conversations yet',
                        style: TextStyle(color: Colors.white54),
                      );
                    }

                    return ValueListenableBuilder<String?>(
                      valueListenable: ChatService.activeConversationNotifier,
                      builder: (context, activeId, _) {
                        return ListView(
                          padding: EdgeInsets.zero,
                          children: snapshot.data!.docs.map((doc) {
                            final title = doc['title'];
                            final id = doc.id;
                            final isSelected = id == activeId;

                            return Container(
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.coolTeal.withOpacity(0.2)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ListTile(
                                dense: true,
                                contentPadding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                title: Text(
                                  title,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: isSelected
                                        ? AppColors.goldSun
                                        : Colors.white,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                                onTap: () {
                                  ChatService.setConversationId(id);
                                  ZoomDrawer.of(context)?.close();
                                },
                              ),
                            );
                          }).toList(),
                        );
                      },
                    );
                  },
                ),
              ),

              // 👇 Fixed bottom profile section
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
                child: Row(
                  children: [
                    if (user?.photoURL != null)
                      CircleAvatar(
                        radius: 20,
                        backgroundImage: NetworkImage(user!.photoURL!),
                      )
                    else
                      const CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.grey,
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        user?.displayName ?? "Anonymous",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.keyboard_arrow_right, color: Colors.white),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
