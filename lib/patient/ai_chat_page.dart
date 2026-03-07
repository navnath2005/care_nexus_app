import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class GeminiService {
  // Your Google API Key
  static const String _apiKey = "AIzaSyAACUIbD1zprN-pNYhzoyVqWpy8ILBk5Gg";

  static const String _url =
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$_apiKey";

  static Future<String> sendMessage(
    String prompt, {
    List<Map<String, String>>? history,
  }) async {
    try {
      // Prepare the history for Gemini's format
      // Gemini uses 'user' and 'model' instead of 'user' and 'assistant'
      List<Map<String, dynamic>> contents = [];

      if (history != null) {
        for (var msg in history) {
          contents.add({
            "role": msg['role'] == "user" ? "user" : "model",
            "parts": [
              {"text": msg['content']},
            ],
          });
        }
      }

      // Add the current prompt
      contents.add({
        "role": "user",
        "parts": [
          {
            "text":
                "System: You are a medical AI assistant. Provide safe advice. User prompt: $prompt",
          },
        ],
      });

      final response = await http
          .post(
            Uri.parse(_url),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "contents": contents,
              "generationConfig": {"temperature": 0.7, "maxOutputTokens": 800},
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['candidates'][0]['content']['parts'][0]['text'];
      } else {
        return "Gemini Error: ${response.statusCode}";
      }
    } on SocketException {
      return "Check your internet connection.";
    } catch (e) {
      return "Unexpected error: $e";
    }
  }
}
