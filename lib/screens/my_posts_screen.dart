import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:fe/core/token_storage.dart';
import '../models/post.dart';
import '../services/post_service.dart';
import 'post_screen.dart';

class MyPostsScreen extends StatefulWidget {
  const MyPostsScreen({super.key});

  @override
  State<MyPostsScreen> createState() => _MyPostsScreenState();
}

class _MyPostsScreenState extends State<MyPostsScreen> {
  late PostService _postService;
  List<MyPost> _posts = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    const String baseUrl = 'http://10.0.2.2:8080';
    _postService = PostService(http.Client(), baseUrl: baseUrl);
    _loadPosts();
  }

  @override
  void dispose() {
    _postService.close();
    super.dispose();
  }

  Future<void> _loadPosts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await TokenStorage.accessToken;
      if (token == null) {
        if (!mounted) return;
        setState(() {
          _errorMessage = '로그인이 필요합니다.';
          _isLoading = false;
        });
        return;
      }

      final posts = await _postService.fetchMyPosts(
        accessToken: token,
      );

      if (!mounted) return;

      setState(() {
        _posts = posts;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = '게시글을 불러오는데 실패했습니다: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _navigateToPost(MyPost post) {
    // 게시글의 boardId를 알아야 하는데, MyPost 모델에 boardId가 없음
    // 일단 기본 boardId를 사용하거나, API에서 boardId를 포함해서 응답하도록 해야 함
    // 임시로 1을 사용 (실제로는 API 응답에 boardId가 포함되어야 함)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostScreen(
          postId: post.postId,
          boardId: 1, // TODO: API에서 boardId를 받아오도록 수정 필요
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          '내가 쓴 게시글',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPosts,
          ),
        ],
      ),
      body: _errorMessage != null
          ? SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 100),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadPosts,
                  child: const Text('다시 시도'),
                ),
              ],
            ),
          ),
        ),
      )
          : _posts.isEmpty && !_isLoading
          ? const Center(
        child: Text(
          '작성한 게시글이 없습니다.',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 16,
          ),
        ),
      )
          : RefreshIndicator(
        onRefresh: _loadPosts,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _posts.length,
          itemBuilder: (context, index) {
            final post = _posts[index];
            return _buildPostItem(post);
          },
        ),
      ),
    );
  }

  Widget _buildPostItem(MyPost post) {
    final dateFormat = DateFormat('yyyy/MM/dd HH:mm', 'ko_KR');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToPost(post),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 게시판 이름
                Row(
                  children: [
                    Icon(
                      Icons.article,
                      size: 16,
                      color: const Color(0xFF6AA84F),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      post.boardName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6AA84F),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // 게시글 제목
                Text(
                  post.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                // 작성 시간
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      dateFormat.format(post.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

