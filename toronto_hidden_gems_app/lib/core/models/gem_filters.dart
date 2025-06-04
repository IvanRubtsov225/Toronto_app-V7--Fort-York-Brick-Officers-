import 'package:flutter/material.dart';
import 'hidden_gem.dart';

enum FilterType {
  category,
  neighborhood,
  priceRange,
  rating,
  score,
  sentiment,
  features,
  moodTags,
  quality,
  distance,
}

enum PriceRange {
  budget,      // $ (0-15)
  moderate,    // $$ (15-30)
  expensive,   // $$$ (30-50)
  luxury,      // $$$$ (50+)
}

enum SentimentFilter {
  veryPositive,
  positive,
  neutral,
  negative,
  veryNegative,
}

enum QualityFilter {
  highQuality,
  popular,
  unique,
  hidden,
  trending,
}

extension PriceRangeExtension on PriceRange {
  String get displayName {
    switch (this) {
      case PriceRange.budget:
        return 'Budget';
      case PriceRange.moderate:
        return 'Moderate';
      case PriceRange.expensive:
        return 'Expensive';
      case PriceRange.luxury:
        return 'Luxury';
    }
  }

  String get symbol {
    switch (this) {
      case PriceRange.budget:
        return '\$';
      case PriceRange.moderate:
        return '\$\$';
      case PriceRange.expensive:
        return '\$\$\$';
      case PriceRange.luxury:
        return '\$\$\$\$';
    }
  }

  String get emoji {
    switch (this) {
      case PriceRange.budget:
        return '💰';
      case PriceRange.moderate:
        return '💵';
      case PriceRange.expensive:
        return '💸';
      case PriceRange.luxury:
        return '🏆';
    }
  }

  Color get color {
    switch (this) {
      case PriceRange.budget:
        return Colors.green;
      case PriceRange.moderate:
        return Colors.blue;
      case PriceRange.expensive:
        return Colors.orange;
      case PriceRange.luxury:
        return Colors.purple;
    }
  }
}

extension SentimentFilterExtension on SentimentFilter {
  String get displayName {
    switch (this) {
      case SentimentFilter.veryPositive:
        return 'Very Positive';
      case SentimentFilter.positive:
        return 'Positive';
      case SentimentFilter.neutral:
        return 'Neutral';
      case SentimentFilter.negative:
        return 'Negative';
      case SentimentFilter.veryNegative:
        return 'Very Negative';
    }
  }

  String get emoji {
    switch (this) {
      case SentimentFilter.veryPositive:
        return '😍';
      case SentimentFilter.positive:
        return '😊';
      case SentimentFilter.neutral:
        return '😐';
      case SentimentFilter.negative:
        return '😞';
      case SentimentFilter.veryNegative:
        return '😡';
    }
  }

  Color get color {
    switch (this) {
      case SentimentFilter.veryPositive:
        return Colors.green.shade600;
      case SentimentFilter.positive:
        return Colors.lightGreen;
      case SentimentFilter.neutral:
        return Colors.grey;
      case SentimentFilter.negative:
        return Colors.orange;
      case SentimentFilter.veryNegative:
        return Colors.red;
    }
  }
}

extension QualityFilterExtension on QualityFilter {
  String get displayName {
    switch (this) {
      case QualityFilter.highQuality:
        return 'High Quality';
      case QualityFilter.popular:
        return 'Popular';
      case QualityFilter.unique:
        return 'Unique';
      case QualityFilter.hidden:
        return 'Hidden';
      case QualityFilter.trending:
        return 'Trending';
    }
  }

  String get emoji {
    switch (this) {
      case QualityFilter.highQuality:
        return '💎';
      case QualityFilter.popular:
        return '🔥';
      case QualityFilter.unique:
        return '🌟';
      case QualityFilter.hidden:
        return '🎭';
      case QualityFilter.trending:
        return '📈';
    }
  }

  Color get color {
    switch (this) {
      case QualityFilter.highQuality:
        return Colors.purple;
      case QualityFilter.popular:
        return Colors.red;
      case QualityFilter.unique:
        return Colors.amber;
      case QualityFilter.hidden:
        return Colors.indigo;
      case QualityFilter.trending:
        return Colors.cyan;
    }
  }
}

