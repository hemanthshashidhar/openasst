import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../ai/claude_provider.dart';
import '../ai/openai_provider.dart';
import '../ai/gemini_provider.dart';
import '../ai/openrouter_provider.dart';
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

class _SettingsScreenState extends State<SettingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _claudeKeyController = TextEditingController();
  final _openaiKeyController = TextEditingController();
  final _geminiKeyController = TextEditingController();
  final _openrouterKeyController = TextEditingController();
  final _userNameController = TextEditingController();
  final _customModelController = TextEditingController();

  bool _showClaude = false, _showOpenAI = false, _showGemini = false, _showOpenRouter = false;

  String _selectedProvider = Constants.providerOpenRouter;
  String _selectedModel = Constants.openRouterModels[0];
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
    _openrouterKeyController.dispose();
    _userNameController.dispose();
    _customModelController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final claudeKey = await ClaudeProvider.instance.getKey();
    final openaiKey = await OpenAIProvider.instance.getKey();
    final geminiKey = await GeminiProvider.instance.getKey();
    final openrouterKey = await OpenRouterProvider.instance.getKey();
    final name = await MemoryManager.instance.getUserName();
    final personality = await MemoryManager.instance.getPersonality();
    final provider = prefs.getString(Constants.selectedProvider) ?? Constants.providerOpenRouter;
    final model = prefs.getString(Constants.selectedModel) ?? Constants.openRouterModels[0];

    setState(() {
      if (claudeKey != null) _claudeKeyController.text = claudeKey;
      if (openaiKey != null) _openaiKeyController.text = openaiKey;
      if (geminiKey != null) _geminiKeyController.text = geminiKey;
      if (openrouterKey != null) _openrouterKeyController.text = openrouterKey;
      _userNameController.text = name;
      _selectedProvider = provider;
      _selectedModel = model;
      _selectedPersonality = personality;
      _loading = false;
    });
  }

  Future<void> _saveApiKeys() async {
    if (_claudeKeyController.text.trim().isNotEmpty)
      await ClaudeProvider.instance.setKey(_claudeKeyController.text.trim());
    if (_openaiKeyController.text.trim().isNotEmpty)
      await OpenAIProvider.instance.setKey(_openaiKeyController.text.trim());
    if (_geminiKeyController.text.trim().isNotEmpty)
      await GeminiProvider.instance.setKey(_geminiKeyController.text.trim());
    if (_openrouterKeyController.text.trim().isNotEmpty)
      await OpenRouterProvider.instance.setKey(_openrouterKeyController.text.trim());

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API Keys saved ✓'), backgroundColor: AppTheme.successColor),
      );
    }
  }

  Future<void> _saveModel() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(Constants.selectedProvider, _selectedProvider);
    await prefs.setString(Constants.selectedModel, _selectedModel);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Model saved ✓'), backgroundColor: AppTheme.successColor),
      );
    }
  }

  Future<void> _savePreferences() async {
    await MemoryManager.instance.setUserName(_userNameController.text.trim());
    await MemoryManager.instance.setPersonality(_selectedPersonality);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preferences saved ✓'), backgroundColor: AppTheme.successColor),
      );
    }
  }

  List<String> get _modelsForProvider {
    switch (_selectedProvider) {
      case Constants.providerOpenAI: return Constants.openAIModels;
      case Constants.providerGemini: return Constants.geminiModels;
      case Constants.providerOpenRouter: return Constants.openRouterModels;
      default: return Constants.claudeModels;
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
          tabs: const [Tab(text: 'API Keys'), Tab(text: 'Model'), Tab(text: 'Preferences'), Tab(text: 'Data')],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [_buildApiKeysTab(), _buildModelTab(), _buildPreferencesTab(), _buildDataTab()],
            ),
    );
  }

  Widget _buildApiKeysTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(icon: Icons.key_outlined, title: 'Your API Keys', subtitle: 'Stored securely on your device only.'),
          const SizedBox(height: 20),

          // OpenRouter - highlighted as recommended
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF7C4DFF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF7C4DFF).withOpacity(0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF7C4DFF))),
                  const SizedBox(width: 8),
                  const Text('OpenRouter  ⭐ Recommended', style: AppTheme.bodyStyle),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xFF7C4DFF), borderRadius: BorderRadius.circular(10)),
                    child: const Text('All models', style: TextStyle(fontSize: 10, color: Colors.white)),
                  ),
                ]),
                const SizedBox(height: 4),
                const Text('One key for Claude, GPT, Gemini, Llama and more', style: AppTheme.captionStyle),
                const SizedBox(height: 10),
                TextField(
                  controller: _openrouterKeyController,
                  obscureText: !_showOpenRouter,
                  style: AppTheme.monoStyle.copyWith(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'sk-or-v1-...',
                    suffixIcon: Row(mainAxisSize: MainAxisSize.min, children: [
                      IconButton(icon: Icon(_showOpenRouter ? Icons.visibility_off : Icons.visibility, color: AppTheme.subtitleColor, size: 18), onPressed: () => setState(() => _showOpenRouter = !_showOpenRouter)),
                      IconButton(icon: const Icon(Icons.clear, color: AppTheme.subtitleColor, size: 18), onPressed: () async { await OpenRouterProvider.instance.deleteKey(); _openrouterKeyController.clear(); }),
                    ]),
                  ),
                ),
                const SizedBox(height: 6),
                const Text('Get free key at openrouter.ai', style: TextStyle(fontSize: 11, color: Color(0xFF7C4DFF))),
              ],
            ),
          ),

          const SizedBox(height: 16),
          const Divider(color: AppTheme.dividerColor),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('Or use direct API keys:', style: AppTheme.captionStyle),
          ),

          _ApiKeyField(label: 'Anthropic (Claude)', hint: 'sk-ant-...', controller: _claudeKeyController, showKey: _showClaude, color: const Color(0xFFFF6B35),
            onToggle: () => setState(() => _showClaude = !_showClaude),
            onClear: () async { await ClaudeProvider.instance.deleteKey(); _claudeKeyController.clear(); }),
          const SizedBox(height: 12),
          _ApiKeyField(label: 'OpenAI (GPT)', hint: 'sk-...', controller: _openaiKeyController, showKey: _showOpenAI, color: const Color(0xFF10A37F),
            onToggle: () => setState(() => _showOpenAI = !_showOpenAI),
            onClear: () async { await OpenAIProvider.instance.deleteKey(); _openaiKeyController.clear(); }),
          const SizedBox(height: 12),
          _ApiKeyField(label: 'Google (Gemini)', hint: 'AIza...', controller: _geminiKeyController, showKey: _showGemini, color: const Color(0xFF4285F4),
            onToggle: () => setState(() => _showGemini = !_showGemini),
            onClear: () async { await GeminiProvider.instance.deleteKey(); _geminiKeyController.clear(); }),

          const SizedBox(height: 24),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _saveApiKeys, child: const Text('Save All Keys'))),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppTheme.accentColor.withOpacity(0.05), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppTheme.accentColor.withOpacity(0.2))),
            child: const Row(children: [
              Icon(Icons.lock_outline, color: AppTheme.accentColor, size: 14),
              SizedBox(width: 8),
              Expanded(child: Text('Keys never leave your device. Direct calls to AI providers.', style: AppTheme.captionStyle)),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildModelTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(icon: Icons.psychology_outlined, title: 'AI Provider & Model', subtitle: 'Choose what powers ORB.'),
          const SizedBox(height: 20),
          Text('Provider', style: AppTheme.titleStyle),
          const SizedBox(height: 12),

          ...[
            (Constants.providerOpenRouter, 'OpenRouter', 'All providers via one key', const Color(0xFF7C4DFF)),
            (Constants.providerClaude, 'Claude', 'Anthropic', const Color(0xFFFF6B35)),
            (Constants.providerOpenAI, 'GPT', 'OpenAI', const Color(0xFF10A37F)),
            (Constants.providerGemini, 'Gemini', 'Google', const Color(0xFF4285F4)),
          ].map((e) => GestureDetector(
            onTap: () => setState(() {
              _selectedProvider = e.$1;
              _selectedModel = _modelsForProvider.first;
            }),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _selectedProvider == e.$1 ? e.$4.withOpacity(0.1) : AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _selectedProvider == e.$1 ? e.$4 : AppTheme.dividerColor, width: _selectedProvider == e.$1 ? 1.5 : 1),
              ),
              child: Row(children: [
                Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: e.$4)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(e.$2, style: AppTheme.titleStyle),
                  Text(e.$3, style: AppTheme.captionStyle),
                ])),
                if (_selectedProvider == e.$1) Icon(Icons.check_circle, color: e.$4, size: 18),
              ]),
            ),
          )),

          const SizedBox(height: 20),
          Text('Model', style: AppTheme.titleStyle),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(color: AppTheme.surfaceColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.accentColor.withOpacity(0.2))),
            child: DropdownButton<String>(
              value: _modelsForProvider.contains(_selectedModel) ? _selectedModel : _modelsForProvider.first,
              isExpanded: true,
              dropdownColor: AppTheme.surfaceColor,
              underline: const SizedBox(),
              style: AppTheme.bodyStyle,
              items: _modelsForProvider.map((m) => DropdownMenuItem(value: m, child: Text(m, style: AppTheme.monoStyle.copyWith(fontSize: 12), overflow: TextOverflow.ellipsis))).toList(),
              onChanged: (v) { if (v != null) setState(() => _selectedModel = v); },
            ),
          ),

          if (_selectedProvider == Constants.providerOpenRouter) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _customModelController,
              style: AppTheme.monoStyle.copyWith(fontSize: 13),
              decoration: const InputDecoration(hintText: 'Or type any custom model ID...', prefixIcon: Icon(Icons.edit_outlined, color: AppTheme.accentColor, size: 18)),
              onChanged: (v) { if (v.trim().isNotEmpty) setState(() => _selectedModel = v.trim()); },
            ),
            const SizedBox(height: 6),
            const Text('Browse all models at openrouter.ai/models', style: TextStyle(fontSize: 11, color: AppTheme.accentColor)),
          ],

          const SizedBox(height: 24),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _saveModel, child: const Text('Save Selection'))),
        ],
      ),
    );
  }

  Widget _buildPreferencesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(icon: Icons.person_outline, title: 'Personalization', subtitle: 'Make ORB feel like yours.'),
          const SizedBox(height: 20),
          Text('Your Name', style: AppTheme.titleStyle),
          const SizedBox(height: 8),
          TextField(
            controller: _userNameController,
            style: AppTheme.bodyStyle,
            decoration: const InputDecoration(hintText: 'What should ORB call you?', prefixIcon: Icon(Icons.person_outline, color: AppTheme.accentColor)),
          ),
          const SizedBox(height: 24),
          Text('ORB Personality', style: AppTheme.titleStyle),
          const SizedBox(height: 12),
          ...Constants.personalities.entries.map((e) => GestureDetector(
            onTap: () => setState(() => _selectedPersonality = e.key),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _selectedPersonality == e.key ? AppTheme.accentColor.withOpacity(0.1) : AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _selectedPersonality == e.key ? AppTheme.accentColor : AppTheme.dividerColor),
              ),
              child: Row(children: [
                Expanded(child: Text(e.value, style: AppTheme.bodyStyle)),
                if (_selectedPersonality == e.key) const Icon(Icons.check_circle, color: AppTheme.accentColor, size: 18),
              ]),
            ),
          )),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _savePreferences, child: const Text('Save Preferences'))),
        ],
      ),
    );
  }

  Widget _buildDataTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(icon: Icons.storage_outlined, title: 'Your Data', subtitle: 'Everything stays on your device.'),
          const SizedBox(height: 20),
          _ActionTile(icon: Icons.history, title: 'Chat History', subtitle: 'View all past conversations',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen()))),
          _ActionTile(icon: Icons.picture_as_pdf_outlined, title: 'Documents', subtitle: 'Manage loaded documents',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DocumentScreen()))),
          _ActionTile(icon: Icons.telegram, title: 'Telegram Bridge', subtitle: 'Connect ORB to Telegram',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TelegramScreen()))),
          const SizedBox(height: 20),
          _DangerTile(title: 'Clear Chat History', subtitle: 'Delete all conversations', onTap: () async {
            final ok = await _confirm('Clear all chat history? Cannot be undone.');
            if (ok) { await MemoryManager.instance.clearHistory(); if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cleared'))); }
          }),
          _DangerTile(title: 'Delete All API Keys', subtitle: 'Remove all stored keys', onTap: () async {
            final ok = await _confirm('Delete all API keys?');
            if (ok) {
              await ClaudeProvider.instance.deleteKey();
              await OpenAIProvider.instance.deleteKey();
              await GeminiProvider.instance.deleteKey();
              await OpenRouterProvider.instance.deleteKey();
              _claudeKeyController.clear(); _openaiKeyController.clear();
              _geminiKeyController.clear(); _openrouterKeyController.clear();
              if (mounted) setState(() {});
            }
          }),
        ],
      ),
    );
  }

  Future<bool> _confirm(String msg) async {
    final r = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('Confirm', style: AppTheme.titleStyle),
        content: Text(msg, style: AppTheme.bodyStyle),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(color: AppTheme.subtitleColor))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirm', style: TextStyle(color: AppTheme.errorColor))),
        ],
      ),
    );
    return r ?? false;
  }
}

