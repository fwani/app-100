import 'package:flutter/material.dart';
import 'package:reading_diary/features/home/widgets/book_detail_screen.dart';
import '../../../models/book.dart';

class BookListTile extends StatelessWidget {
  final Book book;
  final VoidCallback? onTap;

  const BookListTile({super.key, required this.book, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: AspectRatio(
        aspectRatio: 3 / 4,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: book.coverUrl != null
              ? Image.network(book.coverUrl!, fit: BoxFit.cover)
              : Container(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  child: const Icon(Icons.menu_book_outlined),
                ),
        ),
      ),
      title: Text(book.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(book.author, maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(width: 8),
              _StatusBadge(status: book.status),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(value: book.progress),
        ],
      ),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final BookStatus status;

  const _StatusBadge({required this.status});

  String get label => switch (status) {
        BookStatus.reading => "읽는중",
        BookStatus.finished => "완독",
        BookStatus.paused => "보류",
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Theme.of(context).colorScheme.surfaceVariant,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall,
      ),
    );
  }
}
