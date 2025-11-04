import 'package:flutter/material.dart';
import '../main.dart';               // navigateWithFadePush 함수 가져오기
import '../widgets/auth_button.dart';
import 'signup_screen.dart';        // 회원가입 화면

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        title: const Text('회원가입'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 회원가입 버튼
              AuthButton(
                label: '회원가입',
                color: const Color(0xFF8FC57F),
                textColor: Colors.white,
                onPressed: () {
                  navigateWithFadePush(context, const SignUpScreen());
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}