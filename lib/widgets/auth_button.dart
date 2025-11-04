import 'package:flutter/material.dart';

/// 공통 인증 버튼 위젯
class AuthButton extends StatelessWidget {
  final String label;          // 버튼에 표시할 텍스트
  final Color color;           // 배경색
  final Color textColor;       // 텍스트 색상
  final Widget? leading;       // 아이콘이나 로고
  final VoidCallback onPressed; // 클릭 시 실행할 함수

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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
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
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}