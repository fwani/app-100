import '../models/post.dart';
import 'api_client.dart';

class PostApi {
  final ApiClient _c;
  PostApi(this._c);

  Future<List<Post>> listPosts(int roomId, {int limit = 30, int offset = 0}) async {
    final res = await _c.dio.get('/rooms/$roomId/posts', queryParameters: {
      'limit': limit,
      'offset': offset,
    });
    final List list = res.data;
    return list.map((e) => Post.fromJson(e)).toList();
  }

  Future<Post> createPost(int roomId, {String? text, List<String>? photos, String? mood}) async {
    final res = await _c.dio.post('/rooms/$roomId/posts', data: {
      'text': text,
      'photos': photos ?? <String>[],
      'mood': mood,
    });
    return Post.fromJson(res.data);
  }
}