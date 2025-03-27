import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class DocumentPreviewScreen extends StatefulWidget {
  final String docUrl;
  const DocumentPreviewScreen({required this.docUrl, super.key});

  @override
  State<DocumentPreviewScreen> createState() => _DocumentPreviewScreenState();
}

class _DocumentPreviewScreenState extends State<DocumentPreviewScreen> {
  String? localPath;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    downloadFile();
  }

  Future<void> downloadFile() async {
    try {
      final response = await http.get(Uri.parse(widget.docUrl));
      if (response.statusCode != 200) {
        throw Exception('Failed to download file: ${response.statusCode}');
      }

      final bytes = response.bodyBytes;
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/temp_doc.pdf');

      await file.writeAsBytes(bytes, flush: true);
      if (mounted) {
        setState(() {
          localPath = file.path;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load document: ${e.toString()}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Document Preview')),
      body: _errorMessage != null
          ? Center(child: Text(_errorMessage!))
          : localPath != null
              ? PDFView(
                  filePath: localPath,
                  autoSpacing: true,
                  swipeHorizontal: false,
                  pageSnap: true,
                )
              : const Center(child: CircularProgressIndicator()),
    );
  }
}
