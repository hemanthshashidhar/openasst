import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/constants.dart';

class OpenAIProvider {
  static final OpenAIProvider instance = OpenAIProvider._internal();
  OpenAIProvider._internal();

  final _storage = const FlutterSecureStorage();

  Future<String?> getKey() async {
    return await _storage.read(key: Constants.openaiKeyStore);
  }

  Future<void> setKey(String key) async {
    await _storage.write(key: Constants.openaiKeyStore, value: key);
  }

  Future<void> deleteKey() async {
    await _storage.delete(key: Constants.openaiKeyStore);
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
      throw Exception('OpenAI API key not set. Please add it in Settings.');
    }

    // Prepend system message for OpenAI format
    final fullMessages = [
      {'role': 'system', 'content': systemPrompt},
      ...messages,
    ];

    final response = await http
        .post(
          Uri.parse(Constants.openaiEndpoint),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $apiKey',
          },
          body: jsonEncode({
            'model': model,
            'max_tokens': Constants.maxTokens,
            'messages': fullMessages,
          }),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final choices = data['choices'] as List;
      if (choices.isNotEmpty) {
        return choices[0]['message']['content'] as String;
      }
      throw Exception('Empty response from OpenAI.');
    } else {
      final error = jsonDecode(response.body);
      final message = error['error']?['message'] ?? 'Unknown error';
      throw Exception('OpenAI API error ${response.statusCode}: $message');
    }
  }
}
