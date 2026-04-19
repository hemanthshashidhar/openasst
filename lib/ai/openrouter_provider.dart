import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/constants.dart';

class OpenRouterProvider {
  static final OpenRouterProvider instance = OpenRouterProvider._internal();
  OpenRouterProvider._internal();

  final _storage = const FlutterSecureStorage();

  Future<String?> getKey() async {
    return await _storage.read(key: Constants.openrouterKeyStore);
  }

  Future<void> setKey(String key) async {
    await _storage.write(key: Constants.openrouterKeyStore, value: key);
  }

  Future<void> deleteKey() async {
    await _storage.delete(key: Constants.openrouterKeyStore);
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
      throw Exception('OpenRouter API key not set. Please add it in Settings.');
    }

    final fullMessages = [
      {'role': 'system', 'content': systemPrompt},
      ...messages,
    ];

    final response = await http
        .post(
          Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $apiKey',
            'HTTP-Referer': 'https://orb-assistant.app',
            'X-Title': 'ORB Assistant',
          },
          body: jsonEncode({
            'model': model,
            'max_tokens': Constants.maxTokens,
            'messages': fullMessages,
          }),
        )
        .timeout(const Duration(seconds: 40));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final choices = data['choices'] as List?;
      if (choices != null && choices.isNotEmpty) {
        return choices[0]['message']['content'] as String? ?? 'No response.';
      }
      throw Exception('Empty response from OpenRouter.');
    } else {
      String message = 'Unknown error';
      try {
        final error = jsonDecode(response.body);
        message = error['error']?['message'] ?? message;
      } catch (_) {}
      throw Exception('OpenRouter error ${response.statusCode}: $message');
    }
  }
}