import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'ai_service.dart';

class GeminiService implements AIService {
  @override
  String get name => 'Gemini';

  final String apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

  String _cut(String? s, int n) {
    if (s == null || s.isEmpty) return '';
    final end = s.length < n ? s.length : n;
    return s.substring(0, end);
  }

  @override
  Future<String> sendMessage(
    String message,
    List<Map<String, String>> history,
  ) async {
    print('\n━━━━━━━━━━━━━━ GEMINI DEBUG START ━━━━━━━━━━━━━━');
    print('🟢 [Gemini] Starting request...');
    print(
      '🔑 [Gemini] API Key loaded: ${apiKey.isEmpty ? "❌ EMPTY!" : "✅ ${_cut(apiKey, 15)}..."}',
    );
    print('📤 [Gemini] User message: "$message"');
    print('📚 [Gemini] History length: ${history.length} messages');

    try {
      // Validate API key
      if (apiKey.isEmpty) {
        print('❌ [Gemini] FATAL: API Key is EMPTY!');
        print('⚠️ [Gemini] Check your .env file has: GEMINI_API_KEY=AIza...');
        throw Exception('Gemini API Key is empty! Check your .env file');
      }

      final model = dotenv.env['GEMINI_MODEL']?.trim().isNotEmpty == true
          ? dotenv.env['GEMINI_MODEL']!.trim()
          : 'gemini-1.5-flash';

      final apiUrl =
          'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey';

      print('🌐 [Gemini] API URL: ${_cut(apiUrl, 100)}...');

      // Build request body
      final contents = [
        ...history.map((m) {
          final role = m['role'] ?? 'user';
          final content = m['content'] ?? '';
          print('   📝 History: $role -> ${_cut(content, 30)}...');
          return {
            'role': role == 'assistant' ? 'model' : 'user',
            'parts': [
              {'text': content},
            ],
          };
        }),
        {
          'role': 'user',
          'parts': [
            {'text': message},
          ],
        },
      ];

      final requestBody = jsonEncode({'contents': contents});
      print('📦 [Gemini] Request body length: ${requestBody.length} chars');
      print('📦 [Gemini] Request body preview: ${_cut(requestBody, 200)}...');

      // Send request
      print('⏳ [Gemini] Sending HTTP POST request...');
      final response = await http
          .post(
            Uri.parse(apiUrl),
            headers: {'Content-Type': 'application/json'},
            body: requestBody,
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              print('⏰ [Gemini] Request TIMEOUT after 30 seconds!');
              throw Exception('Request timeout after 30 seconds');
            },
          );

      print('📊 [Gemini] Response received!');
      print('📊 [Gemini] Status Code: ${response.statusCode}');
      print('📊 [Gemini] Response headers: ${response.headers}');
      print('📄 [Gemini] Response body length: ${response.body.length} chars');
      print('📄 [Gemini] Response body:\n${response.body}');

      if (response.statusCode == 200) {
        print('✅ [Gemini] Status 200 - SUCCESS!');

        final data = jsonDecode(utf8.decode(response.bodyBytes));
        print('🔍 [Gemini] Parsed JSON successfully');
        print(
          '🔍 [Gemini] JSON keys: ${data is Map ? data.keys.toList() : data.runtimeType}',
        );

        // Validate structure
        if (data is! Map || data['candidates'] == null) {
          print('❌ [Gemini] ERROR: No "candidates" field in response!');
          print('🔍 [Gemini] Full response: $data');
          throw Exception('Invalid response structure: missing "candidates"');
        }

        final candidates = data['candidates'];
        if (candidates is! List || candidates.isEmpty) {
          print('❌ [Gemini] ERROR: "candidates" array is EMPTY!');
          throw Exception('Empty candidates array in response');
        }

        print('✅ [Gemini] Found ${candidates.length} candidate(s)');

        final candidate = candidates[0];
        if (candidate is! Map || candidate['content'] == null) {
          print('❌ [Gemini] ERROR: No "content" in candidate!');
          throw Exception('Missing content in candidate');
        }

        final content = candidate['content'];
        if (content is! Map || content['parts'] == null) {
          print('❌ [Gemini] ERROR: No "parts" in content!');
          throw Exception('Missing parts in content');
        }

        final parts = content['parts'];
        if (parts is! List || parts.isEmpty || parts[0]['text'] == null) {
          print('❌ [Gemini] ERROR: No text in parts[0]!');
          throw Exception('Missing text in parts');
        }

        final text = parts[0]['text'] as String;
        print('✅ [Gemini] Extracted text successfully!');
        print('📝 [Gemini] Response length: ${text.length} chars');
        print('📝 [Gemini] Response preview: ${_cut(text, 100)}...');
        print('━━━━━━━━━━━━━━ GEMINI DEBUG END ━━━━━━━━━━━━━━\n');

        return text;
      } else {
        print('❌ [Gemini] HTTP ERROR: Status ${response.statusCode}');
        print('❌ [Gemini] Error body: ${response.body}');

        // Try to parse error message
        try {
          final errorData = jsonDecode(response.body);
          print('🔍 [Gemini] Parsed error JSON: $errorData');

          if (errorData is Map && errorData['error'] != null) {
            final err = errorData['error'];
            final errorMessage = err['message'] ?? 'Unknown error';
            final errorStatus = err['status'] ?? 'UNKNOWN';
            print('❌ [Gemini] Error message: $errorMessage');
            print('❌ [Gemini] Error status: $errorStatus');
            throw Exception('Gemini API Error [$errorStatus]: $errorMessage');
          }
        } catch (parseError) {
          print('⚠️ [Gemini] Could not parse error JSON: $parseError');
        }

        throw Exception(
          'Gemini HTTP Error ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e, stackTrace) {
      print('\n💥 [Gemini] EXCEPTION CAUGHT!');
      print('💥 [Gemini] Error: $e');
      print('💥 [Gemini] Error type: ${e.runtimeType}');
      print('💥 [Gemini] Stack trace:');
      print(stackTrace.toString());
      print('━━━━━━━━━━━━━━ GEMINI DEBUG END (ERROR) ━━━━━━━━━━━━━━\n');

      throw Exception('Lỗi Gemini: $e');
    }
  }
}
