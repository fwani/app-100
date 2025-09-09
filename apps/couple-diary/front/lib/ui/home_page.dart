import 'package:flutter/material.dart';
import '../core/session.dart';
import '../data/room_api.dart';
import '../data/post_api.dart';
import 'timeline_page.dart';

class HomePage extends StatefulWidget {
  final Session session;
  final PostApi posts;
  final RoomApi rooms;

  const HomePage({
    super.key,
    required this.session,
    required this.posts,
    required this.rooms,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;
  String? _inviteCode;
  bool _busy = false;

  Future<void> _ensureRoom() async {
    if (widget.session.roomId != null) return;
    // 간단 선택 다이얼로그: 새로 만들기 or 코드로 참여
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (c) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('새 방 만들기'),
                onTap: () => Navigator.pop(c, 'create'),
              ),
              ListTile(
                title: const Text('초대코드로 참여'),
                onTap: () => Navigator.pop(c, 'join'),
              ),
            ],
          ),
        );
      },
    );
    if (!mounted || action == null) return;
    setState(() => _busy = true);
    try {
      if (action == 'create') {
        final res = await widget.rooms.createRoom();
        await widget.session.setRoomId(res.roomId);
        setState(() => _inviteCode = res.code);
      } else {
        final code = await showDialog<String>(
          context: context,
          builder: (c) {
            final ctrl = TextEditingController();
            return AlertDialog(
              title: const Text('초대코드 입력'),
              content: TextField(
                controller: ctrl,
                decoration: const InputDecoration(hintText: '예: ABC123'),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(c),
                  child: const Text('취소'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(c, ctrl.text.trim()),
                  child: const Text('참여'),
                ),
              ],
            );
          },
        );
        if (code != null && code.isNotEmpty) {
          await widget.rooms.joinRoom(code);
          // 서버에서 내 룸을 조회하는 API가 없다면, join 성공하면 클라이언트에선 수동으로 세팅 필요
          // 실제론 "내가 속한 room" 조회 API를 추가하는 걸 권장
          // 지금은 단순히 "참여 성공"만 처리해두자(테스트 용)
          // -> 실전에서는 join 성공 시 서버가 room_id를 반환하도록 바꾸기 권장
        }
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void initState() {
    super.initState();
    // 홈 진입 시 방 없으면 만들거나 참여 유도
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureRoom());
  }

  @override
  Widget build(BuildContext context) {
    final roomId = widget.session.roomId;
    final pages = <Widget>[
      TimelinePage(roomId: roomId, posts: widget.posts),
      const Center(child: Text('기념일 (추가 예정)')),
      const Center(child: Text('장소 (추가 예정)')),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Couple Diary'),
        actions: [
          if (_inviteCode != null)
            IconButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (c) => AlertDialog(
                    title: const Text('초대코드'),
                    content: SelectableText(_inviteCode!),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(c),
                        child: const Text('닫기'),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.key_outlined),
              tooltip: '초대코드',
            ),
          IconButton(
            onPressed: _busy
                ? null
                : () async {
                    await widget.session.signOut();
                    if (mounted) {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/',
                        (_) => false,
                      );
                    }
                  },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: _busy
          ? const Center(child: CircularProgressIndicator())
          : pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            label: '타임라인',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_outline),
            label: '기념일',
          ),
          NavigationDestination(icon: Icon(Icons.place_outlined), label: '장소'),
        ],
      ),
      floatingActionButton: roomId == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () async {
                final text = await showDialog<String>(
                  context: context,
                  builder: (c) {
                    final ctrl = TextEditingController();
                    return AlertDialog(
                      title: const Text('글 쓰기'),
                      content: TextField(
                        controller: ctrl,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          hintText: '무엇을 기록할까요?',
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(c),
                          child: const Text('취소'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(c, ctrl.text.trim()),
                          child: const Text('등록'),
                        ),
                      ],
                    );
                  },
                );
                if (text != null && text.isNotEmpty) {
                  await widget.posts.createPost(roomId, text: text);
                  if (mounted) setState(() {});
                }
              },
              label: const Text('새 글'),
              icon: const Icon(Icons.add),
            ),
    );
  }
}
