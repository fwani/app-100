import 'package:isar/isar.dart';

part 'reading_entry.g.dart';

@collection
class ReadingEntry {
  Id id = Isar.autoIncrement;
  late int bookId;
  late DateTime startedAt;
  DateTime? endedAt;
  int? startPage;
  int? endPage;
  String? note;
  DateTime updatedAt = DateTime.now();

  int? get durationMinutes => endedAt?.difference(startedAt).inMinutes;

  int? get pages =>
      (startPage != null && endPage != null) ? (endPage! - startPage!) : null;
}

extension ReadingEntryJson on ReadingEntry {
  Map<String, dynamic> toMap() => {
        'id': id,
        'bookId': bookId,
        'startedAt': startedAt.toIso8601String(),
        'endedAt': endedAt?.toIso8601String(),
        'startPage': startPage,
        'endPage': endPage,
        'note': note,
        'updatedAt': updatedAt.toIso8601String(),
      };

  static ReadingEntry fromMap(Map<String, dynamic> m) {
    final e = ReadingEntry()
      ..id = (m['id'] as num).toInt()
      ..bookId = (m['bookId'] as num).toInt()
      ..startedAt = DateTime.parse(m['startedAt'])
      ..endedAt = (m['endedAt'] != null) ? DateTime.parse(m['endedAt']) : null
      ..startPage = (m['startPage'] as num?)?.toInt()
      ..endPage = (m['endPage'] as num?)?.toInt()
      ..note = m['note'] as String?
      ..updatedAt = DateTime.tryParse(m['updatedAt'] ?? '') ?? DateTime.now();
    return e;
  }
}
