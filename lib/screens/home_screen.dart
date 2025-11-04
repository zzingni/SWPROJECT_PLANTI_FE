import 'package:fe/screens/plant_selection_screen.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  final String? plantType;
  final String? plantName;
  final String? wateringCycle;
  final int? optimalTemperature;
  final int? optimalHumidity;

  const HomeScreen({
    super.key,
    this.plantType,
    this.plantName,
    this.wateringCycle,
    this.optimalTemperature,
    this.optimalHumidity,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    // 반려식물이 등록된 경우와 아닌 경우를 구분
    if (widget.plantType != null) {
      return _buildPlantRegisteredView();
    } else {
      return _buildAddPlantView();
    }
  }

  Widget _buildPlantRegisteredView() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // 반려식물 메인 카드
            _PlantMainCard(
              plantType: widget.plantType!,
              plantName: widget.plantName!,
            ),
            const SizedBox(height: 20),
            // 환경 정보 카드들
            _EnvironmentCards(
              temperature: widget.optimalTemperature ?? 25,
              humidity: widget.optimalHumidity ?? 43,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNavigationBar(),
    );
  }

  Widget _buildAddPlantView() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: const Center(
        child: _AddPlantCard(),
      ),
      bottomNavigationBar: const CustomBottomNavigationBar(),
    );
  }
}

// 반려식물 추가 카드 (기존과 동일)
class _AddPlantCard extends StatelessWidget {
  const _AddPlantCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE8F5E8),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '반려식물을 추가해주세요!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF2D3748),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            '반려식물을 추가하고 물주기 알림과\n환경 알림을 받아보세요!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF3182CE),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 95,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PlantSelectionScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF2D3748),
                elevation: 2,
                shadowColor: Colors.black.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(
                    color: Color(0xFFE8F5E8),
                    width: 1.5,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '반려식물 추가하기',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 반려식물 메인 카드 (캐릭터 포함)
class _PlantMainCard extends StatelessWidget {
  final String plantType;
  final String plantName;

  const _PlantMainCard({
    required this.plantType,
    required this.plantName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE8F5E8),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // 식물 이름 (우상단)
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              plantName,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2D3748),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 식물 캐릭터
          Container(
            width: 350,
            height: 350,
            child: ClipOval(
              child: Image.asset(
                'assets/images/main.png',
                width: 350,
                height: 350,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  print('이미지 로드 에러: $error'); // 디버그용
                  return const Icon(
                    Icons.eco_rounded,
                    size: 60,
                    color: Color(0xFF4F7F43),
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 칭찬 메시지
          Text(
            '반려식물에게 칭찬을 해주세요!',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2D3748),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '오늘도 초록초록 예쁘게 자라고 있어요 🌱',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF4F7F43),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// 환경 정보 카드들
class _EnvironmentCards extends StatelessWidget {
  final int temperature;
  final int humidity;

  const _EnvironmentCards({
    required this.temperature,
    required this.humidity,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // 실내 기온 카드
          _EnvironmentCard(
            icon: Icons.thermostat_rounded,
            label: '실내 기온',
            value: '${temperature} 도',
          ),
          const SizedBox(height: 10),
          // 실내 습도 카드
          _EnvironmentCard(
            icon: Icons.water_drop_rounded,
            label: '실내 습도',
            value: '${humidity} %',
          ),
        ],
      ),
    );
  }
}

// 환경 정보 개별 카드
class _EnvironmentCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _EnvironmentCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF4F7F43),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// 하단 네비게이션바 (기존과 동일)
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
        break;
      case 2:
      // 검색 화면으로 이동
        break;
      case 3:
      // 마이페이지 화면으로 이동
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