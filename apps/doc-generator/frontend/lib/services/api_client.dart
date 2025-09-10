import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  ApiClient({required this.baseUrl});

  final String baseUrl; // 예: http://127.0.0.1:8000
  Uri _u(String p) => Uri.parse('$baseUrl/api$p');

  // 모델 목록
  Future<List<String>> listModels() async {
    final res = await http.get(_u('/models'));
    if (res.statusCode != 200) {
      throw Exception('List models failed: ${res.statusCode} ${res.body}');
    }
    final data = jsonDecode(res.body) as List<dynamic>;
    return data
        .map((e) => e['name'] as String)
        .where((s) => s.isNotEmpty)
        .toList();
  }

  // 초안 생성 (M1)
  Future<String> generateOnce({
    required String prompt,
    required String category,
    double temperature = 0.7,
    int maxTokens = 1024,
    String? model,
  }) async {
    final res = await http.post(
      _u('/generate'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'prompt': prompt,
        'category': category,
        'temperature': temperature,
        'max_tokens': maxTokens,
        if (model != null) 'model': model,
        'stream': false,
      }),
    );
    if (res.statusCode != 200) {
      throw Exception('Generate failed: ${res.statusCode} ${res.body}');
    }
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    return j['content'] as String;
  }

  Stream<String> generateStream({
    required String prompt,
    required String category,
    double temperature = 0.7,
    int maxTokens = 1024,
    String? model,
  }) async* {
    final req = http.Request('POST', _u('/generate'))
      ..headers['Content-Type'] = 'application/json'
      ..body = jsonEncode({
        'prompt': prompt,
        'category': category,
        'temperature': temperature,
        'max_tokens': maxTokens,
        if (model != null) 'model': model,
        'stream': true,
      });
    final streamed = await http.Client().send(req);
    if (streamed.statusCode != 200) {
      final body = await streamed.stream.bytesToString();
      throw Exception('Stream failed: ${streamed.statusCode} $body');
    }
    yield* streamed.stream.transform(utf8.decoder);
  }

  // 문서 저장
  Future<int> createDocument({
    required String title,
    required String category,
    required String content,
  }) async {
    final res = await http.post(
      _u('/documents'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'title': title,
        'category': category,
        'content': content,
      }),
    );
    if (res.statusCode != 200) {
      throw Exception('create failed: ${res.statusCode} ${res.body}');
    }
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    return j['id'] as int;
  }

  // 문서 수정 (M2)
  Future<String> reviseOnce({
    required int documentId,
    required String instruction,
    String? target,
    double temperature = 0.5,
    int maxTokens = 1024,
    String? model,
  }) async {
    final res = await http.post(
      _u('/documents/$documentId/revise'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'instruction': instruction,
        if (target != null) 'target': target,
        'temperature': temperature,
        'max_tokens': maxTokens,
        if (model != null) 'model': model,
        'stream': false,
      }),
    );
    if (res.statusCode != 200) {
      throw Exception('revise failed: ${res.statusCode} ${res.body}');
    }
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    return j['content'] as String;
  }

  Stream<String> reviseStream({
    required int documentId,
    required String instruction,
    String? target,
    double temperature = 0.5,
    int maxTokens = 1024,
    String? model,
  }) async* {
    final req = http.Request('POST', _u('/documents/$documentId/revise'))
      ..headers['Content-Type'] = 'application/json'
      ..body = jsonEncode({
        'instruction': instruction,
        if (target != null) 'target': target,
        'temperature': temperature,
        'max_tokens': maxTokens,
        if (model != null) 'model': model,
        'stream': true,
      });
    final streamed = await http.Client().send(req);
    if (streamed.statusCode != 200) {
      final body = await streamed.stream.bytesToString();
      throw Exception('revise stream failed: ${streamed.statusCode} $body');
    }
    yield* streamed.stream.transform(utf8.decoder);
  }
}
