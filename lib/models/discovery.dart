import 'package:uuid/uuid.dart';

/// A shared community discovery — a scan someone chose to publish to the map.
class Discovery {
  final String id;
  final String author;
  final String rockType;
  final String topMineral;
  final double topProbability; // 0–100
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final String? note;

  /// Average community rating, 0–5.
  final double rating;
  final int ratingCount;

  Discovery({
    String? id,
    required this.author,
    required this.rockType,
    required this.topMineral,
    required this.topProbability,
    required this.latitude,
    required this.longitude,
    DateTime? timestamp,
    this.note,
    this.rating = 0,
    this.ratingCount = 0,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();

  factory Discovery.fromJson(Map<String, dynamic> json) => Discovery(
        id: json['id'] as String?,
        author: json['author'] as String? ?? 'Anonymous',
        rockType: json['rockType'] as String? ?? 'Unknown',
        topMineral: json['topMineral'] as String? ?? '—',
        topProbability: (json['topProbability'] as num?)?.toDouble() ?? 0,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        timestamp: json['timestamp'] != null
            ? DateTime.parse(json['timestamp'] as String)
            : null,
        note: json['note'] as String?,
        rating: (json['rating'] as num?)?.toDouble() ?? 0,
        ratingCount: (json['ratingCount'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'author': author,
        'rockType': rockType,
        'topMineral': topMineral,
        'topProbability': topProbability,
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': timestamp.toIso8601String(),
        'note': note,
        'rating': rating,
        'ratingCount': ratingCount,
      };

  Discovery withRating(double newStars) {
    final total = rating * ratingCount + newStars;
    final count = ratingCount + 1;
    return Discovery(
      id: id,
      author: author,
      rockType: rockType,
      topMineral: topMineral,
      topProbability: topProbability,
      latitude: latitude,
      longitude: longitude,
      timestamp: timestamp,
      note: note,
      rating: total / count,
      ratingCount: count,
    );
  }
}
