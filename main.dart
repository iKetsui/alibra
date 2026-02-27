import 'package:flutter/material.dart';
import 'models/book.dart';
import 'utils/file_picker.dart';
import 'utils/storage_helper.dart';
import 'pages/library_page.dart';
import 'pages/reader_page.dart';
import 'pages/settings_page.dart'; // ← ADD THIS IMPORT

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'E-Reader',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3498DB),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFFFFFFF),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF8F9FA),
          elevation: 0,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  List<Book> _books = [];

  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      icon: Icons.home,
      label: 'Home',
      color: const Color(0xFF3498DB).withOpacity(0.1),
      activeColor: const Color(0xFF3498DB),
    ),
    NavigationItem(
      icon: Icons.library_books,
      label: 'Library',
      color: const Color(0xFF3498DB).withOpacity(0.1),
      activeColor: const Color(0xFF3498DB),
    ),
    NavigationItem(
      icon: Icons.settings,
      label: 'Settings',
      color: const Color(0xFF3498DB).withOpacity(0.1),
      activeColor: const Color(0xFF3498DB),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    final savedBooks = await StorageHelper.loadBooks();
    setState(() {
      _books = savedBooks;
    });
  }

  Future<void> _saveBooks() async {
    await StorageHelper.saveBooks(_books);
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _addBooks(List<String> filePaths) async {
    final newBooks = <Book>[];
    for (final path in filePaths) {
      final fileName = path.split('/').last;
      final fileExtension = fileName.split('.').last.toLowerCase();
      
      newBooks.add(Book(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: fileName.replaceAll('.pdf', '').replaceAll('.epub', '').replaceAll('_', ' '),
        filePath: path,
        fileType: fileExtension,
        author: 'Unknown Author',
      ));
    }

    setState(() {
      _books.addAll(newBooks);
    });
    
    await _saveBooks();
  }

  void _openBook(Book book) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReaderPage(book: book),
      ),
    );
  }

  void _deleteBooks(List<Book> booksToDelete) {
    setState(() {
      _books.removeWhere((book) => booksToDelete.contains(book));
    });
    
    _saveBooks();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          booksToDelete.length == 1
              ? 'Removed "${booksToDelete.first.title}" from library'
              : 'Removed ${booksToDelete.length} books from library',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildCurrentPage() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomePage();
      case 1:
        return LibraryPage(
          books: _books,
          onBookSelected: _openBook,
          onBooksDelete: _deleteBooks,
        );
      case 2:
        return _buildSettingsPage(); // This will now use the new SettingsPage
      default:
        return _buildHomePage();
    }
  }

  Widget _buildHomePage() {
    return Container(
      color: const Color(0xFFFFFFFF),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.menu_book,
              size: 64,
              color: const Color(0xFF3498DB),
            ),
            const SizedBox(height: 20),
            Text(
              'Welcome to E-Reader',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '${_books.length} books in your library',
              style: TextStyle(
                fontSize: 16,
                color: const Color(0xFF7F8C8D),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _selectedIndex = 1;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3498DB),
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              child: const Text(
                'Browse Library',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ← REPLACE THIS ENTIRE METHOD
  Widget _buildSettingsPage() {
    return const SettingsPage(); // Just return the new SettingsPage
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        centerTitle: true,
        title: Text(
          _selectedIndex == 0
              ? 'E-Reader'
              : _selectedIndex == 1
                  ? 'Library'
                  : 'Settings',
          style: const TextStyle(
            color: Color(0xFF2C3E50),
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      body: _buildCurrentPage(),
      floatingActionButton: _selectedIndex == 1
          ? FloatingActionButton(
              onPressed: () async {
                final files = await FilePickerHelper.pickBooks();
                if (files.isNotEmpty) {
                  _addBooks(files.map((book) => book.filePath).toList());
                }
              },
              backgroundColor: const Color(0xFF3498DB),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(
            _navigationItems.length,
            (index) {
              final item = _navigationItems[index];
              final isSelected = _selectedIndex == index;
              
              return GestureDetector(
                onTap: () => _onItemTapped(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? item.color : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.icon,
                        size: 24,
                        color: isSelected ? item.activeColor : const Color(0xFF7F8C8D),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? item.activeColor : const Color(0xFF7F8C8D),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class NavigationItem {
  final IconData icon;
  final String label;
  final Color color;
  final Color activeColor;

  NavigationItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.activeColor,
  });
}