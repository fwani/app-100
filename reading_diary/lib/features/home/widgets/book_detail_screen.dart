import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../models/book.dart';
import '../../../models/reading_entry.dart';
import '../../../store/book_dao.dart';
import '../../../store/entry_dao.dart';
import 'cover_image.dart';

class BookDetailScreen extends StatefulWidget {
  final int bookId; // int로 변경
  const BookDetailScreen({super.key, required this.bookId});

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  final _bookDao = BookDao();
  final _entryDao = EntryDao();

  Book? _book;
  List<ReadingEntry> _entries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    final b = await _bookDao.getById(widget.bookId);
    final e = await _entryDao.byBook(widget.bookId);
    setState(() {
      _book = b;
      _entries = e;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final book = _book;
    if (book == null) {
      return Scaffold(
          appBar: AppBar(), body: const Center(child: Text('책을 찾을 수 없습니다.')));
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(book.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          bottom: const TabBar(tabs: [Tab(text: '진행률'), Tab(text: '세션 기록')]),
          actions: [
            IconButton(
              tooltip: '편집',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () async {
                final ok = await showModalBottomSheet<bool>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => _EditBookSheet(book: book, bookDao: _bookDao),
                );
                if (ok == true) await _reload();
              },
            ),
            IconButton(
              tooltip: '삭제',
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                final entryCount = await _bookDao.countEntriesOf(book.id);
                final sure = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('책 삭제'),
                    content: Text(
                      entryCount == 0
                          ? '정말 이 책을 삭제할까요?'
                          : '이 책과 연결된 세션 $entryCount건도 함께 삭제됩니다. 계속할까요?',
                    ),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('취소')),
                      FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('삭제')),
                    ],
                  ),
                );
                if (sure == true) {
                  await _bookDao.deleteBook(book.id);
                  if (!mounted) return;
                  Navigator.pop(context); // 상세 화면 닫기
                }
              },
            ),
          ],
        ),
        floatingActionButton: Builder(
          builder: (context) {
            final idx = DefaultTabController.of(context).index;
            return idx == 1
                ? FloatingActionButton.extended(
                    icon: const Icon(Icons.timer),
                    label: const Text('세션 추가'),
                    onPressed: () async {
                      final added = await showModalBottomSheet<bool>(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => _AddSessionSheet(
                            bookId: book.id, entryDao: _entryDao),
                      );
                      if (added == true) await _reload();
                    },
                  )
                : const SizedBox.shrink();
          },
        ),
        body: TabBarView(
          children: [
            _ProgressTab(
              book: book,
              onAdjustPages: (d) async {
                await _bookDao.updatePagesRead(book.id, d);
                await _reload();
              },
              onChangeStatus: (s) async {
                await _bookDao.updateStatus(book.id, s);
                await _reload();
              },
            ),
            _SessionsTab(entries: _entries),
          ],
        ),
      ),
    );
  }
}

class _ProgressTab extends StatelessWidget {
  final Book book;
  final void Function(int delta) onAdjustPages;
  final void Function(BookStatus status) onChangeStatus;

