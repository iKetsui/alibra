import 'package:flutter/material.dart';
import '../models/book.dart';
import '../utils/tags_manager.dart';
import '../utils/deletion.dart';

// Make the state class public
class LibraryPageState extends State<LibraryPage> {
  bool _isDeleteModeActive = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;
  bool _showSearchBar = false;
  final FocusNode _searchFocusNode = FocusNode();
  
  // Tag-related variables
  List<Tag> _allTags = [];
  List<String> _selectedTagIds = [];
  SortOption _currentSortOption = SortOption.title;
  bool _sortAscending = true;
  List<TaggedBook> _taggedBooks = [];

  List<Book> get _filteredAndSortedBooks {
    // First, convert to TaggedBook for tag filtering
    List<Book> booksToProcess = _taggedBooks.isEmpty 
        ? widget.books 
        : _taggedBooks.cast<Book>();
    
    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      booksToProcess = booksToProcess.where((book) {
        final titleLower = book.title.toLowerCase();
        final queryLower = _searchQuery.toLowerCase();
        return titleLower.contains(queryLower) ||
            book.fileType.toLowerCase().contains(queryLower);
      }).toList();
    }
    
    // Apply tag filter (AND logic)
    if (_selectedTagIds.isNotEmpty) {
      booksToProcess = booksToProcess.where((book) {
        if (book is TaggedBook) {
          return _selectedTagIds.every((tagId) => book.tagIds.contains(tagId));
        }
        return false;
      }).toList();
    }
    
