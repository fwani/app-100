import 'package:flutter/material.dart';
import '../core/session.dart';
import '../data/auth_api.dart';

class LoginPage extends StatefulWidget {
  final Session session;
  final AuthApi auth;

  const LoginPage({super.key, required this.session, required this.auth});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _loading = false;
  String? _err;

  Future<void> _doLogin(bool register) async {
    setState(() {
      _loading = true;
      _err = null;
    });
    try {
      final t = register
          ? await widget.auth.register(_email.text.trim(), _pass.text)
          : await widget.auth.login(_email.text.trim(), _pass.text);
      await widget.session.setToken(t);
      if (mounted) setState(() {});
    } catch (e) {
      _err = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('로그인')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _email,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _pass,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            const SizedBox(height: 16),
            if (_err != null)
              Text(_err!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: _loading ? null : () => _doLogin(false),
                    child: const Text('로그인'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _loading ? null : () => _doLogin(true),
                    child: const Text('회원가입'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
