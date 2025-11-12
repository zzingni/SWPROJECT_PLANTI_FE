import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fe/core/token_storage.dart';
import '../models/post.dart';
import '../services/post_service.dart';
import 'post_screen.dart';
import 'create_post_screen.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // 탭 변경 시 UI 업데이트
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabTap(int index) {
    // 네비게이션 바 탭 처리
    // 필요시 다른 화면으로 이동하는 로직 추가
    // 현재는 커뮤니티 화면(index 1)이므로 다른 탭을 눌러도 아무 동작 안 함
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 탭 바
            _buildTabBar(),
            // 탭 뷰
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  ShowOffBoardTab(), // 자랑게시판
                  QuestionBoardTab(), // 궁금해요
                  InformationBoardTab(), // 정보게시판
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _tabController.index != 2
          ? FloatingActionButton(
        onPressed: () {
          final boardId = _tabController.index == 0
              ? BoardIds.showOff
              : BoardIds.question;
          final boardName = _tabController.index == 0
              ? '자랑게시판'
              : '궁금해요';
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreatePostScreen(
                boardId: boardId,
                boardName: boardName,
              ),
            ),
          ).then((created) {
            // 게시글이 작성된 경우 목록 새로고침
            if (created == true) {
              // TODO: 현재 탭의 게시글 목록 새로고침
            }
          });
        },
        backgroundColor: const Color(0xFF6AA84F),
        child: const Icon(Icons.add, color: Colors.white),
      )
          : null,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: 1, // 커뮤니티가 선택된 상태
          onTap: (index) {
            // 네비게이션 처리
            if (index == 0) {
              // 홈으로 이동
              Navigator.of(context).popUntil((route) => route.isFirst);
            } else if (index == 1) {
              // 커뮤니티는 이미 현재 화면
            } else if (index == 2) {
              // 검색 화면으로 이동 (필요시 구현)
            } else if (index == 3) {
              // 마이페이지로 이동 (필요시 구현)
            }
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: Colors.black87,
          unselectedItemColor: Colors.grey,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: '홈',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people),
              label: '커뮤니티',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search),
              label: '검색',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: '마이페이지',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: const Color(0xFF6AA84F),
        unselectedLabelColor: Colors.grey,
        indicatorColor: const Color(0xFF6AA84F),
        indicatorWeight: 2,
        tabs: const [
          Tab(text: '자랑게시판'),
          Tab(text: '궁금해요'),
          Tab(text: '정보게시판'),
        ],
      ),
    );
  }
}

// 게시판 ID 상수
class BoardIds {
  static const int showOff = 1; // 자랑게시판
  static const int question = 2; // 궁금해요
  static const int information = 3; // 정보게시판
}

// 공통 게시글 목록 탭 (자랑게시판, 궁금해요 공통 사용)
class PostListTab extends StatefulWidget {
  final int boardId;
  final String boardName;

  const PostListTab({
    super.key,
    required this.boardId,
    required this.boardName,
  });

  @override
  State<PostListTab> createState() => _PostListTabState();
}

