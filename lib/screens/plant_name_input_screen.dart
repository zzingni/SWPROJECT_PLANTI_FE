import 'package:fe/core/token_storage.dart';
import 'package:fe/screens/plant_watering_schedule_screen.dart';
import 'package:flutter/material.dart';

class PlantNameInputScreen extends StatefulWidget {
  final int selectedPlantId;
  final TokenStorage tokenStorage;

  const PlantNameInputScreen({
    super.key,
    required this.selectedPlantId,
    required this.tokenStorage,
  });

  @override
  State<PlantNameInputScreen> createState() => _PlantNameInputScreenState();
}

class _PlantNameInputScreenState extends State<PlantNameInputScreen> {
  final TextEditingController _nameController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _nameController.dispose();
    _focusNode.dispose();
    super.dispose();
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
            const SizedBox(height: 40),

            // 제목
            Text(
              '반려식물의 이름을 입력해주세요!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF2D3748),
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 40),

            // 이름 입력 필드
            TextField(
              controller: _nameController,
              focusNode: _focusNode,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _nextPage(),
              decoration: InputDecoration(
                hintText: '예: 뽀뽀, 초록이, 행복이',
                hintStyle: const TextStyle(
                  color: Color(0xFFA0AEC0),
                  fontSize: 16,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                filled: true,
                fillColor: const Color(0xFFF7F8FA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Color(0xFFE2E8F0),
                    width: 1.5,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Color(0xFFE2E8F0),
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Color(0xFF4F7F43),
                    width: 1.5,
                  ),
                ),
              ),
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF2D3748),
              ),
            ),

            const Spacer(),

            // 페이지 인디케이터
            Text(
              '2/3',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF2D3748),
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 24),

            // 다음 버튼
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _nameController.text.trim().isNotEmpty ? _nextPage : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _nameController.text.trim().isNotEmpty
                      ? const Color(0xFF4F7F43)
                      : const Color(0xFFE2E8F0),
                  foregroundColor: _nameController.text.trim().isNotEmpty
                      ? Colors.white
                      : const Color(0xFFA0AEC0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 2,
                  shadowColor: Colors.black.withOpacity(0.1),
                ),
                child: const Text(
                  '다음',
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

  void _nextPage() {
    final nickname = _nameController.text.trim();
    if (nickname.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PlantWateringScheduleScreen(
            selectedPlantId: widget.selectedPlantId,
            nickname: nickname,
            tokenStorage: widget.tokenStorage,
          ),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    // 텍스트 변경 시 버튼 상태 업데이트
    _nameController.addListener(() {
      setState(() {});
    });
  }
}