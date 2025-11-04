import 'package:flutter/material.dart';

import '../core/auth_service.dart';
import '../core/token_storage.dart';
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
  bool _loading = false;

  static const Color _green = Color(0xFF426D3F);

  void _submit() async {
    if (_formKey.currentState?.validate() != true) return;
    FocusScope.of(context).unfocus();

    setState(() => _loading = true);
    try {
      await AuthService.handleLogin(
        _idController.text.trim(),
        _pwController.text.trim(),
      );

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
            padding: const EdgeInsets.all(24),
            children: [
              const SizedBox(height: 48),
              TextFormField(
                controller: _idController,
                decoration: const InputDecoration(labelText: '아이디'),
                validator: (v) => (v == null || v.isEmpty) ? '아이디를 입력해주세요.' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _pwController,
                obscureText: true,
                decoration: const InputDecoration(labelText: '비밀번호'),
                validator: (v) => (v == null || v.isEmpty) ? '비밀번호를 입력해주세요.' : null,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(backgroundColor: _green),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('로그인'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
