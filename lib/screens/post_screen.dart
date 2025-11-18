import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:fe/core/token_storage.dart';
import '../models/post.dart' show Post, PostDetail, Comment;
import '../services/post_service.dart';
import 'create_post_screen.dart';

class PostScreen extends StatefulWidget {
  final int postId;
  final int boardId;

  const PostScreen({
    super.key,
    required this.postId,
    required this.boardId,
  });

  @override
  State<PostScreen> createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen> {
  late PostService _postService;
  PostDetail? _postDetail;
  bool _isLoading = true;
  String? _errorMessage;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    const String baseUrl = 'http://10.0.2.2:8080'; // 안드로이드 에뮬레이터용
    _postService = PostService(http.Client(), baseUrl: baseUrl);
    _loadPostDetail();
  }

  @override
  void dispose() {
    _postService.close();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadPostDetail() async {
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

      final postDetail = await _postService.fetchPostDetail(
        postId: widget.postId,
        boardId: widget.boardId,
        accessToken: token,
      );

      if (!mounted) return;

      // 백엔드에서 isOwner를 보내주지 않는 경우를 대비해
      // 현재 사용자 ID와 게시글 작성자 ID를 비교해서 owner 판단
      final currentUserId = extractUserIdFromToken(token);
      final isOwner = currentUserId != null && currentUserId == postDetail.userId;

      // 디버깅: owner 판단 로직 확인
      print('PostScreen._loadPostDetail - currentUserId: $currentUserId (타입: ${currentUserId.runtimeType})');
      print('PostScreen._loadPostDetail - postDetail.userId: ${postDetail.userId} (타입: ${postDetail.userId.runtimeType})');
      print('PostScreen._loadPostDetail - isOwner 계산: $isOwner');

      // 좋아요 개수가 0이면 무조건 좋아요를 누르지 않은 상태로 설정
      var finalPostDetail = postDetail.likeCount == 0
          ? postDetail.copyWith(isLiked: false, owner: isOwner)
          : postDetail.copyWith(owner: isOwner);

      // 디버깅: 최종 상태 확인
      print('PostScreen._loadPostDetail - 최종 owner: ${finalPostDetail.owner}');
      print('PostScreen._loadPostDetail - likeCount: ${finalPostDetail.likeCount}, isLiked: ${finalPostDetail.isLiked}');

      setState(() {
        _postDetail = finalPostDetail;
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

  Future<void> _deletePost() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFF0F8F0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('게시글 삭제'),
        content: const Text('정말 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final token = await TokenStorage.accessToken;
      if (token == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('로그인이 필요합니다.')),
        );
        return;
      }

      await _postService.deletePost(
        postId: widget.postId,
        accessToken: token,
      );

      if (!mounted) return;

      // 삭제 성공 시 목록으로 돌아가기 (true는 삭제됨을 의미)
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('게시글 삭제에 실패했습니다: ${e.toString()}')),
      );
    }
  }

  Future<void> _editPost() async {
    if (_postDetail == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreatePostScreen(
          boardId: widget.boardId,
          boardName: widget.boardId == 1 ? '자랑게시판' : widget.boardId == 2 ? '궁금해요' : '정보게시판',
          postId: _postDetail!.postId,
          initialTitle: _postDetail!.title,
          initialContent: _postDetail!.content,
        ),
      ),
    );

    // 수정 성공 시 게시글 상세 정보 새로고침
    if (result == true && mounted) {
      _loadPostDetail();
    }
  }

  Future<void> _addComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    try {
      final token = await TokenStorage.accessToken;
      if (token == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('로그인이 필요합니다.')),
        );
        return;
      }

      await _postService.createComment(
        postId: widget.postId,
        content: content,
        accessToken: token,
      );

      if (!mounted) return;

      _commentController.clear();

      // 댓글 작성 후 게시글 상세 정보 새로고침
      _loadPostDetail();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('댓글이 작성되었습니다.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('댓글 작성에 실패했습니다: ${e.toString()}')),
      );
    }
  }

  Future<void> _toggleLike() async {
    if (_postDetail == null) return;

    // 낙관적 업데이트: 즉시 UI 업데이트
    final previousIsLiked = _postDetail!.isLiked;
    final previousLikeCount = _postDetail!.likeCount;

    setState(() {
      _postDetail = _postDetail!.copyWith(
        isLiked: !previousIsLiked,
        likeCount: previousIsLiked
            ? previousLikeCount - 1
            : previousLikeCount + 1,
      );
    });

    try {
      final token = await TokenStorage.accessToken;
      if (token == null) {
        if (!mounted) return;
        // 토큰이 없으면 이전 상태로 롤백
        setState(() {
          _postDetail = _postDetail!.copyWith(
            isLiked: previousIsLiked,
            likeCount: previousLikeCount,
          );
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('로그인이 필요합니다.')),
        );
        return;
      }

      await _postService.toggleLike(
        postId: widget.postId,
        accessToken: token,
      );

      // 성공 시 상태는 이미 업데이트됨
      // 백엔드에서 최신 좋아요 개수를 받아오려면 _loadPostDetail()을 호출할 수 있지만,
      // 사용자 요청에 따라 좋아요 정보만 보내므로 낙관적 업데이트로 충분
    } catch (e) {
      if (!mounted) return;
      // 에러 발생 시 이전 상태로 롤백
      setState(() {
        _postDetail = _postDetail!.copyWith(
          isLiked: previousIsLiked,
          likeCount: previousLikeCount,
        );
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('좋아요 처리에 실패했습니다: ${e.toString()}')),
      );
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
        actions: () {
          // 디버깅: owner 값 확인
          final isOwner = _postDetail?.owner ?? false;
          print('PostScreen.build - AppBar actions 체크: owner=$isOwner');
          return isOwner
              ? [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _editPost,
              tooltip: '수정',
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deletePost,
              tooltip: '삭제',
              color: Colors.red,
            ),
          ]
              : null;
        }(),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadPostDetail,
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      )
          : _postDetail == null
          ? const Center(child: Text('게시글을 찾을 수 없습니다.'))
          : RefreshIndicator(
        onRefresh: _loadPostDetail,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 작성자 정보
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: const Color(0xFF6AA84F),
                          child: Text(
                            _postDetail!.nickname[0],
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _postDetail!.nickname,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                DateFormat('yyyy/MM/dd', 'ko_KR')
                                    .format(_postDetail!.createdAt),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // 제목
                    Text(
                      _postDetail!.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // 내용
                    Text(
                      _postDetail!.content,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // 이미지
                    if (_postDetail!.imageUrl != null &&
                        _postDetail!.imageUrl!.isNotEmpty)
                      Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            _getImageUrl(_postDetail!.imageUrl!),
                            width: 380,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 200,
                                width: 370,
                                color: Colors.grey[300],
                                child: const Icon(Icons.image,
                                    color: Colors.grey),
                              );
                            },
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                    // 좋아요
                    Builder(
                      builder: (context) {
                        // 디버깅: UI 렌더링 시 값 확인
                        print('PostScreen.build - 좋아요 UI 렌더링: isLiked=${_postDetail!.isLiked}, likeCount=${_postDetail!.likeCount}');
                        return InkWell(
                          onTap: _toggleLike,
                          child: Row(
                            children: [
                              Icon(
                                _postDetail!.isLiked
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: _postDetail!.isLiked
                                    ? Colors.red
                                    : Colors.grey,
                                size: 20,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${_postDetail!.likeCount}',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),
                    // 댓글 헤더
                    Row(
                      children: [
                        const Text(
                          '댓글',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_postDetail!.comments.length}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6AA84F),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // 댓글 목록
                    if (_postDetail!.comments.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Center(
                          child: Text(
                            '댓글이 없습니다.',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      )
                    else
                      ..._postDetail!.comments.map((comment) =>
                          _buildCommentItem(comment)),
                    const SizedBox(height: 16), // 하단 여백 추가
                  ],
                ),
              ),
            ),
            // 댓글 입력창
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
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
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          decoration: InputDecoration(
                            hintText: '댓글을 입력하세요',
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          maxLines: null,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: IconButton(
                          onPressed: _addComment,
                          icon: const Icon(Icons.send),
                          color: const Color(0xFF6AA84F),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentItem(Comment comment) {
    final dateFormat = DateFormat('yyyy/MM/dd HH:mm', 'ko_KR');
    // 댓글 작성자가 게시글 작성자인지 확인
    final isPostOwner = _postDetail != null &&
        comment.userId == _postDetail!.userId;
    // 본인이 작성한 댓글인지 확인
    final isMyComment = comment.owner;

    return GestureDetector(
      onLongPress: isMyComment ? () => _showCommentActionDialog(comment) : null,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF6AA84F),
              child: Text(
                comment.nickname[0],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        comment.nickname,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (isPostOwner) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6AA84F),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '작성자',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    comment.content,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateFormat.format(comment.createdAt),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCommentActionDialog(Comment comment) async {
    final action = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFF0F8F0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('댓글'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: Color(0xFF6AA84F)),
              title: const Text('수정'),
              onTap: () => Navigator.pop(context, 'edit'),
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('삭제'),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
        ],
      ),
    );

    if (action == 'edit') {
      _showEditCommentDialog(comment);
    } else if (action == 'delete') {
      _showDeleteCommentDialog(comment);
    }
  }

  Future<void> _showEditCommentDialog(Comment comment) async {
    final TextEditingController editController = TextEditingController(text: comment.content);

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFF0F8F0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('댓글 수정'),
        content: TextField(
          controller: editController,
          decoration: const InputDecoration(
            hintText: '댓글을 입력하세요',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, editController.text.trim()),
            child: const Text('수정'),
          ),
        ],
      ),
    );

    if (result == null || result.isEmpty) return;

    try {
      final token = await TokenStorage.accessToken;
      if (token == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('로그인이 필요합니다.')),
        );
        return;
      }

      await _postService.updateComment(
        commentId: comment.commentId,
        content: result,
        accessToken: token,
      );

      if (!mounted) return;

      // 댓글 수정 후 게시글 상세 정보 새로고침
      _loadPostDetail();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('댓글이 수정되었습니다.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('댓글 수정에 실패했습니다: ${e.toString()}')),
      );
    }
  }

  Future<void> _showDeleteCommentDialog(Comment comment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFF0F8F0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('댓글 삭제'),
        content: const Text('정말 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final token = await TokenStorage.accessToken;
      if (token == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('로그인이 필요합니다.')),
        );
        return;
      }

      await _postService.deleteComment(
        commentId: comment.commentId,
        accessToken: token,
      );

      if (!mounted) return;

      // 댓글 삭제 후 게시글 상세 정보 새로고침
      _loadPostDetail();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('댓글이 삭제되었습니다.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('댓글 삭제에 실패했습니다: ${e.toString()}')),
      );
    }
  }

  String _getImageUrl(String imagePath) {
    if (imagePath.startsWith('http')) {
      return imagePath;
    }
    const String baseUrl = 'http://10.0.2.2:8080';
    return '$baseUrl$imagePath';
  }
}

