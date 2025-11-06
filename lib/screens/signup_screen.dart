import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _pwController = TextEditingController();
  final _nickController = TextEditingController();
  final _ageController = TextEditingController();

  String? _gender; // 'MALE' or 'FEMALE'

  @override
  void dispose() {
    _idController.dispose();
    _pwController.dispose();
    _nickController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  OutlineInputBorder _border(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: BorderSide(color: color, width: 1.2),
  );

  InputDecoration _decoration(String label, {String? helper}) {
    const green = Color(0xFF426D3F);
    return InputDecoration(
      labelText: label,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      enabledBorder: _border(const Color(0xFFD8DEE4)),
      focusedBorder: _border(green),
      border: _border(const Color(0xFFD8DEE4)),
      helperText: helper,
      helperMaxLines: 2,
    );
  }

  void _submit() async {
    if (_formKey.currentState?.validate() != true) return;
    if (_gender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('성별을 선택해주세요.')),
      );
      return;
    }

    // FCM 토큰 가져오기
    String? fcmToken;
    try {
      // fcm 토큰을 안전하게 가져오기 시도
      fcmToken = await FirebaseMessaging.instance.getToken();
      print("FCM Token: $fcmToken");
    } catch (e) {
      // 토큰 가져오기 실패 시 오류를 출력하지만 앱의 흐름은 막지 않음
      print("FCM 토큰을 가져오는 데 실패했습니다: $e");
      // fcmToken은 null 상태로 다음 로직을 진행합니다.
    }

    final url = Uri.parse('http://10.0.2.2:8080/api/auth/signup');
    final body = jsonEncode({
      "loginId": _idController.text.trim(),
      "password": _pwController.text.trim(),
      "nickname": _nickController.text.trim(),
      "gender": _gender,
      "age": int.parse(_ageController.text.trim()),
      "fcmToken": fcmToken, // 추가
    });

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // 배경을 흐리게 하는 오버레이 표시
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => PopScope(
            canPop: false,
            child: Stack(
              children: [
                // 흐린 배경
                Container(
                  color: Colors.black.withOpacity(0.3),
                  width: double.infinity,
                  height: double.infinity,
                ),
                // 중앙의 토스트 메시지
                Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4F7F43),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      '회원가입이 완료되었습니다!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.none,
                        decorationColor: Colors.transparent,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

        // 2초 후 전화면으로 돌아가기
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pop(context); // 토스트 닫기
            Navigator.pop(context); // 회원가입 화면에서 로그인 화면으로 돌아가기
          }
        });
      }

      else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류 발생: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('서버 연결 실패: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF4F7F43);
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            children: [
              const SizedBox(height: 8),
              Text(
                '반려식물과 함께\n행복한 삶을 꾸려나가요!',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                '*다른 목적으로 사용되거나 제3자에게 제공되지 않습니다.',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: const Color(0xFF8B95A1)),
              ),
              const SizedBox(height: 20),

              // 아이디
              TextFormField(
                controller: _idController,
                decoration: _decoration('아이디'),
                textInputAction: TextInputAction.next,
                validator: (v) =>
                (v == null || v.trim().isEmpty) ? '아이디를 입력해주세요.' : null,
              ),
              const SizedBox(height: 16),

              // 비밀번호
              TextFormField(
                controller: _pwController,
                obscureText: true,
                decoration: _decoration(
                  '비밀번호',
                  helper: '*특수문자(! - _ &! ^~) 포함 8~14자리로 입력해주세요',
                ),
                textInputAction: TextInputAction.next,
                validator: (v) {
                  final value = v ?? '';
                  if (value.length < 8 || value.length > 14) {
                    return '8~14자리로 입력해주세요.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 닉네임
              TextFormField(
                controller: _nickController,
                decoration: _decoration('닉네임'),
                textInputAction: TextInputAction.next,
                validator: (v) =>
                (v == null || v.trim().isEmpty) ? '닉네임을 입력해주세요.' : null,
              ),
              const SizedBox(height: 16),

              // 성별
              Text('성별', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _GenderChip(
                      label: '남자',
                      selected: _gender == 'MALE',
                      onTap: () => setState(() => _gender = 'MALE'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _GenderChip(
                      label: '여자',
                      selected: _gender == 'FEMALE',
                      onTap: () => setState(() => _gender = 'FEMALE'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 나이
              TextFormField(
                controller: _ageController,
                decoration: _decoration('나이'),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  if (n == null || n <= 0) return '올바른 나이를 입력해주세요.';
                  return null;
                },
              ),
              const SizedBox(height: 28),

              // 가입 버튼
              SizedBox(
                height: 52,
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _submit,
                  child: const Text(
                    '회원가입',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _GenderChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _GenderChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final border = BorderSide(
      color: selected ? const Color(0xFF4F7F43) : const Color(0xFFD8DEE4),
      width: 1.2,
    );
    final bg = selected ? const Color(0xFFE8F1E5) : Colors.white;
    final fg = selected ? const Color(0xFF4F7F43) : const Color(0xFF4B5563);

    return SizedBox(
      height: 44,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          side: border,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: onTap,
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}