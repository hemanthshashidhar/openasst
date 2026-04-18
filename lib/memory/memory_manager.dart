import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'database.dart';
import '../utils/constants.dart';

class MemoryManager {
  static final MemoryManager instance = MemoryManager._internal();
  MemoryManager._internal();

  final _uuid = const Uuid();
  String _currentSessionId = '';

  String get currentSessionId => _currentSessionId;

  Future<void> startNewSession() async {
    _currentSessionId = _uuid.v4();
  }

  Future<void> saveMessage({
    required String role,
    required String content,
    String? provider,
    String? model,
  }) async {
    if (_currentSessionId.isEmpty) await startNewSession();

    await OrbDatabase.instance.insertMessage({
      'id': _uuid.v4(),
      'role': role,
      'content': content,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'session_id': _currentSessionId,
      'provider': provider,
      'model': model,
    });
  }

  /// Returns last N messages formatted for AI API context
  Future<List<Map<String, String>>> getContextMessages(int count) async {
    final rows = await OrbDatabase.instance.getMessages(
      sessionId: _currentSessionId,
      limit: count,
    );
    return rows
        .map((r) => {
              'role': r['role'] as String,
              'content': r['content'] as String,
            })
        .toList();
  }

  /// Returns all messages across all sessions for history screen
  Future<List<OrbMessage>> getAllMessages({int limit = 100}) async {
    final rows =
        await OrbDatabase.instance.getMessages(limit: limit);
    return rows.map((r) => OrbMessage.fromMap(r)).toList();
  }

  Future<void> clearHistory() async {
    await OrbDatabase.instance.clearAllMessages();
    await startNewSession();
  }

  // User preferences
  Future<String> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(Constants.userName) ?? 'User';
  }

  Future<void> setUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(Constants.userName, name);
  }

  Future<String> getPersonality() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(Constants.assistantPersonality) ?? 'assistant';
  }

  Future<void> setPersonality(String personality) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(Constants.assistantPersonality, personality);
  }

  /// Build system prompt based on user preferences
  Future<String> buildSystemPrompt({String? documentContext}) async {
    final name = await getUserName();
    final personality = await getPersonality();

    final personalityInstructions = {
      'assistant':
          'You are ORB, a helpful and concise AI assistant. Be clear, practical, and direct.',
      'mentor':
          'You are ORB, a patient mentor and teacher. Explain things clearly, ask questions to understand the user\'s level, and guide them through concepts step by step.',
      'friend':
          'You are ORB, a friendly and casual AI companion. Be conversational, warm, and approachable. Use natural language.',
      'expert':
          'You are ORB, a highly technical expert. Be precise, detailed, and use technical terminology when appropriate.',
    };

    String prompt =
        personalityInstructions[personality] ?? personalityInstructions['assistant']!;
    prompt +=
        '\n\nYou are a floating assistant on the user\'s Android phone. You can help with questions, documents, setting alarms, creating notes, and more.';
    prompt += '\nThe user\'s name is $name.';
    prompt +=
        '\nKeep responses concise but complete. Format code in markdown code blocks.';

    if (documentContext != null && documentContext.isNotEmpty) {
      prompt +=
          '\n\n--- ACTIVE DOCUMENT CONTEXT ---\n$documentContext\n--- END DOCUMENT CONTEXT ---';
      prompt +=
          '\nThe user has loaded a document. Answer questions about it based on the content above.';
    }

    return prompt;
  }
}

class OrbMessage {
  final String id;
  final String role;
  final String content;
  final DateTime timestamp;
  final String sessionId;
  final String? provider;
  final String? model;

  OrbMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    required this.sessionId,
    this.provider,
    this.model,
  });

  factory OrbMessage.fromMap(Map<String, dynamic> map) {
    return OrbMessage(
      id: map['id'] as String,
      role: map['role'] as String,
      content: map['content'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      sessionId: map['session_id'] as String,
      provider: map['provider'] as String?,
      model: map['model'] as String?,
    );
  }

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';
}
