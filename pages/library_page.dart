import 'package:flutter/material.dart';
import '../models/book.dart';

class LibraryPage extends StatefulWidget {
  final List<Book> books;
  final Function(Book) onBookSelected;
  final Function(List<String>) onBooksAdded;
  final Function(List<Book>)? onBooksDelete; // Added missing parameter

  const LibraryPage({
    super.key,
    required this.books,
    required this.onBookSelected,
    required this.onBooksAdded,
    this.onBooksDelete, // Added this
  });
  
  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  // Track which books are selected for deletion
  final Set<String> _selectedBooks = {};
  bool _isDeleteMode = false;
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main content
        Column(
          children: [
            // Delete mode header (only shows when in delete mode)
            if (_isDeleteMode)
              Container(
                color: const Color.fromRGBO(240, 37, 37, 0.894),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_selectedBooks.length} selected',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      onPressed: _exitDeleteMode,
                      icon: const Icon(Icons.close, color: Colors.white),
                      tooltip: 'Exit delete mode',
                    ),
                  ],
                ),
              ),
            
            // Main content area
            Expanded(
              child: Container(
                color: _isDeleteMode ? const Color.fromRGBO(255, 0, 0, 0.05) : const Color(0xFFFFFFFF),
                padding: const EdgeInsets.all(16),
                child: widget.books.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.library_books,
                              size: 64,
                              color: const Color(0xFF3498DB),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Your Library',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF2C3E50),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'No books added yet',
                              style: TextStyle(
                                fontSize: 16,
                                color: const Color(0xFF7F8C8D),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Tap + to add books',
                              style: TextStyle(
                                fontSize: 14,
                                color: const Color(0xFF3498CD),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.75,
                        ),
                        itemCount: widget.books.length,
                        itemBuilder: (context, index) {
                          final book = widget.books[index];
                          return _buildBookCard(book);
                        },
                      ),
              ),
            ),
          ],
        ),
        
        // Delete button (no animation)
        if (_selectedBooks.isNotEmpty && _isDeleteMode)
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Container(
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  width: 245,
                  height: 45,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: InkWell(
                    onTap: _deleteSelectedBooks,
                    borderRadius: BorderRadius.circular(22),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.delete,
                          color: Colors.white,
                          size: 24,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'DELETE ${_selectedBooks.length} BOOK${_selectedBooks.length > 1 ? 'S' : ''}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
  
  Widget _buildBookCard(Book book) {
    final isSelected = _selectedBooks.contains(book.id);
    final bookColor = Color(book.colorCode);
    
    return GestureDetector(
      onLongPress: () {
        // Enter delete mode on long press
        if (!_isDeleteMode) {
          _enterDeleteMode();
        }
        // Toggle selection
        _toggleBookSelection(book.id);
      },
      onTap: () {
        if (_isDeleteMode) {
          // In delete mode - toggle selection
          _toggleBookSelection(book.id);
        } else {
          // Normal mode - open book
          widget.onBookSelected(book); // Fixed: Use onBookSelected instead of onBookTap
        }
      },
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Color.fromRGBO(bookColor.red, bookColor.green, bookColor.blue, 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? const Color.fromRGBO(216, 9, 9, 0.8) : Color.fromRGBO(bookColor.red, bookColor.green, bookColor.blue, 0.3),
                width: isSelected ? 2.5 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Book icon/cover area
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Color.fromRGBO(bookColor.red, bookColor.green, bookColor.blue, 0.2),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.book,
                            size: 48,
                            color: bookColor,
                          ),
                          const SizedBox(height: 8),
                          // FIXED: Changed from book.icon to book.fileType
                          Text(
                            book.fileType.toUpperCase(),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: bookColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Book info area
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        book.fileType.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF7F8C8D),
                        ),
                      ),
                      if (book.author.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          book.author,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF7F8C8D),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Selection checkbox (top-left)
          if (_isDeleteMode)
            Container(
              width: 24,
              height: 24,
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.red : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? Colors.red : Colors.grey,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      size: 16,
                      color: Colors.white,
                    )
                  : null,
            ),
          
          // Delete icon (top-right, only when selected)
          if (isSelected && _isDeleteMode)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  void _enterDeleteMode() {
    setState(() {
      _isDeleteMode = true;
      _selectedBooks.clear();
    });
  }
  
  void _exitDeleteMode() {
    setState(() {
      _isDeleteMode = false;
      _selectedBooks.clear();
    });
  }
  
  void _toggleBookSelection(String bookId) {
    setState(() {
      if (_selectedBooks.contains(bookId)) {
        _selectedBooks.remove(bookId);
        // Auto-exit delete mode if nothing is selected
        if (_selectedBooks.isEmpty && _isDeleteMode) {
          _exitDeleteMode();
        }
      } else {
        _selectedBooks.add(bookId);
      }
    });
  }
  
  void _deleteSelectedBooks() {
    if (_selectedBooks.isEmpty) return;
    
    final selectedBooksList = widget.books
        .where((book) => _selectedBooks.contains(book.id))
        .toList();
    
    _showDeleteConfirmation(selectedBooksList);
  }
  
  void _showDeleteConfirmation(List<Book> booksToDelete) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Books'),
        content: Text(
          booksToDelete.length == 1
              ? 'Are you sure you want to delete "${booksToDelete.first.title}"?'
              : 'Are you sure you want to delete ${booksToDelete.length} books?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (widget.onBooksDelete != null) {
                widget.onBooksDelete!(booksToDelete);
              }
              _exitDeleteMode();
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}