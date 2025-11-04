import 'package:fe/core/token_storage.dart';
import 'package:fe/screens/plant_name_input_screen.dart';
import 'package:flutter/material.dart';

class PlantSelectionScreen extends StatefulWidget {
  final TokenStorage tokenStorage;
  const PlantSelectionScreen({super.key, required this.tokenStorage});

  @override
  State<PlantSelectionScreen> createState() => _PlantSelectionScreenState();
}

class _PlantSelectionScreenState extends State<PlantSelectionScreen> {
  String? _selectedPlant;
  int? _selectedPlantId;

  final Map<String, int> plantMap = {
    '선인장' : 1,
    '다육이' : 2 ,
    '난' : 3,
    '산세베리아' : 4,
    '고무나무' : 5,
    '스파트필름' : 6,
    '몬스테라' : 7,
    '스투키' : 8,
    '행운목' : 9,
    '알로카시아' : 10,
    '아이비' : 11,
    '팔손이' : 12
    // '이름을 모르겠어요' :,
    // '여기 없어요',
  };

  @override
  Widget build(BuildContext context) {
    final plantEntries = plantMap.entries.toList();
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
            Text(
              '반려식물을 알려주세요!',
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
            const SizedBox(height: 32),
            // 식물 선택 그리드
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 2.5,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: plantEntries.length,
                itemBuilder: (context, index) {
                  final plantEntry = plantEntries[index];
                  final plantName = plantEntry.key;
                  final plantId = plantEntry.value;
                  final isSelected = _selectedPlantId == plantId;

                  return _PlantButton(
                    plant: plantName,
                    isSelected: isSelected,
                    onTap: () {
                      setState(() {
                        _selectedPlantId = plantId;
                        _selectedPlant = plantName;
                      });
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // 페이지 인디케이터
            Text(
              '1/3',
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

            // 다음 버튼
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _selectedPlant != null ? _nextPage : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedPlant != null
                      ? const Color(0xFF4F7F43)
                      : const Color(0xFFE2E8F0),
                  foregroundColor: _selectedPlant != null
                      ? Colors.white
                      : const Color(0xFFA0AEC0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
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
    if (_selectedPlantId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              PlantNameInputScreen(
                selectedPlantId: _selectedPlantId!,
                tokenStorage: widget.tokenStorage,
              ),
        ),
      );
    }
  }
}

class _PlantButton extends StatelessWidget {
  final String plant;
  final bool isSelected;
  final VoidCallback onTap;

  const _PlantButton({
    required this.plant,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
            plant,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected
                  ? const Color(0xFF4F7F43)
                  : const Color(0xFF2D3748),
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}