  const _ProgressTab(
      {required this.book,
      required this.onAdjustPages,
      required this.onChangeStatus});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Cover(coverUrl: book.coverUrl),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    style: Theme.of(context).textTheme.titleLarge,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(book.author,
                      style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(value: book.progress),
                  const SizedBox(height: 6),
                  Text(_progressLabel(book)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // 페이지 조절 버튼들
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              icon: const Icon(Icons.exposure_plus_1),
              label: const Text('+10p'),
              onPressed: () => onAdjustPages(10),
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.exposure_plus_2),
              label: const Text('+25p'),
              onPressed: () => onAdjustPages(25),
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.exposure_neg_1),
              label: const Text('-5p'),
              onPressed: () => onAdjustPages(-5),
            ),
            FilledButton.icon(
              icon: const Icon(Icons.flag),
              label: const Text('완독'),
              onPressed: () => onChangeStatus(BookStatus.finished),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 상태 변경 드롭다운
        DropdownButtonFormField<BookStatus>(
          initialValue: book.status,
          decoration: const InputDecoration(
            labelText: '상태 변경',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          items: const [
            DropdownMenuItem(value: BookStatus.reading, child: Text('읽는중')),
            DropdownMenuItem(value: BookStatus.finished, child: Text('완독')),
            DropdownMenuItem(value: BookStatus.paused, child: Text('보류')),
          ],
          onChanged: (v) {
            if (v != null) onChangeStatus(v);
          },
        ),
      ],
    );
  }

  String _progressLabel(Book b) {
    final tp = b.totalPages ?? 0;
    if (tp > 0) {
      return '진행: ${b.pagesRead}/${tp}p '
          '(${(b.progress * 100).toStringAsFixed(0)}%)';
    } else {
      return '진행: ${b.pagesRead}p (총 페이지 미입력)';
    }
  }
}

class _Cover extends StatelessWidget {
  final String? coverUrl;

  const _Cover({this.coverUrl});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      height: 128,
      child: ClipRRect(
          borderRadius: BorderRadius.circular(8), child: CoverImage(coverRef: coverUrl)),
    );
  }
}

class _SessionsTab extends StatelessWidget {
  final List<ReadingEntry> entries;

  const _SessionsTab({required this.entries});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const Center(child: Text('아직 기록된 세션이 없어요'));
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
      itemCount: entries.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final e = entries[i];
        final parts = <String>[];
        if (e.durationMinutes != null) parts.add('시간 ${e.durationMinutes}분');
        if (e.pages != null) parts.add('페이지 ${e.pages}p');
        if (e.note != null && e.note!.isNotEmpty) parts.add('메모: ${e.note!}');
        return ListTile(
          leading: const Icon(Icons.schedule),
          title: Text('${e.startedAt} ~ ${e.endedAt ?? e.startedAt}',
              maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(parts.join(' · ')),
        );
      },
    );
  }
}

class _AddSessionSheet extends StatefulWidget {
  final int bookId;
  final EntryDao entryDao;

  const _AddSessionSheet({required this.bookId, required this.entryDao});

  @override
  State<_AddSessionSheet> createState() => _AddSessionSheetState();
}

class _AddSessionSheetState extends State<_AddSessionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _startCtrl = TextEditingController();
  final _endCtrl = TextEditingController();
  final _startPageCtrl = TextEditingController();
  final _endPageCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startCtrl.text = _fmt(now.subtract(const Duration(minutes: 25)));
    _endCtrl.text = _fmt(now);
  }

  @override
  void dispose() {
    _startCtrl.dispose();
    _endCtrl.dispose();
    _startPageCtrl.dispose();
    _endPageCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // (입력 폼 UI는 이전과 동일)
              Row(
                children: [
                  Expanded(
                      child: TextFormField(
                    controller: _startCtrl,
                    decoration: const InputDecoration(
                        labelText: '시작 (YYYY-MM-DD HH:MM)',
                        border: OutlineInputBorder(),
                        isDense: true),
                    validator: _validateDateTime,
                  )),
                  const SizedBox(width: 8),
                  Expanded(
                      child: TextFormField(
                    controller: _endCtrl,
                    decoration: const InputDecoration(
                        labelText: '종료 (YYYY-MM-DD HH:MM)',
                        border: OutlineInputBorder(),
                        isDense: true),
                    validator: _validateDateTime,
                  )),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                      child: TextFormField(
                    controller: _startPageCtrl,
                    decoration: const InputDecoration(
                        labelText: '시작 페이지(선택)',
                        border: OutlineInputBorder(),
                        isDense: true),
                    keyboardType: TextInputType.number,
                  )),
                  const SizedBox(width: 8),
                  Expanded(
                      child: TextFormField(
                    controller: _endPageCtrl,
                    decoration: const InputDecoration(
                        labelText: '종료 페이지(선택)',
                        border: OutlineInputBorder(),
                        isDense: true),
                    keyboardType: TextInputType.number,
                  )),
                ],
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _noteCtrl,
                decoration: const InputDecoration(
                    labelText: '메모(선택)',
                    border: OutlineInputBorder(),
                    isDense: true),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                      child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('취소'),
                  )),
                  const SizedBox(width: 12),
                  Expanded(
                      child: FilledButton(
                    onPressed: () async {
                      if (_formKey.currentState?.validate() != true) return;
                      final s = _parseDT(_startCtrl.text.trim())!;
                      final e = _parseDT(_endCtrl.text.trim())!;
                      final sp = int.tryParse(_startPageCtrl.text.trim());
                      final ep = int.tryParse(_endPageCtrl.text.trim());
                      await widget.entryDao.add(
                        bookId: widget.bookId,
                        startedAt: s,
                        endedAt: e,
                        startPage: sp,
                        endPage: ep,
                        note: _noteCtrl.text.trim(),
                      );
                      if (!mounted) return;
                      Navigator.pop(context, true);
                    },
                    child: const Text('추가'),
                  )),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _validateDateTime(String? v) =>
      _parseDT(v?.trim() ?? '') == null ? '형식: 2025-09-01 13:30' : null;

  DateTime? _parseDT(String s) {
    try {
      final parts = s.split(' ');
      final d = parts[0].split('-').map(int.parse).toList();
      final t = parts[1].split(':').map(int.parse).toList();
      return DateTime(d[0], d[1], d[2], t[0], t[1]);
    } catch (_) {
      return null;
    }
  }

  String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

