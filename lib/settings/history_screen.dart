import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../memory/memory_manager.dart';
import '../utils/app_theme.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<OrbMessage> _messages = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final messages = await MemoryManager.instance.getAllMessages(limit: 200);
    setState(() {
      _messages = messages.reversed.toList();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        title: const Text('Chat History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: () async {
              await MemoryManager.instance.clearHistory();
              _load();
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _messages.isEmpty
              ? _buildEmpty()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    return _HistoryTile(message: msg);
                  },
                ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline,
              color: AppTheme.subtitleColor, size: 48),
          SizedBox(height: 16),
          Text('No history yet', style: AppTheme.captionStyle),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final OrbMessage message;
  const _HistoryTile({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final formatter = DateFormat('MMM d, h:mm a');

    return Container(
      margin: EdgeInsets.only(
        bottom: 8,
        left: isUser ? 40 : 0,
        right: isUser ? 0 : 40,
      ),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isUser
            ? AppTheme.accentColor.withOpacity(0.08)
            : AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUser
              ? AppTheme.accentColor.withOpacity(0.2)
              : AppTheme.dividerColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                isUser ? 'You' : 'ORB',
                style: AppTheme.captionStyle.copyWith(
                  color: isUser ? AppTheme.accentColor : AppTheme.subtitleColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                formatter.format(message.timestamp),
                style: AppTheme.captionStyle.copyWith(fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            message.content,
            style: AppTheme.bodyStyle.copyWith(fontSize: 13),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
