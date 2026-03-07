import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class GeminiService {
  // Your Google API Key
  static const String _apiKey = "AIzaSyBUPTW1im0JUS_9fzn22TLzHWlm6ANYT2c";

  // Gemini 1.5 Flash is the best free-tier model
  static const String _url =
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$_apiKey";

  static Future<String> sendMessage(String prompt) async {
    try {
      final response = await http
          .post(
            Uri.parse(_url),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "contents": [
                {
                  "parts": [
                    {
                      "text":
                          "System: You are a medical AI assistant. Provide safe, non-diagnostic advice. User: $prompt",
                    },
                  ],
                },
              ],
              "generationConfig": {"temperature": 0.7, "maxOutputTokens": 800},
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Gemini's response structure is different from OpenAI's
        return data['candidates'][0]['content']['parts'][0]['text'];
      } else {
        return "Gemini Error: ${response.statusCode} - ${response.body}";
      }
    } on SocketException {
      return "No internet connection.";
    } catch (e) {
      return "An unexpected error occurred: $e";
    }
  }
}
