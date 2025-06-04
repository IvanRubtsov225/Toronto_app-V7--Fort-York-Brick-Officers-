import 'dart:math';

enum GemCategory {
  restaurant,
  cafe,
  park,
  museum,
  shopping,
  entertainment,
  historical,
  viewpoint;

  String get displayName {
    switch (this) {
      case GemCategory.restaurant:
        return 'Restaurant';
      case GemCategory.cafe:
        return 'Café';
      case GemCategory.park:
        return 'Park';
      case GemCategory.museum:
        return 'Museum';
      case GemCategory.shopping:
        return 'Shopping';
      case GemCategory.entertainment:
        return 'Entertainment';
      case GemCategory.historical:
        return 'Historical';
      case GemCategory.viewpoint:
        return 'Viewpoint';
    }
  }
}

enum GemSortOption {
  distance,
  rating,
  popularity,
  newest;

  String get displayName {
    switch (this) {
      case GemSortOption.distance:
        return 'Distance';
      case GemSortOption.rating:
        return 'Rating';
      case GemSortOption.popularity:
        return 'Popularity';
      case GemSortOption.newest:
        return 'Newest';
    }
  }
}

class HiddenGem {
  final String id;
  final String name;
  final String address;
  final String type;
  final double latitude;
  final double longitude;
  final double hiddenGemScore;
  final double dinesafeScore;
  final double recommendationScore;
  final double uniquenessScore;
  final int mentionCount;
  final double avgSentiment;
  final String moodTags;
  final int positiveIndicators;
  final int negativeIndicators;
  final String establishmentId;
  
  // Additional properties for UI
  final String description;
  final String neighborhood;
  final GemCategory category;
  final double? rating;
  final List<String> features;
  final String? imageUrl;
  final String? websiteUrl;

  const HiddenGem({
    required this.id,
    required this.name,
    required this.address,
    required this.type,
    required this.latitude,
    required this.longitude,
    required this.hiddenGemScore,
    required this.dinesafeScore,
    required this.recommendationScore,
    required this.uniquenessScore,
    required this.mentionCount,
    required this.avgSentiment,
    required this.moodTags,
    required this.positiveIndicators,
    required this.negativeIndicators,
    required this.establishmentId,
    required this.description,
    required this.neighborhood,
    required this.category,
    this.rating,
    this.features = const [],
    this.imageUrl,
    this.websiteUrl,
  });

