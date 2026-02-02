import 'package:flutter/material.dart';
import 'models/book.dart';
import 'utils/file_picker.dart';
import 'pages/home_page.dart';
import 'pages/library_page.dart';
import 'pages/settings_page.dart';

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
      home: const ModernHomePage(title: 'E-Reader'),
    );
  }
}

class ModernHomePage extends StatefulWidget {
  const ModernHomePage({super.key, required this.title});
  final String title;

  @override
  State<ModernHomePage> createState() => _ModernHomePageState();
}

class _ModernHomePageState extends State<ModernHomePage> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();
  bool _showAddBookOverlay = false;
  OverlayEntry? _overlayEntry;
  List<Book> _books = [];

  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      icon: Icons.home_filled,
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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _pickAndAddBook() async {
    _toggleAddBookOverlay(); // Close the overlay first
    
    final book = await FilePickerHelper.pickBook();
    if (book != null) {
      setState(() {
        _books.add(book);
      });
    }
  }

  void _toggleAddBookOverlay() {
    if (_showAddBookOverlay) {
      _overlayEntry?.remove();
      setState(() {
        _showAddBookOverlay = false;
      });
    } else {
      setState(() {
        _showAddBookOverlay = true;
      });
      _overlayEntry = _createOverlayEntry();
      Overlay.of(context).insert(_overlayEntry!);
    }
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    var size = renderBox.size;
    var offset = renderBox.localToGlobal(Offset(size.width - 90, size.height - 200));

    return OverlayEntry(
      builder: (context) => GestureDetector(
        onTap: _toggleAddBookOverlay,
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: Stack(
              children: [
                Positioned(
                  left: offset.dx - 120,
                  top: offset.dy - 100,
                  child: Container(
                    width: 160,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFFFF),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ElevatedButton(
                          onPressed: _pickAndAddBook,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3498DB),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text(
                            'Add PDF/EPUB',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onBookTap(Book book) {
    print('Book tapped: ${book.title}');
    // Empty function for now - will be implemented later
  }

  Widget _buildFloatingActionButton() {
    if (_selectedIndex == 2) {
      return Container();
    }
    
    return FloatingActionButton(
      onPressed: _toggleAddBookOverlay,
      backgroundColor: const Color(0xFF3498DB),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: Icon(
          _showAddBookOverlay ? Icons.close : Icons.add,
          key: ValueKey(_showAddBookOverlay),
          color: Colors.white,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        centerTitle: true,
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Color(0xFF2C3E50),
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Color(0xFF2C3E50)),
          onPressed: () {},
        ),
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        physics: const BouncingScrollPhysics(),
        children: [
          const HomePage(),
          LibraryPage(
            books: _books,
            onBookTap: _onBookTap,
          ),
          const SettingsPage(),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFFFFFF),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            _navigationItems.length,
            (index) {
              final item = _navigationItems[index];
              final isSelected = _selectedIndex == index;
              
              return GestureDetector(
                onTap: () => _onItemTapped(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFF8F9FA) : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: isSelected
                        ? Border.all(color: const Color(0xFF3498DB), width: 2)
                        : null,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.icon,
                        size: 24,
                        color: isSelected ? const Color(0xFF3498DB) : const Color(0xFF7F8C8D),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? const Color(0xFF3498DB) : const Color(0xFF7F8C8D),
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