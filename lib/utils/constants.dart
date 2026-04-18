class Constants {
  // Overlay bubble size
  static const double bubbleSize = 70.0;

  // Chat overlay dimensions
  static const double overlayHeight = 520.0;
  static const double overlayWidth = 360.0;

  // Database
  static const String dbName = 'orb_database.db';
  static const int dbVersion = 1;

  // Table names
  static const String messagesTable = 'messages';
  static const String settingsTable = 'settings';
  static const String documentsTable = 'documents';

  // Secure storage keys
  static const String openaiKeyStore = 'openai_api_key';
  static const String claudeKeyStore = 'claude_api_key';
  static const String geminiKeyStore = 'gemini_api_key';

  // SharedPreferences keys
  static const String selectedProvider = 'selected_provider';
  static const String selectedModel = 'selected_model';
  static const String userName = 'user_name';
  static const String assistantPersonality = 'assistant_personality';
  static const String telegramBotToken = 'telegram_bot_token';

  // AI providers
  static const String providerClaude = 'claude';
  static const String providerOpenAI = 'openai';
  static const String providerGemini = 'gemini';

  // Claude models
  static const List<String> claudeModels = [
    'claude-opus-4-5',
    'claude-sonnet-4-5',
    'claude-haiku-4-5-20251001',
  ];

  // OpenAI models
  static const List<String> openAIModels = [
    'gpt-4o',
    'gpt-4o-mini',
    'gpt-4-turbo',
  ];

  // Gemini models
  static const List<String> geminiModels = [
    'gemini-1.5-pro',
    'gemini-1.5-flash',
    'gemini-2.0-flash',
  ];

  // Personality options
  static const Map<String, String> personalities = {
    'assistant': 'Helpful Assistant',
    'mentor': 'Mentor & Teacher',
    'friend': 'Casual Friend',
    'expert': 'Technical Expert',
  };

  // Max message history to send for context
  static const int maxContextMessages = 10;

  // Max tokens
  static const int maxTokens = 2048;

  // API endpoints
  static const String claudeEndpoint =
      'https://api.anthropic.com/v1/messages';
  static const String openaiEndpoint =
      'https://api.openai.com/v1/chat/completions';
  static const String geminiEndpoint =
      'https://generativelanguage.googleapis.com/v1beta/models';
}
