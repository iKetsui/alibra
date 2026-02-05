import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

class PDFViewerScreen extends StatefulWidget {
  final String filePath;

  const PDFViewerScreen({super.key, required this.filePath});

  @override
  State<PDFViewerScreen> createState() => _PDFViewerScreenState();
}

class _PDFViewerScreenState extends State<PDFViewerScreen> {
  PDFViewController? _pdfViewController;
  int totalPages = 0;
  int currentPage = 0;
  bool isReady = false;
  String errorMessage = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            'PDF Viewer - Page ${currentPage + 1} of ${totalPages > 0 ? totalPages : '?'}'),
        actions: [
          if (isReady && totalPages > 0)
            IconButton(
              onPressed: currentPage > 0
                  ? () => _pdfViewController?.setPage(currentPage - 1)
                  : null,
              icon: const Icon(Icons.arrow_back),
            ),
          if (isReady && totalPages > 0)
            IconButton(
              onPressed: currentPage < totalPages - 1
                  ? () => _pdfViewController?.setPage(currentPage + 1)
                  : null,
              icon: const Icon(Icons.arrow_forward),
            ),
        ],
      ),
      body: _buildPDFView(),
    );
  }

  Widget _buildPDFView() {
    if (errorMessage.isNotEmpty) {
      return Center(child: Text('Error: $errorMessage'));
    }

    return PDFView(
      filePath: widget.filePath,
      enableSwipe: true,
      swipeHorizontal: true,
      autoSpacing: true,
      pageFling: true,
      fitPolicy: FitPolicy.BOTH,
      nightMode: false,
      backgroundColor: Colors.grey[200]!,
      onRender: (pages) {
        setState(() {
          totalPages = pages ?? 0;
          isReady = true;
        });
      },
      onError: (error) {
        setState(() {
          errorMessage = error.toString();
        });
        debugPrint('PDF Error: $error');
      },
      onPageError: (page, error) {
        debugPrint('PDF Page Error - Page $page: $error');
      },
      onViewCreated: (PDFViewController controller) {
        _pdfViewController = controller;
      },
      onPageChanged: (int? page, int? total) {
        debugPrint('Page changed: $page/$total');
        setState(() {
          currentPage = page ?? 0; // Use 0 if page is null
          totalPages = total ?? 0; // Use 0 if total is null
        });
      },
    );
  }
}
