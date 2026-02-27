import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/book.dart';

class FileHandler {
  // MARK: - Single/Multiple File Picking
  static Future<List<Book>> pickBooks() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'epub'],
        allowMultiple: true,
      );
      
      if (result == null || result.files.isEmpty) return [];
      
      return _processFileResults(result.files);
    } catch (e) {
      print('❌ Error picking files: $e');
      return [];
    }
  }

  // MARK: - Folder Scanning (Recursive)
  static Future<List<Book>> scanFolder({String? customPath}) async {
    if (customPath == null || customPath.isEmpty) {
      print('❌ No folder path provided');
      return [];
    }
    
    final books = <Book>[];
    final directory = Directory(customPath);
    
    print('🔍 Scanning folder: $customPath');
    
    if (!await directory.exists()) {
      print('❌ Folder does not exist: $customPath');
      return books;
    }
    
    try {
      await for (final entity in directory.list(recursive: true)) {
        if (entity is File) {
          final file = entity;
          final fileName = file.path.split('/').last;
          
          // Check if file is PDF or EPUB
          if (_isSupportedFile(fileName)) {
            final book = _createBookFromFile(file.path, fileName);
            books.add(book);
            print('📚 Found: $fileName');
          }
        }
      }
    } catch (e) {
      print('❌ Error scanning folder: $e');
    }
    
    print('✅ Found ${books.length} books in folder');
    return books;
  }

  // MARK: - Pick Single File
  static Future<Book?> pickSingleFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'epub'],
        allowMultiple: false,
      );
      
      if (result == null || result.files.isEmpty) return null;
      
      final books = _processFileResults(result.files);
      return books.isNotEmpty ? books.first : null;
    } catch (e) {
      print('❌ Error picking file: $e');
      return null;
    }
  }

  // MARK: - Private Helpers
  static List<Book> _processFileResults(List<PlatformFile> files) {
    final books = <Book>[];
    for (final file in files) {
      final fileName = file.name;
      final filePath = file.path ?? '';
      
      if (filePath.isEmpty) continue;
      
      final book = _createBookFromFile(filePath, fileName);
      books.add(book);
    }
    return books;
  }

  static Book _createBookFromFile(String filePath, String fileName) {
    // Extract title from filename (remove extension)
    String title = fileName;
    if (title.contains('.')) {
      title = title.substring(0, title.lastIndexOf('.'));
    }
    
    // Clean up title (replace underscores and dashes with spaces)
    title = title.replaceAll('_', ' ').replaceAll('-', ' ');
    
    // Get file extension
    final fileExtension = fileName.split('.').last.toLowerCase();
    
    return Book(
      id: '${DateTime.now().millisecondsSinceEpoch}_${fileName.hashCode}',
      title: title,
      filePath: filePath,
      fileType: fileExtension,
      author: 'Unknown Author',
    );
  }

  static bool _isSupportedFile(String fileName) {
    final lowerName = fileName.toLowerCase();
    return lowerName.endsWith('.pdf') || lowerName.endsWith('.epub');
  }

  // MARK: - File Information
  static Future<FileStat?> getFileInfo(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return file.statSync();
      }
    } catch (e) {
      print('❌ Error getting file info: $e');
    }
    return null;
  }

  static Future<bool> fileExists(String filePath) async {
    try {
      return await File(filePath).exists();
    } catch (e) {
      print('❌ Error checking file existence: $e');
      return false;
    }
  }

  static String getFileName(String filePath) {
    return filePath.split('/').last;
  }

  static String getFileExtension(String filePath) {
    final fileName = getFileName(filePath);
    return fileName.contains('.') 
        ? fileName.split('.').last.toLowerCase() 
        : '';
  }

  static int getFileSize(String filePath) {
    try {
      final file = File(filePath);
      if (file.existsSync()) {
        return file.lengthSync();
      }
    } catch (e) {
      print('❌ Error getting file size: $e');
    }
    return 0;
  }
  // MARK: - Strict Duplicate Prevention
  static List<Book> filterNewBooks(List<Book> foundBooks, List<Book> existingBooks) {
    return foundBooks.where((book) {
      // Check if file with SAME PATH exists
      final pathExists = existingBooks.any((existing) => existing.filePath == book.filePath);
      if (pathExists) {
        print('🚫 Duplicate by path: ${book.filePath}');
        return false;
      }
      
      // Check if file with SAME NAME exists (case insensitive)
      final newFileName = getFileName(book.filePath).toLowerCase();
      final nameExists = existingBooks.any((existing) {
        final existingFileName = getFileName(existing.filePath).toLowerCase();
        return existingFileName == newFileName;
      });
      
      if (nameExists) {
        print('🚫 Duplicate by name: ${getFileName(book.filePath)}');
        return false;
      }
      
      // If neither path nor name matches, it's a new book
      return true;
    }).toList();
  }

  // MARK: - Get Duplicate Summary
  static Map<String, dynamic> getDuplicateSummary(List<Book> foundBooks, List<Book> existingBooks) {
    int pathDuplicates = 0;
    int nameDuplicates = 0;
    int newBooks = 0;
    
    for (final book in foundBooks) {
      final fileName = getFileName(book.filePath);
      final fileNameLower = fileName.toLowerCase();
      
      // Check path
      final pathExists = existingBooks.any((existing) => existing.filePath == book.filePath);
      if (pathExists) {
        pathDuplicates++;
        continue;
      }
      
      // Check name
      final nameExists = existingBooks.any((existing) {
        return getFileName(existing.filePath).toLowerCase() == fileNameLower;
      });
      
      if (nameExists) {
        nameDuplicates++;
      } else {
        newBooks++;
      }
    }
    
    return {
      'pathDuplicates': pathDuplicates,
      'nameDuplicates': nameDuplicates,
      'newBooks': newBooks,
      'total': foundBooks.length,
    };
  }

  // MARK: - Check Single File for Duplicates
  static Future<bool> isDuplicate(String filePath, List<Book> existingBooks) async {
    final fileName = getFileName(filePath).toLowerCase();
    
    // Check by path
    final pathExists = existingBooks.any((book) => book.filePath == filePath);
    if (pathExists) return true;
    
    // Check by name
    final nameExists = existingBooks.any((book) {
      return getFileName(book.filePath).toLowerCase() == fileName;
    });
    
    return nameExists;
  }

  // MARK: - Get Duplicate Details
  static Map<String, dynamic> getDuplicateDetails(String filePath, List<Book> existingBooks) {
    final fileName = getFileName(filePath);
    final fileNameLower = fileName.toLowerCase();
    
    // Check by path
    Book? pathMatch;
    try {
      pathMatch = existingBooks.firstWhere((book) => book.filePath == filePath);
    } catch (e) {
      pathMatch = null;
    }
    
    // Check by name
    Book? nameMatch;
    try {
      nameMatch = existingBooks.firstWhere(
        (book) => getFileName(book.filePath).toLowerCase() == fileNameLower,
      );
    } catch (e) {
      nameMatch = null;
    }
    
    return {
      'isDuplicate': pathMatch != null || nameMatch != null,
      'pathDuplicate': pathMatch,
      'nameDuplicate': nameMatch,
      'duplicateType': pathMatch != null ? 'path' : (nameMatch != null ? 'name' : 'none'),
    };
  }

  // MARK: - Filter Books with Custom Rules
  static List<Book> filterBooks(
    List<Book> books, {
    bool Function(Book)? predicate,
  }) {
    if (predicate == null) return books;
    return books.where(predicate).toList();
  }

  // MARK: - Batch Operations
  static Future<List<Book>> scanMultipleFolders(List<String> folderPaths) async {
    final allBooks = <Book>[];
    for (final path in folderPaths) {
      final books = await scanFolder(customPath: path);
      allBooks.addAll(books);
    }
    return allBooks;
  }

  // MARK: - Validate Files
  static Future<List<Book>> validateAndFilterBooks(List<Book> books) async {
    final validBooks = <Book>[];
    for (final book in books) {
      if (await fileExists(book.filePath)) {
        validBooks.add(book);
      } else {
        print('⚠️ File missing: ${book.filePath}');
      }
    }
    return validBooks;
  }

  // MARK: - Get Folder Contents Summary
  static Future<Map<String, dynamic>> getFolderSummary(String folderPath) async {
    int pdfCount = 0;
    int epubCount = 0;
    int totalFiles = 0;
    
    final directory = Directory(folderPath);
    if (!await directory.exists()) {
      return {'error': 'Folder does not exist'};
    }
    
    try {
      await for (final entity in directory.list(recursive: true)) {
        if (entity is File) {
          totalFiles++;
          final fileName = entity.path.split('/').last.toLowerCase();
          if (fileName.endsWith('.pdf')) {
            pdfCount++;
          } else if (fileName.endsWith('.epub')) {
            epubCount++;
          }
        }
      }
    } catch (e) {
      print('❌ Error scanning folder: $e');
    }
    
    return {
      'totalFiles': totalFiles,
      'pdfCount': pdfCount,
      'epubCount': epubCount,
      'supportedCount': pdfCount + epubCount,
    };
  }
}