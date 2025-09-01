import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:reading_diary/features/home/widgets/book_detail_screen.dart';
import '../../models/book.dart';
import '../../store/backup_service.dart';
import '../../store/book_dao.dart';
import 'widgets/book_list_tile.dart';
import 'widgets/empty_state.dart';
import 'widgets/quick_add_sheet.dart';

enum SortKey { recent, title, author, progress }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _dao = BookDao();
  final TextEditingController _searchCtrl = TextEditingController();

  String _search = "";
  bool _showReading = true;
  bool _showFinished = true;
  bool _showPaused = true;
  SortKey _sortKey = SortKey.recent;

  List<Book> _list = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() => _search = _searchCtrl.text.trim());
      _reload();
    });
    _reload();
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    var list = await _dao.search(
      q: _search,
      showReading: _showReading,
      showFinished: _showFinished,
      showPaused: _showPaused,
    );
    // 정렬
    list.sort((a, b) {
      switch (_sortKey) {
        case SortKey.recent:
          return b.updatedAt.compareTo(a.updatedAt);
        case SortKey.title:
          return a.title.toLowerCase().compareTo(b.title.toLowerCase());
        case SortKey.author:
          return a.author.toLowerCase().compareTo(b.author.toLowerCase());
        case SortKey.progress:
          return b.progress.compareTo(a.progress);
      }
    });
    setState(() {
      _list = list;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('독서 기록'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'export') {
                final json = await BackupService.exportJson();
                await Clipboard.setData(ClipboardData(text: json));
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('백업 JSON이 클립보드에 복사되었습니다.')),
                );
              } else if (v == 'import') {
                final text = await showDialog<String?>(
                  context: context,
                  builder: (ctx) => const _JsonPasteDialog(),
                );
                if (text == null || text.trim().isEmpty) return;
                try {
                  final result = await BackupService.importJson(text.trim(),
                      clearBefore: false);
                  await _reload();
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            '복원 완료: 책 ${result.booksUpserted}권, 세션 ${result.entriesUpserted}건'
                            '${result.entriesSkippedNoBook > 0 ? " (부모 없는 세션 ${result.entriesSkippedNoBook} 건 스킵)" : ""}')),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('복원 실패: $e')),
                  );
                }
              } else if (v == 'clear') {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('모든 데이터 삭제'),
                    content: const Text('정말 전체 데이터를 삭제할까요? 되돌릴 수 없습니다.'),
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
                if (ok == true) {
                  final json =
                      await BackupService.exportJson(); // 안전망: 삭제 전에 자동 백업 복사
                  await Clipboard.setData(ClipboardData(text: json));
                  await BackupService.importJson(
                      '{"version":"1","exportedAt":"", "books":[],"entries":[]}',
                      clearBefore: true);
                  await _reload();
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            '모든 데이터를 삭제했습니다. (직전에 백업 JSON을 클립보드로 복사해두었어요)')),
                  );
                }
              }
            },
            itemBuilder: (ctx) => const [
              PopupMenuItem(value: 'export', child: Text('백업(JSON 복사)')),
              PopupMenuItem(value: 'import', child: Text('복원(JSON 붙여넣기)')),
              PopupMenuItem(value: 'clear', child: Text('모두 삭제(주의)')),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('책 추가'),
        onPressed: () async {
          final ok = await showModalBottomSheet<bool>(
            context: context,
            isScrollControlled: true,
            builder: (_) => const QuickAddSheet(),
          );
          if (ok == true) await _reload();
        },
      ),
      body: Column(
        children: [
          // 검색
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(
                hintText: '제목/저자 검색',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          // 필터칩 + 정렬
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('읽는중'),
                  selected: _showReading,
                  onSelected: (s) {
                    setState(() => _showReading = s);
                    _reload();
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('완독'),
                  selected: _showFinished,
                  onSelected: (s) {
                    setState(() => _showFinished = s);
                    _reload();
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('보류'),
                  selected: _showPaused,
                  onSelected: (s) {
                    setState(() => _showPaused = s);
                    _reload();
                  },
                ),
                const SizedBox(width: 12),
                PopupMenuButton<SortKey>(
                  tooltip: '정렬',
                  onSelected: (k) {
                    setState(() => _sortKey = k);
                    _reload();
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: SortKey.recent, child: Text('최근')),
                    PopupMenuItem(value: SortKey.title, child: Text('제목')),
                    PopupMenuItem(value: SortKey.author, child: Text('저자')),
                    PopupMenuItem(value: SortKey.progress, child: Text('진행률')),
                  ],
                  child: const Row(children: [
                    Icon(Icons.sort),
                    SizedBox(width: 4),
                    Text('정렬')
                  ]),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // 목록
          Expanded(
            child: _loading
                ? const _ListSkeleton(count: 6)
                : (_list.isEmpty
                    ? const EmptyState(
                        title: '아직 등록된 책이 없어요',
                        message: '오른쪽 아래 버튼으로 첫 책을 추가해보세요.',
                      )
                    : RefreshIndicator(
                        onRefresh: _reload,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
                          itemCount: _list.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (_, i) => BookListTile(
                            book: _list[i],
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      BookDetailScreen(bookId: _list[i].id),
                                ),
                              );
                              await _reload();
                            },
                          ),
                        ),
                      )),
          ),
        ],
      ),
    );
  }
}

class _ListSkeleton extends StatelessWidget {
  final int count;

  const _ListSkeleton({required this.count});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: count,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
      itemBuilder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        height: 84,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(.5),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

class _JsonPasteDialog extends StatefulWidget {
  const _JsonPasteDialog();

  @override
  State<_JsonPasteDialog> createState() => _JsonPasteDialogState();
}

class _JsonPasteDialogState extends State<_JsonPasteDialog> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();

  final Set<PhysicalKeyboardKey> _pressed = <PhysicalKeyboardKey>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_){
      if (mounted) _focus.requestFocus();
    });
  }
  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focus,
      autofocus: true,
      onKeyEvent: (node, event) {
        final pk = event.physicalKey;

        if (event is KeyDownEvent) {
          if (_pressed.contains(pk)){
            return KeyEventResult.handled;
          }
          _pressed.add(pk);
        } else if (event is KeyUpEvent){
          _pressed.remove(pk);
        }
        return KeyEventResult.ignored;
      },
      child: AlertDialog(
        title: const Text('JSON 붙여넣기'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: SizedBox(
            width: 480,
            child: TextField(
              controller: _ctrl,
              autofocus: true,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              decoration: const InputDecoration(
                hintText: '여기에 백업 JSON을 붙여넣으세요',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              maxLines: 12,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              // 클릭 제스처 기반이므로 웹에서도 clipboard read가 잘 동작
              final data = await Clipboard.getData(Clipboard.kTextPlain);
              if (data?.text?.isNotEmpty == true) {
                _ctrl.text = data!.text!;
              }
            },
            child: const Text('클립보드에서 붙여넣기'),
          ),
          TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('취소')),
          FilledButton(
              onPressed: () => Navigator.pop(context, _ctrl.text),
              child: const Text('복원')),
        ],
      ),
    );
  }
}
