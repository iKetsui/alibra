import 'dart:io';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/book.dart';
import '../models/tags.dart';

class HiveService {
  // Box names
  static const String booksBoxName = 'alibra_books';
  static const String tagsBoxName = 'alibra_tags';
  static const String settingsBoxName = 'alibra_settings';
  static const String bookTagsBoxName = 'alibra_book_tags';

  // Key for storing custom path in settings box
  static const String _customPathKey = 'hive_custom_path';

  // Singleton instance
  static final HiveService _instance = HiveService._internal();
  factory HiveService() => _instance;
  HiveService._internal();

  static bool _isInitialized = false;
  static String? _currentPath;

  // Get platform-specific database path
  static Future<String> _getDatabasePath() async {
    // Check if we have a saved custom path in Hive settings
    if (_isInitialized) {
      final savedPath = settingsBox.get(_customPathKey);
      if (savedPath != null && await Directory(savedPath).exists()) {
        return savedPath;
      }
    }

    // Platform-specific default paths
    if (Platform.isAndroid) {
      // Android: Use app documents directory
      final appDir = await getApplicationDocumentsDirectory();
      return path.join(appDir.path, 'alibra_data');
    } else if (Platform.isLinux) {
      // Linux: Use ~/.local/share/alibra (standard for Linux apps)
      final homeDir = Platform.environment['HOME'] ?? '/home/user';
      return path.join(homeDir, '.local', 'share', 'alibra');
    } else {
      // Fallback
      final appDir = await getApplicationDocumentsDirectory();
      return path.join(appDir.path, 'alibra');
    }
  }

  // Initialize Hive with platform-appropriate path
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _currentPath = await _getDatabasePath();

