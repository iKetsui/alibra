import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/book.dart';

class FilePickerHelper {
  static Future<Book?> pickBook() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'epub'],
        allowMultiple: false,
      );
      
      if (result == null || result.files.isEmpty) return null;
      
      final file = result.files.first;
      final fileName = file.name;
      final filePath = file.path ?? '';
      
      // Extract title from filename (remove extension)
      String title = fileName;
      if (title.contains('.')) {
        title = title.substring(0, title.lastIndexOf('.'));
      }
      
      // Get file extension
      final fileExtension = fileName.split('.').last.toLowerCase();
      
      return Book(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        filePath: filePath,
        fileType: fileExtension,
      );
    } catch (e) {
      print('Error picking file: $e');
      return null;
    }
  }
}