import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import 'claude_provider.dart';
import 'openai_provider.dart';
import 'gemini_provider.dart';
import 'openrouter_provider.dart';

class AIRouter {
  static final AIRouter instance = AIRouter._internal();
  AIRouter._internal();

  Future<String> getSelectedProvider() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(Constants.selectedProvider) ?? Constants.providerOpenRouter;
  }

  Future<String> getSelectedModel() async {
    final prefs = await SharedPreferences.getInstance();
    final provider = await getSelectedProvider();
    final defaults = {
      Constants.providerClaude: Constants.claudeModels[1],
      Constants.providerOpenAI: Constants.openAIModels[0],
      Constants.providerGemini: Constants.geminiModels[0],
      Constants.providerOpenRouter: Constants.openRouterModels[0],
    };
    return prefs.getString(Constants.selectedModel) ?? defaults[provider]!;
  }

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
            messages: messages, systemPrompt: systemPrompt, model: model);
        case Constants.providerOpenAI:
          return await OpenAIProvider.instance.chat(
            messages: messages, systemPrompt: systemPrompt, model: model);
        case Constants.providerGemini:
          return await GeminiProvider.instance.chat(
            messages: messages, systemPrompt: systemPrompt, model: model);
        case Constants.providerOpenRouter:
          return await OpenRouterProvider.instance.chat(
            messages: messages, systemPrompt: systemPrompt, model: model);
        default:
          return '⚠️ No provider selected. Go to Settings → Model and pick a provider.';
      }
    } catch (e) {
      return _formatError(e, provider);
    }
  }

  String _formatError(Object e, String provider) {
    final msg = e.toString();
    if (msg.contains('401') || msg.contains('authentication') || msg.contains('invalid')) {
      return '⚠️ API key invalid for $provider. Go to Settings → API Keys and check your key.';
    }
    if (msg.contains('429') || msg.contains('rate limit')) {
      return '⚠️ Rate limit reached. Wait a moment and try again.';
    }
    if (msg.contains('SocketException') || msg.contains('connection') || msg.contains('network')) {
      return '⚠️ No internet connection. Check your network.';
    }
    if (msg.contains('not set')) {
      return '⚠️ $msg';
    }
    return '⚠️ Error: $msg';
  }

  Future<bool> hasAnyKey() async {
    return await ClaudeProvider.instance.hasKey() ||
        await OpenAIProvider.instance.hasKey() ||
        await GeminiProvider.instance.hasKey() ||
        await OpenRouterProvider.instance.hasKey();
  }
}