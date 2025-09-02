import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
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
    final all = await isar.books.where().findAll();
    for (final b in all) {
      await _deleteCoverFile(b.coverUrl);
    }
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

  Future<void> updateBook({
    required int id,
    String? title,
    String? author,
    String? coverUrl,
    int? totalPages,
    XFile? coverFile,
  }) async {
    final isar = await IsarDb.open();
    await isar.writeTxn(() async {
      final b = await isar.books.get(id);
      if (b == null) return;
      final oldCover = b.coverUrl;
      if (title != null) b.title = title;
      if (author != null) b.author = author;
      if (totalPages != null) {
        b.totalPages = totalPages;
        // 총 페이지가 줄어든 경우 pagesRead 보정
        if (b.totalPages != null && b.pagesRead > b.totalPages!) {
          b.pagesRead = b.totalPages!;
        }
      }
      if (coverUrl != null && coverFile != null) {
        b.coverUrl = await saveCoverFile(coverFile, b.id);
      }
      b.updatedAt = DateTime.now();
      await isar.books.put(b);

      if (coverUrl != null && oldCover != coverUrl) {
        await _deleteCoverFile(oldCover);
      }
    });
  }

  Future<String> saveCoverFile(XFile picked, int bookId) async {
    final dir = await getApplicationDocumentsDirectory();
    final ext = (picked.name.split('.').last).toLowerCase();
    final fileName = 'cover_$bookId.${ext.isEmpty ? 'jpg' : ext}';
    final _ = File(picked.path).copy('${dir.path}/$fileName');
    return fileName;
  }

  Future<void> deleteBook(int id) async {
    final isar = await IsarDb.open();
    await isar.writeTxn(() async {
      // 세션 먼저 삭제(참조 정리)
      final b = await isar.books.get(id);
      if (b == null) return;
      await isar.readingEntrys.filter().bookIdEqualTo(id).deleteAll();
      await _deleteCoverFile(b.coverUrl);
      await isar.books.delete(id);
    });
  }

  Future<int> countEntriesOf(int bookId) async {
    final isar = await IsarDb.open();
    return await isar.readingEntrys.filter().bookIdEqualTo(bookId).count();
  }

  Future<void> _deleteCoverFile(String? ref) async {
    if (ref == null || ref.isEmpty) return;

    try {
      String fullPath;

      if (ref.startsWith('http://') || ref.startsWith('https://')) {
        // 네트워크 URL은 삭제 대상 아님
        return;
      } else if (ref.startsWith('/') || ref.startsWith('file://')) {
        // 절대 경로
        fullPath = ref.startsWith('file://') ? Uri.parse(ref).path : ref;
      } else {
        // ✅ 파일명만 저장된 경우 → 앱 Documents 경로와 합침
        final dir = await getApplicationDocumentsDirectory();
        fullPath = '${dir.path}/$ref';
      }

      final f = File(fullPath);
      if (await f.exists()) {
        await f.delete();
      }
    } catch (e) {
      // 파일이 없거나 권한 문제면 무시
    }
  }
}
