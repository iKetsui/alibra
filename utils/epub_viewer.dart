import 'package:flutter/material.dart';
import 'package:flutter_epub_viewer_kit/flutter_epub_viewer_kit.dart';
import '../models/book.dart';

class EpubViewerScreen extends StatelessWidget {
  final Book book;

  const EpubViewerScreen({
    super.key,
    required this.book,
  });

  @override
  Widget build(BuildContext context) {
    print('=== EPUB DEBUG INFO ===');
    print('File path: ${book.filePath}');
    print('File name: ${book.title}');
    
    return EpubReaderWidget(
      source: EpubSourceFile(book.filePath),
      controller: EpubReaderController(),
      settingsStorageKey: 'epub_reader_settings',
      onBookLoaded: (title, author) {
        print('📖 Book metadata loaded:');
        print('  Title: $title');
        print('  Author: $author');
      },
      onError: (error) {
        print('❌ EPUB Error: $error');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load EPUB: $error')),
        );
      },
    );
  }
}