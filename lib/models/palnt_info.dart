class PlantInfo {
  final String plantName; // 식물명
  final String scientificName; // 식물학명
  final String family; // 과목
  final String watering; // 물주기
  final String optimalTemperature; // 적정 온도
  final String optimalHumidity; // 적정 습도
  final String pestManagement; // 병충해 관리 정보
  final String functionalInfo; // 기능성 정보
  final String specialCare; // 특별관리 정보
  final String toxicity; // 독성 정보
  final String? characterImageUrl; // 대표 캐릭터 이미지 URL

  PlantInfo({
    required this.plantName,
    required this.scientificName,
    required this.family,
    required this.watering,
    required this.optimalTemperature,
    required this.optimalHumidity,
    required this.pestManagement,
    required this.functionalInfo,
    required this.specialCare,
    required this.toxicity,
    this.characterImageUrl,
  });

  factory PlantInfo.fromJson(Map<String, dynamic> json) {
    return PlantInfo(
      plantName: json['plantName'] as String? ?? '',
      scientificName: json['scientificName'] as String? ?? '',
      family: json['family'] as String? ?? '',
      watering: json['watering'] as String? ?? '',
      optimalTemperature: json['optimalTemperature'] as String? ?? '',
      optimalHumidity: json['optimalHumidity'] as String? ?? '',
      pestManagement: json['pestManagement'] as String? ?? '',
      functionalInfo: json['functionalInfo'] as String? ?? '',
      specialCare: json['specialCare'] as String? ?? '',
      toxicity: json['toxicity'] as String? ?? '',
      characterImageUrl: json['characterImageUrl'] as String?,
    );
  }
}

