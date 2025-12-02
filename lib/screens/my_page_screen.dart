import 'package:flutter/material.dart';
import 'package:fe/core/token_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/post_service.dart';
import 'chatbot_screen.dart';
import 'watering_history_screen.dart';
import 'my_posts_screen.dart';
import 'my_comments_screen.dart';

class MyPageScreen extends StatefulWidget {
  const MyPageScreen({super.key});

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  String? _nickname;
  String? _profileImageUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      final token = await TokenStorage.accessToken;
      if (token == null) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // 사용자 정보 조회 API 호출
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8080/api/user/plant'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _nickname = data['nickname'] as String?;
            _profileImageUrl = data['profileImageUrl'] as String?;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('사용자 정보 조회 에러: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFF0F8F0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('로그아웃'),
        content: const Text('정말 로그아웃하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // TODO: TokenStorage.clearTokens() 메서드가 있다면 사용
      // 토큰 삭제는 SharedPreferences에서 직접 삭제하거나
      // TokenStorage에 clearTokens 메서드가 있다면 사용

      if (!mounted) return;

      // 로그인 화면으로 이동
      // 모든 화면을 제거하고 루트로 이동
      Navigator.of(context).popUntil((route) => route.isFirst);
      // 또는 Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('로그아웃에 실패했습니다: ${e.toString()}')),
      );
    }
  }

  Future<void> _handleWithdrawal() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFF0F8F0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('회원탈퇴'),
        content: const Text('정말 회원탈퇴하시겠습니까?\n모든 데이터가 삭제되며 복구할 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('탈퇴'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // TODO: 회원탈퇴 API 호출
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('회원탈퇴 기능은 준비 중입니다.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          '마이페이지',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          children: [
            // 프로필 섹션
            _buildProfileSection(),
            const SizedBox(height: 24),
            // 메뉴 섹션
            _buildMenuSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          // 프로필 이미지
          CircleAvatar(
            radius: 40,
            backgroundColor: const Color(0xFF6AA84F),
            backgroundImage: _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                ? NetworkImage(_profileImageUrl!)
                : null,
            child: _profileImageUrl == null || _profileImageUrl!.isEmpty
                ? Text(
              _nickname != null && _nickname!.isNotEmpty
                  ? _nickname![0].toUpperCase()
                  : 'U',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            )
                : null,
          ),
          const SizedBox(width: 16),
          // 닉네임
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _nickname ?? '사용자',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: () {
                    // TODO: 프로필 수정 화면으로 이동
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    '프로필 수정',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6AA84F),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection() {
    return Column(
      children: [
        _buildMenuItem(
          icon: Icons.chat_bubble_outline,
          title: 'AI 챗봇 이용하기',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ChatbotScreen(),
              ),
            );
          },
        ),
        _buildDivider(),
        _buildMenuItem(
          icon: Icons.water_drop_outlined,
          title: '물주기 이력',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const WateringHistoryScreen(),
              ),
            );
          },
        ),
        _buildDivider(),
        _buildMenuItem(
          icon: Icons.article_outlined,
          title: '내가 쓴 게시글',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const MyPostsScreen(),
              ),
            );
          },
        ),
        _buildDivider(),
        _buildMenuItem(
          icon: Icons.comment_outlined,
          title: '내가 쓴 댓글',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const MyCommentsScreen(),
              ),
            );
          },
        ),
        _buildDivider(),
        _buildMenuItem(
          icon: Icons.description_outlined,
          title: '개인정보제공이용동의',
          onTap: () {
            // TODO: 개인정보제공이용동의 화면으로 이동
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('개인정보제공이용동의 기능은 준비 중입니다.')),
            );
          },
        ),
        _buildDivider(),
        _buildMenuItem(
          icon: Icons.person_remove_outlined,
          title: '회원탈퇴',
          onTap: _handleWithdrawal,
          textColor: Colors.red,
        ),
        _buildDivider(),
        _buildMenuItem(
          icon: Icons.logout,
          title: '로그아웃',
          onTap: _handleLogout,
          textColor: Colors.red,
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      thickness: 1,
      indent: 0,
      endIndent: 0,
      color: Color(0xFFE0E0E0),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        child: Row(
          children: [
            Icon(
              icon,
              color: textColor ?? Colors.black87,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  color: textColor ?? Colors.black87,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey[400],
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}

