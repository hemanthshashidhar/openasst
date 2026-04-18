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

  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isListening = false;
  bool _speechAvailable = false;
  String? _activeDocumentContext;

  @override
  void initState() {
    super.initState();
    _activeDocumentContext = widget.initialDocumentContext;
    _initSpeech();
    _loadHistory();
    if (_messages.isEmpty) _addWelcomeMessage();
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

  Future<void> _loadHistory() async {
    final history = await MemoryManager.instance.getContextMessages(
      Constants.maxContextMessages,
    );
    if (history.isNotEmpty && mounted) {
      setState(() {
        for (final msg in history) {
          _messages.add(ChatMessage(
            id: _uuid.v4(),
            role: msg['role']!,
            content: msg['content']!,
            timestamp: DateTime.now(),
          ));
        }
      });
      _scrollToBottom();
    }
  }

  void _addWelcomeMessage() {
    _messages.add(ChatMessage(
      id: _uuid.v4(),
      role: 'assistant',
      content:
          'Hey! I\'m **ORB** 👁️\n\nI\'m your on-screen AI assistant. Ask me anything, load a document, or say things like:\n- *"Set alarm for 7am"*\n- *"Summarize this"*\n- *"Remind me about the meeting"*',
      timestamp: DateTime.now(),
    ));
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _isLoading) return;

    final userMsg = ChatMessage(
      id: _uuid.v4(),
      role: 'user',
      content: text.trim(),
      timestamp: DateTime.now(),
    );

    final loadingMsg = ChatMessage(
      id: _uuid.v4(),
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

    // Save user message to DB
    await MemoryManager.instance.saveMessage(
      role: 'user',
      content: text.trim(),
    );

    // Check for phone actions first
    final actionResult = await ActionDetector.instance.detect(text.trim());

    String response;
    if (actionResult != null) {
      response = actionResult;
    } else {
      // Build context and call AI
      final contextMessages = await MemoryManager.instance.getContextMessages(
        Constants.maxContextMessages,
      );
      final systemPrompt = await MemoryManager.instance.buildSystemPrompt(
        documentContext: _activeDocumentContext,
      );
      response = await AIRouter.instance.chat(
        messages: contextMessages,
        systemPrompt: systemPrompt,
      );
    }

    // Save assistant response to DB
    await MemoryManager.instance.saveMessage(
      role: 'assistant',
      content: response,
    );

    if (mounted) {
      setState(() {
        _messages.remove(loadingMsg);
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
        border: Border.all(
          color: AppTheme.accentColor.withOpacity(0.3),
        ),
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
            if (_activeDocumentContext != null) _buildDocumentBanner(),
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
        border: Border(
          bottom: BorderSide(
            color: AppTheme.accentColor.withOpacity(0.15),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.accentColor.withOpacity(0.15),
              border: Border.all(color: AppTheme.accentColor, width: 1.5),
            ),
            child: const Center(
              child: Text('◉', style: TextStyle(fontSize: 14)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ORB', style: AppTheme.titleStyle.copyWith(fontSize: 14)),
                Text('On-screen Reasoning Brain',
                    style: AppTheme.captionStyle.copyWith(fontSize: 10)),
              ],
            ),
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

  Widget _buildDocumentBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: AppTheme.accentSecondary.withOpacity(0.15),
      child: Row(
        children: [
          const Icon(Icons.description_outlined,
              color: AppTheme.accentSecondary, size: 14),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Document loaded — ask me anything about it',
              style: AppTheme.captionStyle
                  .copyWith(color: AppTheme.accentSecondary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _activeDocumentContext = null),
            child: const Icon(Icons.close,
                color: AppTheme.accentSecondary, size: 14),
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
      itemBuilder: (context, index) {
        final msg = _messages[index];
        return _MessageBubble(message: msg);
      },
    );
  }

  Widget _buildQuickActions() {
    final actions = ['Summarize', 'Explain', 'Translate', 'Key points'];
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: actions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => _sendMessage(actions[index]),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(
                    color: AppTheme.accentColor.withOpacity(0.4)),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                actions[index],
                style: AppTheme.captionStyle
                    .copyWith(color: AppTheme.accentColor),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        border: Border(
          top: BorderSide(color: AppTheme.accentColor.withOpacity(0.15)),
        ),
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
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Voice button
          if (_speechAvailable)
            GestureDetector(
              onTap: _isListening ? _stopListening : _startListening,
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isListening
                      ? AppTheme.errorColor.withOpacity(0.2)
                      : AppTheme.bgColor,
                  border: Border.all(
                    color: _isListening
                        ? AppTheme.errorColor
                        : AppTheme.accentColor.withOpacity(0.4),
                  ),
                ),
                child: Icon(
                  _isListening ? Icons.mic : Icons.mic_none,
                  color: _isListening
                      ? AppTheme.errorColor
                      : AppTheme.accentColor,
                  size: 18,
                ),
              ),
            ),
          const SizedBox(width: 8),
          // Send button
          GestureDetector(
            onTap: () => _sendMessage(_inputController.text),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isLoading
                    ? AppTheme.accentColor.withOpacity(0.3)
                    : AppTheme.accentColor,
              ),
              child: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send, color: Colors.black, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';

    if (message.isLoading) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            _orbAvatar(),
            const SizedBox(width: 8),
            _TypingIndicator(),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(
        bottom: 12,
        left: isUser ? 40 : 0,
        right: isUser ? 0 : 40,
      ),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            _orbAvatar(),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser
                    ? AppTheme.accentColor.withOpacity(0.15)
                    : AppTheme.surfaceColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                border: Border.all(
                  color: isUser
                      ? AppTheme.accentColor.withOpacity(0.3)
                      : AppTheme.dividerColor,
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

  Widget _orbAvatar() {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.accentColor.withOpacity(0.1),
        border: Border.all(color: AppTheme.accentColor, width: 1),
      ),
      child: const Center(
        child: Text('◉', style: TextStyle(fontSize: 11)),
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final delay = i * 0.2;
            final value = (_controller.value - delay).clamp(0.0, 1.0);
            return Container(
              margin: const EdgeInsets.only(right: 4),
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.accentColor.withOpacity(0.3 + value * 0.7),
              ),
            );
          },
        );
      }),
    );
  }
}
