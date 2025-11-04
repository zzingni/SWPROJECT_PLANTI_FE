import 'dart:async';
import 'package:fe/screens/home_screen.dart';
import 'package:fe/screens/login_screen.dart';
import 'package:fe/screens/plant_name_input_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'core/token_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final storage = FlutterSecureStorage();
  await storage.deleteAll();

  // 앱 시작 시 FCM 토큰 가져오기
  try {
    String? token = await FirebaseMessaging.instance.getToken();
  } catch (e) {
    print('FCM token error: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashGate(),
    );
  }
}

/// 앱 실행 시 자동 로그인 여부 + 사용자 반려식물 여부 판별
class SplashGate extends StatefulWidget {
  const SplashGate({super.key});

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  final _storage = const FlutterSecureStorage();
  late final TokenStorage _tokenStorage;
  late Future<Widget> _startScreen;

  @override
  void initState() {
    super.initState();
    _tokenStorage = TokenStorage();
    _startScreen = _determineStartScreen();
  }

  Future<Widget> _determineStartScreen() async {
    final access = await _storage.read(key: 'accessToken');
    if (access == null || access.isEmpty) {
      // 토큰 없으면 로그인 화면
      return LoginScreen(tokenStorage: _tokenStorage);
    }

    // 토큰 있으면 저장
    await TokenStorage.saveTokens(accessToken: access);

    try {
      // 백엔드 호출해서 사용자 반려식물 존재 여부 확인
      const apiUrl = 'http://10.0.2.2:8080/api/user-plants/me'; // 예시 엔드포인트
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $access',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        if (data.isNotEmpty) {
          // 반려식물 존재 → HomeScreen
          final plant = data.first;
          return HomeScreen(
            tokenStorage: _tokenStorage,
            nickname: plant['plantNickName'],
          );
        } else {
          // 반려식물 없음 → 이름 입력 화면
          return PlantNameInputScreen(
            selectedPlantId: 0, // 기본값, 사용자가 선택 후 바뀜
            tokenStorage: _tokenStorage,
          );
        }
      } else {
        // API 호출 실패 → 로그인 화면
        return LoginScreen(tokenStorage: _tokenStorage);
      }
    } catch (e) {
      // 오류 발생 시 로그인 화면
      return LoginScreen(tokenStorage: _tokenStorage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _startScreen,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return snapshot.data!;
      },
    );
  }
}

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

