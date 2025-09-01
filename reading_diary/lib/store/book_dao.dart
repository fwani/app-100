import 'package:isar/isar.dart';
import 'package:reading_diary/models/reading_entry.dart';
import '../models/book.dart';
import 'isar_db.dart';

class BookDao {
  Future<int> add({
    required String title,
    String author = '작가 미상',
    int? totalPages,
    String? coverUrl,
    BookStatus status = BookStatus.reading,
  }) async {
    final isar = await IsarDb.open();
    final book = Book()
      ..title = title
      ..author = author
      ..totalPages = totalPages
      ..coverUrl = coverUrl
      ..status = status
      ..updatedAt = DateTime.now();
    return isar.writeTxn(() => isar.books.put(book));
  }

  Future<List<Book>> getAll() async {
    final isar = await IsarDb.open();
    return isar.books.where().sortByUpdatedAtDesc().findAll();
  }

  Future<Book?> getById(int id) async {
    final isar = await IsarDb.open();
    return isar.books.get(id);
  }

  Future<void> clearAll() async {
    final isar = await IsarDb.open();
    await isar.writeTxn(() async {
      await isar.readingEntrys.clear();
      await isar.books.clear();
    });
  }

  Future<void> updateStatus(int bookId, BookStatus status) async {
    final isar = await IsarDb.open();
    await isar.writeTxn(() async {
      final b = await isar.books.get(bookId);
      if (b == null) return;
      b
        ..status = status
        ..updatedAt = DateTime.now();
      await isar.books.put(b);
    });
  }

  Future<void> updatePagesRead(int bookId, int delta) async {
    final isar = await IsarDb.open();
    await isar.writeTxn(() async {
      final b = await isar.books.get(bookId);
      if (b == null) return;
      final maxPages = b.totalPages ?? 1 << 30;
      final next = (b.pagesRead + delta).clamp(0, maxPages);
      b
        ..pagesRead = next
        ..updatedAt = DateTime.now();
      await isar.books.put(b);
    });
  }

  /// 간단 검색 + 상태 필터(메모리 필터로도 충분)
  Future<List<Book>> search({
    String q = '',
    bool showReading = true,
    bool showFinished = true,
    bool showPaused = true,
  }) async {
    final isar = await IsarDb.open();
    final list = await isar.books.where().findAll();
    final ql = q.toLowerCase();
    return list.where((b) {
      if (ql.isNotEmpty &&
          !(b.title.toLowerCase().contains(ql) ||
              b.author.toLowerCase().contains(ql))) return false;
      if (b.status == BookStatus.reading && !showReading) return false;
      if (b.status == BookStatus.finished && !showFinished) return false;
      if (b.status == BookStatus.paused && !showPaused) return false;
      return true;
    }).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }
}