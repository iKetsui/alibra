class Book {
  final String id;
  final String title;
  final String? author;
  final String filePath;
  final String fileType; // 'pdf' or 'epub'
  final DateTime addedDate;
  
  Book({
    required this.id,
    required this.title,
    required this.filePath,
    required this.fileType,
    this.author,
    DateTime? addedDate,
  }) : addedDate = addedDate ?? DateTime.now();
  
  // Get appropriate icon based on file type
  String get icon {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return 'PDF';
      case 'epub':
        return 'EPUB';
      default:
        return 'DOC';
    }
  }
  
  // Get color based on file type
  int get colorCode {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return 0xFFFF6B6B; // Red
      case 'epub':
        return 0xFF4ECDC4; // Teal
      default:
        return 0xFF45B7D1; // Blue
    }
  }
}