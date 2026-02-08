import 'package:flutter/material.dart';
import '../models/book.dart';
import '../utils/deletion.dart';

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
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  bool _isDeleteModeActive = false;
  
  @override
  Widget build(BuildContext context) {
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
        padding: const EdgeInsets.all(16),
        child: widget.books.isEmpty
            ? _buildEmptyState()
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
                  return _buildBookCard(book, context);
                },
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
                  color: Color.fromRGBO(bookColor.red, bookColor.green, bookColor.blue, 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected 
                        ? const Color.fromRGBO(216, 9, 9, 0.8)
                        : Color.fromRGBO(bookColor.red, bookColor.green, bookColor.blue, 0.3),
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
    return Center(
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
    );
  }
}