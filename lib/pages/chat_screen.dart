import 'package:flutter/material.dart';
import 'package:flutter_chatbot/pages/widgets/enabled_input_field.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../services/gemini_service.dart';
import '../theme/colors.dart';
import '../services/chat_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:markdown/markdown.dart' as markdown;
import 'package:url_launcher/url_launcher.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isWaitingForResponse = false;
  bool _hasError = false;
  final List<Map<String, dynamic>> _localMessages = [];

  @override
  void initState() {
    super.initState();

    final convoId = ChatService.activeConversationNotifier.value;
    print('🔁 initState - current convoId: $convoId');

    if (convoId != null) {
      ChatService.setConversationId(convoId);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  Future<void> _sendPrompt() async {
    final input = _controller.text.trim();
    if (input.isEmpty) return;

    final isFirstMessage = ChatService.activeConversationNotifier.value == null;
    final previousConvoId = ChatService.activeConversationNotifier.value;

    // Optimistically add user message
    setState(() {
      _isWaitingForResponse = true;
      _localMessages.insert(0, {'sender': 'user', 'text': input});
    });

    _controller.clear();
    _scrollToBottom();

    // Save user message
    await ChatService.saveMessage("user", input);

    // Handle new conversation logic
    if (isFirstMessage) {
      final newId = ChatService.getCurrentConversationId();
      if (newId != null && newId != previousConvoId) {
        await ChatService.setConversationId(newId);

        // 🛠 Wait for the first Firestore snapshot with at least one message
        bool initialMessageSeen = false;
        int retries = 0;

        while (!initialMessageSeen && retries < 10) {
          final snapshot = await ChatService.getMessageStream().first;
          if (snapshot.docs.isNotEmpty) {
            initialMessageSeen = true;
          } else {
            await Future.delayed(const Duration(milliseconds: 200));
            retries++;
          }
        }
      }
    }

    final finalConvoId = ChatService.getCurrentConversationId() ?? 'temp-id';

    // Get AI response and save it
    final aiResponse = await GeminiService.getResponse(input, finalConvoId);
    await ChatService.saveMessage("gemini", aiResponse);

    // Wait for Firestore to reflect the new AI message before updating UI
    bool responseSaved = false;
    int retries = 0;

    while (!responseSaved && retries < 10) {
      final snapshot = await ChatService.getMessageStream().first;
      final docs = snapshot.docs;

      responseSaved = docs.any((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return data['text'] == aiResponse && data['sender'] == 'gemini';
      });

      if (!responseSaved) {
        await Future.delayed(const Duration(milliseconds: 200));
        retries++;
      }
    }

    // Update UI after message is confirmed in Firestore
    if (mounted) {
      setState(() {
        _isWaitingForResponse = false;
        _localMessages.clear();
      });
    }

    _scrollToBottom();
  }

  Widget _buildMessage(String sender, String text) {
    final isUser = sender == "user";
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          color: isUser ? AppColors.coolTeal : AppColors.gray,
          borderRadius: BorderRadius.circular(14),
        ),
        child: isUser
            ? Text(
                text,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              )
            : MarkdownBody(
                data: text,
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(color: AppColors.darkNavy, fontSize: 16),
                  strong: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.gray.withOpacity(0.8),
          borderRadius: BorderRadius.circular(14),
        ),
        child: LoadingAnimationWidget.waveDots(
          color: AppColors.darkNavy,
          size: 40,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkNavy,
appBar: AppBar(
  backgroundColor: AppColors.coolTeal,
  elevation: 3,
  automaticallyImplyLeading: false,
  toolbarHeight: 70,
  titleSpacing: 0,
  title: Row(
    children: [

      const Text(
        'USAP AI',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 1,
        ),
      ),
            Image.asset(
        'assets/images/logo/app_logo_v3_notext.png',
        height: 35,
        width: 35,
      ),
    ],
  ),
  leading: IconButton(
    icon: const Icon(Icons.menu, color: Colors.white),
    onPressed: () {
      final drawer = ZoomDrawer.of(context);
      if (drawer != null) {
        drawer.toggle();
      }
    },
  ),
  actions: [
    IconButton(
      icon: const Icon(Icons.lightbulb_outline, color: Colors.white),
      tooltip: 'Tips',
      onPressed: () {
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    behavior: SnackBarBehavior.floating,
    backgroundColor: AppColors.coolTeal.withOpacity(0.95),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    duration: const Duration(seconds: 3),
    content: Row(
      children: const [
        Icon(Icons.lightbulb_outline, color: Colors.white, size: 20),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            'Tip: Tanong ka lang, walang mali sa curiosity!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14.5,
            ),
          ),
        ),
      ],
    ),
  ),
);

      },
    ),
  ],
),


      body: Column(
        children: [
          Expanded(
            child: ValueListenableBuilder<String?>(
              valueListenable: ChatService.activeConversationNotifier,
              builder: (context, convoId, _) {
                if (convoId == null) {
return Center(
  child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24.0),
    child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.gray.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Text(
            'Tahimik ka yata, par? 👀',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Kung may gusto kang sabihin o itanong,\nusap lang tayo.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white38,
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    ),
  ),
);


                }

                return StreamBuilder<QuerySnapshot>(
                  stream: ChatService.getMessageStream(),
                  builder: (context, snapshot) {
                    debugPrint("📡 StreamBuilder rebuild triggered");

                    final docs = snapshot.data?.docs ?? [];
                    final firestoreMessages = docs
                        .map((doc) => doc.data() as Map<String, dynamic>)
                        .toList();

                    final allMessages = [
                      ..._localMessages.where((localMsg) {
                        return !firestoreMessages.any((fsMsg) =>
                            fsMsg['text'] == localMsg['text'] &&
                            fsMsg['sender'] == localMsg['sender']);
                      }),
                      ...firestoreMessages,
                    ];

                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      reverse: true,
                      itemCount:
                          allMessages.length + (_isWaitingForResponse ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (_isWaitingForResponse && index == 0) {
                          return _buildTypingIndicator();
                        }

                        final actualIndex =
                            _isWaitingForResponse ? index - 1 : index;
                        final msg = allMessages[actualIndex];
                        return _buildMessage(msg['sender'], msg['text']);
                      },
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: ExpandableInputField(
              controller: _controller,
              onSend: (msg) {
                _sendPrompt();
              },
            ),
          ),
        ],
      ),
    );
  }
}
