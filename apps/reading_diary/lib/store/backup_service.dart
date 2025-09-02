import 'dart:convert';
import 'package:isar/isar.dart';
import '../models/book.dart';
import '../models/reading_entry.dart';
import 'isar_db.dart';

class BackupBundle {
  final String version;
  final DateTime exportedAt;
  final List<Book> books;
  final List<ReadingEntry> entries;

  BackupBundle({
    required this.version,
    required this.exportedAt,
    required this.books,
    required this.entries,
  });

  Map<String, dynamic> toMap() => {
    'version': version,
    'exportedAt': exportedAt.toIso8601String(),
    'books': books.map((b) => b.toMap()).toList(),
    'entries': entries.map((e) => e.toMap()).toList(),
  };

  static BackupBundle fromMap(Map<String, dynamic> m) => BackupBundle(
    version: m['version'] as String? ?? '1',
    exportedAt: DateTime.tryParse(m['exportedAt'] ?? '') ?? DateTime.now(),
    books: (m['books'] as List<dynamic>? ?? const [])
        .map((x) => BookJson.fromMap(Map<String,dynamic>.from(x))).toList(),
    entries: (m['entries'] as List<dynamic>? ?? const [])
        .map((x) => ReadingEntryJson.fromMap(Map<String,dynamic>.from(x))).toList(),
  );
}

class RestoreResult {
  final int booksUpserted;
  final int entriesUpserted;
  final int entriesSkippedNoBook; // 연결 책이 없어서 건너뜀
  RestoreResult(this.booksUpserted, this.entriesUpserted, this.entriesSkippedNoBook);
}

class BackupService {
  static const _bundleVersion = '1';

  /// 모든 데이터를 JSON 문자열로 내보냄
  static Future<String> exportJson() async {
    final isar = await IsarDb.open();
    final books = await isar.books.where().findAll();
    final entries = await isar.readingEntrys.where().findAll();
    final bundle = BackupBundle(
      version: _bundleVersion,
      exportedAt: DateTime.now(),
      books: books,
      entries: entries,
    );
    return const JsonEncoder.withIndent('  ').convert(bundle.toMap());
  }

  /// JSON을 병합(import). 같은 id가 있으면 updatedAt 최신 승리(LWW)로 업서트
  static Future<RestoreResult> importJson(String json, {bool clearBefore = false}) async {
    final isar = await IsarDb.open();
    final map = jsonDecode(json) as Map<String, dynamic>;
    final bundle = BackupBundle.fromMap(map);

    int bookUp = 0, entryUp = 0, entrySkip = 0;

    await isar.writeTxn(() async {
      if (clearBefore) {
        await isar.readingEntrys.clear();
        await isar.books.clear();
      }

      // Books 먼저
      for (final nb in bundle.books) {
        final cur = await isar.books.get(nb.id);
        if (cur == null || nb.updatedAt.isAfter(cur.updatedAt)) {
          await isar.books.put(nb);
          bookUp++;
        }
      }

      // Entries (부모 책이 있는 경우만)
      for (final ne in bundle.entries) {
        final parent = await isar.books.get(ne.bookId);
        if (parent == null) {
          entrySkip++;
          continue;
        }
        final cur = await isar.readingEntrys.get(ne.id);
        if (cur == null || ne.updatedAt.isAfter(cur.updatedAt)) {
          await isar.readingEntrys.put(ne);
          entryUp++;
        }
      }
    });

    return RestoreResult(bookUp, entryUp, entrySkip);
  }
}