    // Apply sorting
    return TagManager.sortBooks(booksToProcess, _currentSortOption, ascending: _sortAscending);
  }

  @override
  void initState() {
    super.initState();
    print('📚 LibraryPage initialized with ${widget.books.length} books');
    _loadTags();
  }

  @override
  void didUpdateWidget(LibraryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    print('📚 LibraryPage updated - books: ${widget.books.length}');
    if (widget.books != oldWidget.books) {
      _loadTags();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadTags() async {
    final tags = await TagManager.loadAllTags();
    final taggedBooks = await TagManager.enrichBooksWithTags(widget.books);
    setState(() {
      _allTags = tags;
      _taggedBooks = taggedBooks.cast<TaggedBook>();
    });
  }

  void _toggleSearch() {
    setState(() {
      _showSearchBar = !_showSearchBar;
      if (!_showSearchBar) {
        _searchController.clear();
        _searchQuery = '';
        _isSearching = false;
      } else {
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

  // Public method to toggle search
  void toggleSearch() {
    _toggleSearch();
  }

  Future<void> _showAddTagDialog(Book book) async {
    final TextEditingController controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Tag'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Enter tag name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            if (_allTags.isNotEmpty) ...[
              const Text('Or select existing:'),
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _allTags.map((tag) {
                      return FilterChip(
                        label: Text(tag.name),
                        selected: false,
                        onSelected: (_) async {
                          Navigator.pop(context);
                          await TagManager.addTagToBook(book.id, tag.id);
                          _loadTags();
                          // Automatically filter by this tag
                          setState(() {
                            if (!_selectedTagIds.contains(tag.id)) {
                              _selectedTagIds.add(tag.id);
                            }
                          });
                        },
                        side: BorderSide(
                          color: Colors.grey.shade400,
                          width: 1,
                        ),
                        backgroundColor: Colors.transparent,
                        selectedColor: Colors.blue.shade50,
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                final newTag = Tag.fromName(controller.text);
                await TagManager.saveTag(newTag);
                await TagManager.addTagToBook(book.id, newTag.id);
                Navigator.pop(context);
                _loadTags();
                // Automatically filter by this new tag
                setState(() {
                  if (!_selectedTagIds.contains(newTag.id)) {
                    _selectedTagIds.add(newTag.id);
                  }
                });
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _toggleTagFilter(String tagId) {
    setState(() {
      if (_selectedTagIds.contains(tagId)) {
        _selectedTagIds.remove(tagId);
      } else {
        _selectedTagIds.add(tagId);
      }
    });
  }

  void _showTagFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Filter by Tags',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _allTags.map((tag) {
                      final isSelected = _selectedTagIds.contains(tag.id);
                      return FilterChip(
                        label: Text(tag.name),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedTagIds.add(tag.id);
                            } else {
                              _selectedTagIds.remove(tag.id);
                            }
                          });
                        },
                        side: BorderSide(
                          color: isSelected ? Colors.blue : Colors.grey.shade400,
                          width: 1.5,
                        ),
                        backgroundColor: Colors.transparent,
                        selectedColor: Colors.blue.shade50,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedTagIds.clear();
                            });
                          },
                          child: const Text('Clear All'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            this.setState(() {});
                          },
                          child: const Text('Apply'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Sort By',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ...SortOption.values.map((option) {
                final isSelected = _currentSortOption == option;
                return ListTile(
                  title: Text(option.name.toUpperCase()),
                  leading: Radio<SortOption>(
                    value: option,
                    groupValue: _currentSortOption,
                    onChanged: (value) {
                      setState(() {
                        _currentSortOption = value!;
                      });
                      Navigator.pop(context);
                    },
                  ),
                  trailing: isSelected
                      ? IconButton(
                          icon: Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward),
                          onPressed: () {
                            setState(() {
                              _sortAscending = !_sortAscending;
                            });
                            Navigator.pop(context);
                          },
                        )
                      : null,
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    print('🎨 Building LibraryPage with ${widget.books.length} books, filtered: ${_filteredAndSortedBooks.length}');

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
                                  hintText: 'Search by title or format...',
                                  border: InputBorder.none,
                                  hintStyle: TextStyle(color: Color(0xFF7F8C8D)),
                                ),
                              ),
                            ),
                            if (_isSearching)
                              IconButton(
                                icon: const Icon(Icons.clear, color: Color(0xFF7F8C8D)),
                                onPressed: _clearSearch,
                              ),
                          ],
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),

            const SizedBox(height: 8),

            // Filter bar
            if (_allTags.isNotEmpty)
              Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    // Filter button
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: const Text('Filter'),
                        selected: _selectedTagIds.isNotEmpty,
                        onSelected: (_) => _showTagFilterSheet(),
                        avatar: const Icon(Icons.filter_list, size: 16),
                        side: BorderSide(
                          color: _selectedTagIds.isNotEmpty ? Colors.blue : Colors.grey.shade400,
                          width: 1.5,
                        ),
                        backgroundColor: Colors.transparent,
                        selectedColor: Colors.blue.shade50,
                      ),
                    ),
                    // Sort button
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        label: Text(_currentSortOption.name),
                        onPressed: _showSortOptions,
                        avatar: Icon(
                          _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                          size: 16,
                        ),
                        side: BorderSide(color: Colors.grey.shade400, width: 1),
                        backgroundColor: Colors.transparent,
                      ),
                    ),
                    // Selected tags
                    ..._selectedTagIds.map((tagId) {
                      final tag = _allTags.firstWhere((t) => t.id == tagId);
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: Chip(
                          label: Text(tag.name),
                          onDeleted: () {
                            setState(() {
                              _selectedTagIds.remove(tagId);
                            });
                          },
                          side: BorderSide(color: Colors.blue, width: 1.5),
                          backgroundColor: Colors.blue.shade50,
                          labelStyle: const TextStyle(color: Colors.blue),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),

            const SizedBox(height: 8),

            // Book grid
            Expanded(
              child: _filteredAndSortedBooks.isEmpty
                  ? _buildEmptyState()
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.75,
                      ),
                      itemCount: _filteredAndSortedBooks.length,
                      itemBuilder: (context, index) {
                        final book = _filteredAndSortedBooks[index];
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
    final deletionState = context.findAncestorStateOfType<DeletionManagerState>();

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
                        : Color.fromRGBO(
                            bookColor.red, bookColor.green, bookColor.blue, 0.3),
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
                          color: Color.fromRGBO(
                              bookColor.red, bookColor.green, bookColor.blue, 0.2),
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
                          
                          // Tags row at bottom - horizontal scrollable
                          if (book is TaggedBook)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    // Existing tags
                                    ...book.tagIds.map((tagId) {
                                      final tag = _allTags.firstWhere(
                                        (t) => t.id == tagId,
                                        orElse: () => Tag.fromName(''), // Fallback empty tag
                                      );
                                      final isTagSelected = _selectedTagIds.contains(tag.id);
                                      return Container(
                                        margin: const EdgeInsets.only(right: 6),
                                        child: FilterChip(
                                          label: Text(tag.name),
                                          selected: isTagSelected,
                                          onSelected: (_) {
                                            _toggleTagFilter(tag.id);
                                          },
                                          side: BorderSide(
                                            color: isTagSelected ? Colors.blue : Colors.grey.shade400,
                                            width: 1.5,
                                          ),
                                          backgroundColor: Colors.transparent,
                                          selectedColor: Colors.blue.shade50,
                                          labelStyle: TextStyle(
                                            fontSize: 10,
                                            color: isTagSelected ? Colors.blue : Colors.black87,
                                            fontWeight: isTagSelected ? FontWeight.bold : FontWeight.normal,
                                          ),
                                          visualDensity: VisualDensity.compact,
                                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        ),
                                      );
                                    }).toList(),
                                    
                                    // Add tag button
                                    Container(
                                      margin: const EdgeInsets.only(right: 4),
                                      child: ActionChip(
                                        label: const Icon(Icons.add, size: 14),
                                        onPressed: () => _showAddTagDialog(book),
                                        side: BorderSide(color: Colors.grey.shade400, width: 1),
                                        backgroundColor: Colors.transparent,
                                        padding: const EdgeInsets.all(4),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
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
    if (widget.books.isEmpty && !_isSearching && _selectedTagIds.isEmpty) {
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
    } else if (_filteredAndSortedBooks.isEmpty) {
      // Search or filter with no results
      String message = '';
      if (_searchQuery.isNotEmpty && _selectedTagIds.isNotEmpty) {
        message = 'No books match your search and filters';
      } else if (_searchQuery.isNotEmpty) {
        message = 'No books match "$_searchQuery"';
      } else if (_selectedTagIds.isNotEmpty) {
        message = 'No books with selected tags';
      }

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
              message,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF7F8C8D),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            if (_searchQuery.isNotEmpty || _selectedTagIds.isNotEmpty)
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _searchController.clear();
                    _searchQuery = '';
                    _isSearching = false;
                    _selectedTagIds.clear();
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3498DB),
                ),
                child: const Text('Clear All Filters'),
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