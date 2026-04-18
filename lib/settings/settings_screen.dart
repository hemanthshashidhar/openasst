import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../ai/claude_provider.dart';
import '../ai/openai_provider.dart';
import '../ai/gemini_provider.dart';
import '../memory/memory_manager.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import 'document_screen.dart';
import 'history_screen.dart';
import 'telegram_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // API Key controllers
  final _claudeKeyController = TextEditingController();
  final _openaiKeyController = TextEditingController();
  final _geminiKeyController = TextEditingController();
  final _userNameController = TextEditingController();

  // Visibility toggles
  bool _showClaudeKey = false;
  bool _showOpenAIKey = false;
  bool _showGeminiKey = false;

  String _selectedProvider = Constants.providerClaude;
  String _selectedModel = Constants.claudeModels[1];
  String _selectedPersonality = 'assistant';

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadSettings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _claudeKeyController.dispose();
    _openaiKeyController.dispose();
    _geminiKeyController.dispose();
    _userNameController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final claudeKey = await ClaudeProvider.instance.getKey();
    final openaiKey = await OpenAIProvider.instance.getKey();
    final geminiKey = await GeminiProvider.instance.getKey();
    final name = await MemoryManager.instance.getUserName();
    final personality = await MemoryManager.instance.getPersonality();

    setState(() {
      if (claudeKey != null) _claudeKeyController.text = claudeKey;
      if (openaiKey != null) _openaiKeyController.text = openaiKey;
      if (geminiKey != null) _geminiKeyController.text = geminiKey;
      _userNameController.text = name;
      _selectedProvider =
          prefs.getString(Constants.selectedProvider) ?? Constants.providerClaude;
      _selectedModel = prefs.getString(Constants.selectedModel) ??
          Constants.claudeModels[1];
      _selectedPersonality = personality;
      _loading = false;
    });
  }

  Future<void> _saveApiKeys() async {
    if (_claudeKeyController.text.trim().isNotEmpty) {
      await ClaudeProvider.instance.setKey(_claudeKeyController.text.trim());
    }
    if (_openaiKeyController.text.trim().isNotEmpty) {
      await OpenAIProvider.instance.setKey(_openaiKeyController.text.trim());
    }
    if (_geminiKeyController.text.trim().isNotEmpty) {
      await GeminiProvider.instance.setKey(_geminiKeyController.text.trim());
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(Constants.selectedProvider, _selectedProvider);
    await prefs.setString(Constants.selectedModel, _selectedModel);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved ✓'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }

  Future<void> _savePreferences() async {
    await MemoryManager.instance.setUserName(_userNameController.text.trim());
    await MemoryManager.instance.setPersonality(_selectedPersonality);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preferences saved ✓'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }

  List<String> get _modelsForProvider {
    switch (_selectedProvider) {
      case Constants.providerOpenAI:
        return Constants.openAIModels;
      case Constants.providerGemini:
        return Constants.geminiModels;
      default:
        return Constants.claudeModels;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        title: const Text('Settings'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.accentColor,
          labelColor: AppTheme.accentColor,
          unselectedLabelColor: AppTheme.subtitleColor,
          isScrollable: true,
          tabs: const [
            Tab(text: 'API Keys'),
            Tab(text: 'Model'),
            Tab(text: 'Preferences'),
            Tab(text: 'Data'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildApiKeysTab(),
                _buildModelTab(),
                _buildPreferencesTab(),
                _buildDataTab(),
              ],
            ),
    );
  }

  // ─── API Keys Tab ─────────────────────────────────────────────────────────

  Widget _buildApiKeysTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: Icons.key_outlined,
            title: 'Your API Keys',
            subtitle: 'Keys are stored securely on your device only.',
          ),
          const SizedBox(height: 24),
          _ApiKeyField(
            label: 'Anthropic (Claude)',
            hint: 'sk-ant-...',
            controller: _claudeKeyController,
            showKey: _showClaudeKey,
            onToggleVisibility: () =>
                setState(() => _showClaudeKey = !_showClaudeKey),
            onClear: () async {
              await ClaudeProvider.instance.deleteKey();
              _claudeKeyController.clear();
            },
            accentColor: const Color(0xFFFF6B35),
          ),
          const SizedBox(height: 16),
          _ApiKeyField(
            label: 'OpenAI (GPT)',
            hint: 'sk-...',
            controller: _openaiKeyController,
            showKey: _showOpenAIKey,
            onToggleVisibility: () =>
                setState(() => _showOpenAIKey = !_showOpenAIKey),
            onClear: () async {
              await OpenAIProvider.instance.deleteKey();
              _openaiKeyController.clear();
            },
            accentColor: const Color(0xFF10A37F),
          ),
          const SizedBox(height: 16),
          _ApiKeyField(
            label: 'Google (Gemini)',
            hint: 'AIza...',
            controller: _geminiKeyController,
            showKey: _showGeminiKey,
            onToggleVisibility: () =>
                setState(() => _showGeminiKey = !_showGeminiKey),
            onClear: () async {
              await GeminiProvider.instance.deleteKey();
              _geminiKeyController.clear();
            },
            accentColor: const Color(0xFF4285F4),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveApiKeys,
              child: const Text('Save API Keys'),
            ),
          ),
          const SizedBox(height: 16),
          _InfoBox(
            text:
                'Your API keys never leave your device. All AI calls go directly from your phone to the AI provider.',
          ),
        ],
      ),
    );
  }

  // ─── Model Tab ────────────────────────────────────────────────────────────

  Widget _buildModelTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: Icons.psychology_outlined,
            title: 'AI Provider & Model',
            subtitle: 'Choose which AI powers ORB.',
          ),
          const SizedBox(height: 24),

          // Provider selection
          Text('Provider', style: AppTheme.titleStyle),
          const SizedBox(height: 12),
          ...{
            Constants.providerClaude: ('Claude', 'Anthropic', const Color(0xFFFF6B35)),
            Constants.providerOpenAI: ('GPT', 'OpenAI', const Color(0xFF10A37F)),
            Constants.providerGemini: ('Gemini', 'Google', const Color(0xFF4285F4)),
          }.entries.map((e) => _ProviderCard(
                id: e.key,
                name: e.value.$1,
                company: e.value.$2,
                color: e.value.$3,
                selected: _selectedProvider == e.key,
                onTap: () {
                  setState(() {
                    _selectedProvider = e.key;
                    _selectedModel = _modelsForProvider.first;
                  });
                },
              )),

          const SizedBox(height: 24),
          Text('Model', style: AppTheme.titleStyle),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppTheme.accentColor.withOpacity(0.2)),
            ),
            child: DropdownButton<String>(
              value: _modelsForProvider.contains(_selectedModel)
                  ? _selectedModel
                  : _modelsForProvider.first,
              isExpanded: true,
              dropdownColor: AppTheme.surfaceColor,
              underline: const SizedBox(),
              style: AppTheme.bodyStyle,
              items: _modelsForProvider
                  .map((m) => DropdownMenuItem(
                        value: m,
                        child: Text(m, style: AppTheme.monoStyle),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _selectedModel = v);
              },
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveApiKeys,
              child: const Text('Save Selection'),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Preferences Tab ──────────────────────────────────────────────────────

  Widget _buildPreferencesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: Icons.person_outline,
            title: 'Personalization',
            subtitle: 'Make ORB feel like yours.',
          ),
          const SizedBox(height: 24),
          Text('Your Name', style: AppTheme.titleStyle),
          const SizedBox(height: 8),
          TextField(
            controller: _userNameController,
            style: AppTheme.bodyStyle,
            decoration: const InputDecoration(
              hintText: 'What should ORB call you?',
              prefixIcon: Icon(Icons.person_outline, color: AppTheme.accentColor),
            ),
          ),
          const SizedBox(height: 24),
          Text('ORB Personality', style: AppTheme.titleStyle),
          const SizedBox(height: 12),
          ...Constants.personalities.entries.map((e) => _PersonalityCard(
                id: e.key,
                label: e.value,
                selected: _selectedPersonality == e.key,
                onTap: () => setState(() => _selectedPersonality = e.key),
              )),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _savePreferences,
              child: const Text('Save Preferences'),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Data Tab ────────────────────────────────────────────────────────────

  Widget _buildDataTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: Icons.storage_outlined,
            title: 'Your Data',
            subtitle: 'Everything stays on your device.',
          ),
          const SizedBox(height: 24),
          _ActionTile(
            icon: Icons.history,
            title: 'Chat History',
            subtitle: 'View all past conversations',
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const HistoryScreen())),
          ),
          _ActionTile(
            icon: Icons.picture_as_pdf_outlined,
            title: 'Documents',
            subtitle: 'Manage loaded documents',
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const DocumentScreen())),
          ),
          _ActionTile(
            icon: Icons.telegram,
            title: 'Telegram Bridge',
            subtitle: 'Connect ORB to Telegram',
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const TelegramScreen())),
          ),
          const SizedBox(height: 24),
          _DangerTile(
            title: 'Clear Chat History',
            subtitle: 'Delete all conversations',
            onTap: () async {
              final confirm = await _showConfirmDialog(
                'Clear all chat history? This cannot be undone.',
              );
              if (confirm) {
                await MemoryManager.instance.clearHistory();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('History cleared')),
                  );
                }
              }
            },
          ),
          _DangerTile(
            title: 'Delete All API Keys',
            subtitle: 'Remove all stored keys',
            onTap: () async {
              final confirm = await _showConfirmDialog(
                'Delete all API keys? You will need to re-enter them.',
              );
              if (confirm) {
                await ClaudeProvider.instance.deleteKey();
                await OpenAIProvider.instance.deleteKey();
                await GeminiProvider.instance.deleteKey();
                _claudeKeyController.clear();
                _openaiKeyController.clear();
                _geminiKeyController.clear();
                if (mounted) setState(() {});
              }
            },
          ),
        ],
      ),
    );
  }

  Future<bool> _showConfirmDialog(String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('Confirm', style: AppTheme.titleStyle),
        content: Text(message, style: AppTheme.bodyStyle),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.subtitleColor)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete',
                style: TextStyle(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

// ─── Reusable Widgets ────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.accentColor, size: 28),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTheme.titleStyle),
            Text(subtitle, style: AppTheme.captionStyle),
          ],
        ),
      ],
    );
  }
}

