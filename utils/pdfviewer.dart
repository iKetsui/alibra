import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

class PDFViewerScreen extends StatefulWidget {
  final String filePath;
  final Function(String)? onError;
  final Function(double)? onProgressChanged;
  
  const PDFViewerScreen({
    super.key, 
    required this.filePath,
    this.onError,
    this.onProgressChanged,
  });

  @override
  State<PDFViewerScreen> createState() => _PDFViewerScreenState();
}

class _PDFViewerScreenState extends State<PDFViewerScreen> {
  PDFViewController? _pdfViewController;
  int _totalPages = 0;
  int _currentPage = 0;
  bool _isReady = false;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _validateFilePath();
    });
  }

  Future<void> _validateFilePath() async {
    try {
      // Check if file exists and is accessible
      final file = File(widget.filePath);
      final exists = await file.exists();
      
      if (!exists) {
        throw Exception('File not found: ${widget.filePath}');
      }

      final size = await file.length();
      if (size == 0) {
        throw Exception('File is empty');
      }
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      _handleError(e.toString());
    }
  }

  void _handleError(String error) {
    setState(() {
      _hasError = true;
      _errorMessage = _getUserFriendlyErrorMessage(error);
      _isLoading = false;
    });
    
    if (widget.onError != null) {
      widget.onError!(_errorMessage);
    }
  }

  String _getUserFriendlyErrorMessage(String error) {
    if (error.contains('File not found')) {
      return 'The file was not found. It may have been moved or deleted.';
    } else if (error.contains('permission denied')) {
      return 'Permission denied. Please check file permissions.';
    } else if (error.contains('PDF header')) {
      return 'The file is not a valid PDF. It may be corrupted.';
    } else if (error.contains('unsupported format')) {
      return 'PDF format is not supported. Try a different PDF file.';
    } else if (error.contains('too large')) {
      return 'The PDF file is too large to open.';
    }
    return 'Failed to open PDF: ${error.split(':').last}';
  }

  Widget _buildErrorScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 20),
            const Text(
              'Cannot Open PDF',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _validateFilePath,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 20),
          Text(
            'Loading PDF...',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingScreen();
    }

    if (_hasError) {
      return _buildErrorScreen();
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
      
      // Loading callbacks
      onRender: (pages) {
        setState(() {
          _totalPages = pages ?? 0;
          _isReady = true;
        });
      },
      
      onError: (error) {
        _handleError(error.toString());
      },
      
      onPageError: (page, error) {
        debugPrint('PDF Page Error - Page $page: $error');
        if (page == 1 && widget.onError != null) {
          widget.onError!('Failed to load page $page');
        }
      },
      
      onViewCreated: (PDFViewController controller) {
        _pdfViewController = controller;
      },
      
      onPageChanged: (int? page, int? total) {
        if (page != null && total != null) {
          setState(() {
            _currentPage = page;
            _totalPages = total;
          });
          
          if (widget.onProgressChanged != null && total > 0) {
            widget.onProgressChanged!(page / total);
          }
        }
      },
    );
  }
}