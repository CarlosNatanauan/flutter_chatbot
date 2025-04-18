import 'package:flutter/material.dart';
import '../services/gemini_service.dart';

class GeminiTestPage extends StatefulWidget {
  @override
  _GeminiTestPageState createState() => _GeminiTestPageState();
}

class _GeminiTestPageState extends State<GeminiTestPage> {
  String _response = 'Press the button to talk to Gemini!';

  Future<void> _sendPrompt() async {
    final result = await GeminiService.getResponse('What is AI?');
    setState(() {
      _response = result;
    });
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
