import 'package:flutter/material.dart';
import '../models/book.dart';

class LibraryPage extends StatefulWidget {
  final List<Book> books;
  final Function(Book)? onBookTap;
  
  const LibraryPage({
    super.key,
    required this.books,
    this.onBookTap,
  });

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFFFFFF),
      padding: const EdgeInsets.all(16),
      child: widget.books.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.library_books,
                    size: 64,
                    color: Color(0xFF3498DB),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Your Library',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'No books added yet',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF7F8C8D),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Tap + to add books',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF3498DB),
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
                childAspectRatio: 0.75, // Makes rectangles taller
              ),
              itemCount: widget.books.length,
              itemBuilder: (context, index) {
                final book = widget.books[index];
                return _buildBookCard(book);
              },
            ),
    );
  }
  
  Widget _buildBookCard(Book book) {
    return GestureDetector(
      onTap: () {
        if (widget.onBookTap != null) {
          widget.onBookTap!(book);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Color(book.colorCode).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Color(book.colorCode).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book icon/cover area (takes most space)
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Color(book.colorCode).withOpacity(0.2),
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
                        color: Color(book.colorCode),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        book.icon,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(book.colorCode),
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
                  if (book.author != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      book.author!,
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
    );
  }
}