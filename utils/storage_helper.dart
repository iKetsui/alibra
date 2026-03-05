import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/book.dart';
import 'tags_manager.dart'; // Add this import

class StorageHelper {
  static const String _booksKey = 'library_books';

  // Save books with pretty JSON
  static Future<void> saveBooks(List<Book> books) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Create JSON with indentation
    final encoder = JsonEncoder.withIndent('  ');
    
    final bookList = books.map((book) {
      // If book is TaggedBook, include tags
      if (book is TaggedBook) {
        return {
          'id': book.id,
          'title': book.title,
          'path': book.filePath,
          'type': book.fileType,
          'author': book.author,
          'tagIds': book.tagIds,
        };
      } else {
        return {
          'id': book.id,
          'title': book.title,
          'path': book.filePath,
          'type': book.fileType,
          'author': book.author,
        };
      }
    }).toList();
    
    final jsonString = encoder.convert(bookList);
    await prefs.setString(_booksKey, jsonString);
  }

  // Load books (now returns TaggedBook if tags exist)
  static Future<List<Book>> loadBooks() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_booksKey);
    
    if (jsonString == null) return [];
    
    try {
      final bookList = jsonDecode(jsonString) as List;
      
      return bookList.map((item) {
        // If item has tagIds, create TaggedBook
        if (item.containsKey('tagIds')) {
          return TaggedBook(
            id: item['id'] as String,
            title: item['title'] as String,
            filePath: item['path'] as String,
            fileType: item['type'] as String,
            author: item['author'] as String? ?? 'Unknown Author',
            tagIds: List<String>.from(item['tagIds'] ?? []),
          );
        } else {
          return Book(
            id: item['id'] as String,
            title: item['title'] as String,
            filePath: item['path'] as String,
            fileType: item['type'] as String,
            author: item['author'] as String? ?? 'Unknown Author',
          );
        }
      }).toList();
    } catch (e) {
      print('Error loading books: $e');
      return [];
    }
  }
}