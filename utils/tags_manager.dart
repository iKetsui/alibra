import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/book.dart';

// SortOption enum at top level
enum SortOption { title, dateAdded }

// Tag model - WITHOUT colors
class Tag {
  final String id;
  final String name;
  final DateTime createdAt;

  Tag({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  // Create from name (auto-generates id)
  factory Tag.fromName(String name) {
    return Tag(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      createdAt: DateTime.now(),
    );
  }

  // Convert to Map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Create from Map
  static Tag fromMap(Map<String, dynamic> map) {
    return Tag(
      id: map['id'],
      name: map['name'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}

// Extended Book class with tags (for use in UI)
class TaggedBook extends Book {
  final List<String> tagIds; // Store tag IDs

  TaggedBook({
    required super.id,
    required super.title,
    required super.filePath,
    required super.fileType,
    super.colorCode,
    this.tagIds = const [],
  });

  // Convert to Map for storage
  Map<String, dynamic> toFullMap() {
    return {
      ...super.toMap(),
      'tagIds': tagIds,
    };
  }

  // Create from Map
  static TaggedBook fromFullMap(Map<String, dynamic> map) {
    return TaggedBook(
      id: map['id'],
      title: map['title'],
      filePath: map['filePath'],
      fileType: map['fileType'],
      colorCode: map['colorCode'],
      tagIds: List<String>.from(map['tagIds'] ?? []),
    );
  }

  // Convert regular Book to TaggedBook
  static TaggedBook fromBook(Book book, {List<String> tagIds = const []}) {
    return TaggedBook(
      id: book.id,
      title: book.title,
      filePath: book.filePath,
      fileType: book.fileType,
      colorCode: book.colorCode,
      tagIds: tagIds,
    );
  }
}

// Main Tag Manager
class TagManager {
  static const String _tagsKey = 'app_tags';
  static const String _bookTagsKey = 'book_tags';

  // Save a tag
  static Future<void> saveTag(Tag tag) async {
    final prefs = await SharedPreferences.getInstance();
    final tags = await loadAllTags();
    
    // Check if tag with same name exists
    final existingIndex = tags.indexWhere((t) => t.name.toLowerCase() == tag.name.toLowerCase());
    if (existingIndex >= 0) {
      tags[existingIndex] = tag; // Replace
    } else {
      tags.add(tag);
    }
    
    final tagsJson = tags.map((t) => t.toMap()).toList();
    await prefs.setString(_tagsKey, jsonEncode(tagsJson));
  }

  // Load all tags
  static Future<List<Tag>> loadAllTags() async {
    final prefs = await SharedPreferences.getInstance();
    final tagsJson = prefs.getString(_tagsKey);
    
    if (tagsJson == null) return [];
    
    try {
      final List<dynamic> decoded = jsonDecode(tagsJson);
      return decoded.map((item) => Tag.fromMap(item)).toList();
    } catch (e) {
      print('Error loading tags: $e');
      return [];
    }
  }

  // Delete a tag
  static Future<void> deleteTag(String tagId) async {
    final prefs = await SharedPreferences.getInstance();
    final tags = await loadAllTags();
    tags.removeWhere((tag) => tag.id == tagId);
    
    // Also remove this tag from all books
    final bookTags = await _loadAllBookTags();
    bookTags.removeWhere((bookId, tagIds) {
      tagIds.remove(tagId);
      return tagIds.isEmpty;
    });
    await _saveAllBookTags(bookTags);
    
    final tagsJson = tags.map((t) => t.toMap()).toList();
    await prefs.setString(_tagsKey, jsonEncode(tagsJson));
  }

  // Update tag
  static Future<void> updateTag(Tag tag) async {
    await saveTag(tag);
  }

  // Get tags for a book
  static Future<List<Tag>> getTagsForBook(String bookId) async {
    final allTags = await loadAllTags();
    final bookTags = await _loadAllBookTags();
    final tagIds = bookTags[bookId] ?? [];
    
    return allTags.where((tag) => tagIds.contains(tag.id)).toList();
  }

  // Add tag to book
  static Future<void> addTagToBook(String bookId, String tagId) async {
    final bookTags = await _loadAllBookTags();
    
    if (!bookTags.containsKey(bookId)) {
      bookTags[bookId] = [];
    }
    
    if (!bookTags[bookId]!.contains(tagId)) {
      bookTags[bookId]!.add(tagId);
      await _saveAllBookTags(bookTags);
    }
  }

  // Remove tag from book
  static Future<void> removeTagFromBook(String bookId, String tagId) async {
    final bookTags = await _loadAllBookTags();
    
    if (bookTags.containsKey(bookId)) {
      bookTags[bookId]!.remove(tagId);
      if (bookTags[bookId]!.isEmpty) {
        bookTags.remove(bookId);
      }
      await _saveAllBookTags(bookTags);
    }
  }

  // Get all books with a specific tag
  static Future<List<String>> getBookIdsWithTag(String tagId) async {
    final bookTags = await _loadAllBookTags();
    final bookIds = <String>[];
    
    bookTags.forEach((bookId, tags) {
      if (tags.contains(tagId)) {
        bookIds.add(bookId);
      }
    });
    
    return bookIds;
  }

  // Convert List<Book> to List<TaggedBook> with tags
  static Future<List<TaggedBook>> enrichBooksWithTags(List<Book> books) async {
    final bookTags = await _loadAllBookTags();
    
    return books.map((book) {
      final tagIds = bookTags[book.id] ?? [];
      return TaggedBook.fromBook(book, tagIds: tagIds);
    }).toList();
  }

  // Private: Load all book-tag associations
  static Future<Map<String, List<String>>> _loadAllBookTags() async {
    final prefs = await SharedPreferences.getInstance();
    final bookTagsJson = prefs.getString(_bookTagsKey);
    
    if (bookTagsJson == null) return {};
    
    try {
      final Map<String, dynamic> decoded = jsonDecode(bookTagsJson);
      final result = <String, List<String>>{};
      
      decoded.forEach((key, value) {
        result[key] = List<String>.from(value);
      });
      
      return result;
    } catch (e) {
      print('Error loading book tags: $e');
      return {};
    }
  }

  // Private: Save all book-tag associations
  static Future<void> _saveAllBookTags(Map<String, List<String>> bookTags) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_bookTagsKey, jsonEncode(bookTags));
  }

  // Sort books
  static List<Book> sortBooks(List<Book> books, SortOption option, {bool ascending = true}) {
    final sorted = List<Book>.from(books);
    
    switch (option) {
      case SortOption.title:
        sorted.sort((a, b) => a.title.compareTo(b.title));
        break;
      case SortOption.dateAdded:
        // Assuming id contains timestamp (milliseconds)
        sorted.sort((a, b) {
          final aTime = int.tryParse(a.id.split('_').first) ?? 0;
          final bTime = int.tryParse(b.id.split('_').first) ?? 0;
          return aTime.compareTo(bTime);
        });
        break;
    }
    
    return ascending ? sorted : sorted.reversed.toList();
  }

  // Filter books by tags (AND logic - book must have all selected tags)
  static List<Book> filterBooksByTags(List<Book> books, List<String> selectedTagIds) {
    if (selectedTagIds.isEmpty) return books;
    
    return books.where((book) {
      // If book is TaggedBook, use its tagIds
      if (book is TaggedBook) {
        return selectedTagIds.every((tagId) => book.tagIds.contains(tagId));
      }
      return false;
    }).toList();
  }

  // Filter books by tags (OR logic - book can have any of the selected tags)
  static List<Book> filterBooksByAnyTag(List<Book> books, List<String> selectedTagIds) {
    if (selectedTagIds.isEmpty) return books;
    
    return books.where((book) {
      if (book is TaggedBook) {
        return book.tagIds.any((tagId) => selectedTagIds.contains(tagId));
      }
      return false;
    }).toList();
  }
}