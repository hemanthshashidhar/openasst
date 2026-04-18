import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/constants.dart';

class GeminiProvider {
  static final GeminiProvider instance = GeminiProvider._internal();
  GeminiProvider._internal();

  final _storage = const FlutterSecureStorage();

  Future<String?> getKey() async {
    return await _storage.read(key: Constants.geminiKeyStore);
  }

  Future<void> setKey(String key) async {
    await _storage.write(key: Constants.geminiKeyStore, value: key);
  }

  Future<void> deleteKey() async {
    await _storage.delete(key: Constants.geminiKeyStore);
  }

  Future<bool> hasKey() async {
    final key = await getKey();
    return key != null && key.trim().isNotEmpty;
  }

  Future<String> chat({
    required List<Map<String, String>> messages,
    required String systemPrompt,
    required String model,
  }) async {
    final apiKey = await getKey();
    if (apiKey == null || apiKey.trim().isEmpty) {
      throw Exception('Gemini API key not set. Please add it in Settings.');
    }

    // Convert messages to Gemini format
    final geminiMessages = messages.map((m) {
      return {
        'role': m['role'] == 'assistant' ? 'model' : 'user',
        'parts': [
          {'text': m['content']}
        ],
      };
    }).toList();

    final url =
        '${Constants.geminiEndpoint}/$model:generateContent?key=$apiKey';

    final response = await http
        .post(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'system_instruction': {
              'parts': [
                {'text': systemPrompt}
              ]
            },
            'contents': geminiMessages,
            'generationConfig': {
              'maxOutputTokens': Constants.maxTokens,
            },
          }),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final candidates = data['candidates'] as List?;
      if (candidates != null && candidates.isNotEmpty) {
        final parts = candidates[0]['content']['parts'] as List;
        if (parts.isNotEmpty) {
          return parts[0]['text'] as String;
        }
      }
      throw Exception('Empty response from Gemini.');
    } else {
      final error = jsonDecode(response.body);
      final message =
          error['error']?['message'] ?? 'Unknown error';
      throw Exception('Gemini API error ${response.statusCode}: $message');
    }
  }
}
