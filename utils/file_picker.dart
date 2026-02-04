import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/book.dart';

class FilePickerHelper {
  static Future<List<Book>> pickBooks() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'epub'],
        allowMultiple: true,
      );
      
      if (result == null || result.files.isEmpty) return [];
      
      final books = <Book>[];
      for (final file in result.files) {
        final fileName = file.name;
        final filePath = file.path ?? '';
        
        // Extract title from filename (remove extension)
        String title = fileName;
        if (title.contains('.')) {
          title = title.substring(0, title.lastIndexOf('.'));
        }
        
        // Get file extension
        final fileExtension = fileName.split('.').last.toLowerCase();
        
        books.add(Book(
          id: '${DateTime.now().millisecondsSinceEpoch}_${books.length}',
          title: title,
          filePath: filePath,
          fileType: fileExtension,
        ));
      }
      
      return books;
    } catch (e) {
      print('Error picking files: $e');
      return [];
    }
  }
}