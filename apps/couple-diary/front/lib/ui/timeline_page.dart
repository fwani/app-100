import 'package:flutter/material.dart';
import '../data/post_api.dart';
import '../models/post.dart';
import 'package:intl/intl.dart';

class TimelinePage extends StatefulWidget {
  final int? roomId;
  final PostApi posts;

  const TimelinePage({super.key, required this.roomId, required this.posts});

  @override
  State<TimelinePage> createState() => _TimelinePageState();
}

class _TimelinePageState extends State<TimelinePage> {
  late Future<List<Post>> _future;

  @override
  void didUpdateWidget(covariant TimelinePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.roomId != widget.roomId) {
      _future = _load();
    }
  }

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Post>> _load() async {
    if (widget.roomId == null) return [];
    return widget.posts.listPosts(widget.roomId!);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.roomId == null) {
      return const Center(child: Text('방을 먼저 생성하거나 참여하세요.'));
    }
    return RefreshIndicator(
      onRefresh: () async => setState(() => _future = _load()),
      child: FutureBuilder<List<Post>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snap.data ?? [];
          if (items.isEmpty) {
            return ListView(
              physics: AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: 240),
                Center(child: Text('첫 글을 작성해 보세요!')),
              ],
            );
          }
          final fmt = DateFormat('yyyy.MM.dd HH:mm');
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final p = items[i];
              return ListTile(
                title: p.text != null ? Text(p.text!) : const Text('(사진만)'),
                subtitle: Text(fmt.format(p.createdAt)),
                leading: const Icon(Icons.chat_bubble_outline),
              );
            },
          );
        },
      ),
    );
  }
}