  factory HiddenGem.fromJson(Map<String, dynamic> json) {
    return HiddenGem(
      id: json['id'] ?? json['establishment_id'] ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      type: json['type'] ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      hiddenGemScore: (json['hidden_gem_score'] ?? 0.0).toDouble(),
      dinesafeScore: (json['dinesafe_score'] ?? 0.0).toDouble(),
      recommendationScore: (json['recommendation_score'] ?? 0.0).toDouble(),
      uniquenessScore: (json['uniqueness_score'] ?? 0.0).toDouble(),
      mentionCount: (json['mention_count'] ?? 0).toInt(),
      avgSentiment: (json['avg_sentiment'] ?? 0.0).toDouble(),
      moodTags: json['mood_tags'] ?? '',
      positiveIndicators: (json['positive_indicators'] ?? 0).toInt(),
      negativeIndicators: (json['negative_indicators'] ?? 0).toInt(),
      establishmentId: json['establishment_id'] ?? '',
      description: json['description'] ?? 'A hidden gem in Toronto',
      neighborhood: json['neighborhood'] ?? _getNeighborhoodFromCoords(
        (json['latitude'] ?? 0.0).toDouble(),
        (json['longitude'] ?? 0.0).toDouble(),
      ),
      category: _getCategoryFromType(json['type'] ?? ''),
      rating: json['rating']?.toDouble(),
      features: List<String>.from(json['features'] ?? []),
      imageUrl: json['image_url'],
      websiteUrl: json['website_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'type': type,
      'latitude': latitude,
      'longitude': longitude,
      'hidden_gem_score': hiddenGemScore,
      'dinesafe_score': dinesafeScore,
      'recommendation_score': recommendationScore,
      'uniqueness_score': uniquenessScore,
      'mention_count': mentionCount,
      'avg_sentiment': avgSentiment,
      'mood_tags': moodTags,
      'positive_indicators': positiveIndicators,
      'negative_indicators': negativeIndicators,
      'establishment_id': establishmentId,
      'description': description,
      'neighborhood': neighborhood,
      'category': category.name,
      'rating': rating,
      'features': features,
      'image_url': imageUrl,
      'website_url': websiteUrl,
    };
  }

  // Helper getters
  List<String> get moodTagsList {
    return moodTags.split(',').map((tag) => tag.trim()).where((tag) => tag.isNotEmpty).toList();
  }

  String get scoreGrade {
    if (hiddenGemScore >= 90) return 'A+';
    if (hiddenGemScore >= 80) return 'A';
    if (hiddenGemScore >= 70) return 'B';
    if (hiddenGemScore >= 60) return 'C';
    return 'D';
  }

  String get sentimentDescription {
    if (avgSentiment >= 0.5) return 'Very Positive';
    if (avgSentiment >= 0.2) return 'Positive';
    if (avgSentiment >= -0.2) return 'Neutral';
    if (avgSentiment >= -0.5) return 'Negative';
    return 'Very Negative';
  }

  bool get isHighQuality => hiddenGemScore >= 75 && dinesafeScore >= 90;
  bool get isPopular => mentionCount >= 5;
  bool get isUnique => uniquenessScore >= 80;

  // Distance calculation method
  double calculateDistance(double userLat, double userLng) {
    const double earthRadius = 6371; // Earth's radius in kilometers
    
    double dLat = _degreesToRadians(latitude - userLat);
    double dLng = _degreesToRadians(longitude - userLng);
    
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(userLat)) * cos(_degreesToRadians(latitude)) *
        sin(dLng / 2) * sin(dLng / 2);
    
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  // Direction calculation method
  String getDirectionFrom(double userLat, double userLng) {
    double deltaLng = longitude - userLng;
    double deltaLat = latitude - userLat;
    
    double angle = atan2(deltaLng, deltaLat) * 180 / pi;
    if (angle < 0) angle += 360;
    
    if (angle >= 337.5 || angle < 22.5) return 'North ⬆️';
    if (angle >= 22.5 && angle < 67.5) return 'Northeast ↗️';
    if (angle >= 67.5 && angle < 112.5) return 'East ➡️';
    if (angle >= 112.5 && angle < 157.5) return 'Southeast ↘️';
    if (angle >= 157.5 && angle < 202.5) return 'South ⬇️';
    if (angle >= 202.5 && angle < 247.5) return 'Southwest ↙️';
    if (angle >= 247.5 && angle < 292.5) return 'West ⬅️';
    return 'Northwest ↖️';
  }

  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  static String _getNeighborhoodFromCoords(double lat, double lng) {
    // CN Tower area (Entertainment District)
    if (lat >= 43.640 && lat <= 43.650 && lng >= -79.395 && lng <= -79.385) {
      return 'Entertainment District';
    }
    // Distillery District
    if (lat >= 43.648 && lat <= 43.653 && lng >= -79.365 && lng <= -79.355) {
      return 'Distillery District';
    }
    // King West
    if (lat >= 43.640 && lat <= 43.650 && lng >= -79.400 && lng <= -79.380) {
      return 'King West';
    }
    // Queen West
    if (lat >= 43.643 && lat <= 43.650 && lng >= -79.420 && lng <= -79.390) {
      return 'Queen West';
    }
    // Kensington Market
    if (lat >= 43.653 && lat <= 43.658 && lng >= -79.405 && lng <= -79.395) {
      return 'Kensington Market';
    }
    // Chinatown
    if (lat >= 43.650 && lat <= 43.655 && lng >= -79.400 && lng <= -79.390) {
      return 'Chinatown';
    }
    return 'Toronto';
  }

  static GemCategory _getCategoryFromType(String type) {
    final lowerType = type.toLowerCase();
    if (lowerType.contains('restaurant') || lowerType.contains('food')) {
      return GemCategory.restaurant;
    }
    if (lowerType.contains('cafe') || lowerType.contains('coffee')) {
      return GemCategory.cafe;
    }
    if (lowerType.contains('park') || lowerType.contains('garden')) {
      return GemCategory.park;
    }
    if (lowerType.contains('museum') || lowerType.contains('gallery')) {
      return GemCategory.museum;
    }
    if (lowerType.contains('shop') || lowerType.contains('store')) {
      return GemCategory.shopping;
    }
    if (lowerType.contains('theater') || lowerType.contains('entertainment')) {
      return GemCategory.entertainment;
    }
    if (lowerType.contains('historic') || lowerType.contains('heritage')) {
      return GemCategory.historical;
    }
    if (lowerType.contains('view') || lowerType.contains('lookout')) {
      return GemCategory.viewpoint;
    }
    return GemCategory.restaurant; // Default
  }

  @override
  String toString() {
    return 'HiddenGem(name: $name, score: $hiddenGemScore)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HiddenGem && other.establishmentId == establishmentId;
  }

  @override
  int get hashCode => establishmentId.hashCode;
} 