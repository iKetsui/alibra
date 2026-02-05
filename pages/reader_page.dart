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

    return PDFViewerScreen(filePath: widget.book!.filePath);
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