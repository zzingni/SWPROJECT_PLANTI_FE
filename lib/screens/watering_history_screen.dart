import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dart:convert';
import 'package:fe/core/token_storage.dart';

class WateringHistory {
  final int id;
  final DateTime wateredAt;
  final String? memo;

  WateringHistory({
    required this.id,
    required this.wateredAt,
    this.memo,
  });

  factory WateringHistory.fromJson(Map<String, dynamic> json) {
    return WateringHistory(
      id: json['id'] as int,
      wateredAt: DateTime.parse(json['wateredAt'] as String),
      memo: json['memo'] as String?,
    );
  }
}

class WateringHistoryScreen extends StatefulWidget {
  const WateringHistoryScreen({super.key});

  @override
  State<WateringHistoryScreen> createState() => _WateringHistoryScreenState();
}

class _WateringHistoryScreenState extends State<WateringHistoryScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  int _currentYear = DateTime.now().year;
  int _currentMonth = DateTime.now().month;
  Map<int, List<WateringHistory>> _calendarData = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedDay = now;
    _selectedDay = now;
    _initCalendar(now.year, now.month);
  }

  Future<void> _initCalendar(int year, int month) async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final token = await TokenStorage.accessToken;
      if (token == null) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // 물주기 이력 API 호출 (백엔드 API 엔드포인트에 맞게 수정 필요)
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8080/api/watering/history')
            .replace(queryParameters: {
          'year': '$year',
          'month': '$month',
        }),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final Map<String, dynamic> monthHistory =
        (data['monthHistory'] as Map<String, dynamic>? ?? {});

        final result = <int, List<WateringHistory>>{};
        for (final e in monthHistory.entries) {
          final dayKey = int.parse(e.key);
          final list = (e.value as List)
              .map((x) => WateringHistory.fromJson(x as Map<String, dynamic>))
              .toList(growable: false);
          result[dayKey] = list;
        }

        setState(() {
          _currentYear = year;
          _currentMonth = month;
          _selectedDay = DateTime(year, month, _selectedDay.day);
          _focusedDay = DateTime(year, month, _selectedDay.day);
          _calendarData = result;
        });
      } else {
        // API가 아직 구현되지 않은 경우 빈 데이터로 처리
        setState(() {
          _currentYear = year;
          _currentMonth = month;
          _calendarData = {};
        });
      }
    } catch (e) {
      if (!mounted) return;
      // API가 아직 구현되지 않은 경우 빈 데이터로 처리
      setState(() {
        _currentYear = year;
        _currentMonth = month;
        _calendarData = {};
      });
      print('물주기 이력 불러오기 실패: $e');
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _goNextMonth() {
    setState(() {
      if (_currentMonth == 12) {
        _currentYear += 1;
        _currentMonth = 1;
      } else {
        _currentMonth += 1;
      }
      _focusedDay = DateTime(_currentYear, _currentMonth, 1);
      _selectedDay = _focusedDay;
    });
    _initCalendar(_currentYear, _currentMonth);
  }

  void _goPrevMonth() {
    setState(() {
      if (_currentMonth == 1) {
        _currentYear -= 1;
        _currentMonth = 12;
      } else {
        _currentMonth -= 1;
      }
      _focusedDay = DateTime(_currentYear, _currentMonth, 1);
      _selectedDay = _focusedDay;
    });
    _initCalendar(_currentYear, _currentMonth);
  }

  List<WateringHistory> get _selectedHistories =>
      _calendarData[_selectedDay.day] ?? [];

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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          children: [
            // 달력 카드
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    // 헤더 with 화살표
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            splashRadius: 18,
                            icon: const Icon(Icons.arrow_back_ios_rounded,
                                size: 20, color: Color(0xFF6AA84F)),
                            onPressed: _goPrevMonth,
                          ),
                          Expanded(
                            child: Center(
                              child: Text(
                                '${_currentYear}년 ${_currentMonth}월',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF6AA84F),
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            splashRadius: 18,
                            icon: const Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 20,
                                color: Color(0xFF6AA84F)),
                            onPressed: _goNextMonth,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: TableCalendar(
                        locale: 'ko_KR',
                        firstDay: DateTime.utc(2020),
                        lastDay: DateTime.utc(2030),
                        focusedDay: _focusedDay,
                        selectedDayPredicate: (d) =>
                            isSameDay(d, _selectedDay),
                        onDaySelected: (selected, focused) {
                          setState(() {
                            _selectedDay = selected;
                            _focusedDay = focused;
                          });
                        },
                        onPageChanged: (focusedDay) {
                          _initCalendar(focusedDay.year, focusedDay.month);
                        },
                        eventLoader: (day) =>
                        (_calendarData[day.day] ?? []).isNotEmpty
                            ? ["물주기"]
                            : [],
                        headerVisible: false,
                        rowHeight: 40,
                        daysOfWeekStyle: const DaysOfWeekStyle(
                          weekendStyle: TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                          weekdayStyle: TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                        calendarStyle: CalendarStyle(
                          markersMaxCount: 1,
                          markerDecoration: const BoxDecoration(
                            color: Color(0xFF6AA84F),
                            shape: BoxShape.circle,
                          ),
                          defaultTextStyle: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                          outsideTextStyle: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Colors.black87.withOpacity(0.4),
                          ),
                          selectedDecoration: const BoxDecoration(
                            color: Color(0xFF6AA84F),
                            shape: BoxShape.circle,
                          ),
                          todayDecoration: BoxDecoration(
                            color: const Color(0xFF6AA84F).withOpacity(0.3),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF6AA84F),
                              width: 1.5,
                            ),
                          ),
                          weekendTextStyle: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // 선택한 날짜의 물주기 이력
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.water_drop,
                          color: Color(0xFF6AA84F),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('yyyy년 M월 d일', 'ko_KR')
                              .format(_selectedDay),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6AA84F),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _selectedHistories.isEmpty
                        ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFF6AA84F)
                                  .withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.water_drop_outlined,
                              size: 24,
                              color: Color(0xFF6AA84F),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            '이 날짜에 물주기 기록이 없습니다',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                        : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _selectedHistories.length,
                      itemBuilder: (context, index) {
                        final history = _selectedHistories[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F8F0),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFF6AA84F)
                                  .withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.water_drop,
                                    color: Color(0xFF6AA84F),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${index + 1}번째 물주기',
                                    style: const TextStyle(
                                      color: Color(0xFF6AA84F),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                DateFormat('yyyy.MM.dd HH:mm', 'ko_KR')
                                    .format(history.wateredAt
                                    .toLocal()),
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontSize: 13,
                                ),
                              ),
                              if (history.memo != null &&
                                  history.memo!.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  history.memo!,
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