class _EditBookSheet extends StatefulWidget {
  final Book book;
  final BookDao bookDao;

  const _EditBookSheet({required this.book, required this.bookDao});

  @override
  State<_EditBookSheet> createState() => _EditBookSheetState();
}

class _EditBookSheetState extends State<_EditBookSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _authorCtrl;
  late final TextEditingController _coverCtrl;
  late final TextEditingController _pagesCtrl;

  final ImagePicker _picker = ImagePicker();
  XFile? _pickedImageFile;

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _pickedImageFile = picked;
        _coverCtrl.text = picked.path;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.book.title);
    _authorCtrl = TextEditingController(text: widget.book.author);
    _coverCtrl = TextEditingController(text: widget.book.coverUrl ?? '');
    _pagesCtrl =
        TextEditingController(text: widget.book.totalPages?.toString() ?? '');
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _authorCtrl.dispose();
    _coverCtrl.dispose();
    _pagesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: inset),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Form(
          key: _formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // 미리보기
            if (_pickedImageFile != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(File(_pickedImageFile!.path),
                    width: 100, height: 140, fit: BoxFit.cover),
              ),
            const SizedBox(height: 8),
            Text('책 정보 편집', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _coverCtrl,
                    decoration: const InputDecoration(
                      labelText: '표지 URL',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.photo_library),
                  onPressed: _pickImage,
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                  labelText: '제목 *',
                  border: OutlineInputBorder(),
                  isDense: true),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? '제목을 입력하세요' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _authorCtrl,
              decoration: const InputDecoration(
                  labelText: '저자', border: OutlineInputBorder(), isDense: true),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _pagesCtrl,
              decoration: const InputDecoration(
                  labelText: '총 페이지(숫자)',
                  border: OutlineInputBorder(),
                  isDense: true),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('취소'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () async {
                    if (_formKey.currentState?.validate() != true) return;
                    final pages = int.tryParse(_pagesCtrl.text.trim());
                    await widget.bookDao.updateBook(
                      id: widget.book.id,
                      title: _titleCtrl.text.trim(),
                      author: _authorCtrl.text.trim(),
                      coverUrl: _coverCtrl.text.trim().isEmpty
                          ? null
                          : _coverCtrl.text.trim(),
                      totalPages: pages,
                      coverFile: _pickedImageFile,
                    );
                    if (!mounted) return;
                    Navigator.pop(context, true);
                  },
                  child: const Text('저장'),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}
