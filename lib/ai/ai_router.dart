import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import 'claude_provider.dart';
import 'openai_provider.dart';
import 'gemini_provider.dart';

class AIRouter {
  static final AIRouter instance = AIRouter._internal();
  AIRouter._internal();

  Future<String> getSelectedProvider() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(Constants.selectedProvider) ?? Constants.providerClaude;
  }

  Future<String> getSelectedModel() async {
    final prefs = await SharedPreferences.getInstance();
    final provider = await getSelectedProvider();
    final defaultModel = {
      Constants.providerClaude: Constants.claudeModels[1],
      Constants.providerOpenAI: Constants.openAIModels[0],
      Constants.providerGemini: Constants.geminiModels[0],
    }[provider]!;
    return prefs.getString(Constants.selectedModel) ?? defaultModel;
  }

  /// Main entry point for all AI calls
  Future<String> chat({
    required List<Map<String, String>> messages,
    required String systemPrompt,
  }) async {
    final provider = await getSelectedProvider();
    final model = await getSelectedModel();

    try {
      switch (provider) {
        case Constants.providerClaude:
          return await ClaudeProvider.instance.chat(
            messages: messages,
            systemPrompt: systemPrompt,
            model: model,
          );
        case Constants.providerOpenAI:
          return await OpenAIProvider.instance.chat(
            messages: messages,
            systemPrompt: systemPrompt,
            model: model,
          );
        case Constants.providerGemini:
          return await GeminiProvider.instance.chat(
            messages: messages,
            systemPrompt: systemPrompt,
            model: model,
          );
        default:
          return 'Error: Unknown provider "$provider". Please check your settings.';
      }
    } catch (e) {
      return _formatError(e, provider);
    }
  }

  String _formatError(Object e, String provider) {
    final msg = e.toString();
    if (msg.contains('401') || msg.contains('authentication')) {
      return '⚠️ API key invalid for $provider. Please check your key in Settings.';
    }
    if (msg.contains('429') || msg.contains('rate limit')) {
      return '⚠️ Rate limit reached. Please wait a moment and try again.';
    }
    if (msg.contains('SocketException') || msg.contains('connection')) {
      return '⚠️ No internet connection. Please check your network.';
    }
    return '⚠️ Error: $msg';
  }

  /// Check if any API key is configured
  Future<bool> hasAnyKey() async {
    final claude = await ClaudeProvider.instance.hasKey();
    final openai = await OpenAIProvider.instance.hasKey();
    final gemini = await GeminiProvider.instance.hasKey();
    return claude || openai || gemini;
  }
}
