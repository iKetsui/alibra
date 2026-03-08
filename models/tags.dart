import 'dart:convert';
import 'package:e_reader/database/hive.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'book.dart';

// ========== ENUMS ==========
enum SortOption { title, dateAdded }

// ========== TAG MODEL ==========
@HiveType(typeId: 1)
class Tag {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
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

  // Convert to Map for storage (keep for backward compatibility)
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

// ========== TAGGED BOOK MODEL ==========
@HiveType(typeId: 2)
class TaggedBook extends Book {
  @HiveField(5)
  final List<String> tagIds;

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

// ========== TAG MANAGER ==========
// ========== TAG MANAGER ==========
class TagManager {
  // Save a tag
  static Future<void> saveTag(Tag tag) async {
    await HiveService.saveTag(tag);
  }

  // Load all tags
  static Future<List<Tag>> loadAllTags() async {
    return HiveService.getAllTags();
  }

  // Delete a tag
  static Future<void> deleteTag(String tagId) async {
    await HiveService.deleteTag(tagId);
  }

  // Update tag
  static Future<void> updateTag(Tag tag) async {
    await HiveService.saveTag(tag);
  }

  // Get tags for a book
  static Future<List<Tag>> getTagsForBook(String bookId) async {
    return HiveService.getBookTags(bookId);
  }

  // Add tag to book
  static Future<void> addTagToBook(String bookId, String tagId) async {
    await HiveService.addTagToBook(bookId, tagId);
  }

  // Remove tag from book
  static Future<void> removeTagFromBook(String bookId, String tagId) async {
    await HiveService.removeTagFromBook(bookId, tagId);
  }

  // Get all books with a specific tag
  static Future<List<String>> getBookIdsWithTag(String tagId) async {
    final books = HiveService.getBooksWithTag(tagId);
    return books.map((b) => b.id).toList();
  }

  // Convert List<Book> to List<TaggedBook> with tags
  static Future<List<TaggedBook>> enrichBooksWithTags(List<Book> books) async {
    return books.map((book) {
      final tagIds = HiveService.getBookTagIds(book.id);
      return TaggedBook.fromBook(book, tagIds: tagIds);
    }).toList();
  }

  // Sort books
  static List<Book> sortBooks(List<Book> books, SortOption option,
      {bool ascending = true}) {
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
  static List<Book> filterBooksByTags(
      List<Book> books, List<String> selectedTagIds) {
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
  static List<Book> filterBooksByAnyTag(
      List<Book> books, List<String> selectedTagIds) {
    if (selectedTagIds.isEmpty) return books;

    return books.where((book) {
      if (book is TaggedBook) {
        return book.tagIds.any((tagId) => selectedTagIds.contains(tagId));
      }
      return false;
    }).toList();
  }
}
