import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fe/core/token_storage.dart';
import '../services/post_service.dart';

class CreatePostScreen extends StatefulWidget {
  final int boardId;
  final String boardName;
  final int? postId; // 수정 모드일 때 게시글 ID
  final String? initialTitle; // 수정 모드일 때 초기 제목
  final String? initialContent; // 수정 모드일 때 초기 내용

  const CreatePostScreen({
    super.key,
    required this.boardId,
    required this.boardName,
    this.postId,
    this.initialTitle,
    this.initialContent,
  });

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  late PostService _postService;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  bool _isSubmitting = false;

  // 게시판 목록
  final List<Map<String, dynamic>> _boards = [
    {'id': 1, 'name': '자랑게시판'},
    {'id': 2, 'name': '궁금해요'},
  ];

  late int _selectedBoardId;
  late String _selectedBoardName;

  @override
  void initState() {
    super.initState();
    const String baseUrl = 'http://10.0.2.2:8080'; // 안드로이드 에뮬레이터용
    _postService = PostService(http.Client(), baseUrl: baseUrl);

    // 초기값 설정
    _selectedBoardId = widget.boardId;
    _selectedBoardName = widget.boardName;

    // 수정 모드일 때 초기값 설정
    if (widget.initialTitle != null) {
      _titleController.text = widget.initialTitle!;
    }
    if (widget.initialContent != null) {
      _contentController.text = widget.initialContent!;
    }
  }

  @override
  void dispose() {
    _postService.close();
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submitPost() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('제목을 입력해주세요.')),
      );
      return;
    }

    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('내용을 입력해주세요.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final token = await TokenStorage.accessToken;
      if (token == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('로그인이 필요합니다.')),
        );
        setState(() {
          _isSubmitting = false;
        });
        return;
      }

      // 수정 모드인지 확인
      if (widget.postId != null) {
        // 게시글 수정 API 호출
        await _postService.updatePost(
          postId: widget.postId!,
          title: title,
          content: content,
          imageUrl: null, // 이미지 업로드는 나중에 구현
          accessToken: token,
        );
      } else {
        // 게시글 작성 API 호출
        await _postService.createPost(
          boardId: _selectedBoardId,
          title: title,
          content: content,
          imageUrl: null, // 이미지 업로드는 나중에 구현
          accessToken: token,
        );
      }

      if (!mounted) return;

      // 작성/수정 성공 시 이전 화면으로 돌아가기
      Navigator.pop(context, true); // true는 게시글이 작성/수정됨을 의미
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('게시글 작성에 실패했습니다: ${e.toString()}')),
      );
      setState(() {
        _isSubmitting = false;
      });
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
        title: Text(
          _selectedBoardName,
          style: const TextStyle(
            color: Color(0xFF6AA84F),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 수정 모드가 아닐 때만 게시판 선택 표시
            if (widget.postId == null) ...[
              const Text(
                '게시판',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (context) => Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: _boards.map((board) {
                          final isSelected = board['id'] == _selectedBoardId;
                          return ListTile(
                            title: Text(
                              board['name'] as String,
                              style: TextStyle(
                                color: isSelected ? const Color(0xFF6AA84F) : Colors.black87,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            trailing: isSelected
                                ? const Icon(
                              Icons.check,
                              color: Color(0xFF6AA84F),
                            )
                                : null,
                            onTap: () {
                              setState(() {
                                _selectedBoardId = board['id'] as int;
                                _selectedBoardName = board['name'] as String;
                              });
                              Navigator.pop(context);
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey[300]!,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _selectedBoardName,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.arrow_drop_down,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
            // 제목 입력
            const Text(
              '제목',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey[300]!,
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: '제목을 입력하세요',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // 내용 입력
            const Text(
              '내용',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 200),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey[300]!,
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _contentController,
                decoration: const InputDecoration(
                  hintText: '내용을 입력하세요',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                ),
                maxLines: null,
                minLines: 8,
              ),
            ),
            const SizedBox(height: 24),
            // 파일첨부 및 등록 버튼
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // TODO: 파일 첨부 기능
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      '파일첨부',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitPost,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6AA84F),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                        : Text(
                      widget.postId != null ? '완료' : '등록',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

