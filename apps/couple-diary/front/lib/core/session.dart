import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class Session extends ChangeNotifier {
  final _storage = const FlutterSecureStorage();

  String? _token;
  int? _roomId;

  String? get token => _token;
  int? get roomId => _roomId;
  bool get isAuthed => _token != null;

  Future<void> load() async {
    _token = await _storage.read(key: 'token');
    final room = await _storage.read(key: 'roomId');
    _roomId = room != null ? int.tryParse(room) : null;
    notifyListeners();
  }

  Future<void> setToken(String? t) async {
    _token = t;
    if (t == null) {
      await _storage.delete(key: 'token');
    } else {
      await _storage.write(key: 'token', value: t);
    }
    notifyListeners();
  }

  Future<void> setRoomId(int? id) async {
    _roomId = id;
    if (id == null) {
      await _storage.delete(key: 'roomId');
    } else {
      await _storage.write(key: 'roomId', value: id.toString());
    }
    notifyListeners();
  }

  Future<void> signOut() async {
    await setToken(null);
    await setRoomId(null);
  }
}