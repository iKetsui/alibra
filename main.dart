import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'models/book.dart';
import 'utils/file_handler.dart';
import 'utils/storage_helper.dart';
import 'utils/theme_provider.dart';
import 'pages/library_page.dart';
import 'pages/reader_page.dart';
import 'pages/settings_page.dart';

void main() {
  WidgetsFlutterBinding
      .ensureInitialized(); // Required for async initialization
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          final theme = themeProvider.currentTheme;

          return MaterialApp(
            title: 'E-Reader',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: theme.primary,
                brightness: Brightness.light,
              ),
              scaffoldBackgroundColor: theme.background,
              appBarTheme: AppBarTheme(
                backgroundColor: theme.appBar,
                elevation: 0,
                foregroundColor: theme.text,
              ),
              useMaterial3: true,
            ),
            home: const HomeScreen(),
          );
        },
      ),
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
  final GlobalKey<LibraryPageState> _libraryKey = GlobalKey<LibraryPageState>();

  late List<NavigationItem> _navigationItems;

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    final savedBooks = await StorageHelper.loadBooks();
    print('📚 Loaded ${savedBooks.length} books from storage');
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

  // Show add menu when FAB is pressed
  void _showAddMenu() {
    final theme =
        Provider.of<ThemeProvider>(context, listen: false).currentTheme;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Add Books',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: theme.text,
                ),
              ),
              const SizedBox(height: 20),

              // Pick files option
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.file_present,
                    color: theme.primary,
                  ),
                ),
                title: Text(
                  'Pick Files',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: theme.text,
                  ),
                ),
                subtitle: const Text('Select individual PDF/EPUB files'),
                onTap: () {
                  Navigator.pop(context);
                  _pickFiles();
                },
              ),

              const SizedBox(height: 8),

              // Pick folder option
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4ECDC4).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.folder_open,
                    color: Color(0xFF4ECDC4),
                  ),
                ),
                title: const Text(
                  'Pick Folder',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: const Text('Scan a folder for all PDF/EPUB files'),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickFolder();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Method for picking individual files with duplicate check
  Future<void> _pickFiles() async {
    final books = await FileHandler.pickBooks();
    if (books.isNotEmpty) {
      // Use FileHandler to filter duplicates (checks both path AND name)
      final newBooks = FileHandler.filterNewBooks(books, _books);

      if (newBooks.isNotEmpty) {
        setState(() {
          _books.addAll(newBooks);
        });
        await _saveBooks();

        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added ${newBooks.length} new book(s) '
                '(${books.length - newBooks.length} duplicates skipped)'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No new books added - all files are duplicates'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  // Method for picking and scanning a folder with duplicate check
  Future<void> _pickFolder() async {
    // Let user pick a folder
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

    if (selectedDirectory == null) {
      return; // User cancelled
    }

    // Show loading dialog
    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    // Scan the selected folder
    final foundBooks =
        await FileHandler.scanFolder(customPath: selectedDirectory);

    // Close loading dialog
    if (context.mounted) Navigator.pop(context);

    if (foundBooks.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No books found in selected folder'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // Get duplicate summary for better feedback
    final summary = FileHandler.getDuplicateSummary(foundBooks, _books);

    // Filter out books that already exist (by path OR name)
    final newBooks = FileHandler.filterNewBooks(foundBooks, _books);

    if (newBooks.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No new books added - '
                '${summary['pathDuplicates']} path duplicates, '
                '${summary['nameDuplicates']} name duplicates'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // Add new books
    setState(() {
      _books.addAll(newBooks);
    });

    await _saveBooks();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added ${newBooks.length} new books '
              '(${summary['pathDuplicates']} path duplicates, '
              '${summary['nameDuplicates']} name duplicates skipped)'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // Updated _addBooks method with duplicate check
  Future<void> _addBooks(List<String> filePaths) async {
    final newBooks = <Book>[];
    int duplicateCount = 0;

    for (final path in filePaths) {
      final fileName = path.split('/').last;
      final fileExtension = fileName.split('.').last.toLowerCase();

      // Check if this file already exists in library (by path OR name)
      final isDuplicate = _books.any((book) =>
          book.filePath == path ||
          book.title.toLowerCase() ==
              fileName
                  .replaceAll('.pdf', '')
                  .replaceAll('.epub', '')
                  .replaceAll('_', ' ')
                  .toLowerCase());

      if (!isDuplicate) {
        newBooks.add(Book(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          title: fileName
              .replaceAll('.pdf', '')
              .replaceAll('.epub', '')
              .replaceAll('_', ' '),
          filePath: path,
          fileType: fileExtension,
        ));
      } else {
        duplicateCount++;
        print('🚫 Skipping duplicate: $fileName');
      }
    }

    if (newBooks.isNotEmpty) {
      setState(() {
        _books.addAll(newBooks);
      });
      await _saveBooks();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added ${newBooks.length} new book(s) '
                '($duplicateCount duplicates skipped)'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No new books added - all files are duplicates'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
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
          key: _libraryKey,
          books: _books,
          onBookSelected: _openBook,
          onBooksDelete: _deleteBooks,
        );
      case 2:
        return _buildSettingsPage();
      default:
        return _buildHomePage();
    }
  }

  Widget _buildHomePage() {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;

    return Container(
      color: theme.background,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.menu_book,
              size: 64,
              color: theme.primary,
            ),
            const SizedBox(height: 20),
            Text(
              'Welcome to E-Reader',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: theme.text,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '${_books.length} books in your library',
              style: TextStyle(
                fontSize: 16,
                color: theme.secondaryText,
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
                backgroundColor: theme.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              child: Text(
                'Browse Library',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsPage() {
    return const SettingsPage();
  }

  // OPTION 4: Always show a placeholder button
  Widget? _getSearchButton() {
    final theme =
        Provider.of<ThemeProvider>(context, listen: false).currentTheme;

    if (_selectedIndex == 1) {
      return IconButton(
        icon: const Icon(Icons.search),
        onPressed: () {
          final libraryState = _libraryKey.currentState;
          if (libraryState != null) {
            libraryState.toggleSearch();
          } else {
            print('⚠️ Library state not ready yet - try again');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Search not ready, please try again'),
                duration: Duration(seconds: 1),
              ),
            );
          }
        },
        color: theme.text,
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;

    // Update navigation items with current theme
    _navigationItems = [
      NavigationItem(
        icon: Icons.home,
        label: 'Home',
        color: theme.primary.withOpacity(0.1),
        activeColor: theme.primary,
      ),
      NavigationItem(
        icon: Icons.library_books,
        label: 'Library',
        color: theme.primary.withOpacity(0.1),
        activeColor: theme.primary,
      ),
      NavigationItem(
        icon: Icons.settings,
        label: 'Settings',
        color: theme.primary.withOpacity(0.1),
        activeColor: theme.primary,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.appBar,
        elevation: 0,
        centerTitle: true,
        title: Text(
          _selectedIndex == 0
              ? 'E-Reader'
              : _selectedIndex == 1
                  ? 'Library'
                  : 'Settings',
          style: TextStyle(
            color: theme.text,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          if (_getSearchButton() != null) _getSearchButton()!,
        ],
      ),
      body: _buildCurrentPage(),
      floatingActionButton: _selectedIndex == 1
          ? FloatingActionButton(
              onPressed: _showAddMenu,
              backgroundColor: theme.primary,
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
                        color:
                            isSelected ? item.activeColor : theme.secondaryText,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected
                              ? item.activeColor
                              : theme.secondaryText,
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
