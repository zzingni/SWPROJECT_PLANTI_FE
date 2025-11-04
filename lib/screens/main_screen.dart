import 'package:fe/screens/login_screen.dart';
import 'package:fe/screens/signup_screen.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'home_screen.dart'; // HomeScreen은 기존 파일 그대로 사용

class MainScreen extends StatelessWidget {
  /// 디버그 중 로그인/스플래시 건너뛰고 바로 Home으로 들어가려면 true
  final bool debugSkipLogin;
  const MainScreen({super.key, this.debugSkipLogin = false});

  @override
  Widget build(BuildContext context) {
    if (debugSkipLogin) {
      // 테스트용 진입 경로
      return const HomeScreen(
        plantType: '다육이',
        plantName: '다육이주인',
        wateringCycle: 'week',
        optimalTemperature: 25,
        optimalHumidity: 43,
      );
    }
    // 기본은 스플래시 → 인증 화면 플로우
    return const SplashOneScreen();
  }
}

/// 1번째 화면
class SplashOneScreen extends StatefulWidget {
  const SplashOneScreen({super.key});

  @override
  State<SplashOneScreen> createState() => _SplashOneScreenState();
}

class _SplashOneScreenState extends State<SplashOneScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 1), () {
      navigateWithFadeReplacement(context, const SplashTwoScreen());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/main.png',
                width: 700,
                height: 700,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

/// 2번째 화면 (로딩 로고만 있는 화면)
class SplashTwoScreen extends StatefulWidget {
  const SplashTwoScreen({super.key});

  @override
  State<SplashTwoScreen> createState() => _SplashTwoScreenState();
}

class _SplashTwoScreenState extends State<SplashTwoScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 1), () {
      navigateWithFadeReplacement(context, const AuthScreen());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Image.asset(
            'assets/images/title.png',
            width: 322,
            height: 203,
          ),
        ),
      ),
    );
  }
}

/// 3번째 화면 (로그인/회원가입 버튼)
class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/login.png',
                width: 443,
                height: 443,
              ),
              const SizedBox(height: 36),
              AuthButton(
                label: '로그인',
                color: const Color(0xFF6AA84F),
                textColor: Colors.white,
                onPressed: () {
                  navigateWithFadePush(context, const LoginScreen());
                },
              ),
              const SizedBox(height: 12),
              AuthButton(
                label: '회원가입',
                color: const Color(0xFF6AA84F),
                textColor: Colors.white,
                onPressed: () {
                  navigateWithFadePush(context, const SignUpScreen());
                },
              ),
              const SizedBox(height: 12),
              AuthButton(
                label: '카카오 로그인',
                color: const Color(0xFFFFE812),
                textColor: Colors.black87,
                leading: const Icon(Icons.chat_bubble_rounded, color: Colors.black87),
                onPressed: () async {
                  final uri = Uri.parse('http://10.200.53.36:8080/oauth2/authorization/kakao');
                  try {
                    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
                    if (!ok) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('카카오 로그인 페이지를 열 수 없습니다.')),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('오류 발생: $e')),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AuthButton extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  final Widget? leading;
  final VoidCallback onPressed;

  const AuthButton({
    super.key,
    required this.label,
    required this.color,
    required this.textColor,
    required this.onPressed,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

// 네비게이션 함수들
void navigateWithFadeReplacement(BuildContext context, Widget screen) {
  Navigator.of(context).pushReplacement(
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => screen,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 300),
    ),
  );
}

void navigateWithFadePush(BuildContext context, Widget screen) {
  Navigator.of(context).push(
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => screen,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 300),
    ),
  );
}
