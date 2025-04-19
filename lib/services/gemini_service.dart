import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_vertexai/firebase_vertexai.dart';

class GeminiService {
  // Map to store conversation histories for different conversation IDs
  static final Map<String, List<Content>> conversationHistories = {};
  static String? currentConversationId;

  static Future<String> getResponse(String promptText, String conversationId) async {
    try {
      // Set current conversation ID
      currentConversationId = conversationId;
      
      // Initialize history for this conversation if it doesn't exist
      if (!conversationHistories.containsKey(conversationId)) {
        conversationHistories[conversationId] = [];
      }
      
      // Get the conversation history for this conversation
      final conversationHistory = conversationHistories[conversationId]!;
      
      final model = FirebaseVertexAI.instance
          .generativeModel(model: 'gemini-2.0-flash');

      // Add the user's message to conversation history
      conversationHistory.add(Content.text(promptText));
      
      // Pass the conversation history to Gemini
      final result = await model.generateContent(conversationHistory);
      
      // Add the model's response to conversation history
      if (result.text != null) {
        conversationHistory.add(Content.text(result.text!));
      }

      return result.text ?? 'No response 😅';
    } catch (e) {
      return 'Error: $e';
    }
  }
  
  // Method to reset a specific conversation's history
  static void resetConversation([String? conversationId]) {
    if (conversationId != null) {
      conversationHistories.remove(conversationId);
    } else if (currentConversationId != null) {
      conversationHistories.remove(currentConversationId);
    }
  }
  
  // Load message history from Firestore for a given conversation
  static Future<void> loadConversationHistory(String conversationId, List<Map<String, dynamic>> messages) async {
    // Clear existing history for this conversation
    conversationHistories[conversationId] = [];
    
    // Sort messages by timestamp (oldest first)
    messages.sort((a, b) {
      final aTime = a['timestamp'] as Timestamp?;
      final bTime = b['timestamp'] as Timestamp?;
      if (aTime == null || bTime == null) return 0;
      return aTime.compareTo(bTime);
    });
    
    // Add messages to conversation history
    for (final message in messages) {
      final sender = message['sender'] as String;
      final text = message['text'] as String;
      conversationHistories[conversationId]!.add(Content.text(text));
    }
  }
}