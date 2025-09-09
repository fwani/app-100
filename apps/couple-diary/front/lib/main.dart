import 'package:flutter/material.dart';
import 'core/session.dart';
import 'data/api_client.dart';
import 'data/auth_api.dart';
import 'data/room_api.dart';
import 'data/post_api.dart';
import 'ui/login_page.dart';
import 'ui/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final session = Session();
  await session.load();
  runApp(AppRoot(session));
}

class AppRoot extends StatefulWidget {
  final Session session;

  const AppRoot(this.session, {super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  late final ApiClient client;
  late final AuthApi auth;
  late final RoomApi rooms;
  late final PostApi posts;

  @override
  void initState() {
    super.initState();
    client = ApiClient(widget.session);
    auth = AuthApi(client);
    rooms = RoomApi(client);
    posts = PostApi(client);
    widget.session.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Couple Diary',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.pink),
      home: AuthGate(
        session: widget.session,
        buildHome: () =>
            HomePage(session: widget.session, posts: posts, rooms: rooms),
        buildLogin: () => LoginPage(session: widget.session, auth: auth),
      ),
    );
  }
}

/// 세션을 직접 구독해서 홈/로그인 전환
class AuthGate extends StatelessWidget {
  final Session session;
  final Widget Function() buildHome;
  final Widget Function() buildLogin;

  const AuthGate({
    super.key,
    required this.session,
    required this.buildHome,
    required this.buildLogin,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session, // 🔑 Session(ChangeNotifier) 구독
      builder: (context, _) {
        return session.isAuthed ? buildHome() : buildLogin();
      },
    );
  }
}
