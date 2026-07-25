import 'package:uuid/uuid.dart';

/// A single detected mineral / rock component with a confidence percentage.
class Detection {
  final String name;
  final double confidence; // 0–100

  const Detection({required this.name, required this.confidence});

  factory Detection.fromJson(Map<String, dynamic> json) => Detection(
        name: json['name'] as String,
        confidence: (json['confidence'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {'name': name, 'confidence': confidence};
}

/// Estimated potential for an economically interesting mineral.
class MineralPotential {
  final String mineral; // Gold, Silver, Copper, Lithium, Rare Earth Elements, Gemstones
  final double probability; // 0–100

  const MineralPotential({required this.mineral, required this.probability});

  factory MineralPotential.fromJson(Map<String, dynamic> json) =>
      MineralPotential(
        mineral: json['mineral'] as String,
        probability: (json['probability'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() =>
      {'mineral': mineral, 'probability': probability};
}

/// The full result of analysing one or more photos of a rock sample.
class ScanResult {
  final String id;
  final DateTime timestamp;

  /// Local file paths of the captured photos.
  final List<String> imagePaths;

  final String rockType;
  final double rockConfidence; // 0–100 confidence in the rock-type call

  final List<Detection> detectedMinerals;
  final List<MineralPotential> potentials;
  final List<String> recommendations;

  final double? latitude;
  final double? longitude;

  /// Where the result came from: "mock", "backend" or "cached".
  final String source;

  /// True once this scan has been synced to the cloud (community feed etc.).
  final bool synced;

  ScanResult({
    String? id,
    DateTime? timestamp,
    required this.imagePaths,
    required this.rockType,
    required this.rockConfidence,
    required this.detectedMinerals,
    required this.potentials,
    required this.recommendations,
    this.latitude,
    this.longitude,
    this.source = 'mock',
    this.synced = false,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();

  /// Highest-value potential, used to rank a sample as high/medium/low priority.
  MineralPotential? get topPotential {
    if (potentials.isEmpty) return null;
    return potentials.reduce(
        (a, b) => a.probability >= b.probability ? a : b);
  }

  /// Coarse priority label derived from the top potential.
  String get priority {
    final top = topPotential;
    if (top == null) return 'Low';
    if (top.probability >= 60) return 'High';
    if (top.probability >= 30) return 'Medium';
    return 'Low';
  }

  bool get hasLocation => latitude != null && longitude != null;

  ScanResult copyWith({bool? synced, double? latitude, double? longitude}) {
    return ScanResult(
      id: id,
      timestamp: timestamp,
      imagePaths: imagePaths,
      rockType: rockType,
      rockConfidence: rockConfidence,
      detectedMinerals: detectedMinerals,
      potentials: potentials,
      recommendations: recommendations,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      source: source,
      synced: synced ?? this.synced,
    );
  }

  factory ScanResult.fromJson(Map<String, dynamic> json) => ScanResult(
        id: json['id'] as String?,
        timestamp: json['timestamp'] != null
            ? DateTime.parse(json['timestamp'] as String)
            : null,
        imagePaths: (json['imagePaths'] as List?)?.cast<String>() ?? const [],
        rockType: json['rockType'] as String? ?? 'Unknown',
        rockConfidence: (json['rockConfidence'] as num?)?.toDouble() ?? 0,
        detectedMinerals: (json['detectedMinerals'] as List?)
                ?.map((e) => Detection.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        potentials: (json['potentials'] as List?)
                ?.map((e) =>
                    MineralPotential.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        recommendations:
            (json['recommendations'] as List?)?.cast<String>() ?? const [],
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        source: json['source'] as String? ?? 'mock',
        synced: json['synced'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'imagePaths': imagePaths,
        'rockType': rockType,
        'rockConfidence': rockConfidence,
        'detectedMinerals': detectedMinerals.map((e) => e.toJson()).toList(),
        'potentials': potentials.map((e) => e.toJson()).toList(),
        'recommendations': recommendations,
        'latitude': latitude,
        'longitude': longitude,
        'source': source,
        'synced': synced,
      };
}
