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

  @override
  void initState() {
    super.initState();
    downloadFile();
  }

  Future<void> downloadFile() async {
    try {
      final response = await http.get(Uri.parse(widget.docUrl));
      final bytes = response.bodyBytes;

      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/temp_doc.pdf');

      await file.writeAsBytes(bytes, flush: true);
      setState(() {
        localPath = file.path;
      });
    } catch (e) {
      print("Error downloading file: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Document Preview')),
      body: localPath != null
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
