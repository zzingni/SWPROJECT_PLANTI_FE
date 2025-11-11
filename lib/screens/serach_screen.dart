import 'package:fe/models/palnt_info.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/plant_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late PlantService _plantService;
  final TextEditingController _searchController = TextEditingController();
  PlantInfo? _plantInfo;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    const String baseUrl = 'http://10.0.2.2:8080'; // 안드로이드 에뮬레이터용
    _plantService = PlantService(http.Client(), baseUrl: baseUrl);
  }

  @override
  void dispose() {
    _plantService.close();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchPlant() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final plantInfo = await _plantService.searchPlant(query);
      if (!mounted) return;
      setState(() {
        _plantInfo = plantInfo;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = '식물 정보를 불러오는데 실패했습니다: ${e.toString()}';
        _isLoading = false;
        _plantInfo = null;
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          '식물도감',
          style: TextStyle(
            color: Color(0xFF6AA84F),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 검색 바
          Padding(
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
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: '식물명을 입력하세요',
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search),
                    color: Color(0xFF6AA84F),
                    onPressed: _searchPlant,
                  ),
                ),
                onSubmitted: (_) => _searchPlant(),
              ),
            ),
          ),
          // 내용 영역
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _searchPlant,
                      child: const Text('다시 시도'),
                    ),
                  ],
                ),
              ),
            )
                : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 대표 캐릭터 이미지
                  if (_plantInfo?.characterImageUrl != null)
                    Center(
                      child: Opacity(
                        opacity: _plantInfo != null ? 1.0 : 0.5,
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: _plantInfo?.characterImageUrl != null
                              ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              _plantInfo!.characterImageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.image,
                                  size: 64,
                                  color: Colors.grey,
                                );
                              },
                            ),
                          )
                              : const Icon(
                            Icons.local_florist,
                            size: 64,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    )
                  else
                    Center(
                      child: Opacity(
                        opacity: 0.5,
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.local_florist,
                            size: 64,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  // 식물 기본 정보 (검색 후에만 표시)
                  if (_plantInfo != null) ...[
                    _buildInfoRow('식물명', _plantInfo!.plantName),
                    const SizedBox(height: 12),
                    _buildInfoRow('식물학명', _plantInfo!.scientificName),
                    const SizedBox(height: 12),
                    _buildInfoRow('과목', _plantInfo!.family),
                    const SizedBox(height: 12),
                    _buildInfoRow('물주기', _plantInfo!.watering),
                    const SizedBox(height: 12),
                    _buildInfoRow('적정 온도', _plantInfo!.optimalTemperature),
                    const SizedBox(height: 12),
                    _buildInfoRow('적정 습도', _plantInfo!.optimalHumidity),
                    const SizedBox(height: 32),
                  ],
                  // 관리 방법 섹션
                  const Text(
                    '관리 방법',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2196F3),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 병충해 관리 정보
                  _buildSectionTitle('병충해 관리 정보'),
                  const SizedBox(height: 8),
                  _buildSectionContent(
                    _plantInfo?.pestManagement ?? '',
                  ),
                  const SizedBox(height: 24),
                  // 기능성 정보
                  _buildSectionTitle('기능성 정보'),
                  const SizedBox(height: 8),
                  _buildSectionContent(
                    _plantInfo?.functionalInfo ?? '',
                  ),
                  const SizedBox(height: 24),
                  // 특별관리 정보
                  _buildSectionTitle('특별관리 정보'),
                  const SizedBox(height: 8),
                  _buildSectionContent(
                    _plantInfo?.specialCare ?? '',
                  ),
                  const SizedBox(height: 24),
                  // 독성 정보
                  _buildSectionTitle('독성 정보'),
                  const SizedBox(height: 8),
                  _buildSectionContent(
                    _plantInfo?.toxicity ?? '',
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
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
          currentIndex: 2, // 검색이 선택된 상태
          onTap: (index) {
            if (index == 0) {
              Navigator.of(context).popUntil((route) => route.isFirst);
            } else if (index == 1) {
              Navigator.pushNamed(context, '/community');
            } else if (index == 2) {
              // 검색은 이미 현재 화면
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

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildSectionContent(String content) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        content.isEmpty ? ' ' : content,
        style: TextStyle(
          fontSize: 14,
          height: 1.6,
          color: content.isEmpty ? Colors.transparent : Colors.black87,
        ),
      ),
    );
  }
}

