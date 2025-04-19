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

  // Scroll to the bottom of the chat
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
    final conversationId = ChatService.activeConversationNotifier.value;

    if (isFirstMessage) {
      final words = input.split(' ');
      final titleWords = words.length > 6 ? words.sublist(0, 6) : words;
      final generatedTitle = titleWords.join(' ');
      print('📝 Generated conversation title: $generatedTitle');
    }

    // Clear the input field immediately
    _controller.clear();

    // Save user message to Firestore first
    await ChatService.saveMessage("user", input);

    // 🧠 Force-select the convo if it was just created
    if (isFirstMessage) {
      final newId = ChatService.getCurrentConversationId();
      if (newId != null) {
        await Future.delayed(const Duration(milliseconds: 100));
        ChatService.setConversationId(newId);
      }
    }

    // Now we're waiting for AI response
    setState(() {
      _isWaitingForResponse = true;
    });

    // Scroll to show the latest message
    _scrollToBottom();

    // Get response from Gemini
    final response =
        await GeminiService.getResponse(input, conversationId ?? 'temp-id');

    // Save AI response to Firestore
    await ChatService.saveMessage("gemini", response);

    // No longer waiting for response
    setState(() {
      _isWaitingForResponse = false;
    });

    // Scroll to show the AI response
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

  Widget _buildDot(int index) {
    return SizedBox(
      width: 8,
      height: 8,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: _isWaitingForResponse
              ? AppColors.darkNavy
              : AppColors.gray.withOpacity(0.5),
          shape: BoxShape.circle,
        ),
        margin: EdgeInsets.symmetric(horizontal: 4),
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

                    if (docs.isEmpty && !_isWaitingForResponse) {
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
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      reverse: true,
                      itemCount: docs.length + (_isWaitingForResponse ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (_isWaitingForResponse && index == 0) {
                          return _buildTypingIndicator();
                        }

                        final actualIndex =
                            _isWaitingForResponse ? index - 1 : index;
                        final doc = docs[actualIndex];
                        final data = doc.data() as Map<String, dynamic>;
                        return _buildMessage(data['sender'], data['text']);
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
