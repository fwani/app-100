import 'package:isar/isar.dart';
import '../models/reading_entry.dart';
import 'isar_db.dart';
import 'book_dao.dart';

class EntryDao {
  Future<List<ReadingEntry>> byBook(int bookId) async {
    final isar = await IsarDb.open();
    final list = await isar.readingEntrys
        .filter()
        .bookIdEqualTo(bookId)
        .sortByStartedAtDesc()
        .findAll();
    return list;
  }

  Future<int> add({
    required int bookId,
    required DateTime startedAt,
    DateTime? endedAt,
    int? startPage,
    int? endPage,
    String? note,
  }) async {
    final isar = await IsarDb.open();
    final entry = ReadingEntry()
      ..bookId = bookId
      ..startedAt = startedAt
      ..endedAt = endedAt
      ..startPage = startPage
      ..endPage = endPage
      ..note = note
      ..updatedAt = DateTime.now();

    final id = await isar.writeTxn(() => isar.readingEntrys.put(entry));

    // 페이지 범위가 있으면 Book 진행률도 업데이트
    if (startPage != null && endPage != null) {
      await BookDao().updatePagesRead(bookId, endPage - startPage);
    }
    return id;
  }
}