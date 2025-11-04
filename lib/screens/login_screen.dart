import 'package:fe/core/token_storage.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  final TokenStorage tokenStorage;
  const LoginScreen({super.key, required this.tokenStorage});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _pwController = TextEditingController();
  final _secure = const FlutterSecureStorage();
  bool _loading = false;

  static const Color _green = Color(0xFF426D3F);
  static const Color _borderGray = Color(0xFFD8DEE4);

  OutlineInputBorder _outline(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: BorderSide(color: color, width: 1.2),
  );

  void _submit() async {
    if (_formKey.currentState?.validate() != true) return;
    FocusScope.of(context).unfocus();

    setState(() => _loading = true);
    try {
      // 1) 로그인 API 호출 (JSON 로그인)
      final url = Uri.parse('http://10.0.2.2:8080/api/auth/login');
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'loginId': _idController.text.trim(),
          'password': _pwController.text.trim(),
        }),
      );

      if (res.statusCode != 200) {
        throw Exception('status=${res.statusCode} body=${res.body}');
      }

      // 2) 액세스 토큰 파싱/저장
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final access = (data['accessToken'] ?? data['token']) as String?;
      final refresh = data['refreshToken'] as String?;
      if (access == null || access.isEmpty) {
        throw Exception('accessToken 누락');
      }
      await _secure.write(key: 'accessToken', value: access);
      if (refresh != null) {
        await _secure.write(key: 'refreshToken', value: refresh);
      }

      // 3) 홈 화면으로 이동 (이전 스택 모두 제거)
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => HomeScreen(tokenStorage: widget.tokenStorage),
          ),
              (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('로그인에 실패했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            children: [
              const SizedBox(height: 24),
              Center(
                child: Text(
                  'LOGIN',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(height: 48),

              // 아이디
              Text('아이디', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              TextFormField(
                controller: _idController,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  enabledBorder: _outline(_borderGray),
                  focusedBorder: _outline(_green),
                  border: _outline(_borderGray),
                ),
                validator: (v) =>
                (v == null || v.trim().isEmpty) ? '아이디를 입력해주세요.' : null,
              ),
              const SizedBox(height: 20),

              // 비밀번호
              Text('비밀번호', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              TextFormField(
                controller: _pwController,
                obscureText: true,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFF2F6F9),
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  enabledBorder: _outline(_borderGray),
                  focusedBorder: _outline(_green),
                  border: _outline(_borderGray),
                ),
                validator: (v) =>
                (v == null || v.isEmpty) ? '비밀번호를 입력해주세요.' : null,
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 56),

              // 로그인 버튼
              SizedBox(
                height: 52,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shadowColor: Colors.black.withOpacity(0.25),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    '로그인',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}