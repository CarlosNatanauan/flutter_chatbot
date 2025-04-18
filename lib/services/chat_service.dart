import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;
static final ValueNotifier<String?> activeConversationNotifier = ValueNotifier(null);

  static String? _activeConversationId;

  /// Generate a title for the conversation from the first user message
  static String _generateTitle(String text) {
    final trimmed = text.trim();
    return trimmed.length <= 30 ? trimmed : '${trimmed.substring(0, 30)}...';
  }

  /// Create a new conversation if one hasn't been started
  static Future<void> _initConversationIfNeeded(String firstUserMessage) async {
    if (_activeConversationId != null) return;

    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      print('🚫 Cannot initialize conversation: user not signed in.');
      return;
    }

    try {
      final newDoc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('conversations')
          .add({
        'title': _generateTitle(firstUserMessage),
        'createdAt': FieldValue.serverTimestamp(),
      });

      _activeConversationId = newDoc.id;

      print('📝 New conversation created: $_activeConversationId');
    } catch (e) {
      print('❌ Failed to create conversation: $e');
    }
  }

  /// Save a message to Firestore under the active conversation
  static Future<void> saveMessage(String sender, String text) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      print('🚫 Cannot save message: user not signed in.');
      return;
    }

    if (sender == "user") {
      await _initConversationIfNeeded(text);
    }

    if (_activeConversationId == null) {
      print('⚠️ No active conversation. Message not saved.');
      return;
    }

    final message = {
      'sender': sender,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    };

    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('conversations')
          .doc(_activeConversationId)
          .collection('messages')
          .add(message);
    } catch (e) {
      print('❌ Failed to save message: $e');
    }
  }

  /// Optional: to reset if user ends or starts a new conversation
static void resetConversation() {
  print('🔄 Resetting active conversation.');
  _activeConversationId = null;
  activeConversationNotifier.value = null; // 👈 notify UI
}


  /// Get the current conversation message stream
static Stream<QuerySnapshot> getMessageStream() {
  final uid = _auth.currentUser?.uid;

  if (uid == null) {
    print('🚫 Cannot get messages: user not signed in.');
    return const Stream.empty();
  }

  if (_activeConversationId == null) {
    print('⚠️ No active conversation. Returning empty stream.');
    return const Stream.empty();
  }

  print('✅ Subscribing to conversation: $_activeConversationId');
  return _firestore
      .collection('users')
      .doc(uid)
      .collection('conversations')
      .doc(_activeConversationId)
      .collection('messages')
      .orderBy('timestamp', descending: true)
      .snapshots();
}


  static void setConversationId(String id) {
    _activeConversationId = id;
    activeConversationNotifier.value = id; // 👈 Notify listeners
  }
}
