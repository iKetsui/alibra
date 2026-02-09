import 'package:e_reader/utils/epub_viewer.dart';
import 'package:flutter/material.dart';
import 'package:e_reader/utils/pdfviewer.dart';
import '../models/book.dart';

class ReaderPage extends StatefulWidget {
  final Book? book;
  
  const ReaderPage({super.key, this.book});

  @override
  State<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage> {
  bool _pdfError = false;
  String _errorMessage = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.book?.title ?? 'No Book Selected'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.format_size),
            onPressed: _showFontSizeDialog,
          ),
          IconButton(
            icon: const Icon(Icons.brightness_6),
            onPressed: _toggleTheme,
          ),
        ],
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (widget.book == null) {
      return _buildNoBookSelected();
    }

    // Check file type
    final fileType = widget.book!.fileType.toLowerCase();
    
    if (fileType == 'pdf') {
      return PDFViewerScreen(
        filePath: widget.book!.filePath,
        onError: _handlePdfError,
      );
    } else if (fileType == 'epub') {
      // Use the new EPUB viewer
      return EpubViewerScreen(book: widget.book!);
    } else {
      // Try to open other file types with PDF viewer
      return _buildOtherFileType();
    }
  }

  Widget _buildNoBookSelected() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.menu_book, size: 100, color: Colors.grey),
          const SizedBox(height: 20),
          Text(
            'No Book Selected',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 10),
          const Text(
            'Go to Library and select a book to read',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildOtherFileType() {
    if (_pdfError) {
      return _buildFileError();
    }
    
    // Try to open with PDF viewer
    return PDFViewerScreen(
      filePath: widget.book!.filePath,
      onError: _handlePdfError,
    );
  }

  void _handlePdfError(String error) {
    setState(() {
      _pdfError = true;
      _errorMessage = error;
    });
  }

  Widget _buildFileError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, size: 100, color: Colors.red),
          const SizedBox(height: 20),
          Text(
            'File Not Compatible',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'File: ${widget.book?.title}',
            style: TextStyle(
              fontSize: 16,
              color: const Color(0xFF7F8C8D),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Type: ${widget.book?.fileType.toUpperCase()}',
            style: TextStyle(
              fontSize: 16,
              color: const Color(0xFF7F8C8D),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.symmetric(horizontal: 40),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF5F5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                const Text(
                  '⚠️ PDF Viewer Error',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _errorMessage.isNotEmpty 
                    ? _errorMessage 
                    : 'The file is not compatible with the PDF viewer.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: const Color(0xFF7F8C8D),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Supported Formats:',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                _buildFormatItem('PDF Files'),
                _buildFormatItem('EPUB Files'),
                _buildFormatItem('Some image formats'),
                _buildFormatItem('Some text files'),
              ],
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () {
              // Go back to library
              Navigator.pop(context);
            },
            icon: const Icon(Icons.arrow_back),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3498DB),
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            ),
            label: const Text(
              'Back to Library',
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: () {
              // Try again
              setState(() {
                _pdfError = false;
                _errorMessage = '';
              });
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildFormatItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, size: 16, color: Colors.green),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: const Color(0xFF7F8C8D),
            ),
          ),
        ],
      ),
    );
  }

  void _showFontSizeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Font Size'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Slider(
              value: 16,
              min: 12,
              max: 24,
              divisions: 6,
              label: '16',
              onChanged: (value) {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _toggleTheme() {
    // Implement theme toggle
  }
}