// ── Shared widgets ──────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon; final String title, subtitle;
  const _SectionHeader({required this.icon, required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, color: AppTheme.accentColor, size: 26),
    const SizedBox(width: 12),
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: AppTheme.titleStyle),
      Text(subtitle, style: AppTheme.captionStyle),
    ]),
  ]);
}

class _ApiKeyField extends StatelessWidget {
  final String label, hint;
  final TextEditingController controller;
  final bool showKey;
  final Color color;
  final VoidCallback onToggle, onClear;
  const _ApiKeyField({required this.label, required this.hint, required this.controller, required this.showKey, required this.color, required this.onToggle, required this.onClear});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: color)), const SizedBox(width: 8), Text(label, style: AppTheme.bodyStyle)]),
    const SizedBox(height: 6),
    TextField(
      controller: controller, obscureText: !showKey,
      style: AppTheme.monoStyle.copyWith(fontSize: 13),
      decoration: InputDecoration(hintText: hint, suffixIcon: Row(mainAxisSize: MainAxisSize.min, children: [
        IconButton(icon: Icon(showKey ? Icons.visibility_off : Icons.visibility, color: AppTheme.subtitleColor, size: 18), onPressed: onToggle),
        IconButton(icon: const Icon(Icons.clear, color: AppTheme.subtitleColor, size: 18), onPressed: onClear),
      ])),
    ),
  ]);
}

class _ActionTile extends StatelessWidget {
  final IconData icon; final String title, subtitle; final VoidCallback onTap;
  const _ActionTile({required this.icon, required this.title, required this.subtitle, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.surfaceColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.dividerColor)),
      child: Row(children: [
        Icon(icon, color: AppTheme.accentColor, size: 22), const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: AppTheme.bodyStyle), Text(subtitle, style: AppTheme.captionStyle)])),
        const Icon(Icons.chevron_right, color: AppTheme.subtitleColor, size: 20),
      ]),
    ),
  );
}

class _DangerTile extends StatelessWidget {
  final String title, subtitle; final VoidCallback onTap;
  const _DangerTile({required this.title, required this.subtitle, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.errorColor.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.errorColor.withOpacity(0.3))),
      child: Row(children: [
        const Icon(Icons.delete_outline, color: AppTheme.errorColor, size: 22), const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: AppTheme.bodyStyle.copyWith(color: AppTheme.errorColor)), Text(subtitle, style: AppTheme.captionStyle)])),
      ]),
    ),
  );
}