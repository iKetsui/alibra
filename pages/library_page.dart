import 'package:flutter/material.dart';
import '../models/book.dart';
import '../utils/deletion.dart';

// Make the state class public
class LibraryPageState extends State<LibraryPage> {
  bool _isDeleteModeActive = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;
  bool _showSearchBar = false;
  final FocusNode _searchFocusNode = FocusNode();

  List<Book> get _filteredBooks {
    if (_searchQuery.isEmpty) {
      return widget.books;
    }
    return widget.books.where((book) {
      final titleLower = book.title.toLowerCase();
      final authorLower = book.author.toLowerCase();
      final queryLower = _searchQuery.toLowerCase();
      return titleLower.contains(queryLower) ||
          authorLower.contains(queryLower) ||
          book.fileType.toLowerCase().contains(queryLower);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    print('📚 LibraryPage initialized with ${widget.books.length} books');
  }

  @override
  void didUpdateWidget(LibraryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    print('📚 LibraryPage updated - books: ${widget.books.length}');
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _showSearchBar = !_showSearchBar;
      if (!_showSearchBar) {
        _searchController.clear();
        _searchQuery = '';
        _isSearching = false;
      } else {
        // Focus the search field when it appears
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _searchFocusNode.requestFocus();
        });
      }
    });
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _isSearching = false;
    });
  }

  // Public method to get the search button
  Widget getSearchButton() {
    return IconButton(
      icon: Icon(_showSearchBar ? Icons.close : Icons.search),
      onPressed: _toggleSearch,
      color: const Color(0xFF2C3E50),
    );
  }

// Add this public method to LibraryPageState class
  void toggleSearch() {
    _toggleSearch();
  }

  @override
  Widget build(BuildContext context) {
    print(
        '🎨 Building LibraryPage with ${widget.books.length} books, filtered: ${_filteredBooks.length}');

    return DeletionManager(
      books: widget.books,
      onDelete: (booksToDelete) {
        if (widget.onBooksDelete != null) {
          widget.onBooksDelete!(booksToDelete);
        }
      },
      onDeleteModeChange: (isActive) {
        setState(() {
          _isDeleteModeActive = isActive;
        });
      },
      child: Container(
        color: _isDeleteModeActive
            ? const Color.fromRGBO(255, 0, 0, 0.05)
            : const Color(0xFFFFFFFF),
        child: Column(
          children: [
            // Search Bar (expandable)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: _showSearchBar ? 70 : 0,
              curve: Curves.easeInOut,
              child: _showSearchBar
                  ? Padding(
                      padding: const EdgeInsets.all(6),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 12),
                            const Icon(Icons.search, color: Color(0xFF7F8C8D)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                focusNode: _searchFocusNode,
                                onChanged: (value) {
                                  setState(() {
                                    _searchQuery = value;
                                    _isSearching = value.isNotEmpty;
                                  });
                                },
                                decoration: const InputDecoration(
                                  hintText:
                                      'Search by title, author, or format...',
                                  border: InputBorder.none,
                                  hintStyle:
                                      TextStyle(color: Color(0xFF7F8C8D)),
                                ),
                              ),
                            ),
                            if (_isSearching)
                              IconButton(
                                icon: const Icon(Icons.clear,
                                    color: Color(0xFF7F8C8D)),
                                onPressed: _clearSearch,
                              ),
                          ],
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),

            const SizedBox(height: 8),

            // Book grid
            Expanded(
              child: _filteredBooks.isEmpty
                  ? _buildEmptyState()
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.75,
                      ),
                      itemCount: _filteredBooks.length,
                      itemBuilder: (context, index) {
                        final book = _filteredBooks[index];
                        return _buildBookCard(book, context);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookCard(Book book, BuildContext context) {
    // Find the DeletionManagerState in the widget tree
    final deletionState =
        context.findAncestorStateOfType<DeletionManagerState>();

    // Wrap with ValueListenableBuilder to rebuild when selection changes
    return ValueListenableBuilder(
      valueListenable: deletionState?.rebuildNotifier ?? ValueNotifier(0),
      builder: (context, value, child) {
        final isSelected = deletionState?.isSelected(book.id) ?? false;
        final isDeleteMode = deletionState?.isDeleteMode ?? false;
        final bookColor = Color(book.colorCode);

        return GestureDetector(
          onLongPress: () {
            deletionState?.toggleBookSelection(book.id);
          },
          onTap: () {
            if (isDeleteMode) {
              deletionState?.toggleBookSelection(book.id);
            } else {
              widget.onBookSelected(book);
            }
          },
          child: Stack(
            children: [
              // Main card content
              Container(
                decoration: BoxDecoration(
                  color: Color.fromRGBO(
                      bookColor.red, bookColor.green, bookColor.blue, 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? const Color.fromRGBO(216, 9, 9, 0.8)
                        : Color.fromRGBO(bookColor.red, bookColor.green,
                            bookColor.blue, 0.3),
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
                          color: Color.fromRGBO(bookColor.red, bookColor.green,
                              bookColor.blue, 0.2),
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
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: bookColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  book.fileType.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF7F8C8D),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (book.author.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              book.author,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
              if (isDeleteMode)
                Positioned(
                  top: 8,
                  left: 8,
                  child: GestureDetector(
                    onTap: () {
                      deletionState?.toggleBookSelection(book.id);
                    },
                    child: Container(
                      width: 24,
                      height: 24,
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
                  ),
                ),

              // Delete icon (top-right, only when selected)
              if (isSelected && isDeleteMode)
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
      },
    );
  }

  Widget _buildEmptyState() {
    if (widget.books.isEmpty && !_isSearching) {
      // No books at all
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.library_books,
              size: 80,
              color: const Color(0xFF3498DB),
            ),
            const SizedBox(height: 20),
            const Text(
              'Your Library',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'No books added yet',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF7F8C8D),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Tap + to add books',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF3498DB),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    } else if (_isSearching && _filteredBooks.isEmpty) {
      // Search with no results
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.search_off,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 20),
            const Text(
              'No matches found',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'No books match "$_searchQuery"',
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF7F8C8D),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _clearSearch,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3498DB),
              ),
              child: const Text('Clear Search'),
            ),
          ],
        ),
      );
    }

    // Should never reach here
    return const SizedBox.shrink();
  }
}

class LibraryPage extends StatefulWidget {
  final List<Book> books;
  final Function(Book) onBookSelected;
  final Function(List<Book>)? onBooksDelete;

  const LibraryPage({
    super.key,
    required this.books,
    required this.onBookSelected,
    this.onBooksDelete,
  });

  @override
  State<LibraryPage> createState() => LibraryPageState();
}
