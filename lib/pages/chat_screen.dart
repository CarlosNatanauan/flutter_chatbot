import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';
import '../services/gemini_service.dart';
import '../theme/colors.dart';
import '../services/chat_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;
  String _typingText = '';

@override
void initState() {
  super.initState();

  final convoId = ChatService.activeConversationNotifier.value;
  print('🔁 initState - current convoId: $convoId');

  if (convoId != null) {
    ChatService.setConversationId(convoId); // ensures stream updates
  }
}

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _sendPrompt() async {
    final input = _controller.text.trim();
    if (input.isEmpty) return;

    final isFirstMessage = ChatService.activeConversationNotifier.value == null;

    if (isFirstMessage) {
      final words = input.split(' ');
      final titleWords = words.length > 6 ? words.sublist(0, 6) : words;
      final generatedTitle = titleWords.join(' ');
      print('📝 Generated conversation title: $generatedTitle');
    }

    setState(() {
      _isLoading = true;
      _controller.clear();
      _typingText = '';
    });

    await ChatService.saveMessage("user", input);
    final response = await GeminiService.getResponse(input);

    // Typing effect
    for (int i = 0; i < response.length; i++) {
      await Future.delayed(const Duration(milliseconds: 0));
      setState(() {
        _typingText = response.substring(0, i + 1);
      });
    }

    setState(() {
      _isLoading = false;
    });

    await ChatService.saveMessage("gemini", response);
    _typingText = '';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkNavy,
      appBar: AppBar(
        backgroundColor: AppColors.coolTeal,
        automaticallyImplyLeading: false,
        title: const Text('USAP AI'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            final drawer = ZoomDrawer.of(context);
            if (drawer != null) {
              drawer.toggle();
            }
          },
        ),
      ),
      body: Column(
        children: [
Expanded(
  child: ValueListenableBuilder<String?>(
    valueListenable: ChatService.activeConversationNotifier,
    builder: (context, convoId, _) {


      return StreamBuilder<QuerySnapshot>(
        stream: ChatService.getMessageStream(),
        builder: (context, snapshot) {
          debugPrint("📡 StreamBuilder rebuild triggered");

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          debugPrint("📄 Loaded ${docs.length} messages");

if (docs.isEmpty && _typingText.isEmpty) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        SizedBox(height: 16),
        Text(
          'Anong kailangan mo par?',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 19,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}


          return ListView.builder(
            padding: const EdgeInsets.all(16),
            reverse: true,
            itemCount: docs.length + (_typingText.isNotEmpty ? 1 : 0),
            itemBuilder: (context, index) {
              if (_typingText.isNotEmpty && index == 0) {
                return _buildMessage("gemini", _typingText);
              }

              final doc = docs[_typingText.isNotEmpty ? index - 1 : index];
              final data = doc.data() as Map<String, dynamic>;
              return _buildMessage(data['sender'], data['text']);
            },
          );
        },
      );
    },
  ),
),


          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: CircularProgressIndicator(color: AppColors.goldSun),
            ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      hintStyle: TextStyle(color: AppColors.lightAquaText),
                      filled: true,
                      fillColor: AppColors.deepPurple.withOpacity(0.3),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _sendPrompt(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _sendPrompt,
                  icon: const Icon(Icons.send, color: AppColors.goldSun),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
