import 'package:flutter/material.dart';
import '../models/book.dart';

class DeletionManager extends StatefulWidget {
  final List<Book> books;
  final Widget child;
  final Function(List<Book>) onDelete;
  final Function(bool) onDeleteModeChange;
  
  const DeletionManager({
    super.key,
    required this.books,
    required this.child,
    required this.onDelete,
    required this.onDeleteModeChange,
  });

  @override
  DeletionManagerState createState() => DeletionManagerState();
}

class DeletionManagerState extends State<DeletionManager> {
  final Set<String> _selectedBooks = {};
  bool _isDeleteMode = false;
  // Add a ValueNotifier to force rebuilds
  final ValueNotifier<int> _rebuildNotifier = ValueNotifier(0);

  void enterDeleteMode() {
    setState(() {
      _isDeleteMode = true;
      _selectedBooks.clear();
    });
    widget.onDeleteModeChange(true);
    _rebuildNotifier.value++; // Trigger rebuild
  }

  void exitDeleteMode() {
    setState(() {
      _isDeleteMode = false;
      _selectedBooks.clear();
    });
    widget.onDeleteModeChange(false);
    _rebuildNotifier.value++; // Trigger rebuild
  }

  void toggleBookSelection(String bookId) {
    setState(() {
      if (_selectedBooks.contains(bookId)) {
        _selectedBooks.remove(bookId);
        if (_selectedBooks.isEmpty && _isDeleteMode) {
          exitDeleteMode();
        }
      } else {
        _selectedBooks.add(bookId);
        if (!_isDeleteMode) {
          enterDeleteMode();
        }
      }
    });
    _rebuildNotifier.value++; // Trigger rebuild when selection changes
  }

  void deleteSelectedBooks() {
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
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onDelete(booksToDelete);
              exitDeleteMode();
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

  bool isSelected(String bookId) => _selectedBooks.contains(bookId);
  bool get isDeleteMode => _isDeleteMode;
  int get selectedCount => _selectedBooks.length;
  ValueNotifier<int> get rebuildNotifier => _rebuildNotifier;

  @override
  void dispose() {
    _rebuildNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Delete mode header
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
                  onPressed: exitDeleteMode,
                  icon: const Icon(Icons.close, color: Colors.white),
                  tooltip: 'Exit delete mode',
                ),
              ],
            ),
          ),
        
        // Main content wrapped with ValueListenableBuilder
        Expanded(
          child: ValueListenableBuilder(
            valueListenable: _rebuildNotifier,
            builder: (context, value, child) {
              return Stack(
                children: [
                  // The library content
                  widget.child,
                  
                  // Delete button
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
                              onTap: deleteSelectedBooks,
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
            },
          ),
        ),
      ],
    );
  }
}