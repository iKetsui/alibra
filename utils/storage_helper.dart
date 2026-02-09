import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/book.dart';

class StorageHelper {
  static const String _booksKey = 'library_books';

  // Save books with pretty JSON
  static Future<void> saveBooks(List<Book> books) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Create JSON with indentation
    final encoder = JsonEncoder.withIndent('  '); // 2 spaces indentation
    
    final bookList = books.map((book) {
      return {
        'id': book.id,
        'title': book.title,
        'path': book.filePath,
        'type': book.fileType,
        'author': book.author,
      };
    }).toList();
    
    final jsonString = encoder.convert(bookList);
    await prefs.setString(_booksKey, jsonString);
  }

  // Load books
  static Future<List<Book>> loadBooks() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_booksKey);
    
    if (jsonString == null) return [];
    
    try {
      final bookList = jsonDecode(jsonString) as List;
      
      return bookList.map((item) {
        return Book(
          id: item['id'] as String,
          title: item['title'] as String,
          filePath: item['path'] as String,
          fileType: item['type'] as String,
          author: item['author'] as String? ?? 'Unknown Author',
        );
      }).toList();
    } catch (e) {
      print('Error loading books: $e');
      return [];
    }
  }
}