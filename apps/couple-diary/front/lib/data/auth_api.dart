import 'package:dio/dio.dart';
import 'api_client.dart';

class AuthApi {
  final ApiClient _c;
  AuthApi(this._c);

  Future<String> register(String email, String password, {String? name}) async {
    final res = await _c.dio.post('/auth/register', data: {
      "email": email,
      "password": password,
      "display_name": name
    });
    return res.data['access_token'];
  }

  Future<String> login(String email, String password) async {
    final res = await _c.dio.post('/auth/login',
        data: {'username': email, 'password': password},
        options: Options(contentType: Headers.formUrlEncodedContentType));
    return res.data['access_token'];
  }
}