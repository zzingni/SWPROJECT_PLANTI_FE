import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// 물주기 알림 이력 모델
class WateringNotificationHistory {
  final DateTime notificationDate; // 알림을 받은 날짜
  final bool isWatered; // 물을 줬는지 여부
  final DateTime? wateredAt; // 물을 준 시간 (null이면 안 줌)

  WateringNotificationHistory({
    required this.notificationDate,
    required this.isWatered,
    this.wateredAt,
  });
}

class WateringHistoryScreen extends StatefulWidget {
  const WateringHistoryScreen({super.key});

  @override
  State<WateringHistoryScreen> createState() => _WateringHistoryScreenState();
}

class _WateringHistoryScreenState extends State<WateringHistoryScreen> {
  List<WateringNotificationHistory> _historyList = [];

  @override
  void initState() {
    super.initState();
    _loadDummyData();
  }

  // 더미데이터 생성
  void _loadDummyData() {
    final now = DateTime.now();
    final List<WateringNotificationHistory> dummyList = [];

    // 최근 30일간의 더미데이터 생성
    for (int i = 0; i < 30; i++) {
      final date = now.subtract(Duration(days: i));
      // 3일마다 알림이 온다고 가정
      if (i % 3 == 0) {
        // 물을 준 경우와 안 준 경우를 랜덤하게
        final isWatered = i % 2 == 0;
        dummyList.add(
          WateringNotificationHistory(
            notificationDate: date,
            isWatered: isWatered,
            wateredAt: isWatered
                ? date.add(const Duration(hours: 2, minutes: 30))
                : null,
          ),
        );
      }
    }

    setState(() {
      _historyList = dummyList;
    });
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
      body: _historyList.isEmpty
          ? Center(
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
      )
          : ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _historyList.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final history = _historyList[index];
          return _buildHistoryItem(history);
        },
      ),
    );
  }

  Widget _buildHistoryItem(WateringNotificationHistory history) {
    final dateFormat = DateFormat('yyyy년 M월 d일 (E)', 'ko_KR');
    final timeFormat = DateFormat('HH:mm', 'ko_KR');
    final isToday = isSameDay(history.notificationDate, DateTime.now());
    final isPast = history.notificationDate.isBefore(
      DateTime.now().copyWith(hour: 0, minute: 0, second: 0, millisecond: 0),
    );

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
                      dateFormat.format(history.notificationDate),
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
                Row(
                  children: [
                    Icon(
                      Icons.notifications_outlined,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '알림 받은 날짜',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
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
                        history.wateredAt != null
                            ? '물주기 완료 (${timeFormat.format(history.wateredAt!)})'
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

  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}

