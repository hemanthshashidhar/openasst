import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';

class TelegramScreen extends StatefulWidget {
  const TelegramScreen({super.key});

  @override
  State<TelegramScreen> createState() => _TelegramScreenState();
}

class _TelegramScreenState extends State<TelegramScreen> {
  final _tokenController = TextEditingController();
  bool _showToken = false;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(Constants.telegramBotToken);
    if (token != null) {
      setState(() {
        _tokenController.text = token;
        _saved = true;
      });
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        Constants.telegramBotToken, _tokenController.text.trim());
    setState(() => _saved = true);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Token saved ✓'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(title: const Text('Telegram Bridge')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF0088CC).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: const Color(0xFF0088CC).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.telegram,
                      color: Color(0xFF0088CC), size: 36),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ORB on Telegram',
                            style: AppTheme.titleStyle),
                        const SizedBox(height: 4),
                        Text(
                          'Chat with ORB from anywhere via Telegram',
                          style: AppTheme.captionStyle,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Step by step
            Text('Setup Steps', style: AppTheme.titleStyle),
            const SizedBox(height: 16),
            _Step(
              number: '1',
              title: 'Create a Telegram Bot',
              body:
                  'Open Telegram and search for @BotFather. Send /newbot and follow the instructions. Copy the bot token it gives you.',
            ),
            _Step(
              number: '2',
              title: 'Paste your bot token below',
              body: 'Enter the token from BotFather.',
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: TextField(
                  controller: _tokenController,
                  obscureText: !_showToken,
                  style: AppTheme.monoStyle.copyWith(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: '123456789:ABCDef...',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showToken ? Icons.visibility_off : Icons.visibility,
                        color: AppTheme.subtitleColor,
                        size: 18,
                      ),
                      onPressed: () =>
                          setState(() => _showToken = !_showToken),
                    ),
                  ),
                ),
              ),
            ),
            _Step(
              number: '3',
              title: 'Run the Python bridge',
              body:
                  'On your PC or always-on device, run the bot.py file from the telegram_bridge/ folder:',
              child: _CodeBlock(
                code:
                    'pip install python-telegram-bot anthropic openai google-generativeai\npython bot.py --token YOUR_BOT_TOKEN --provider claude --apikey YOUR_API_KEY',
              ),
            ),
            _Step(
              number: '4',
              title: 'Start chatting',
              body:
                  'Open your bot in Telegram and send /start. ORB will respond with the same AI model you configured.',
            ),

            const SizedBox(height: 24),

            if (_tokenController.text.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.dividerColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Your Bot Token', style: AppTheme.captionStyle),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _showToken
                                ? _tokenController.text
                                : '••••••••••••••••••••',
                            style: AppTheme.monoStyle.copyWith(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy,
                              color: AppTheme.accentColor, size: 16),
                          onPressed: () {
                            Clipboard.setData(
                                ClipboardData(text: _tokenController.text));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Copied!')),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Save Token'),
              ),
            ),

            const SizedBox(height: 16),
            _InfoBox(
              text:
                  'The Telegram bridge runs separately on a PC or server. Your phone does not need to be unlocked for Telegram to work.',
            ),
          ],
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final String number;
  final String title;
  final String body;
  final Widget? child;

  const _Step({
    required this.number,
    required this.title,
    required this.body,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.accentColor.withOpacity(0.15),
              border:
                  Border.all(color: AppTheme.accentColor.withOpacity(0.5)),
            ),
            child: Center(
              child: Text(
                number,
                style: AppTheme.monoStyle.copyWith(fontSize: 13),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTheme.titleStyle),
                const SizedBox(height: 6),
                Text(body, style: AppTheme.captionStyle),
                if (child != null) child!,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CodeBlock extends StatelessWidget {
  final String code;
  const _CodeBlock({required this.code});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.accentColor.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              code,
              style: AppTheme.monoStyle.copyWith(fontSize: 11),
            ),
          ),
          GestureDetector(
            onTap: () => Clipboard.setData(ClipboardData(text: code)),
            child: const Icon(Icons.copy,
                color: AppTheme.subtitleColor, size: 14),
          ),
        ],
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final String text;
  const _InfoBox({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.accentColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: AppTheme.accentColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline,
              color: AppTheme.accentColor, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: AppTheme.captionStyle),
          ),
        ],
      ),
    );
  }
}
