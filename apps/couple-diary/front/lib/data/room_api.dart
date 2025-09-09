import 'api_client.dart';

class RoomApi {
  final ApiClient _c;
  RoomApi(this._c);

  Future<({int roomId, String code})> createRoom() async {
    final res = await _c.dio.post('/rooms');
    return (roomId: res.data['room_id'] as int, code: res.data['code'] as String);
    }
  Future<void> joinRoom(String code) async {
    await _c.dio.post('/rooms/join/$code');
  }
}