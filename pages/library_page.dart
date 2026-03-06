import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/book.dart';
import '../utils/tags_manager.dart';
import '../utils/deletion.dart';
import '../utils/theme_provider.dart';

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
    final theme = Provider.of<ThemeProvider>(context, listen: false).currentTheme;
    
    return IconButton(
      icon: Icon(_showSearchBar ? Icons.close : Icons.search),
      onPressed: _toggleSearch,
      color: theme.text,
    );
  }

  // Public method to toggle search
  void toggleSearch() {
    _toggleSearch();
  }

  Future<void> _showAddTagDialog(Book book) async {
    final TextEditingController controller = TextEditingController();
    final theme = Provider.of<ThemeProvider>(context, listen: false).currentTheme;
    
    // Get current tags for this book - refresh every time dialog opens
    await _loadTags(); // Ensure tags are up to date
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Get fresh copy of current book tags
            final currentBook = _taggedBooks.firstWhere(
              (b) => b.id == book.id,
              orElse: () => TaggedBook.fromBook(book),
            );
            final currentBookTags = currentBook.tagIds;
            
            return AlertDialog(
              title: Text('Manage Tags', style: TextStyle(color: theme.text)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Create new tag field
                  TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: 'Enter new tag name',
                      border: const OutlineInputBorder(),
                      suffixIcon: Icon(Icons.add, color: theme.primary),
                    ),
                    onSubmitted: (value) async {
                      if (value.isNotEmpty) {
                        final newTag = Tag.fromName(value);
                        await TagManager.saveTag(newTag);
                        await TagManager.addTagToBook(book.id, newTag.id);
                        await _loadTags(); // Reload all tags
                        setDialogState(() {}); // Update dialog UI
                        controller.clear();
                      }
                    },
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Existing tags section
                  if (_allTags.isNotEmpty) ...[
                    const Text(
                      'Tap to toggle tags:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: SingleChildScrollView(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _allTags.map((tag) {
                            final isTagActive = currentBookTags.contains(tag.id);
                            
                            return FilterChip(
                              label: Text(
                                tag.name,
                                style: TextStyle(
                                  fontWeight: isTagActive ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              selected: isTagActive,
                              onSelected: (selected) async {
                                if (selected) {
                                  await TagManager.addTagToBook(book.id, tag.id);
                                } else {
                                  await TagManager.removeTagFromBook(book.id, tag.id);
                                }
                                await _loadTags(); // Reload all tags
                                setDialogState(() {}); // Update dialog UI
                              },
                              side: BorderSide(
                                color: isTagActive ? theme.primary : Colors.grey.shade400,
                                width: 1.5,
                              ),
                              backgroundColor: isTagActive ? theme.primary.withOpacity(0.1) : Colors.grey.shade100,
                              selectedColor: Colors.transparent,
                              showCheckmark: false,
                              shape: const StadiumBorder(),
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
                  child: Text('Done', style: TextStyle(color: theme.primary)),
                ),
              ],
            );
          },
        );
      },
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
    final theme = Provider.of<ThemeProvider>(context, listen: false).currentTheme;
    
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
                  Text(
                    'Filter by Tags',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: theme.text,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _allTags.map((tag) {
                      final isSelected = _selectedTagIds.contains(tag.id);
                      return FilterChip(
                        label: Text(
                          tag.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
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
                          color: isSelected ? theme.primary : Colors.grey.shade400,
                          width: 1.5,
                        ),
                        backgroundColor: Colors.transparent,
                        selectedColor: theme.primary.withOpacity(0.1),
                        showCheckmark: false,
                        shape: const StadiumBorder(),
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
                          child: Text('Clear All', style: TextStyle(color: theme.primary)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            this.setState(() {});
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.primary,
                          ),
                          child: const Text('Apply', style: TextStyle(color: Colors.white)),
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
    final theme = Provider.of<ThemeProvider>(context, listen: false).currentTheme;
    
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
              Text(
                'Sort By',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: theme.text,
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
                    activeColor: theme.primary,
                  ),
                  trailing: isSelected
                      ? IconButton(
                          icon: Icon(
                            _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                            color: theme.primary,
                          ),
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
    final theme = Provider.of<ThemeProvider>(context).currentTheme;
    
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
            : theme.background,
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
                          color: theme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 12),
                            Icon(Icons.search, color: theme.secondaryText),
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
                                decoration: InputDecoration(
                                  hintText: 'Search by title or format...',
                                  border: InputBorder.none,
                                  hintStyle: TextStyle(color: theme.secondaryText),
                                ),
                                style: TextStyle(color: theme.text),
                              ),
                            ),
                            if (_isSearching)
                              IconButton(
                                icon: Icon(Icons.clear, color: theme.secondaryText),
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
                        label: const Text(
                          'Filter',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        selected: _selectedTagIds.isNotEmpty,
                        onSelected: (_) => _showTagFilterSheet(),
                        avatar: Icon(Icons.filter_list, size: 16, color: theme.primary),
                        side: BorderSide(
                          color: _selectedTagIds.isNotEmpty ? theme.primary : Colors.grey.shade400,
                          width: 1.5,
                        ),
                        backgroundColor: Colors.transparent,
                        selectedColor: theme.primary.withOpacity(0.1),
                        showCheckmark: false,
                        shape: const StadiumBorder(),
                      ),
                    ),
                    // Sort button
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        label: Text(
                          _currentSortOption.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onPressed: _showSortOptions,
                        avatar: Icon(
                          _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                          size: 16,
                          color: theme.primary,
                        ),
                        side: BorderSide(color: Colors.grey.shade400, width: 1),
                        backgroundColor: theme.surface,
                        shape: const StadiumBorder(),
                      ),
                    ),
                    // Selected tags
                    ..._selectedTagIds.map((tagId) {
                      final tag = _allTags.firstWhere((t) => t.id == tagId);
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: Chip(
                          label: Text(
                            tag.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: theme.primary,
                              fontSize: 12,
                            ),
                          ),
                          onDeleted: () {
                            setState(() {
                              _selectedTagIds.remove(tagId);
                            });
                          },
                          side: BorderSide(color: theme.primary, width: 1.5),
                          backgroundColor: theme.primary.withOpacity(0.1),
                          deleteIconColor: theme.primary,
                          deleteIcon: const Icon(Icons.close, size: 14),
                          labelPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          visualDensity: VisualDensity.compact,
                          shape: const StadiumBorder(),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),

            const SizedBox(height: 8),

            // Book grid with dynamic aspect ratio
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Calculate card width based on available space
                  final cardWidth = (constraints.maxWidth - 32 - 16) / 2;
                  // Fixed height that works for all cards
                  const cardHeight = 280.0;
                  
                  return _filteredAndSortedBooks.isEmpty
                      ? _buildEmptyState()
                      : GridView.builder(
                          padding: const EdgeInsets.all(12),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: cardWidth / cardHeight,
                          ),
                          itemCount: _filteredAndSortedBooks.length,
                          itemBuilder: (context, index) {
                            final book = _filteredAndSortedBooks[index];
                            return _buildBookCard(book, context);
                          },
                        );
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
    final theme = Provider.of<ThemeProvider>(context).currentTheme;

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
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 260),
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Book icon/cover area (fixed height)
                    SizedBox(
                      height: 120,
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
                    
                    // Book info area - COMPACT SPACING
                    Container(
                      padding: const EdgeInsets.all(6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Title
                          Text(
                            book.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: theme.text,
                            ),
                          ),
                          const SizedBox(height: 2),
                          
                          // File type indicator
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
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.secondaryText,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 4),
                          
                          // Tags section - ALWAYS SHOW (with or without tags)
                          if (book is TaggedBook)
                            _buildTagsSection(book, bookColor, theme)
                          else
                            // Show just the add button for books without tags
                            _buildAddTagButtonOnly(book, theme),
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

  // Helper method for books without tags
  Widget _buildAddTagButtonOnly(Book book, AppThemeColors theme) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Material(
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: () => _showAddTagDialog(book),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade400, width: 1),
              ),
              child: Center(
                child: Icon(
                  Icons.add,
                  size: 14,
                  color: theme.primary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Helper method to build tags section with dynamic display
  Widget _buildTagsSection(TaggedBook book, Color bookColor, AppThemeColors theme) {
    final int totalTags = book.tagIds.length;
    
    // Determine display mode based on tag count
    if (totalTags < 4) {
      // Mode 1: Show all tags
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            spacing: 4,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ...book.tagIds.map((tagId) {
                final tag = _allTags.firstWhere(
                  (t) => t.id == tagId,
                  orElse: () => Tag.fromName(''),
                );
                final isTagSelected = _selectedTagIds.contains(tag.id);
                
                return FilterChip(
                  label: Text(
                    tag.name,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  selected: isTagSelected,
                  onSelected: (_) {
                    _toggleTagFilter(tag.id);
                  },
                  side: BorderSide(
                    color: isTagSelected ? theme.primary : Colors.grey.shade400,
                    width: 1.2,
                  ),
                  backgroundColor: Colors.transparent,
                  selectedColor: theme.primary.withOpacity(0.1),
                  showCheckmark: false,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                  labelPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  shape: const StadiumBorder(),
                );
              }).toList(),
              
              // Add tag button
              Material(
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  onTap: () => _showAddTagDialog(book),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade400, width: 1),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.add,
                        size: 14,
                        color: theme.primary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    } else {
      // Mode 2: Show +tags count
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            spacing: 4,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Show first 3 tags
              ...book.tagIds.take(3).map((tagId) {
                final tag = _allTags.firstWhere(
                  (t) => t.id == tagId,
                  orElse: () => Tag.fromName(''),
                );
                final isTagSelected = _selectedTagIds.contains(tag.id);
                
                return FilterChip(
                  label: Text(
                    tag.name,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  selected: isTagSelected,
                  onSelected: (_) {
                    _toggleTagFilter(tag.id);
                  },
                  side: BorderSide(
                    color: isTagSelected ? theme.primary : Colors.grey.shade400,
                    width: 1.2,
                  ),
                  backgroundColor: Colors.transparent,
                  selectedColor: theme.primary.withOpacity(0.1),
                  showCheckmark: false,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                  labelPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  shape: const StadiumBorder(),
                );
              }).toList(),
              
              // +X more chip
              if (totalTags > 3)
                FilterChip(
                  label: Text(
                    '+${totalTags - 3}',
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  selected: false,
                  onSelected: (_) => _showAllTagsDialog(book),
                  side: BorderSide(color: Colors.grey.shade400, width: 1.2),
                  backgroundColor: theme.surface,
                  selectedColor: Colors.transparent,
                  showCheckmark: false,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                  labelPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  shape: const StadiumBorder(),
                ),
              
              // Add tag button
              Material(
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  onTap: () => _showAddTagDialog(book),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade400, width: 1),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.add,
                        size: 14,
                        color: theme.primary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          // "See all tags" link for large collections
          if (totalTags > 8)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => _showAllTagsDialog(book),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'See all $totalTags tags',
                  style: TextStyle(
                    fontSize: 8,
                    color: theme.primary,
                  ),
                ),
              ),
            ),
        ],
      );
    }
  }

  // Dialog to show all tags for a book
  void _showAllTagsDialog(TaggedBook book) {
    final theme = Provider.of<ThemeProvider>(context, listen: false).currentTheme;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'All Tags',
          style: TextStyle(fontSize: 18, color: theme.text),
        ),
        content: Container(
          width: double.maxFinite,
          constraints: const BoxConstraints(maxHeight: 300),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                book.title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: theme.text,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              
              Expanded(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: book.tagIds.map((tagId) {
                      final tag = _allTags.firstWhere(
                        (t) => t.id == tagId,
                        orElse: () => Tag.fromName(''),
                      );
                      final isTagSelected = _selectedTagIds.contains(tag.id);
                      
                      return FilterChip(
                        label: Text(tag.name),
                        selected: isTagSelected,
                        onSelected: (_) {
                          _toggleTagFilter(tag.id);
                          Navigator.pop(context);
                        },
                        side: BorderSide(
                          color: isTagSelected ? theme.primary : Colors.grey.shade400,
                          width: 1.2,
                        ),
                        backgroundColor: Colors.transparent,
                        selectedColor: theme.primary.withOpacity(0.1),
                        showCheckmark: false,
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: theme.primary)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;
    
    if (widget.books.isEmpty && !_isSearching && _selectedTagIds.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.library_books,
              size: 80,
              color: theme.primary,
            ),
            const SizedBox(height: 20),
            Text(
              'Your Library',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: theme.text,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'No books added yet',
              style: TextStyle(
                fontSize: 16,
                color: theme.secondaryText,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Tap + to add books',
              style: TextStyle(
                fontSize: 14,
                color: theme.primary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    } else if (_filteredAndSortedBooks.isEmpty) {
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
            Text(
              'No matches found',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: theme.text,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: theme.secondaryText,
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
                  backgroundColor: theme.primary,
                ),
                child: const Text('Clear All Filters', style: TextStyle(color: Colors.white)),
              ),
          ],
        ),
      );
    }

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