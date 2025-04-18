import 'package:firebase_vertexai/firebase_vertexai.dart';

class GeminiService {
  static Future<String> getResponse(String promptText) async {
    try {
      final model = FirebaseVertexAI.instance
          .generativeModel(model: 'gemini-2.0-flash');

      final prompt = [Content.text(promptText)];
      final result = await model.generateContent(prompt);

      return result.text ?? 'No response 😅';
    } catch (e) {
      return 'Error: $e';
    }
  }
}
