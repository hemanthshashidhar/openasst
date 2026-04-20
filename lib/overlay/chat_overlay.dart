import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:uuid/uuid.dart';
import '../ai/ai_router.dart';
import '../memory/memory_manager.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../actions/action_detector.dart';

class ChatMessage {
  final String id;
  final String role;
  final String content;
  final DateTime timestamp;
  bool isLoading;

  ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.isLoading = false,
  });
}

class ChatOverlay extends StatefulWidget {
  final VoidCallback onClose;
  final String? initialDocumentContext;

  const ChatOverlay({
    super.key,
    required this.onClose,
    this.initialDocumentContext,
  });

  @override
  State<ChatOverlay> createState() => _ChatOverlayState();
}

class _ChatOverlayState extends State<ChatOverlay> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final SpeechToText _speech = SpeechToText();
  final _uuid = const Uuid();

  // In-memory message list for the current session UI
  final List<ChatMessage> _messages = [];
  // Separate list tracking the actual conversation sent to AI
  final List<Map<String, String>> _conversationHistory = [];

  bool _isLoading = false;
  bool _isListening = false;
  bool _speechAvailable = false;
  String? _activeDocumentContext;

  @override
  void initState() {
    super.initState();
    _activeDocumentContext = widget.initialDocumentContext;
    _initSpeech();
    // Start fresh session
    MemoryManager.instance.startNewSession();
    _addWelcomeMessage();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize(
      onError: (e) => debugPrint('Speech error: $e'),
    );
    if (mounted) setState(() {});
  }

  void _addWelcomeMessage() {
    final greeting = _activeDocumentContext != null
        ? 'Document loaded ✓\n\nI\'ve read the document. Ask me anything about it — summarize, explain, key points, or any question you have.'
        : 'Hey! I\'m **ORB** 👁️\n\nYour on-screen AI assistant. Ask me anything, load a document, or try:\n- *"Set alarm for 7am"*\n- *"What\'s the capital of Japan?"*\n- *"Explain machine learning simply"*';

    _messages.add(ChatMessage(
      id: _uuid.v4(),
      role: 'assistant',
      content: greeting,
      timestamp: DateTime.now(),
    ));
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _isLoading) return;

    final userText = text.trim();

    final userMsg = ChatMessage(
      id: _uuid.v4(),
      role: 'user',
      content: userText,
      timestamp: DateTime.now(),
    );

    final loadingMsg = ChatMessage(
      id: 'loading',
      role: 'assistant',
      content: '',
      timestamp: DateTime.now(),
      isLoading: true,
    );

    setState(() {
      _messages.add(userMsg);
      _messages.add(loadingMsg);
      _isLoading = true;
      _inputController.clear();
    });
    _scrollToBottom();

    // Add user message to local conversation history
    _conversationHistory.add({'role': 'user', 'content': userText});

    // Save to DB
    await MemoryManager.instance.saveMessage(role: 'user', content: userText);

    String response;

    // Check for phone actions first
    final actionResult = await ActionDetector.instance.detect(userText);
    if (actionResult != null) {
      response = actionResult;
    } else {
      // Build system prompt
      final systemPrompt = await MemoryManager.instance.buildSystemPrompt(
        documentContext: _activeDocumentContext,
      );

      // Send FULL conversation history to AI - this is the key fix
      // We pass a copy of the history so it includes the current user message
      response = await AIRouter.instance.chat(
        messages: List.from(_conversationHistory),
        systemPrompt: systemPrompt,
      );
    }

    // Add assistant response to local history
    _conversationHistory.add({'role': 'assistant', 'content': response});

    // Save to DB
    await MemoryManager.instance.saveMessage(role: 'assistant', content: response);

    if (mounted) {
      setState(() {
        _messages.removeWhere((m) => m.id == 'loading');
        _messages.add(ChatMessage(
          id: _uuid.v4(),
          role: 'assistant',
          content: response,
          timestamp: DateTime.now(),
        ));
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _startListening() async {
    if (!_speechAvailable) return;
    await _speech.listen(
      onResult: (result) {
        setState(() {
          _inputController.text = result.recognizedWords;
          _inputController.selection = TextSelection.fromPosition(
            TextPosition(offset: _inputController.text.length),
          );
        });
      },
    );
    setState(() => _isListening = true);
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: Constants.overlayWidth,
      height: Constants.overlayHeight,
      decoration: BoxDecoration(
        color: AppTheme.bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.accentColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentColor.withOpacity(0.1),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            _buildHeader(),
            if (_activeDocumentContext != null) _buildDocBanner(),
            Expanded(child: _buildMessages()),
            _buildQuickActions(),
            _buildInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        border: Border(bottom: BorderSide(color: AppTheme.accentColor.withOpacity(0.15))),
      ),
      child: Row(
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.accentColor.withOpacity(0.15),
              border: Border.all(color: AppTheme.accentColor, width: 1.5),
            ),
            child: const Center(child: Text('◉', style: TextStyle(fontSize: 14))),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('ORB', style: AppTheme.titleStyle.copyWith(fontSize: 14)),
              Text('On-screen Reasoning Brain', style: AppTheme.captionStyle.copyWith(fontSize: 10)),
            ]),
          ),
          IconButton(
            icon: Icon(Icons.close, color: AppTheme.subtitleColor, size: 18),
            onPressed: widget.onClose,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildDocBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: AppTheme.accentSecondary.withOpacity(0.15),
      child: Row(
        children: [
          const Icon(Icons.description_outlined, color: AppTheme.accentSecondary, size: 14),
          const SizedBox(width: 6),
          const Expanded(
            child: Text('Document active — ask me anything about it',
                style: TextStyle(fontSize: 11, color: AppTheme.accentSecondary)),
          ),
          GestureDetector(
            onTap: () => setState(() => _activeDocumentContext = null),
            child: const Icon(Icons.close, color: AppTheme.accentSecondary, size: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildMessages() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(12),
      itemCount: _messages.length,
      itemBuilder: (context, index) => _MessageBubble(message: _messages[index]),
    );
  }

  Widget _buildQuickActions() {
    final actions = ['Summarize', 'Explain', 'Translate', 'Key points'];
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: actions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, i) => GestureDetector(
          onTap: () => _sendMessage(actions[i]),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.accentColor.withOpacity(0.4)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(actions[i], style: AppTheme.captionStyle.copyWith(color: AppTheme.accentColor)),
          ),
        ),
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        border: Border(top: BorderSide(color: AppTheme.accentColor.withOpacity(0.15))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputController,
              style: AppTheme.bodyStyle.copyWith(fontSize: 14),
              maxLines: 3,
              minLines: 1,
              textInputAction: TextInputAction.send,
              onSubmitted: _sendMessage,
              decoration: InputDecoration(
                hintText: 'Ask ORB anything...',
                hintStyle: AppTheme.captionStyle,
                filled: true,
                fillColor: AppTheme.bgColor,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (_speechAvailable)
            GestureDetector(
              onTap: _isListening ? _stopListening : _startListening,
              child: Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isListening ? AppTheme.errorColor.withOpacity(0.2) : AppTheme.bgColor,
                  border: Border.all(color: _isListening ? AppTheme.errorColor : AppTheme.accentColor.withOpacity(0.4)),
                ),
                child: Icon(
                  _isListening ? Icons.mic : Icons.mic_none,
                  color: _isListening ? AppTheme.errorColor : AppTheme.accentColor,
                  size: 18,
                ),
              ),
            ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _sendMessage(_inputController.text),
            child: Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isLoading ? AppTheme.accentColor.withOpacity(0.3) : AppTheme.accentColor,
              ),
              child: _isLoading
                  ? const Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send, color: Colors.black, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Message bubble ───────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';

    if (message.isLoading) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(children: [_avatar(), const SizedBox(width: 8), _TypingIndicator()]),
      );
    }

    return Padding(
      padding: EdgeInsets.only(bottom: 12, left: isUser ? 40 : 0, right: isUser ? 0 : 40),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[_avatar(), const SizedBox(width: 8)],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser ? AppTheme.accentColor.withOpacity(0.15) : AppTheme.surfaceColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                border: Border.all(
                  color: isUser ? AppTheme.accentColor.withOpacity(0.3) : AppTheme.dividerColor,
                ),
              ),
              child: isUser
                  ? Text(message.content, style: AppTheme.bodyStyle.copyWith(fontSize: 13))
                  : MarkdownBody(
                      data: message.content,
                      styleSheet: MarkdownStyleSheet(
                        p: AppTheme.bodyStyle.copyWith(fontSize: 13),
                        code: AppTheme.monoStyle.copyWith(fontSize: 11),
                        codeblockDecoration: BoxDecoration(
                          color: AppTheme.bgColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        strong: AppTheme.bodyStyle.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.accentColor,
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatar() => Container(
    width: 24, height: 24,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: AppTheme.accentColor.withOpacity(0.1),
      border: Border.all(color: AppTheme.accentColor, width: 1),
    ),
    child: const Center(child: Text('◉', style: TextStyle(fontSize: 11))),
  );
}

class _TypingIndicator extends StatefulWidget {
  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true);
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(3, (i) => AnimatedBuilder(
        animation: _c,
        builder: (_, __) {
          final v = ((_c.value - i * 0.2)).clamp(0.0, 1.0);
          return Container(
            margin: const EdgeInsets.only(right: 4),
            width: 7, height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.accentColor.withOpacity(0.3 + v * 0.7),
            ),
          );
        },
      )),
    );
  }
}