/*
// ✅ ADD THIS NEW FILE
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PDFViewerScreen extends StatelessWidget {
  final String url;
  final String title;

  const PDFViewerScreen({
    Key? key,
    required this.url,
    this.title = 'PDF Document',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.blue.shade700,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // Share PDF URL
            },
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              // Download PDF
            },
          ),
        ],
      ),
      body: WebView(
        initialUrl: url,
        javascriptMode: JavascriptMode.unrestricted,
        onPageFinished: (url) {
          print('PDF loaded: $url');
        },
        onWebResourceError: (error) {
          print('Error loading PDF: $error');
        },
      ),
    );
  }
}*/
