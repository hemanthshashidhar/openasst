import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../document/pdf_reader.dart';
import '../overlay/chat_overlay.dart';
import '../utils/app_theme.dart';

class DocumentScreen extends StatefulWidget {
  const DocumentScreen({super.key});
  @override
  State<DocumentScreen> createState() => _DocumentScreenState();
}

class _DocumentScreenState extends State<DocumentScreen> {
  List<SavedDocument> _documents = [];
  bool _loading = true;
  bool _extracting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final docs = await PdfReader.instance.getSavedDocuments();
    setState(() { _documents = docs; _loading = false; });
  }

  Future<void> _addDocument() async {
    setState(() => _extracting = true);
    final result = await PdfReader.instance.pickAndExtract();
    setState(() => _extracting = false);

    if (result == null) return;

    if (!result.success) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error ?? 'Failed to load'), backgroundColor: AppTheme.errorColor),
      );
      return;
    }

    await _load();

    // Automatically open chat with this document
    if (mounted && result.content != null) {
      _openChat(result.name ?? 'Document', result.content!);
    }
  }

  void _openChat(String name, String content) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: AppTheme.bgColor,
          appBar: AppBar(
            title: Text(name, overflow: TextOverflow.ellipsis),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Chip(
                  label: const Text('Document loaded', style: TextStyle(fontSize: 11, color: Colors.white)),
                  backgroundColor: AppTheme.accentSecondary,
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          body: ChatOverlay(
            onClose: () => Navigator.pop(context),
            initialDocumentContext: content,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        title: const Text('Documents'),
        actions: [
          if (_extracting)
            const Padding(padding: EdgeInsets.all(16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
          else
            IconButton(icon: const Icon(Icons.add), onPressed: _addDocument),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _documents.isEmpty
              ? _buildEmpty()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _documents.length,
                  itemBuilder: (context, i) => _DocTile(
                    doc: _documents[i],
                    onAsk: () => _openChat(_documents[i].name, _documents[i].content),
                    onDelete: () async {
                      await PdfReader.instance.deleteDocument(_documents[i].id);
                      _load();
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addDocument,
        backgroundColor: AppTheme.accentColor,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.upload_file),
        label: const Text('Load PDF / TXT'),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.picture_as_pdf_outlined, color: AppTheme.subtitleColor, size: 56),
          const SizedBox(height: 16),
          const Text('No documents loaded', style: AppTheme.titleStyle),
          const SizedBox(height: 8),
          const Text('Load a PDF or TXT file\nthen ask ORB anything about it', style: AppTheme.captionStyle, textAlign: TextAlign.center),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            onPressed: _addDocument,
            icon: const Icon(Icons.upload_file),
            label: const Text('Load Document'),
          ),
        ],
      ),
    );
  }
}

class _DocTile extends StatelessWidget {
  final SavedDocument doc;
  final VoidCallback onAsk, onDelete;
  const _DocTile({required this.doc, required this.onAsk, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 0),
            child: Row(children: [
              const Icon(Icons.description_outlined, color: AppTheme.accentColor, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text(doc.name, style: AppTheme.titleStyle, overflow: TextOverflow.ellipsis)),
              IconButton(icon: const Icon(Icons.delete_outline, color: AppTheme.errorColor, size: 18), onPressed: onDelete, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Text(
              doc.content.length > 120 ? '${doc.content.substring(0, 120)}...' : doc.content,
              style: AppTheme.captionStyle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Row(children: [
              Text('Added ${DateFormat('MMM d, yyyy').format(doc.addedAt)}', style: AppTheme.captionStyle.copyWith(fontSize: 11)),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: onAsk,
                icon: const Icon(Icons.chat_bubble_outline, size: 14),
                label: const Text('Ask ORB'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentColor,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}