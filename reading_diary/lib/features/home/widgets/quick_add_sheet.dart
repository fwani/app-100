import 'package:flutter/material.dart';
import '../../../models/book.dart';
import '../../../store/book_dao.dart';

class QuickAddSheet extends StatefulWidget {
  const QuickAddSheet({super.key});

  @override
  State<QuickAddSheet> createState() => _QuickAddSheetState();
}

class _QuickAddSheetState extends State<QuickAddSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _authorCtrl = TextEditingController();
  final _pagesCtrl = TextEditingController();
  BookStatus _status = BookStatus.reading;
  final _dao = BookDao();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _authorCtrl.dispose();
    _pagesCtrl.dispose();
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
              Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text('빠른 추가', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: '제목 *', border: OutlineInputBorder(), isDense: true,
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? '제목을 입력하세요' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _authorCtrl,
                decoration: const InputDecoration(
                  labelText: '저자 (선택)', border: OutlineInputBorder(), isDense: true,
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _pagesCtrl,
                decoration: const InputDecoration(
                  labelText: '총 페이지 (선택)', border: OutlineInputBorder(), isDense: true,
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<BookStatus>(
                value: _status,
                decoration: const InputDecoration(
                  labelText: '상태', border: OutlineInputBorder(), isDense: true,
                ),
                items: const [
                  DropdownMenuItem(value: BookStatus.reading, child: Text('읽는중')),
                  DropdownMenuItem(value: BookStatus.finished, child: Text('완독')),
                  DropdownMenuItem(value: BookStatus.paused, child: Text('보류')),
                ],
                onChanged: (v) => setState(() => _status = v ?? BookStatus.reading),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
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
                        await _dao.add(
                          title: _titleCtrl.text.trim(),
                          author: _authorCtrl.text.trim().isEmpty ? "작가 미상" : _authorCtrl.text.trim(),
                          totalPages: pages,
                          status: _status,
                        );
                        if (!mounted) return;
                        Navigator.pop(context, true);
                      },
                      child: const Text('추가'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}