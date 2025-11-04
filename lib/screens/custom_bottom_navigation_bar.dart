import 'package:flutter/material.dart';

class CustomBottomNavigationBar extends StatefulWidget {
  const CustomBottomNavigationBar({super.key});

  @override
  State<CustomBottomNavigationBar> createState() => _CustomBottomNavigationBarState();
}

class _CustomBottomNavigationBarState extends State<CustomBottomNavigationBar> {
  int _currentIndex = 0;

  final List<BottomNavItem> _navItems = [
    BottomNavItem(
      icon: Icons.home_rounded,
      label: '홈',
      isActive: true,
    ),
    BottomNavItem(
      icon: Icons.people_rounded,
      label: '커뮤니티',
      isActive: false,
    ),
    BottomNavItem(
      icon: Icons.search_rounded,
      label: '검색',
      isActive: false,
    ),
    BottomNavItem(
      icon: Icons.person_rounded,
      label: '마이페이지',
      isActive: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF7F8FA),
        border: Border(
          top: BorderSide(
            color: Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _navItems.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isSelected = _currentIndex == index;

              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentIndex = index;
                    });
                    // TODO: 각 탭에 따른 화면 전환
                    _handleTabTap(index);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item.icon,
                          size: 24,
                          color: isSelected
                              ? const Color(0xFF2D3748)
                              : const Color(0xFFA0AEC0),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isSelected
                                ? const Color(0xFF2D3748)
                                : const Color(0xFFA0AEC0),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _handleTabTap(int index) {
    switch (index) {
      case 0:
      // 홈 - 이미 현재 화면
        break;
      case 1:
      // 커뮤니티 화면으로 이동
      // Navigator.push(context, MaterialPageRoute(builder: (context) => CommunityScreen()));
        break;
      case 2:
      // 검색 화면으로 이동
      // Navigator.push(context, MaterialPageRoute(builder: (context) => SearchScreen()));
        break;
      case 3:
      // 마이페이지 화면으로 이동
      // Navigator.push(context, MaterialPageRoute(builder: (context) => MyPageScreen()));
        break;
    }
  }
}

class BottomNavItem {
  final IconData icon;
  final String label;
  final bool isActive;

  BottomNavItem({
    required this.icon,
    required this.label,
    required this.isActive,
  });
}