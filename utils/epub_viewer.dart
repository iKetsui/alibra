import 'package:flutter/material.dart';
import 'package:flutter_epub_viewer_kit/flutter_epub_viewer_kit.dart';
import '../models/book.dart';

class SimpleEpubViewer extends StatelessWidget {
  final Book book;

  const SimpleEpubViewer({
    super.key,
    required this.book,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: EpubReaderWidget(
        source: EpubSourceFile(book.filePath),
        controller: EpubReaderController(),
        settingsStorageKey: 'epub_reader_settings',
        onError: (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${error.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        },
      ),
    );
  }
}