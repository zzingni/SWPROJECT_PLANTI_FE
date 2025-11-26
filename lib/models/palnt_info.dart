class PlantInfo {
  final String id;
  final String plantName;         // backend 'name'
  final String? scientificName;
  final String? family;
  final String? watering;
  final String? optimalTemperature; // backend 'temperature'
  final String? optimalHumidity;    // backend 'humidity'
  final String? pestManagement;     // backend 'pestControl'
  final String? functionalInfo;    // backend 'functionality'
  final String? specialCare;
  final String? toxicity;
  final String? characterImageUrl; // backend 없으면 null 또는 서버에 추가 요청

  PlantInfo({
    required this.id,
    required this.plantName,
    this.scientificName,
    this.family,
    this.watering,
    this.optimalTemperature,
    this.optimalHumidity,
    this.pestManagement,
    this.functionalInfo,
    this.specialCare,
    this.toxicity,
    this.characterImageUrl,
  });

  factory PlantInfo.fromJson(Map<String, dynamic> json) {
    return PlantInfo(
      id: json['id']?.toString() ?? '',
      plantName: json['name'] ?? json['plantName'] ?? '',
      scientificName: json['scientificName'] as String?,
      family: json['family'] as String?,
      watering: json['watering'] as String?,
      optimalTemperature: json['temperature'] as String?,
      optimalHumidity: json['humidity'] as String?,
      pestManagement: json['pestControl'] as String?,
      functionalInfo: json['functionality'] as String?,
      specialCare: json['specialCare'] as String?,
      toxicity: json['toxicity'] as String?,
      characterImageUrl: json['characterImageUrl'] as String?, // 서버에 없다면 null
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': plantName,
    'scientificName': scientificName,
    'family': family,
    'watering': watering,
    'temperature': optimalTemperature,
    'humidity': optimalHumidity,
    'pestControl': pestManagement,
    'functionality': functionalInfo,
    'specialCare': specialCare,
    'toxicity': toxicity,
    'characterImageUrl': characterImageUrl,
  };
}