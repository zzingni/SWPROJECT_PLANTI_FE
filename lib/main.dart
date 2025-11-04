import 'dart:async';
import 'package:fe/screens/home_screen.dart';
import 'package:fe/screens/login_screen.dart';
import 'package:fe/screens/main_screen.dart';
import 'package:fe/screens/signup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'widgets/auth_button.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: _SplashGate(),
    );
  }
}

/// 앱 실행 시 자동 로그인 여부를 판별하는 스플래시 게이트
class _SplashGate extends StatefulWidget {
  const _SplashGate({super.key});

  @override
  State<_SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<_SplashGate> {
  final _storage = const FlutterSecureStorage();
  Future<bool>? _hasToken;

  @override
  void initState() {
    super.initState();
    _hasToken = _checkToken();
  }

  // 저장된 토큰 유무 확인
  Future<bool> _checkToken() async {
    // 실제 자동 로그인 확인용
    final access = await _storage.read(key: 'accessToken');
    return access != null && access.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _hasToken,
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final loggedIn = snap.data!;

        // 테스트용 코드: 로그인 없이 바로 HomeScreen 진입
        // 실제 배포 시엔 아래 주석 해제
        // return loggedIn ? const HomeScreen() : const LoginScreen();

        // return const HomeScreen(
        //   plantType: '다육이',
        //   plantName: '초록다육이주인',
        //   wateringCycle: 'week',
        //   optimalTemperature: 25,
        //   optimalHumidity: 43,
        // );
        return const MainScreen();
      },
    );
  }
}

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: 'Planti',
//       theme: ThemeData(
//         colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6AA84F)),
//         useMaterial3: true,
//       ),
//       home: const SplashOneScreen(),
//     );
//   }
// }

/// 공통 페이드 전환
Future<void> navigateWithFadeReplacement(BuildContext context, Widget page,
    {Duration transitionDuration = const Duration(milliseconds: 2000)}) async {
  Navigator.of(context).pushReplacement(PageRouteBuilder(
    transitionDuration: transitionDuration,
    pageBuilder: (_, animation, __) => FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
      child: page,
    ),
  ));
}

Future<void> navigateWithFadePush(BuildContext context, Widget page,
    {Duration transitionDuration = const Duration(milliseconds: 800)}) async {
  Navigator.of(context).push(PageRouteBuilder(
    transitionDuration: transitionDuration,
    pageBuilder: (_, animation, __) => FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
      child: page,
    ),
  ));
}

