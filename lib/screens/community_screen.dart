import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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
          // 게시글 작성 화면으로 이동
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

// 자랑게시판 탭
class ShowOffBoardTab extends StatelessWidget {
  const ShowOffBoardTab({super.key});

  @override
  Widget build(BuildContext context) {
    // 샘플 데이터
    final posts = [
      {
        'title': '다육이 짱 많이 큼',
        'content': '작년부터 키웠는데 벌써 이만큼 컸음 ㅜㅜ',
        'author': '다육다육',
        'date': '9/14',
        'hasImage': false,
      },
      {
        'title': '이렇게 예쁜 나팔꽃 본 적 있는 사람...?',
        'content': 'AI 합성 아닙니다.',
        'author': '나팔꽃키우는재미',
        'date': '9/14',
        'hasImage': true,
      },
    ];

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: posts.length,
      separatorBuilder: (context, index) => const Divider(
        height: 1,
        thickness: 1,
        color: Color(0xFFE0E0E0),
      ),
      itemBuilder: (context, index) {
        final post = posts[index];
        return _buildPostItem(post);
      },
    );
  }

  Widget _buildPostItem(Map<String, dynamic> post) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (post['hasImage'] == true) ...[
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
                  'https://via.placeholder.com/80',
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
                  post['title'] as String,
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
                  post['content'] as String,
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
                      post['author'] as String,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      post['date'] as String,
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
    );
  }
}

// 궁금해요 게시판 탭 (자랑게시판과 동일한 UI)
class QuestionBoardTab extends StatelessWidget {
  const QuestionBoardTab({super.key});

  @override
  Widget build(BuildContext context) {
    // 샘플 데이터
    final posts = [
      {
        'title': '다육이 물주기 궁금해요',
        'content': '얼마나 자주 물을 주면 될까요?',
        'author': '초보자',
        'date': '9/15',
        'hasImage': false,
      },
      {
        'title': '식물 잎이 노랗게 변했어요',
        'content': '어떻게 해야 할까요? 도와주세요.',
        'author': '식물키우기',
        'date': '9/15',
        'hasImage': true,
      },
    ];

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: posts.length,
      separatorBuilder: (context, index) => const Divider(
        height: 1,
        thickness: 1,
        color: Color(0xFFE0E0E0),
      ),
      itemBuilder: (context, index) {
        final post = posts[index];
        return _buildPostItem(post);
      },
    );
  }

  Widget _buildPostItem(Map<String, dynamic> post) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (post['hasImage'] == true) ...[
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
                  'https://via.placeholder.com/80',
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
                  post['title'] as String,
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
                  post['content'] as String,
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
                      post['author'] as String,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      post['date'] as String,
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

