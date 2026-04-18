import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:uuid/uuid.dart';
import '../memory/database.dart';

class PdfReader {
  static final PdfReader instance = PdfReader._internal();
  PdfReader._internal();

  final _uuid = const Uuid();

  /// Pick a PDF file and extract its text
  Future<DocumentResult?> pickAndExtract() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'txt'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return null;

      final file = result.files.first;
      if (file.path == null) return null;

      final extension = file.extension?.toLowerCase();

      if (extension == 'txt') {
        return await _extractFromTxt(file.path!, file.name);
      } else {
        return await _extractFromPdf(file.path!, file.name);
      }
    } catch (e) {
      return DocumentResult.error('Failed to open file: ${e.toString()}');
    }
  }

  Future<DocumentResult> _extractFromPdf(
      String filePath, String fileName) async {
    try {
      final bytes = await File(filePath).readAsBytes();
      final document = PdfDocument(inputBytes: bytes);

      final extractor = PdfTextExtractor(document);
      final StringBuffer buffer = StringBuffer();

      for (int i = 0; i < document.pages.count; i++) {
        final pageText = extractor.extractText(startPageIndex: i, endPageIndex: i);
        if (pageText.trim().isNotEmpty) {
          buffer.writeln('--- Page ${i + 1} ---');
          buffer.writeln(pageText.trim());
          buffer.writeln();
        }
      }

      document.dispose();

      final content = buffer.toString();
      if (content.trim().isEmpty) {
        return DocumentResult.error(
            'No text found in PDF. It may be a scanned image-only PDF.');
      }

      // Truncate if too large (keep first 15k chars for context)
      final truncated = content.length > 15000
          ? '${content.substring(0, 15000)}\n\n[... document truncated for context ...]'
          : content;

      // Save to DB
      final id = _uuid.v4();
      await OrbDatabase.instance.insertDocument({
        'id': id,
        'name': fileName,
        'path': filePath,
        'content': truncated,
        'added_at': DateTime.now().millisecondsSinceEpoch,
      });

      return DocumentResult.success(
        id: id,
        name: fileName,
        content: truncated,
        pageCount: document.pages.count,
      );
    } catch (e) {
      return DocumentResult.error('PDF extraction failed: ${e.toString()}');
    }
  }

  Future<DocumentResult> _extractFromTxt(
      String filePath, String fileName) async {
    try {
      final content = await File(filePath).readAsString();
      final truncated = content.length > 15000
          ? '${content.substring(0, 15000)}\n\n[... document truncated ...]'
          : content;

      final id = _uuid.v4();
      await OrbDatabase.instance.insertDocument({
        'id': id,
        'name': fileName,
        'path': filePath,
        'content': truncated,
        'added_at': DateTime.now().millisecondsSinceEpoch,
      });

      return DocumentResult.success(
        id: id,
        name: fileName,
        content: truncated,
        pageCount: 1,
      );
    } catch (e) {
      return DocumentResult.error('Text file extraction failed: ${e.toString()}');
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
  final String? id;
  final String? name;
  final String? content;
  final int? pageCount;
  final String? error;

  DocumentResult._({
    required this.success,
    this.id,
    this.name,
    this.content,
    this.pageCount,
    this.error,
  });

  factory DocumentResult.success({
    required String id,
    required String name,
    required String content,
    required int pageCount,
  }) =>
      DocumentResult._(
        success: true,
        id: id,
        name: name,
        content: content,
        pageCount: pageCount,
      );

  factory DocumentResult.error(String message) =>
      DocumentResult._(success: false, error: message);
}

class SavedDocument {
  final String id;
  final String name;
  final String path;
  final String content;
  final DateTime addedAt;

  SavedDocument({
    required this.id,
    required this.name,
    required this.path,
    required this.content,
    required this.addedAt,
  });

  factory SavedDocument.fromMap(Map<String, dynamic> map) {
    return SavedDocument(
      id: map['id'] as String,
      name: map['name'] as String,
      path: map['path'] as String,
      content: map['content'] as String,
      addedAt: DateTime.fromMillisecondsSinceEpoch(map['added_at'] as int),
    );
  }
}