      // Create directory if it doesn't exist
      final directory = Directory(_currentPath!);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
        print('📁 Created database directory: $_currentPath');
      }

      // Initialize Hive with the path
      Hive.init(_currentPath);

      // Open boxes
      await Future.wait([
        Hive.openBox(booksBoxName),
        Hive.openBox(tagsBoxName),
        Hive.openBox(settingsBoxName),
        Hive.openBox(bookTagsBoxName),
      ]);

      _isInitialized = true;
      print('✅ Hive initialized at: $_currentPath');

      // Verify files were created
      _listHiveFiles();
    } catch (e) {
      print('❌ Hive initialization failed: $e');
      rethrow;
    }
  }

  // Optional: Allow user to set custom path
  static Future<bool> setCustomPath(String customPath) async {
    try {
      // Create directory
      final directory = Directory(customPath);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      // Save to Hive settings box
      await settingsBox.put(_customPathKey, customPath);

      // Reinitialize with new path
      await _reinitializeWithPath(customPath);

      return true;
    } catch (e) {
      print('❌ Failed to set custom path: $e');
      return false;
    }
  }

  // Reset to default platform path
  static Future<void> resetToDefaultPath() async {
    await settingsBox.delete(_customPathKey);
    await _reinitializeWithPath(await _getDatabasePath());
  }

  // Reinitialize with new path
  static Future<void> _reinitializeWithPath(String newPath) async {
    // Close current connection
    await close();

    // Update path
    _currentPath = newPath;

    // Initialize Hive with new path
    Hive.init(_currentPath!);

    // Open boxes
    await Future.wait([
      Hive.openBox(booksBoxName),
      Hive.openBox(tagsBoxName),
      Hive.openBox(settingsBoxName),
      Hive.openBox(bookTagsBoxName),
    ]);

    print('✅ Hive reinitialized at: $_currentPath');
  }

  // Box getters
  static Box get booksBox => Hive.box(booksBoxName);
  static Box get tagsBox => Hive.box(tagsBoxName);
  static Box get settingsBox => Hive.box(settingsBoxName);
  static Box get bookTagsBox => Hive.box(bookTagsBoxName);

  // Get current database path
  static String? get currentPath => _currentPath;

  // List all Hive files (for debugging)
  static void _listHiveFiles() {
    if (_currentPath == null) return;

    final dir = Directory(_currentPath!);
    if (!dir.existsSync()) return;

    print('\n📁 Hive files in $_currentPath:');
    final files = dir.listSync();
    for (var file in files) {
      if (file.path.endsWith('.hive')) {
        final stat = file.statSync();
        final sizeKB = (stat.size / 1024).toStringAsFixed(2);
        print('  📄 ${file.path.split('/').last} (${sizeKB} KB)');
      }
    }
    print('');
  }

  // ========== BOOK OPERATIONS ==========

  static Future<void> saveBook(Book book) async {
    await booksBox.put(book.id, book.toMap());
  }

  static Future<void> saveBooks(List<Book> books) async {
    final Map<String, Map<String, dynamic>> bookMap = {};
    for (var book in books) {
      bookMap[book.id] = book.toMap();
    }
    await booksBox.putAll(bookMap);
  }

  static List<Book> getAllBooks() {
    final books = <Book>[];
    for (var key in booksBox.keys) {
      final value = booksBox.get(key);
      if (value != null) {
        books.add(Book.fromMap(Map<String, dynamic>.from(value)));
      }
    }
    return books;
  }

  static Book? getBook(String id) {
    final value = booksBox.get(id);
    if (value != null) {
      return Book.fromMap(Map<String, dynamic>.from(value));
    }
    return null;
  }

  static Future<void> deleteBook(String id) async {
    await bookTagsBox.delete(id);
    await booksBox.delete(id);
  }

  static Future<void> deleteBooks(List<String> ids) async {
    await bookTagsBox.deleteAll(ids);
    await booksBox.deleteAll(ids);
  }

  static Future<void> clearAllBooks() async {
    await bookTagsBox.clear();
    await booksBox.clear();
  }

  static int get booksCount => booksBox.length;

  // ========== TAG OPERATIONS ==========

  static Future<void> saveTag(Tag tag) async {
    await tagsBox.put(tag.id, tag.toMap());
  }

  static Future<void> saveTags(List<Tag> tags) async {
    final Map<String, Map<String, dynamic>> tagMap = {};
    for (var tag in tags) {
      tagMap[tag.id] = tag.toMap();
    }
    await tagsBox.putAll(tagMap);
  }

  static List<Tag> getAllTags() {
    final tags = <Tag>[];
    for (var key in tagsBox.keys) {
      final value = tagsBox.get(key);
      if (value != null) {
        tags.add(Tag.fromMap(Map<String, dynamic>.from(value)));
      }
    }
    return tags;
  }

  static Tag? getTag(String id) {
    final value = tagsBox.get(id);
    if (value != null) {
      return Tag.fromMap(Map<String, dynamic>.from(value));
    }
    return null;
  }

  // In HiveService class - this should already exist
  static Future<void> deleteTag(String id) async {
    // Remove this tag from all books first
    final allBookTags = bookTagsBox.toMap();
    for (var entry in allBookTags.entries) {
      final tags = List<String>.from(entry.value);
      if (tags.contains(id)) {
        tags.remove(id);
        if (tags.isEmpty) {
          await bookTagsBox.delete(entry.key);
        } else {
          await bookTagsBox.put(entry.key, tags);
        }
      }
    }
    await tagsBox.delete(id);
  }

  static Future<void> clearAllTags() async {
    await bookTagsBox.clear();
    await tagsBox.clear();
  }

  static int get tagsCount => tagsBox.length;

  // ========== BOOK-TAG RELATIONSHIPS ==========

  static Future<void> addTagToBook(String bookId, String tagId) async {
    if (!booksBox.containsKey(bookId) || !tagsBox.containsKey(tagId)) return;

    List<String> currentTags =
        bookTagsBox.get(bookId, defaultValue: [])?.cast<String>() ?? [];
    if (!currentTags.contains(tagId)) {
      currentTags.add(tagId);
      await bookTagsBox.put(bookId, currentTags);
    }
  }

  static Future<void> removeTagFromBook(String bookId, String tagId) async {
    List<String> currentTags =
        bookTagsBox.get(bookId, defaultValue: [])?.cast<String>() ?? [];
    if (currentTags.contains(tagId)) {
      currentTags.remove(tagId);
      if (currentTags.isEmpty) {
        await bookTagsBox.delete(bookId);
      } else {
        await bookTagsBox.put(bookId, currentTags);
      }
    }
  }

  static List<String> getBookTagIds(String bookId) {
    final tags = bookTagsBox.get(bookId, defaultValue: []);
    if (tags != null) {
      return List<String>.from(tags);
    }
    return [];
  }

  static List<Tag> getBookTags(String bookId) {
    final tagIds = getBookTagIds(bookId);
    return tagIds.map((id) => getTag(id)).whereType<Tag>().toList();
  }

  static List<Book> getBooksWithTag(String tagId) {
    final bookIds = <String>[];
    final allBookTags = bookTagsBox.toMap();
    for (var entry in allBookTags.entries) {
      final tags = List<String>.from(entry.value);
      if (tags.contains(tagId)) {
        bookIds.add(entry.key);
      }
    }
    return bookIds.map((id) => getBook(id)).whereType<Book>().toList();
  }

  static TaggedBook getTaggedBook(String bookId) {
    final book = getBook(bookId);
    if (book == null) throw Exception('Book not found');
    final tagIds = getBookTagIds(bookId);
    return TaggedBook.fromBook(book, tagIds: tagIds);
  }

  static List<TaggedBook> getAllTaggedBooks() {
    return getAllBooks().map((book) {
      final tagIds = getBookTagIds(book.id);
      return TaggedBook.fromBook(book, tagIds: tagIds);
    }).toList();
  }

  // ========== SETTINGS OPERATIONS ==========

  static Future<void> saveSetting(String key, dynamic value) async {
    await settingsBox.put(key, value);
  }

  static dynamic getSetting(String key, {dynamic defaultValue}) {
    return settingsBox.get(key, defaultValue: defaultValue);
  }

  static Future<void> deleteSetting(String key) async {
    await settingsBox.delete(key);
  }

  static Map<dynamic, dynamic> getAllSettings() {
    return settingsBox.toMap();
  }

  // ========== SEARCH ==========

  static List<Book> searchBooks(String query) {
    if (query.isEmpty) return getAllBooks();
    final lowerQuery = query.toLowerCase();
    return getAllBooks().where((book) {
      return book.title.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  // ========== UTILITY ==========

  static Future<void> close() async {
    await Hive.close();
  }

  static void printAllData() {
    print('\n========== HIVE DATABASE CONTENTS ==========');
    print('\n📚 BOOKS (${booksBox.length}):');
    for (var key in booksBox.keys) {
      final value = booksBox.get(key);
      print('  - $key: ${value?['title']}');
    }
    print('\n🏷️ TAGS (${tagsBox.length}):');
    for (var key in tagsBox.keys) {
      final value = tagsBox.get(key);
      print('  - $key: ${value?['name']}');
    }
    print('\n🔗 RELATIONSHIPS (${bookTagsBox.length}):');
    for (var key in bookTagsBox.keys) {
      final value = bookTagsBox.get(key);
      print('  - $key: $value');
    }
    print('\n⚙️ SETTINGS (${settingsBox.length}):');
    for (var key in settingsBox.keys) {
      final value = settingsBox.get(key);
      print('  - $key: $value');
    }
    print('============================================\n');
  }

  // Migration helper
  static Future<void> migrateFromSharedPrefs(
    List<Book> books,
    List<Tag> tags,
    Map<String, List<String>> bookTags,
  ) async {
    await clearAllBooks();
    await clearAllTags();
    await saveBooks(books);
    await saveTags(tags);

    for (var entry in bookTags.entries) {
      if (booksBox.containsKey(entry.key)) {
        await bookTagsBox.put(entry.key, entry.value);
      }
    }
    print('✅ Migration complete!');
    printAllData();
  }

  // Add to HiveService class
  static void debugBook(String bookId) {
    print('\n=== DEBUG BOOK: $bookId ===');

    // Check if book exists in books box
    final bookData = booksBox.get(bookId);
    print('📚 In booksBox: ${bookData != null ? 'YES' : 'NO'}');
    if (bookData != null) {
      print('   Data: $bookData');
    }

    // Check if book has tags
    final tags = bookTagsBox.get(bookId);
    print('🔗 In bookTagsBox: ${tags != null ? 'YES' : 'NO'}');
    if (tags != null) {
      print('   Tags: $tags');
    }

    // List all book keys
    print('📋 All book keys: ${booksBox.keys.toList()}');
    print('================================\n');
  }
}