class GemFilters {
  final Set<GemCategory> categories;
  final Set<String> neighborhoods;
  final Set<PriceRange> priceRanges;
  final double minRating;
  final double maxRating;
  final double minScore;
  final double maxScore;
  final double minDinesafeScore;
  final double maxDinesafeScore;
  final Set<SentimentFilter> sentiments;
  final Set<String> features;
  final Set<String> moodTags;
  final Set<QualityFilter> qualityFilters;
  final double? maxDistance;
  final int minMentionCount;
  final int maxMentionCount;
  final String searchQuery;
  final GemSortOption sortOption;

  const GemFilters({
    this.categories = const {},
    this.neighborhoods = const {},
    this.priceRanges = const {},
    this.minRating = 0.0,
    this.maxRating = 5.0,
    this.minScore = 0.0,
    this.maxScore = 100.0,
    this.minDinesafeScore = 0.0,
    this.maxDinesafeScore = 100.0,
    this.sentiments = const {},
    this.features = const {},
    this.moodTags = const {},
    this.qualityFilters = const {},
    this.maxDistance,
    this.minMentionCount = 0,
    this.maxMentionCount = 999999,
    this.searchQuery = '',
    this.sortOption = GemSortOption.popularity,
  });

  bool get hasActiveFilters {
    return categories.isNotEmpty ||
           neighborhoods.isNotEmpty ||
           priceRanges.isNotEmpty ||
           minRating > 0.0 ||
           maxRating < 5.0 ||
           minScore > 0.0 ||
           maxScore < 100.0 ||
           minDinesafeScore > 0.0 ||
           maxDinesafeScore < 100.0 ||
           sentiments.isNotEmpty ||
           features.isNotEmpty ||
           moodTags.isNotEmpty ||
           qualityFilters.isNotEmpty ||
           maxDistance != null ||
           minMentionCount > 0 ||
           maxMentionCount < 999999 ||
           searchQuery.isNotEmpty;
  }

  int get activeFilterCount {
    int count = 0;
    if (categories.isNotEmpty) count++;
    if (neighborhoods.isNotEmpty) count++;
    if (priceRanges.isNotEmpty) count++;
    if (minRating > 0.0 || maxRating < 5.0) count++;
    if (minScore > 0.0 || maxScore < 100.0) count++;
    if (minDinesafeScore > 0.0 || maxDinesafeScore < 100.0) count++;
    if (sentiments.isNotEmpty) count++;
    if (features.isNotEmpty) count++;
    if (moodTags.isNotEmpty) count++;
    if (qualityFilters.isNotEmpty) count++;
    if (maxDistance != null) count++;
    if (minMentionCount > 0 || maxMentionCount < 999999) count++;
    if (searchQuery.isNotEmpty) count++;
    return count;
  }

  GemFilters copyWith({
    Set<GemCategory>? categories,
    Set<String>? neighborhoods,
    Set<PriceRange>? priceRanges,
    double? minRating,
    double? maxRating,
    double? minScore,
    double? maxScore,
    double? minDinesafeScore,
    double? maxDinesafeScore,
    Set<SentimentFilter>? sentiments,
    Set<String>? features,
    Set<String>? moodTags,
    Set<QualityFilter>? qualityFilters,
    double? maxDistance,
    int? minMentionCount,
    int? maxMentionCount,
    String? searchQuery,
    GemSortOption? sortOption,
  }) {
    return GemFilters(
      categories: categories ?? this.categories,
      neighborhoods: neighborhoods ?? this.neighborhoods,
      priceRanges: priceRanges ?? this.priceRanges,
      minRating: minRating ?? this.minRating,
      maxRating: maxRating ?? this.maxRating,
      minScore: minScore ?? this.minScore,
      maxScore: maxScore ?? this.maxScore,
      minDinesafeScore: minDinesafeScore ?? this.minDinesafeScore,
      maxDinesafeScore: maxDinesafeScore ?? this.maxDinesafeScore,
      sentiments: sentiments ?? this.sentiments,
      features: features ?? this.features,
      moodTags: moodTags ?? this.moodTags,
      qualityFilters: qualityFilters ?? this.qualityFilters,
      maxDistance: maxDistance ?? this.maxDistance,
      minMentionCount: minMentionCount ?? this.minMentionCount,
      maxMentionCount: maxMentionCount ?? this.maxMentionCount,
      searchQuery: searchQuery ?? this.searchQuery,
      sortOption: sortOption ?? this.sortOption,
    );
  }

