import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'home_screen.dart';

class PlantWateringScheduleScreen extends StatefulWidget {
  final String selectedPlant;
  final String plantName;

  const PlantWateringScheduleScreen({
    super.key,
    required this.selectedPlant,
    required this.plantName,
  });

  @override
  State<PlantWateringScheduleScreen> createState() => _PlantWateringScheduleScreenState();
}

class _PlantWateringScheduleScreenState extends State<PlantWateringScheduleScreen> {
  String? _selectedSchedule;
  bool _isLoading = false;

  final List<String> _schedules = [
    '매일',
    '한주에 1번',
    '한달에 1번',
    '수시로',
    '가끔',
  ];

  // 주기 문자열을 백엔드 형식으로 변환
  String _convertScheduleToBackendFormat(String? schedule) {
    switch (schedule) {
      case '매일':
        return 'DAY';
      case '한주에 1번':
        return 'WEEK';
      case '한달에 1번':
        return 'MONTH';
      case '수시로':
        return 'OFTEN';
      case '가끔':
        return 'SOMETIMES';
      default:
        return 'WEEK';
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
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // 제목
            Text(
              '사용자가 직접 물 주기를\n정할 수 있어요!',
              style: Theme
                  .of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF2D3748),
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            // 부제목
            Text(
              '선택하지 않으면 해당 식물의 기본 주기로 설정됩니다.',
              style: Theme
                  .of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(
                color: const Color(0xFF718096),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // 물주기 선택 옵션들 (세로로 정렬)
            Expanded(
              child: ListView.separated(
                itemCount: _schedules.length,
                separatorBuilder: (context, index) =>
                const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final schedule = _schedules[index];
                  final isSelected = _selectedSchedule == schedule;

                  return _WateringScheduleButton(
                    schedule: schedule,
                    isSelected: isSelected,
                    onTap: () {
                      setState(() {
                        _selectedSchedule = schedule;
                      });
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // 페이지 인디케이터
            Text(
              '3/3',
              style: Theme
                  .of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(
                color: const Color(0xFF2D3748),
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 24),

            // 완료 버튼
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _completeSetup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isLoading
                      ? const Color(0xFFA0AEC0)
                      : const Color(0xFF4F7F43),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : const Text(
                  '완료',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _completeSetup() async {
    setState(() {
      _isLoading = true;
    });

    // 1. plantData 생성
    final plantData = {
      'plantType': widget.selectedPlant,
      'plantName': widget.plantName,
      'wateringCycle': _convertScheduleToBackendFormat(_selectedSchedule),
      // 필요하면 온도, 습도 등 다른 데이터 추가
    };

    try {
      final response = await _sendPlantDataToBackend(plantData);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // 성공
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('반려식물이 성공적으로 추가되었습니다!'),
              backgroundColor: Color(0xFF4F7F43),
            ),
          );

          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) =>
                  HomeScreen(
                    plantType: widget.selectedPlant,
                    plantName: widget.plantName,
                    wateringCycle: _convertScheduleToBackendFormat(
                        _selectedSchedule),
                    optimalTemperature: 25,
                    optimalHumidity: 43,
                  ),
            ),
                (route) => false,
          );
        }
      } else {
        // 실패
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('등록 실패: ${response.statusCode}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<http.Response> _sendPlantDataToBackend(
      Map<String, dynamic> plantData) async {
    // 실제 백엔드 API URL로 변경
    const String apiUrl = 'https://your-api-url.com/api/plants';

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Content-Type': 'application/json',
        // 인증 토큰 필요 시 추가
        // 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(plantData),
    );
    return response;
  }
}

class _WateringScheduleButton extends StatelessWidget {
  final String schedule;
  final bool isSelected;
  final VoidCallback onTap;

  const _WateringScheduleButton({
    required this.schedule,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 48,
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFE8F5E8)
              : const Color(0xFFF7F8FA),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF4F7F43)
                : const Color(0xFFE2E8F0),
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            schedule,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isSelected
                  ? const Color(0xFF4F7F43)
                  : const Color(0xFF2D3748),
            ),
          ),
        ),
      ),
    );
  }
}