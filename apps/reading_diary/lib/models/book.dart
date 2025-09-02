import 'package:isar/isar.dart';

part 'book.g.dart';

@collection
class Book {
  Id id = Isar.autoIncrement;
  late String title;
  late String author;
  String? coverUrl;
  int? totalPages;
  int pagesRead = 0;

  @Enumerated(EnumType.name)
  BookStatus status = BookStatus.reading;
  DateTime updatedAt = DateTime.now();

  double get progress {
    final tp = totalPages ?? 0;
    if (tp <= 0) {
      return 0;
    }
    final v = pagesRead / tp;
    return v.clamp(0, 1);
  }
}

enum BookStatus { reading, finished, paused }
extension BookJson on Book {
  Map<String, dynamic> toMap() => {
    'id': id, // int
    'title': title,
    'author': author,
    'coverUrl': coverUrl,
    'totalPages': totalPages,
    'pagesRead': pagesRead,
    'status': status.name, // 'reading'|'finished'|'paused'
    'updatedAt': updatedAt.toIso8601String(),
  };
  static Book fromMap(Map<String, dynamic> m) {
    final b = Book()
      ..id = (m['id'] as num).toInt()
      ..title = m['title'] as String
      ..author = m['author'] as String
      ..coverUrl = m['coverUrl'] as String?
      ..totalPages = (m['totalPages'] as num?)?.toInt()
      ..pagesRead = (m['pagesRead'] as num?)?.toInt() ?? 0
      ..status = BookStatus.values.firstWhere(
            (e) => e.name == (m['status'] as String? ?? 'reading'),
        orElse: () => BookStatus.reading,
      )
      ..updatedAt = DateTime.tryParse(m['updatedAt'] ?? '') ?? DateTime.now();
    return b;
  }
}