  GemFilters clear() {
    return const GemFilters();
  }

  bool matches(HiddenGem gem) {
    // Category filter
    if (categories.isNotEmpty && !categories.contains(gem.category)) {
      return false;
    }

    // Neighborhood filter
    if (neighborhoods.isNotEmpty && !neighborhoods.contains(gem.neighborhood)) {
      return false;
    }

    // Price range filter (based on hidden gem score as proxy)
    if (priceRanges.isNotEmpty) {
      PriceRange gemPriceRange = _getPriceRangeFromScore(gem.hiddenGemScore);
      if (!priceRanges.contains(gemPriceRange)) {
        return false;
      }
    }

    // Rating filter
    if (gem.rating != null) {
      if (gem.rating! < minRating || gem.rating! > maxRating) {
        return false;
      }
    }

    // Score filters
    if (gem.hiddenGemScore < minScore || gem.hiddenGemScore > maxScore) {
      return false;
    }

    if (gem.dinesafeScore < minDinesafeScore || gem.dinesafeScore > maxDinesafeScore) {
      return false;
    }

    // Sentiment filter
    if (sentiments.isNotEmpty) {
      SentimentFilter gemSentiment = _getSentimentFromValue(gem.avgSentiment);
      if (!sentiments.contains(gemSentiment)) {
        return false;
      }
    }

    // Features filter
    if (features.isNotEmpty) {
      bool hasMatchingFeature = features.any((feature) => 
        gem.features.any((gemFeature) => 
          gemFeature.toLowerCase().contains(feature.toLowerCase())
        )
      );
      if (!hasMatchingFeature) {
        return false;
      }
    }

    // Mood tags filter
    if (moodTags.isNotEmpty) {
      bool hasMatchingMood = moodTags.any((mood) => 
        gem.moodTagsList.any((gemMood) => 
          gemMood.toLowerCase().contains(mood.toLowerCase())
        )
      );
      if (!hasMatchingMood) {
        return false;
      }
    }

    // Quality filters
    if (qualityFilters.isNotEmpty) {
      bool matchesQuality = qualityFilters.any((quality) {
        switch (quality) {
          case QualityFilter.highQuality:
            return gem.isHighQuality;
          case QualityFilter.popular:
            return gem.isPopular;
          case QualityFilter.unique:
            return gem.isUnique;
          case QualityFilter.hidden:
            return gem.hiddenGemScore >= 70 && gem.mentionCount < 3;
          case QualityFilter.trending:
            return gem.mentionCount >= 3 && gem.avgSentiment > 0.3;
        }
      });
      if (!matchesQuality) {
        return false;
      }
    }

    // Mention count filter
    if (gem.mentionCount < minMentionCount || gem.mentionCount > maxMentionCount) {
      return false;
    }

    // Search query filter
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      final nameMatch = gem.name.toLowerCase().contains(query);
      final addressMatch = gem.address.toLowerCase().contains(query);
      final descriptionMatch = gem.description.toLowerCase().contains(query);
      final neighborhoodMatch = gem.neighborhood.toLowerCase().contains(query);
      final featuresMatch = gem.features.any((feature) => 
        feature.toLowerCase().contains(query)
      );
      final moodMatch = gem.moodTagsList.any((mood) => 
        mood.toLowerCase().contains(query)
      );
      
      if (!nameMatch && !addressMatch && !descriptionMatch && 
          !neighborhoodMatch && !featuresMatch && !moodMatch) {
        return false;
      }
    }

    return true;
  }

  static PriceRange _getPriceRangeFromScore(double score) {
    if (score >= 85) return PriceRange.luxury;
    if (score >= 70) return PriceRange.expensive;
    if (score >= 55) return PriceRange.moderate;
    return PriceRange.budget;
  }

  static SentimentFilter _getSentimentFromValue(double sentiment) {
    if (sentiment >= 0.5) return SentimentFilter.veryPositive;
    if (sentiment >= 0.2) return SentimentFilter.positive;
    if (sentiment >= -0.2) return SentimentFilter.neutral;
    if (sentiment >= -0.5) return SentimentFilter.negative;
    return SentimentFilter.veryNegative;
  }
} 