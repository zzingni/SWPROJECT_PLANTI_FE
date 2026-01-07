import 'dart:convert';
import 'package:fe/notification/push_notification_service.dart';
import 'package:http/http.dart' as http;
import 'package:fe/core/token_storage.dart';
import 'package:fe/screens/plant_selection_screen.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  final int? plantId;
  final String? nickname;
  final String? wateringCycle;
  final int? optimalTemperature;
  final int? optimalHumidity;
  final TokenStorage tokenStorage;

  const HomeScreen({
    super.key,
    this.plantId,
    this.nickname,
    this.wateringCycle,
    this.optimalTemperature,
    this.optimalHumidity,
    required this.tokenStorage,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? nickname;
  int? optimalTemperature;
  int? optimalHumidity;
  int? companionPlantId;
  bool isLoading = true;
  bool showWateringPrompt = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _fetchPlantInfo();
    // FCM 알림 리스너 등록
    _setupNotificationListener();
  }

  void _setupNotificationListener() {
    // PushNotificationService에서 알림이 올 때 호출될 콜백 등록
    PushNotificationService.instance.setOnWateringNotificationReceived(() {
      showWateringPromptCard();
    });
  }

  void showWateringPromptCard() {
    if (mounted) {
      setState(() {
        showWateringPrompt = true;
      });
    }
  }

  void hideWateringPromptCard() {
    if (mounted) {
      setState(() {
        showWateringPrompt = false;
      });
    }
  }

  Future<void> _saveWateringHistory(String wateringStatus) async {
    if (_saving) return;

    final token = await TokenStorage.accessToken;
    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인이 필요합니다.'), backgroundColor: Colors.red),
      );
      return;
    }

    final id = companionPlantId ?? await _fetchCompanionPlantId(token);
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('반려식물 ID를 찾을 수 없습니다.'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final res = await http.post(
        Uri.parse('http://10.0.2.2:8080/api/watering/history'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'companionPlantId': id,
          'wateringStatus': wateringStatus, // "완료" or "미완료"
        }),
      );

      debugPrint('POST /api/watering/history => ${res.statusCode} ${res.body}');

      if (res.statusCode == 201 || res.statusCode == 200) {
        hideWateringPromptCard();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(wateringStatus == '완료' ? '물주기가 완료되었습니다.' : '물주기가 미완료 되었어요.'),
            backgroundColor: const Color(0xFF4F7F43),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('저장 실패 (${res.statusCode}) ${res.body}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('저장 중 오류: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _fetchPlantInfo() async {
    try {
      // 토큰 가져오기
      final token = await TokenStorage.accessToken;
      if (token == null || token.isEmpty) {
        print('토큰 없음');
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
        return;
      }

      // 1) 반려식물 기본 정보(닉네임) 조회
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8080/api/user/plant'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        String? fetchedNickname;

        // 응답이 Map인 경우
        if (decoded is Map<String, dynamic>) {
          fetchedNickname = decoded['nickname'] as String?;
        }

        // 응답이 List인 경우
        else if (decoded is List && decoded.isNotEmpty) {
          final first = decoded.first;
          if (first is Map<String, dynamic>) {
            fetchedNickname = first['nickname'] as String?;
          }
        }

        // 2) companionPlantId도 같이 확보(물주기 이력 저장/조회용)
        final id = await _fetchCompanionPlantId(token);

        if (mounted) {
          setState(() {
            nickname = fetchedNickname;
            companionPlantId = id;
            isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
        print('반려식물 정보 조회 실패: ${response.statusCode} / ${response.body}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      print('반려식물 정보 조회 중 에러: $e');
    }
  }



  Future<int?> _fetchCompanionPlantId(String token) async {
    final response = await http.get(
      Uri.parse('http://10.0.2.2:8080/api/user-plants'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) return null;

    final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
    if (data.isEmpty) return null;

    final first = data.first as Map<String, dynamic>;
    final id = first['companionPlantId'] ?? first['id'];

    if (id is int) return id;
    if (id is String) return int.tryParse(id);
    return null;
  }


  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (nickname != null) {
      return _buildPlantRegisteredView();
    } else {
      return _buildAddPlantView();
    }
  }

  Widget _buildPlantRegisteredView() {
    return Scaffold(
      // 기존 Column의 AppBar 부분을 Scaffold의 appBar로 이동
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        color: const Color(0xFFF8F9FA),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),
              // 반려식물 메인 카드
              showWateringPrompt
                  ? _PlantWateringPromptCard(
                nickname: nickname!,
                onYes: () async {
                  await _saveWateringHistory('완료');
                },
                onNo: () async {
                  await _saveWateringHistory('미완료');
                },
              )
                  : _PlantMainCard(nickname: nickname!),
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
      ),
    );
  }

  Widget _buildAddPlantView() {
    return Scaffold(
      // 기존 Column의 AppBar 부분을 Scaffold의 appBar로 이동
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        color: const Color(0xFFF8F9FA),
        child: Center(
          child: _AddPlantCard(tokenStorage: widget.tokenStorage),
        ),
      ),
    );
  }
}

// 반려식물 추가 카드 (기존과 동일)
class _AddPlantCard extends StatelessWidget {

  final TokenStorage tokenStorage;
  const _AddPlantCard({required this.tokenStorage});

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
                    builder: (context) => PlantSelectionScreen(
                      tokenStorage: tokenStorage,
                    ),
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
  final String nickname;

  const _PlantMainCard({
    required this.nickname,
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
              nickname,
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

// 물주기 프롬프트 카드 (FCM 알림 시 표시)
class _PlantWateringPromptCard extends StatelessWidget {
  final String nickname;
  final VoidCallback onYes;
  final VoidCallback onNo;

  const _PlantWateringPromptCard({
    required this.nickname,
    required this.onYes,
    required this.onNo,
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
              nickname,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF3182CE),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 물주기 프롬프트 캐릭터 (목이 마른 상태)
          // SizedBox(
          //   height: 280,
          //   child: Stack(
          //     alignment: Alignment.center,
          //     children: [
          //       // 물뿌리개와 물방울 (왼쪽 위)
          //       Positioned(
          //         top: 20,
          //         left: 30,
          //         child: Column(
          //           children: [
          //             // 물뿌리개
          //             Container(
          //               width: 35,
          //               height: 35,
          //               decoration: BoxDecoration(
          //                 color: const Color(0xFF87CEEB),
          //                 borderRadius: BorderRadius.circular(6),
          //               ),
          //               child: const Icon(
          //                 Icons.water_drop,
          //                 color: Colors.white,
          //                 size: 20,
          //               ),
          //             ),
          //             const SizedBox(height: 6),
          //             // 물방울
          //             Container(
          //               width: 10,
          //               height: 10,
          //               decoration: const BoxDecoration(
          //                 color: Color(0xFF87CEEB),
          //                 shape: BoxShape.circle,
          //               ),
          //             ),
          //           ],
          //         ),
          //       ),
          //       // 목이 마른 캐릭터
          //       Positioned(
          //         child: Column(
          //           mainAxisSize: MainAxisSize.min,
          //           children: [
          //             // 잎사귀 (머리 위)
          //             Row(
          //               mainAxisSize: MainAxisSize.min,
          //               children: [
          //                 Container(
          //                   width: 25,
          //                   height: 25,
          //                   decoration: BoxDecoration(
          //                     color: const Color(0xFF4F7F43),
          //                     borderRadius: BorderRadius.circular(12),
          //                   ),
          //                 ),
          //                 const SizedBox(width: 8),
          //                 Container(
          //                   width: 25,
          //                   height: 25,
          //                   decoration: BoxDecoration(
          //                     color: const Color(0xFF4F7F43),
          //                     borderRadius: BorderRadius.circular(12),
          //                   ),
          //                 ),
          //               ],
          //             ),
          //             const SizedBox(height: 4),
          //             // 식물 몸통 (연한 초록색 구체)
          //             Container(
          //               width: 140,
          //               height: 140,
          //               decoration: BoxDecoration(
          //                 color: const Color(0xFFB8E6B8),
          //                 shape: BoxShape.circle,
          //               ),
          //               child: Stack(
          //                 alignment: Alignment.center,
          //                 children: [
          //                   // 큰 눈들
          //                   Positioned(
          //                     top: 35,
          //                     child: Row(
          //                       mainAxisSize: MainAxisSize.min,
          //                       children: [
          //                         Container(
          //                           width: 18,
          //                           height: 18,
          //                           decoration: const BoxDecoration(
          //                             color: Colors.black,
          //                             shape: BoxShape.circle,
          //                           ),
          //                         ),
          //                         const SizedBox(width: 25),
          //                         Container(
          //                           width: 18,
          //                           height: 18,
          //                           decoration: const BoxDecoration(
          //                             color: Colors.black,
          //                             shape: BoxShape.circle,
          //                           ),
          //                         ),
          //                       ],
          //                     ),
          //                   ),
          //                   // 볼 (분홍색)
          //                   Positioned(
          //                     top: 55,
          //                     child: Row(
          //                       mainAxisSize: MainAxisSize.min,
          //                       children: [
          //                         Container(
          //                           width: 10,
          //                           height: 10,
          //                           decoration: const BoxDecoration(
          //                             color: Color(0xFFFFB6C1),
          //                             shape: BoxShape.circle,
          //                           ),
          //                         ),
          //                         const SizedBox(width: 35),
          //                         Container(
          //                           width: 10,
          //                           height: 10,
          //                           decoration: const BoxDecoration(
          //                             color: Color(0xFFFFB6C1),
          //                             shape: BoxShape.circle,
          //                           ),
          //                         ),
          //                       ],
          //                     ),
          //                   ),
          //                   // 입 (목이 마른 표정 - 열린 입)
          //                   Positioned(
          //                     top: 70,
          //                     child: Container(
          //                       width: 24,
          //                       height: 16,
          //                       decoration: BoxDecoration(
          //                         color: Colors.black,
          //                         borderRadius: BorderRadius.circular(12),
          //                       ),
          //                     ),
          //                   ),
          //                 ],
          //               ),
          //             ),
          //             const SizedBox(height: 8),
          //             // 화분 (오렌지색)
          //             Container(
          //               width: 110,
          //               height: 55,
          //               decoration: BoxDecoration(
          //                 color: const Color(0xFFFFA500),
          //                 borderRadius: BorderRadius.circular(8),
          //               ),
          //             ),
          //           ],
          //         ),
          //       ),
          //     ],
          //   ),
          // ),
          SizedBox(
            height: 280,
            child: Image.asset(
              'assets/images/water.png',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                print('이미지 로드 에러: $error');
                return const Icon(
                  Icons.eco_rounded,
                  size: 60,
                  color: Color(0xFF4F7F43),
                );
              },
            ),
          ),

          const SizedBox(height: 20),

          // 메시지
          Text(
            '목이 말라요!',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D3748),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '오늘 \'$nickname\' 에게 물을 주셨나요?',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF2D3748),
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          // 버튼들
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onNo,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(
                      color: Color(0xFFE0E0E0),
                      width: 1,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    '아니요!',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onYes,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: const Color(0xFF4F7F43),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    '네!',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
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