import 'dart:convert';

import 'package:fe/core/token_storage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

// 물주기 이력 모델 (백엔드 응답을 유연하게 파싱)
class WateringHistoryItem {
  final DateTime wateringDate;
  final String wateringStatus; // "완료" / "미완료"

  WateringHistoryItem({
    required this.wateringDate,
    required this.wateringStatus,
  });

  bool get isWatered => wateringStatus == '완료';

  factory WateringHistoryItem.fromJson(Map<String, dynamic> json) {
    DateTime _parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      return DateTime.parse(value.toString());
    }

    return WateringHistoryItem(
      wateringDate: _parseDate(json['wateringDate']),
      wateringStatus: (json['wateringStatus'] ?? '미완료').toString(),
    );
  }
}

class WateringHistoryScreen extends StatefulWidget {
  const WateringHistoryScreen({super.key});

  @override
  State<WateringHistoryScreen> createState() => _WateringHistoryScreenState();
}

class _WateringHistoryScreenState extends State<WateringHistoryScreen> {
  List<WateringHistoryItem> _historyList = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await TokenStorage.accessToken;
      if (token == null || token.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = '로그인이 필요합니다.';
        });
        return;
      }

      final companionPlantId = await _fetchCompanionPlantId(token);
      if (companionPlantId == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = '반려식물 정보를 불러올 수 없습니다.';
        });
        return;
      }

      final response = await http.get(
        Uri.parse(
            'http://10.0.2.2:8080/api/watering/history?companionPlantId=$companionPlantId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
        final history = data
            .map((e) => WateringHistoryItem.fromJson(e as Map<String, dynamic>))
            .toList();

        setState(() {
          _historyList = history;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = '이력 조회 실패 (${response.statusCode})';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '이력 조회 중 오류가 발생했습니다: $e';
      });
    }
  }

  // 사용자 반려식물 목록 중 첫 번째 companionPlantId를 조회
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          '물주기 이력',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.red,
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    if (_historyList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFF6AA84F).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.water_drop_outlined,
                size: 32,
                color: Color(0xFF6AA84F),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '물주기 알림 이력이 없습니다',
              style: TextStyle(
                color: Colors.black54,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _historyList.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final history = _historyList[index];
        return _buildHistoryItem(history);
      },
    );
  }

  Widget _buildHistoryItem(WateringHistoryItem history) {
    final dateFormat = DateFormat('yyyy년 M월 d일 (E)', 'ko_KR');
    final timeFormat = DateFormat('HH:mm', 'ko_KR');
    final isToday = _isSameDay(history.wateringDate, DateTime.now());

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: history.isWatered
              ? const Color(0xFF6AA84F).withOpacity(0.3)
              : Colors.grey.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 상태 아이콘
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: history.isWatered
                  ? const Color(0xFF6AA84F).withOpacity(0.1)
                  : Colors.orange.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              history.isWatered
                  ? Icons.check_circle
                  : Icons.cancel_outlined,
              color: history.isWatered
                  ? const Color(0xFF6AA84F)
                  : Colors.orange,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          // 날짜 및 상태 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      dateFormat.format(history.wateringDate),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    if (isToday) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6AA84F).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '오늘',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF6AA84F),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                const SizedBox(height: 4),
                if (history.isWatered) ...[
                  Row(
                    children: [
                      const Icon(
                        Icons.water_drop,
                        size: 16,
                        color: Color(0xFF6AA84F),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        history.wateringDate != null
                            ? '물주기 완료 (${timeFormat.format(history.wateringDate!)})'
                            : '물주기 완료',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6AA84F),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Row(
                    children: [
                      Icon(
                        Icons.water_drop_outlined,
                        size: 16,
                        color: Colors.orange[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '물주기 미완료',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.orange[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          // 상태 배지
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: history.isWatered
                  ? const Color(0xFF6AA84F).withOpacity(0.1)
                  : Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              history.isWatered ? '완료' : '미완료',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: history.isWatered
                    ? const Color(0xFF6AA84F)
                    : Colors.orange,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}

