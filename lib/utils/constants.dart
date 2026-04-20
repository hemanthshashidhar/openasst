class Constants {
  static const double bubbleSize = 70.0;
  static const double overlayHeight = 520.0;
  static const double overlayWidth = 360.0;

  static const String dbName = 'orb_database.db';
  static const int dbVersion = 1;
  static const String messagesTable = 'messages';
  static const String settingsTable = 'settings';
  static const String documentsTable = 'documents';

  static const String openaiKeyStore = 'openai_api_key';
  static const String claudeKeyStore = 'claude_api_key';
  static const String geminiKeyStore = 'gemini_api_key';
  static const String openrouterKeyStore = 'openrouter_api_key';

  static const String selectedProvider = 'selected_provider';
  static const String selectedModel = 'selected_model';
  static const String userName = 'user_name';
  static const String assistantPersonality = 'assistant_personality';
  static const String telegramBotToken = 'telegram_bot_token';

  static const String providerClaude = 'claude';
  static const String providerOpenAI = 'openai';
  static const String providerGemini = 'gemini';
  static const String providerOpenRouter = 'openrouter';

  static const List<String> claudeModels = [
    'claude-opus-4-5',
    'claude-sonnet-4-5',
    'claude-haiku-4-5-20251001',
  ];
  static const List<String> openAIModels = [
    'gpt-4o',
    'gpt-4o-mini',
    'gpt-4-turbo',
  ];
  static const List<String> geminiModels = [
    'gemini-1.5-pro',
    'gemini-1.5-flash',
    'gemini-2.0-flash',
  ];
  static const List<String> openRouterModels = [
    'openai/gpt-4o',
    'openai/gpt-4o-mini',
    'anthropic/claude-sonnet-4-5',
    'anthropic/claude-haiku-4-5',
    'google/gemini-flash-1.5',
    'meta-llama/llama-3.1-8b-instruct:free',
    'meta-llama/llama-3.3-70b-instruct',
    'mistralai/mistral-7b-instruct:free',
    'deepseek/deepseek-chat',
    'qwen/qwen-2.5-72b-instruct',
  ];

  static const Map<String, String> personalities = {
    'assistant': 'Helpful Assistant',
    'mentor': 'Mentor & Teacher',
    'friend': 'Casual Friend',
    'expert': 'Technical Expert',
  };

  static const int maxContextMessages = 10;
  static const int maxTokens = 1024;

  static const String claudeEndpoint = 'https://api.anthropic.com/v1/messages';
  static const String openaiEndpoint = 'https://api.openai.com/v1/chat/completions';
  static const String geminiEndpoint = 'https://generativelanguage.googleapis.com/v1beta/models';
  static const String openrouterEndpoint = 'https://openrouter.ai/api/v1/chat/completions';
}