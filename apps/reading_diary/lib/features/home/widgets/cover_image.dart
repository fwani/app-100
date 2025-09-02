import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class CoverImage extends StatefulWidget {
  final String? coverRef;
  final double width;
  final double height;

  const CoverImage(
      {super.key, required this.coverRef, this.width = 96, this.height = 128});

  @override
  State<CoverImage> createState() => _CoverImageState();
}

class _CoverImageState extends State<CoverImage> {
  late Future<ImageProvider?> _providerFuture;

  @override
  void initState() {
    super.initState();
    _providerFuture = _resolveProvider(widget.coverRef);
  }

  @override
  void didUpdateWidget(covariant CoverImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.coverRef != widget.coverRef) {
      _providerFuture = _resolveProvider(widget.coverRef);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: FutureBuilder<ImageProvider?>(
        future: _providerFuture,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return Container(
              width: widget.width,
              height: widget.height,
              color: Theme.of(context).colorScheme.surfaceVariant,
              child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2)),
            );
          }
          final provider = snap.data;
          if (provider == null) {
            return Container(
              width: widget.width,
              height: widget.height,
              color: Theme.of(context).colorScheme.surfaceVariant,
              child: const Icon(Icons.menu_book_outlined),
            );
          }
          return Image(
            image: provider,
            fit: BoxFit.cover,
            width: widget.width,
            height: widget.height,
          );
        },
      ),
    );
  }

  Future<ImageProvider?> _resolveProvider(String? ref) async {
    if (ref == null || ref.isEmpty) return null;

    if (ref.startsWith('http://') || ref.startsWith('https://')) {
      return NetworkImage(ref);
    }
    if (ref.startsWith('/') || ref.startsWith('file://')) {
      final path = ref.startsWith('file://') ? Uri.parse(ref).path : ref;
      return FileImage(File(path));
    }

    // 파일명만 저장된 경우
    try {
      final dir = await getApplicationDocumentsDirectory();
      return FileImage(File('${dir.path}/$ref'));
    } catch (_) {
      return null;
    }
  }
}
