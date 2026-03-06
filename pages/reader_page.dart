import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:e_reader/utils/pdfviewer.dart';
import 'package:e_reader/utils/epub_viewer.dart';
import '../utils/theme_provider.dart';
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
    final theme = Provider.of<ThemeProvider>(context).currentTheme;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.book?.title ?? 'No Book Selected'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.text),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.format_size, color: theme.text),
            onPressed: _showFontSizeDialog,
          ),
          IconButton(
            icon: Icon(Icons.brightness_6, color: theme.text),
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

    final fileType = widget.book!.fileType.toLowerCase();
    
    if (fileType == 'pdf') {
      return PDFViewerScreen(
        filePath: widget.book!.filePath,
        onError: _handlePdfError,
      );
    } else if (fileType == 'epub') {
      return SimpleEpubViewer(book: widget.book!);
    } else {
      if (_pdfError) {
        return _buildFileError();
      }
      return PDFViewerScreen(
        filePath: widget.book!.filePath,
        onError: _handlePdfError,
      );
    }
  }

  Widget _buildNoBookSelected() {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.menu_book, size: 100, color: theme.secondaryText),
          const SizedBox(height: 20),
          Text(
            'No Book Selected',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: theme.text,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Go to Library and select a book to read',
            textAlign: TextAlign.center,
            style: TextStyle(color: theme.secondaryText),
          ),
        ],
      ),
    );
  }

  void _handlePdfError(String error) {
    setState(() {
      _pdfError = true;
      _errorMessage = error;
    });
  }

  Widget _buildFileError() {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;
    
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
              color: theme.text,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'File: ${widget.book?.title}',
            style: TextStyle(
              fontSize: 16,
              color: theme.secondaryText,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Type: ${widget.book?.fileType.toUpperCase()}',
            style: TextStyle(
              fontSize: 16,
              color: theme.secondaryText,
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
                    color: theme.secondaryText,
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
              Navigator.pop(context);
            },
            icon: const Icon(Icons.arrow_back),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            ),
            label: Text(
              'Back to Library',
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: () {
              setState(() {
                _pdfError = false;
                _errorMessage = '';
              });
            },
            child: Text(
              'Try Again',
              style: TextStyle(color: theme.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormatItem(String text) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;
    
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
              color: theme.secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  void _showFontSizeDialog() {
    final theme = Provider.of<ThemeProvider>(context, listen: false).currentTheme;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Font Size', style: TextStyle(color: theme.text)),
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
              activeColor: theme.primary,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: TextStyle(color: theme.primary)),
          ),
        ],
      ),
    );
  }

  void _toggleTheme() {
    // Implement theme toggle
  }
}