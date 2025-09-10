import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'services/api_client.dart';

void main() => runApp(const DocGenApp());

class DocGenApp extends StatelessWidget {
  const DocGenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DocGen – 대화형 편집',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _api = ApiClient(
    baseUrl: const String.fromEnvironment(
      'API_BASE',
      defaultValue: 'http://127.0.0.1:8000',
    ),
  );

  // 상태
  final _inputCtrl = TextEditingController();
  final List<_Msg> _messages = [];
  StreamSubscription<String>? _sub;
  bool _loading = false;

  // 문서 컨텍스트
  int? _docId; // null이면 생성 모드, 있으면 수정 모드
  String _category = 'blog';

  // 공통 옵션
  String? _model;
  List<String> _models = [];
  double _temperature = 0.7;
  double _maxTokens = 1024;
  bool _stream = true; // 생성/수정 공통
  bool _unlimited = false;

  @override
  void initState() {
    super.initState();
    _loadModels();
  }

  Future<void> _loadModels() async {
    try {
      final list = await _api.listModels();
      setState(() {
        _models = list;
        _model ??= _models.isNotEmpty ? _models.first : null;
      });
    } catch (_) {
      setState(() => _models = []);
    }
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _sub?.cancel();
    super.dispose();
  }

  // [대상: ...] 파싱
  (String? target, String instruction) _parseTargetInstruction(String raw) {
    final re = RegExp(r'^\s*\[\s*대상\s*:\s*([^\]]+)\]\s*(.*)$');
    final m = re.firstMatch(raw);
    if (m != null) {
      return (m.group(1)!.trim(), (m.group(2) ?? '').trim());
    }
    return (null, raw.trim());
  }

  String _titleFrom(String md) {
    final first = RegExp(r'^\s*#\s+(.+)$', multiLine: true).firstMatch(md);
    return (first?.group(1) ?? '초안').trim();
  }

  Future<void> _send() async {
    final raw = _inputCtrl.text.trim();
    if (raw.isEmpty || _loading) return;

    setState(() {
      _loading = true;
      _messages.add(_Msg.user(raw));
      _messages.add(_Msg.assistant(''));
    });

    try {
      if (_docId == null) {
        // 생성 모드
        if (_stream) {
          final idx = _messages.length - 1;
          _sub = _api
              .generateStream(
                prompt: raw,
                category: _category,
                temperature: _temperature,
                maxTokens: _maxTokens.toInt(),
                model: _model,
              )
              .listen(
                (chunk) => setState(
                  () => _messages[idx] = _messages[idx].append(chunk),
                ),
                onDone: () async {
                  final content = _messages[idx].text;
                  final id = await _api.createDocument(
                    title: _titleFrom(content),
                    category: _category,
                    content: content,
                  );
                  setState(() {
                    _docId = id;
                    _loading = false;
                  });
                },
                onError: (e) => setState(() {
                  _messages.add(_Msg.system('에러: $e'));
                  _loading = false;
                }),
              );
        } else {
          final content = await _api.generateOnce(
            prompt: raw,
            category: _category,
            temperature: _temperature,
            maxTokens: _maxTokens.toInt(),
            model: _model,
          );
          setState(
            () => _messages[_messages.length - 1] = _messages.last.replace(
              content,
            ),
          );
          final id = await _api.createDocument(
            title: _titleFrom(content),
            category: _category,
            content: content,
          );
          setState(() {
            _docId = id;
            _loading = false;
          });
        }
      } else {
        // 수정 모드
        final (target, inst) = _parseTargetInstruction(raw);
        if (_stream) {
          final idx = _messages.length - 1;
          _sub = _api
              .reviseStream(
                documentId: _docId!,
                instruction: inst,
                target: target,
                temperature: 0.5,
                maxTokens: 1024,
                model: _model,
              )
              .listen(
                (chunk) => setState(
                  () => _messages[idx] = _messages[idx].append(chunk),
                ),
                onDone: () => setState(() => _loading = false),
                onError: (e) => setState(() {
                  _messages.add(_Msg.system('수정 실패: $e'));
                  _loading = false;
                }),
              );
        } else {
          final content = await _api.reviseOnce(
            documentId: _docId!,
            instruction: inst,
            target: target,
            temperature: 0.5,
            maxTokens: 1024,
            model: _model,
          );
          setState(() {
            _messages[_messages.length - 1] = _messages.last.replace(content);
            _loading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _messages.add(_Msg.system('에러: $e'));
        _loading = false;
      });
    } finally {
      _inputCtrl.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final left = SizedBox(
      width: 320,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('카테고리', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'article', label: Text('기사')),
              ButtonSegment(value: 'blog', label: Text('블로그')),
              ButtonSegment(value: 'novel', label: Text('소설')),
            ],
            selected: <String>{_category},
            onSelectionChanged: (s) => setState(() => _category = s.first),
          ),
          const SizedBox(height: 16),
          const Text('모델 선택'),
          InputDecorator(
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: _model,
                hint: const Text('모델 목록 불러오는 중...'),
                items: _models
                    .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                    .toList(),
                onChanged: (v) => setState(() => _model = v),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Temperature'),
          Slider(
            min: 0.0,
            max: 1.5,
            divisions: 15,
            value: _temperature,
            label: _temperature.toStringAsFixed(2),
            onChanged: (v) => setState(() => _temperature = v),
          ),
          const SizedBox(height: 8),
          const Text('Max tokens'),
          Slider(
            min: 32,
            max: 8192,
            divisions: 256,
            value: _maxTokens,
            label: _maxTokens.toInt().toString(),
            onChanged: (v) => setState(() => _maxTokens = v),
          ),
          SwitchListTile(
            title: const Text('무제한(모델이 멈출 때까지)'),
            value: _unlimited,
            onChanged: (v) => setState(() => _unlimited = v),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('스트리밍(생성/수정 공통)'),
            value: _stream,
            onChanged: (v) => setState(() => _stream = v),
          ),
          const SizedBox(height: 8),
          ListTile(
            title: Text(_docId == null ? '대화 모드: 생성' : '대화 모드: 수정'),
            subtitle: Text(
              _docId == null ? '첫 응답 완료 시 자동 저장' : '문서 ID: $_docId (자동 이력 저장)',
            ),
          ),
        ],
      ),
    );

    final right = Expanded(
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, i) {
                final m = _messages[i];
                final isUser = m.role == 'user';
                final bubbleColor = isUser
                    ? Colors.indigo.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.08);
                return Align(
                  alignment: isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.all(12),
                    constraints: const BoxConstraints(maxWidth: 900),
                    decoration: BoxDecoration(
                      color: bubbleColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: isUser
                        ? Text(m.text)
                        : MarkdownBody(
                            selectable: true,
                            data: m.text.isEmpty ? '…생성 중' : m.text,
                          ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputCtrl,
                    minLines: 1,
                    maxLines: 6,
                    decoration: const InputDecoration(
                      hintText: '프롬프트 또는 [대상: …] 수정 지시를 입력하세요',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: _loading ? null : _send,
                  icon: _loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  label: const Text('보내기'),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('DocGen – 대화형 편집 (M2)'),
        actions: [
          IconButton(
            tooltip: '대화 초기화',
            onPressed: () => setState(() {
              _messages.clear();
              _docId = null;
            }),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: Row(children: [left, const VerticalDivider(width: 1), right]),
    );
  }
}

class _Msg {
  final String role; // 'user' | 'assistant' | 'system'
  final String text;

  const _Msg._(this.role, this.text);

  factory _Msg.user(String t) => _Msg._('user', t);

  factory _Msg.assistant(String t) => _Msg._('assistant', t);

  factory _Msg.system(String t) => _Msg._('system', t);

  _Msg replace(String t) => _Msg._(role, t);

  _Msg append(String t) => _Msg._(role, text + t);
}
