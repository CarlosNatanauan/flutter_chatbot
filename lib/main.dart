import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_vertexai/firebase_vertexai.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Chatbot',
      home: GeminiTestPage(),
    );
  }
}

class GeminiTestPage extends StatefulWidget {
  @override
  _GeminiTestPageState createState() => _GeminiTestPageState();
}

class _GeminiTestPageState extends State<GeminiTestPage> {
  String _response = 'Press the button to talk to Gemini!';

  Future<void> _sendPrompt() async {
    try {
      final model = FirebaseVertexAI.instance
          .generativeModel(model: 'gemini-2.0-flash');

      final prompt = [Content.text('What is Philippines')];
      final result = await model.generateContent(prompt);

      setState(() {
        _response = result.text ?? 'No response 😅';
      });
    } catch (e) {
      setState(() {
        _response = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Gemini Test')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(child: SingleChildScrollView(child: Text(_response))),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _sendPrompt,
              child: Text('Ask Gemini'),
            ),
          ],
        ),
      ),
    );
  }
}
