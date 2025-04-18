import 'package:flutter/material.dart';
import 'package:flutter_chatbot/pages/chat_screen.dart';
import 'package:flutter_chatbot/pages/menu/menu_screen.dart';
import 'package:flutter_chatbot/services/chat_service.dart';
import 'package:flutter_chatbot/theme/colors.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';

class DrawerWrapper extends StatelessWidget {
  final zoomDrawerController = ZoomDrawerController();

  DrawerWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return ZoomDrawer(
  controller: zoomDrawerController,
  menuScreen: const MenuScreen(),
  mainScreen: ValueListenableBuilder(
  valueListenable: ChatService.activeConversationNotifier,

  builder: (context, conversationId, _) {
    return ChatScreen(key: ValueKey(conversationId)); // force rebuild
  },
),

  borderRadius: 24.0,
  showShadow: true,
  angle: -5.0,
  slideWidth: MediaQuery.of(context).size.width * 0.85,
  style: DrawerStyle.defaultStyle,

  // ✅ This is the correct one!
  drawerShadowsBackgroundColor: AppColors.lightAquaText,

  // Optional: make the menu area match too
  menuBackgroundColor: AppColors.lightNavy,
  mainScreenTapClose: true,
);

  }
}
