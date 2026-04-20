import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:uuid/uuid.dart';
import '../memory/database.dart';

class PdfReader {
  static final PdfReader instance = PdfReader._internal();
  PdfReader._internal();

  final _uuid = const Uuid();

  Future<DocumentResult?> pickAndExtract() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'txt'],
        allowMultiple: false,
        withData: true, // ensure bytes are loaded on all platforms
      );

      if (result == null || result.files.isEmpty) return null;

      final file = result.files.first;
      final extension = file.extension?.toLowerCase() ?? '';

      if (extension == 'txt') {
        return await _extractTxt(file);
      } else {
        return await _extractPdf(file);
      }
    } catch (e) {
      return DocumentResult.error('Failed to open file: $e');
    }
  }

  Future<DocumentResult> _extractPdf(PlatformFile file) async {
    try {
      // Try bytes first (more reliable), fall back to path
      List<int>? bytes;
      if (file.bytes != null) {
        bytes = file.bytes!;
      } else if (file.path != null) {
        bytes = await File(file.path!).readAsBytes();
      } else {
        return DocumentResult.error('Cannot read file — no path or bytes available.');
      }

      PdfDocument? document;
      try {
        document = PdfDocument(inputBytes: bytes);
      } catch (e) {
        return DocumentResult.error('Could not parse PDF: $e');
      }

      final pageCount = document.pages.count;
      if (pageCount == 0) {
        document.dispose();
        return DocumentResult.error('PDF has no pages.');
      }

      final extractor = PdfTextExtractor(document);
      final buffer = StringBuffer();

      for (int i = 0; i < pageCount; i++) {
        try {
          final text = extractor.extractText(startPageIndex: i, endPageIndex: i);
          if (text.trim().isNotEmpty) {
            buffer.writeln('--- Page ${i + 1} ---');
            buffer.writeln(text.trim());
            buffer.writeln();
          }
        } catch (_) {
          // Skip pages that fail extraction
        }
      }

      document.dispose();

      var content = buffer.toString().trim();

      if (content.isEmpty) {
        return DocumentResult.error(
          'No text found in this PDF.\n\nThis is likely a scanned/image-based PDF. ORB can only read text-based PDFs right now.',
        );
      }

      // Trim to 15k chars to keep AI context manageable
      if (content.length > 15000) {
        content = '${content.substring(0, 15000)}\n\n[... document truncated for AI context ...]';
      }

      final id = _uuid.v4();
      await OrbDatabase.instance.insertDocument({
        'id': id,
        'name': file.name,
        'path': file.path ?? '',
        'content': content,
        'added_at': DateTime.now().millisecondsSinceEpoch,
      });

      return DocumentResult.success(
        id: id,
        name: file.name,
        content: content,
        pageCount: pageCount,
      );
    } catch (e) {
      return DocumentResult.error('PDF extraction failed: $e');
    }
  }

  Future<DocumentResult> _extractTxt(PlatformFile file) async {
    try {
      String content;
      if (file.bytes != null) {
        content = String.fromCharCodes(file.bytes!);
      } else if (file.path != null) {
        content = await File(file.path!).readAsString();
      } else {
        return DocumentResult.error('Cannot read text file.');
      }

      if (content.length > 15000) {
        content = '${content.substring(0, 15000)}\n\n[... truncated ...]';
      }

      final id = _uuid.v4();
      await OrbDatabase.instance.insertDocument({
        'id': id,
        'name': file.name,
        'path': file.path ?? '',
        'content': content,
        'added_at': DateTime.now().millisecondsSinceEpoch,
      });

      return DocumentResult.success(
        id: id,
        name: file.name,
        content: content,
        pageCount: 1,
      );
    } catch (e) {
      return DocumentResult.error('Text file read failed: $e');
    }
  }

  Future<List<SavedDocument>> getSavedDocuments() async {
    final rows = await OrbDatabase.instance.getDocuments();
    return rows.map((r) => SavedDocument.fromMap(r)).toList();
  }

  Future<void> deleteDocument(String id) async {
    await OrbDatabase.instance.deleteDocument(id);
  }
}

class DocumentResult {
  final bool success;
  final String? id, name, content, error;
  final int? pageCount;

  DocumentResult._({required this.success, this.id, this.name, this.content, this.pageCount, this.error});

  factory DocumentResult.success({required String id, required String name, required String content, required int pageCount}) =>
      DocumentResult._(success: true, id: id, name: name, content: content, pageCount: pageCount);

  factory DocumentResult.error(String message) =>
      DocumentResult._(success: false, error: message);
}

class SavedDocument {
  final String id, name, path, content;
  final DateTime addedAt;

  SavedDocument({required this.id, required this.name, required this.path, required this.content, required this.addedAt});

  factory SavedDocument.fromMap(Map<String, dynamic> map) => SavedDocument(
    id: map['id'] as String,
    name: map['name'] as String,
    path: map['path'] as String,
    content: map['content'] as String,
    addedAt: DateTime.fromMillisecondsSinceEpoch(map['added_at'] as int),
  );
}