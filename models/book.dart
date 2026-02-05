class Book {
  final String id;
  final String title;
  final String filePath;
  final String fileType;
  final String author;
  final int colorCode;

  Book({
    required this.id,
    required this.title,
    required this.filePath,
    required this.fileType,
    this.author = 'Unknown Author',
    this.colorCode = 0xFF3498DB,
  });

  Book copyWith({
    String? id,
    String? title,
    String? filePath,
    String? fileType,
    String? author,
    int? colorCode,
    String? icon,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      filePath: filePath ?? this.filePath,
      fileType: fileType ?? this.fileType,
      author: author ?? this.author,
      colorCode: colorCode ?? this.colorCode,
    );
  }
}