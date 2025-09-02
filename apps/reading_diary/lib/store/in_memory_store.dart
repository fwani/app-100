import 'dart:math';
import 'package:reading_diary/models/reading_entry.dart';

import '../models/book.dart';

/// 아주 간단한 메모리 저장소 (나중에 Isar/Firebase로 교체 예정)
class InMemoryStore {
  static final InMemoryStore _instance = InMemoryStore._internal();

  factory InMemoryStore() => _instance;

  InMemoryStore._internal();

  final List<Book> _books = [];
  final List<ReadingEntry> _entries = [];

  void clear() {
    _books.clear();
    _entries.clear();
  }

  // --- Book ---
  List<Book> getAll() => List.unmodifiable(_books);

  Book? getById(String id) =>
      _books.where((element) => element.id == id).firstOrNull;

  Book add({
    required String title,
    String author = "작가 미상",
    int? totalPages,
    BookStatus status = BookStatus.reading,
  }) {
    final id = _randomId();
    final book = Book(
      id: id,
      title: title,
      author: author,
      totalPages: totalPages,
      status: status,
    );
    _books.add(book);
    return book;
  }

  void updateStatus(String bookId, BookStatus status) {
    final idx = _books.indexWhere((element) => element.id == bookId);
    if (idx >= 0) {
      _books[idx] = _books[idx].copyWith(status: status);
    }
  }

  void updatePagesRead(String bookId, int delta) {
    final idx = _books.indexWhere((b) => b.id == bookId);
    if (idx < 0) return;
    final b = _books[idx];
    final next = (b.pagesRead + delta).clamp(0, (b.totalPages ?? 1 << 30));
    _books[idx] = b.copyWith(pagesRead: next);
  }

  // --- Entries ---

  List<ReadingEntry> getEntriesByBook(String bookId) {
    final list = _entries.where((e) => e.bookId == bookId).toList();
    list.sort((a, b) => (b.startedAt).compareTo(a.startedAt));
    return list;
  }

  ReadingEntry addEntry(
    String bookId, {
    required DateTime startedAt,
    DateTime? endedAt,
    int? startPage,
    int? endPage,
    String? note,
  }) {
    final id = _randomId();
    final e = ReadingEntry(
      id: id,
      bookId: bookId,
      startedAt: startedAt,
      endedAt: endedAt,
      startPage: startPage,
      endPage: endPage,
      note: note,
    );
    _entries.add(e);

    // 페이지가 입력된 경우 진행률 반영(간단 규칙)
    if (startPage != null && endPage != null) {
      final delta = endPage - startPage;
      updatePagesRead(bookId, delta);
    }
    return e;
  }

  String _randomId() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final rand = Random();
    return List.generate(12, (_) => chars[rand.nextInt(chars.length)]).join();
  }
}
