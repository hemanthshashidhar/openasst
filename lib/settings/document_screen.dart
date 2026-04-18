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
    setState(() {
      _documents = docs;
      _loading = false;
    });
  }

  Future<void> _addDocument() async {
    setState(() => _extracting = true);
    final result = await PdfReader.instance.pickAndExtract();
    setState(() => _extracting = false);

    if (result == null) return;

    if (!result.success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error ?? 'Failed to load document'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
      return;
    }

    await _load();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Loaded: ${result.name}'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }

  Future<void> _openWithOrb(SavedDocument doc) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: AppTheme.bgColor,
          appBar: AppBar(title: Text(doc.name)),
          body: ChatOverlay(
            onClose: () => Navigator.pop(context),
            initialDocumentContext: doc.content,
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
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _addDocument,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _documents.isEmpty
              ? _buildEmpty()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _documents.length,
                  itemBuilder: (context, index) {
                    final doc = _documents[index];
                    return _DocumentTile(
                      document: doc,
                      onAsk: () => _openWithOrb(doc),
                      onDelete: () async {
                        await PdfReader.instance.deleteDocument(doc.id);
                        _load();
                      },
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addDocument,
        backgroundColor: AppTheme.accentColor,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.upload_file),
        label: const Text('Load Document'),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.picture_as_pdf_outlined,
              color: AppTheme.subtitleColor, size: 48),
          const SizedBox(height: 16),
          const Text('No documents loaded', style: AppTheme.captionStyle),
          const SizedBox(height: 8),
          const Text('Load a PDF or TXT file to ask ORB about it',
              style: AppTheme.captionStyle),
          const SizedBox(height: 24),
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

class _DocumentTile extends StatelessWidget {
  final SavedDocument document;
  final VoidCallback onAsk;
  final VoidCallback onDelete;

  const _DocumentTile({
    required this.document,
    required this.onAsk,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('MMM d, yyyy');
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.description_outlined,
                  color: AppTheme.accentColor, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  document.name,
                  style: AppTheme.titleStyle,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    color: AppTheme.errorColor, size: 18),
                onPressed: onDelete,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            document.content.substring(
                0, document.content.length > 100 ? 100 : document.content.length),
            style: AppTheme.captionStyle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Added ${formatter.format(document.addedAt)}',
                style: AppTheme.captionStyle.copyWith(fontSize: 11),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onAsk,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Ask ORB',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