class _ApiKeyField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final bool showKey;
  final VoidCallback onToggleVisibility;
  final VoidCallback onClear;
  final Color accentColor;

  const _ApiKeyField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.showKey,
    required this.onToggleVisibility,
    required this.onClear,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                  shape: BoxShape.circle, color: accentColor),
            ),
            const SizedBox(width: 8),
            Text(label, style: AppTheme.bodyStyle),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: !showKey,
          style: AppTheme.monoStyle.copyWith(fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    showKey ? Icons.visibility_off : Icons.visibility,
                    color: AppTheme.subtitleColor,
                    size: 18,
                  ),
                  onPressed: onToggleVisibility,
                ),
                IconButton(
                  icon: const Icon(Icons.clear,
                      color: AppTheme.subtitleColor, size: 18),
                  onPressed: onClear,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ProviderCard extends StatelessWidget {
  final String id;
  final String name;
  final String company;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _ProviderCard({
    required this.id,
    required this.name,
    required this.company,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.1) : AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : AppTheme.dividerColor,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppTheme.titleStyle),
                  Text(company, style: AppTheme.captionStyle),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle, color: color, size: 18),
          ],
        ),
      ),
    );
  }
}

class _PersonalityCard extends StatelessWidget {
  final String id;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PersonalityCard({
    required this.id,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.accentColor.withOpacity(0.1)
              : AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppTheme.accentColor : AppTheme.dividerColor,
          ),
        ),
        child: Row(
          children: [
            Expanded(child: Text(label, style: AppTheme.bodyStyle)),
            if (selected)
              const Icon(Icons.check_circle,
                  color: AppTheme.accentColor, size: 18),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.dividerColor),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.accentColor, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTheme.bodyStyle),
                  Text(subtitle, style: AppTheme.captionStyle),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: AppTheme.subtitleColor, size: 20),
          ],
        ),
      ),
    );
  }
}

class _DangerTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _DangerTile({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.errorColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: AppTheme.errorColor.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.delete_outline,
                color: AppTheme.errorColor, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppTheme.bodyStyle
                          .copyWith(color: AppTheme.errorColor)),
                  Text(subtitle, style: AppTheme.captionStyle),
                ],
              ),
            ),
          ],
        ),
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
        border: Border.all(
            color: AppTheme.accentColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outline,
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
