import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/constants.dart';

class ClaudeProvider {
  static final ClaudeProvider instance = ClaudeProvider._internal();
  ClaudeProvider._internal();

  final _storage = const FlutterSecureStorage();

  Future<String?> getKey() async {
    return await _storage.read(key: Constants.claudeKeyStore);
  }

  Future<void> setKey(String key) async {
    await _storage.write(key: Constants.claudeKeyStore, value: key);
  }

  Future<void> deleteKey() async {
    await _storage.delete(key: Constants.claudeKeyStore);
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
      throw Exception('Claude API key not set. Please add it in Settings.');
    }

    final response = await http
        .post(
          Uri.parse(Constants.claudeEndpoint),
          headers: {
            'Content-Type': 'application/json',
            'x-api-key': apiKey,
            'anthropic-version': '2023-06-01',
          },
          body: jsonEncode({
            'model': model,
            'max_tokens': Constants.maxTokens,
            'system': systemPrompt,
            'messages': messages,
          }),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final content = data['content'] as List;
      if (content.isNotEmpty && content[0]['type'] == 'text') {
        return content[0]['text'] as String;
      }
      throw Exception('Unexpected response format from Claude.');
    } else {
      final error = jsonDecode(response.body);
      final message = error['error']?['message'] ?? 'Unknown error';
      throw Exception('Claude API error ${response.statusCode}: $message');
    }
  }
}
