class Book {
  final String id;
  final String title;
  final String filePath;
  final String fileType;
  final int colorCode;

  Book({
    required this.id,
    required this.title,
    required this.filePath,
    required this.fileType,
    int? colorCode,
  }) : colorCode = colorCode ?? _getColorCodeForFileType(fileType);

  static int _getColorCodeForFileType(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return 0xFFFF6B6B;
      case 'epub':
        return 0xFF4ECDC4;
      default:
        return 0xFF45B7D1;
    }
  }

  // Convert to Map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'filePath': filePath,
      'fileType': fileType,
      'colorCode': colorCode,
    };
  }

  // Create from Map
  static Book fromMap(Map<String, dynamic> map) {
    return Book(
      id: map['id'],
      title: map['title'],
      filePath: map['filePath'],
      fileType: map['fileType'],
      colorCode: map['colorCode'],
    );
  }

  Book copyWith({
    String? id,
    String? title,
    String? filePath,
    String? fileType,
    int? colorCode,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      filePath: filePath ?? this.filePath,
      fileType: fileType ?? this.fileType,
      colorCode: colorCode ?? this.colorCode,
    );
  }
}