class _PostListTabState extends State<PostListTab> {
  late PostService _postService;
  List<Post> _posts = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _currentPage = 0;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    // baseUrl 설정 - 안드로이드 에뮬레이터의 경우 10.0.2.2 사용
    // 실제 디바이스나 iOS 시뮬레이터의 경우 localhost 사용
    // 실제 서버 배포 시 서버 주소로 변경
    const String baseUrl = 'http://10.0.2.2:8080'; // 안드로이드 에뮬레이터용
    // const String baseUrl = 'http://localhost:8080'; // iOS 시뮬레이터 또는 실제 디바이스용
    // const String baseUrl = 'http://43.202.149.234:8080'; // 실제 서버용
    _postService = PostService(http.Client(), baseUrl: baseUrl);
    _loadPosts();
  }

  @override
  void dispose() {
    _postService.close();
    super.dispose();
  }

  Future<void> _loadPosts({bool loadMore = false}) async {
    if (!loadMore) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _currentPage = 0;
      });
    } else {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      // 토큰 가져오기
      final token = await TokenStorage.accessToken;
      if (token == null) {
        if (!mounted) return;
        setState(() {
          _errorMessage = '로그인이 필요합니다.\n로그인 후 다시 시도해주세요.';
          _isLoading = false;
        });
        return;
      }

      final pageToLoad = loadMore ? _currentPage + 1 : 0;
      final response = await _postService.fetchPosts(
        boardId: widget.boardId,
        page: pageToLoad,
        size: 20,
        sortBy: 'createdAt',
        direction: 'DESC',
        accessToken: token,
      );

      if (!mounted) return;

      setState(() {
        if (loadMore) {
          _posts.addAll(response.content);
        } else {
          _posts = response.content;
        }
        _currentPage = response.page;
        _hasMore = !response.last;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e, stackTrace) {
      if (!mounted) return;
      // 에러 로깅
      print('게시글 로드 에러: $e');
      print('스택 트레이스: $stackTrace');

      String errorMsg = '게시글을 불러오는데 실패했습니다.';
      if (e.toString().contains('Failed host lookup') ||
          e.toString().contains('SocketException') ||
          e.toString().contains('Network is unreachable')) {
        errorMsg = '네트워크 연결을 확인해주세요.\n서버에 연결할 수 없습니다.';
      } else if (e.toString().contains('404')) {
        errorMsg = '게시판을 찾을 수 없습니다.';
      } else if (e.toString().contains('401') || e.toString().contains('403')) {
        errorMsg = '인증이 필요합니다.\n로그인 후 다시 시도해주세요.';
      } else if (e.toString().contains('500')) {
        errorMsg = '서버 오류가 발생했습니다.';
      } else {
        errorMsg = '게시글을 불러오는데 실패했습니다.\n${e.toString()}';
      }

      setState(() {
        _errorMessage = errorMsg;
        _isLoading = false;
      });
    }
  }

  Future<void> _refresh() async {
    await _loadPosts(loadMore: false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _posts.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null && _posts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _refresh,
                icon: const Icon(Icons.refresh),
                label: const Text('다시 시도'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '서버가 실행 중인지 확인해주세요.\n안드로이드 에뮬레이터: http://10.0.2.2:8080',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (_posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.article_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              '${widget.boardName}에 게시글이 없습니다.',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _posts.length + (_hasMore ? 1 : 0),
        separatorBuilder: (context, index) {
          if (index < _posts.length - 1) {
            return const Divider(
              height: 1,
              thickness: 1,
              color: Color(0xFFE0E0E0),
            );
          }
          return const SizedBox.shrink();
        },
        itemBuilder: (context, index) {
          if (index == _posts.length) {
            // 더 불러오기 버튼
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : TextButton(
                  onPressed: _hasMore
                      ? () {
                    _loadPosts(loadMore: true);
                  }
                      : null,
                  child: Text(_hasMore ? '더 보기' : '마지막 페이지'),
                ),
              ),
            );
          }

          final post = _posts[index];
          return _buildPostItem(post);
        },
      ),
    );
  }

  Widget _buildPostItem(Post post) {
    final dateFormat = DateFormat('M/d', 'ko_KR');
    final hasImage = post.imageUrl != null && post.imageUrl!.isNotEmpty;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PostScreen(
              postId: post.postId,
              boardId: widget.boardId,
            ),
          ),
        ).then((deleted) {
          // 게시글이 삭제된 경우 목록 새로고침
          if (deleted == true) {
            _loadPosts(loadMore: false);
          }
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasImage) ...[
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    _getImageUrl(post.imageUrl!),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.image, color: Colors.grey),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    post.content,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        post.nickname,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        dateFormat.format(post.createdAt),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getImageUrl(String imagePath) {
    // 이미지 URL이 상대 경로인 경우 baseUrl과 결합
    if (imagePath.startsWith('http')) {
      return imagePath;
    }
    const String baseUrl = 'http://10.0.2.2:8080'; // 안드로이드 에뮬레이터용
    // const String baseUrl = 'http://localhost:8080'; // iOS 시뮬레이터 또는 실제 디바이스용
    return '$baseUrl$imagePath';
  }
}

// 자랑게시판 탭
class ShowOffBoardTab extends StatelessWidget {
  const ShowOffBoardTab({super.key});

  @override
  Widget build(BuildContext context) {
    return PostListTab(
      boardId: BoardIds.showOff,
      boardName: '자랑게시판',
    );
  }
}

// 궁금해요 게시판 탭
class QuestionBoardTab extends StatelessWidget {
  const QuestionBoardTab({super.key});

  @override
  Widget build(BuildContext context) {
    return PostListTab(
      boardId: BoardIds.question,
      boardName: '궁금해요',
    );
  }
}

// 정보게시판 탭
class InformationBoardTab extends StatelessWidget {
  const InformationBoardTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 히어로 이미지
          _buildHeroImage(),
          // 제목과 본문
          _buildHeaderSection(),
          // 카드 목록
          _buildCardList(),
        ],
      ),
    );
  }

  Widget _buildHeroImage() {
    return GestureDetector(
      onTap: () async {
        // 매거진 링크 열기 (실제 URL은 관리자가 설정)
        final uri = Uri.parse('https://example.com/magazine');
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            height: 250,
            color: Colors.grey[300],
            child: Image.network(
              'https://via.placeholder.com/400x250',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[300],
                  child: const Center(
                    child: Icon(Icons.image, size: 64, color: Colors.grey),
                  ),
                );
              },
            ),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '클릭해서 매거진을 확인하세요!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '식물인테리어, 초록이 주는 가장 조용한 위로',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '하루 종일 화면만 바라보다가 문득, 창가의 초록에게 눈길이 멈춘 적 있으신가요? 그 순간이 시작일지 몰라요.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black54,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardList() {
    final cards = [
      {
        'title': '브라더가든',
        'description': '그린 스타일링, 식물 인테리어에 관심이 있다면 방문해 보세요!',
        'tags': ['인테리어', '배달', '매거진'],
      },
      {
        'title': '선데이플래닛47',
        'description': '실내식물 케어에 관심이 있다면 방문해 보세요!',
        'tags': ['영양제', '관리용품'],
      },
      {
        'title': '어플라워가드닝',
        'description': '다양한 흙자재와 씨앗을 구매하고 싶다면 방문해 보세요!',
        'tags': ['분갈이', '흙자재', '씨앗'],
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: cards.map((card) => _buildInfoCard(card)).toList(),
      ),
    );
  }

  Widget _buildInfoCard(Map<String, dynamic> card) {
    return GestureDetector(
      onTap: () async {
        // 카드 클릭 시 링크 열기 (실제 URL은 관리자가 설정)
        final uri = Uri.parse('https://example.com/${card['title']}');
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 태그들
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (card['tags'] as List<String>).map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    tag,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF6AA84F),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            // 제목
            Text(
              card['title'] as String,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            // 설명
            Text(
              card['description'] as String,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

