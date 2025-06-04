import 'package:flutter/material.dart';
import '../../core/models/gem_filters.dart';
import '../../core/models/hidden_gem.dart';

class FilterStatusBar extends StatelessWidget {
  final GemFilters filters;
  final Function(GemFilters) onFiltersChanged;
  final int totalResults;

  const FilterStatusBar({
    super.key,
    required this.filters,
    required this.onFiltersChanged,
    required this.totalResults,
  });

  @override
  Widget build(BuildContext context) {
    if (!filters.hasActiveFilters) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Results count and clear all
          Row(
            children: [
              Expanded(
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '$totalResults',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.primaryColor,
                        ),
                      ),
                      TextSpan(
                        text: ' gems found with ',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      TextSpan(
                        text: '${filters.activeFilterCount} filters',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Clear all button
              TextButton.icon(
                onPressed: () => onFiltersChanged(filters.clear()),
                icon: const Icon(Icons.clear_all_rounded, size: 18),
                label: const Text('Clear All'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red[400],
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Active filter chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _buildActiveFilterChips(context),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildActiveFilterChips(BuildContext context) {
    final theme = Theme.of(context);
    List<Widget> chips = [];

    // Search query
    if (filters.searchQuery.isNotEmpty) {
      chips.add(_buildFilterChip(
        context,
        '🔍 "${filters.searchQuery}"',
        () => onFiltersChanged(filters.copyWith(searchQuery: '')),
        theme.primaryColor,
      ));
    }

    // Categories
    for (final category in filters.categories) {
      chips.add(_buildFilterChip(
        context,
        '${_getCategoryEmoji(category)} ${category.displayName}',
        () {
          final newCategories = Set<GemCategory>.from(filters.categories)
            ..remove(category);
          onFiltersChanged(filters.copyWith(categories: newCategories));
        },
        theme.primaryColor,
      ));
    }

    // Quality filters
    for (final quality in filters.qualityFilters) {
      chips.add(_buildFilterChip(
        context,
        '${quality.emoji} ${quality.displayName}',
        () {
          final newQualities = Set<QualityFilter>.from(filters.qualityFilters)
            ..remove(quality);
          onFiltersChanged(filters.copyWith(qualityFilters: newQualities));
        },
        quality.color,
      ));
    }

    // Price ranges
    for (final price in filters.priceRanges) {
      chips.add(_buildFilterChip(
        context,
        '${price.emoji} ${price.symbol}',
        () {
          final newPrices = Set<PriceRange>.from(filters.priceRanges)
            ..remove(price);
          onFiltersChanged(filters.copyWith(priceRanges: newPrices));
        },
        price.color,
      ));
    }

    // Neighborhoods
    for (final neighborhood in filters.neighborhoods) {
      chips.add(_buildFilterChip(
        context,
        '📍 $neighborhood',
        () {
          final newNeighborhoods = Set<String>.from(filters.neighborhoods)
            ..remove(neighborhood);
          onFiltersChanged(filters.copyWith(neighborhoods: newNeighborhoods));
        },
        Colors.blue,
      ));
    }

    // Sentiments
    for (final sentiment in filters.sentiments) {
      chips.add(_buildFilterChip(
        context,
        '${sentiment.emoji} ${sentiment.displayName}',
        () {
          final newSentiments = Set<SentimentFilter>.from(filters.sentiments)
            ..remove(sentiment);
          onFiltersChanged(filters.copyWith(sentiments: newSentiments));
        },
        sentiment.color,
      ));
    }

    // Mood tags
    for (final mood in filters.moodTags) {
      chips.add(_buildFilterChip(
        context,
        '${_getMoodEmoji(mood)} $mood',
        () {
          final newMoods = Set<String>.from(filters.moodTags)
            ..remove(mood);
          onFiltersChanged(filters.copyWith(moodTags: newMoods));
        },
        _getMoodColor(context, mood),
      ));
    }

    // Rating range (if not default)
    if (filters.minRating > 0 || filters.maxRating < 5) {
      chips.add(_buildFilterChip(
        context,
        '⭐ ${filters.minRating.toStringAsFixed(1)}-${filters.maxRating.toStringAsFixed(1)}',
        () => onFiltersChanged(filters.copyWith(minRating: 0.0, maxRating: 5.0)),
        Colors.amber,
      ));
    }

    // Score range (if not default)
    if (filters.minScore > 0 || filters.maxScore < 100) {
      chips.add(_buildFilterChip(
        context,
        '💎 ${filters.minScore.toStringAsFixed(0)}-${filters.maxScore.toStringAsFixed(0)}',
        () => onFiltersChanged(filters.copyWith(minScore: 0.0, maxScore: 100.0)),
        theme.primaryColor,
      ));
    }

    // Distance (if set)
    if (filters.maxDistance != null) {
      chips.add(_buildFilterChip(
        context,
        '📍 ≤${filters.maxDistance!.toStringAsFixed(1)}km',
        () => onFiltersChanged(filters.copyWith(maxDistance: null)),
        Colors.blue,
      ));
    }

    // Mention count range (if not default)
    if (filters.minMentionCount > 0 || filters.maxMentionCount < 999999) {
      final maxDisplay = filters.maxMentionCount == 999999 
          ? 'Any' 
          : filters.maxMentionCount.toString();
      chips.add(_buildFilterChip(
        context,
        '🔥 ${filters.minMentionCount}-$maxDisplay mentions',
        () => onFiltersChanged(filters.copyWith(
          minMentionCount: 0,
          maxMentionCount: 999999,
        )),
        Colors.orange,
      ));
    }

    // Sort option (if not default)
    if (filters.sortOption != GemSortOption.popularity) {
      chips.add(_buildFilterChip(
        context,
        '📊 ${filters.sortOption.displayName}',
        () => onFiltersChanged(filters.copyWith(sortOption: GemSortOption.popularity)),
        Colors.grey[600]!,
      ));
    }

    return chips;
  }

  Widget _buildFilterChip(
    BuildContext context,
    String label,
    VoidCallback onRemove,
    Color color,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onRemove,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getCategoryEmoji(GemCategory category) {
    switch (category) {
      case GemCategory.restaurant:
        return '🍽️';
      case GemCategory.cafe:
        return '☕';
      case GemCategory.park:
        return '🌳';
      case GemCategory.museum:
        return '🏛️';
      case GemCategory.shopping:
        return '🛍️';
      case GemCategory.entertainment:
        return '🎭';
      case GemCategory.historical:
        return '🏰';
      case GemCategory.viewpoint:
        return '👁️';
    }
  }

  String _getMoodEmoji(String mood) {
    switch (mood.toLowerCase()) {
      case 'romantic':
        return '💕';
      case 'foodie':
        return '🍽️';
      case 'adventure':
        return '🌟';
      case 'relaxing':
        return '🌸';
      case 'cultural':
        return '🎭';
      case 'nightlife':
        return '🌙';
      case 'family':
        return '👨‍👩‍👧‍👦';
      default:
        return '💎';
    }
  }

  Color _getMoodColor(BuildContext context, String mood) {
    switch (mood.toLowerCase()) {
      case 'romantic':
        return Colors.pink;
      case 'foodie':
        return Colors.orange;
      case 'adventure':
        return Colors.purple;
      case 'relaxing':
        return Colors.green;
      case 'cultural':
        return Colors.indigo;
      case 'nightlife':
        return Colors.deepPurple;
      case 'family':
        return Colors.amber;
      default:
        return Theme.of(context).primaryColor;
    }
  }
} 