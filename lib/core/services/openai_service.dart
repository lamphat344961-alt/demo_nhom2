import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'ai_service.dart';

class OpenAIService implements AIService {
  @override
  String get name => 'ChatGPT';

  final String apiKey = dotenv.env['OPENAI_API_KEY'] ?? '';
  final String apiUrl = 'https://api.openai.com/v1/chat/completions';

  @override
  Future<String> sendMessage(
    String message,
    List<Map<String, String>> history,
  ) async {
    print('🔵 [OpenAI] Starting request...');
    print(
      '🔑 [OpenAI] API Key loaded: ${apiKey.isEmpty ? "EMPTY ❌" : "${apiKey.substring(0, 10)}..."}',
    );
    print('📤 [OpenAI] Message: $message');
    print('📚 [OpenAI] History length: ${history.length}');

    try {
      if (apiKey.isEmpty) {
        throw Exception('API Key is empty! Check your .env file');
      }

      final messages = [
        ...history,
        {'role': 'user', 'content': message},
      ];

      print('🌐 [OpenAI] Sending request to: $apiUrl');

      final requestBody = jsonEncode({
        'model': 'gpt-4o-mini',
        'messages': messages,
        'max_tokens': 1000,
      });

      print('📦 [OpenAI] Request body: $requestBody');

      final response = await http
          .post(
            Uri.parse(apiUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $apiKey',
            },
            body: requestBody,
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('Request timeout after 30 seconds');
            },
          );

      print('📊 [OpenAI] Response status: ${response.statusCode}');
      print('📄 [OpenAI] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final content = data['choices'][0]['message']['content'];
        print('✅ [OpenAI] Success! Response length: ${content.length} chars');
        return content;
      } else {
        final errorBody = response.body;
        print('❌ [OpenAI] Error ${response.statusCode}: $errorBody');

        // Parse error message if possible
        try {
          final errorData = jsonDecode(errorBody);
          final errorMessage = errorData['error']['message'] ?? 'Unknown error';
          throw Exception('OpenAI Error ${response.statusCode}: $errorMessage');
        } catch (_) {
          throw Exception('OpenAI Error ${response.statusCode}: $errorBody');
        }
      }
    } catch (e) {
      print('💥 [OpenAI] Exception caught: $e');
      print('📍 [OpenAI] Exception type: ${e.runtimeType}');
      throw Exception('Lỗi OpenAI: $e');
    }
  }
}
