import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/hidden_gem.dart';
import '../../core/providers/gems_provider.dart';

class MapFilterBar extends StatefulWidget {
  final Function(Set<GemCategory>) onCategoryFilterChanged;
  final Function(double, double) onScoreRangeChanged;
  final Function(bool) onHighQualityToggled;
  final Function(bool) onPopularToggled;

  const MapFilterBar({
    super.key,
    required this.onCategoryFilterChanged,
    required this.onScoreRangeChanged,
    required this.onHighQualityToggled,
    required this.onPopularToggled,
  });

  @override
  State<MapFilterBar> createState() => _MapFilterBarState();
}

class _MapFilterBarState extends State<MapFilterBar> {
  Set<GemCategory> _selectedCategories = {};
  bool _showHighQualityOnly = false;
  bool _showPopularOnly = false;
  double _minScore = 0.0;
  double _maxScore = 100.0;
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Quick Filter Chips Row
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.tune_rounded,
                      color: theme.primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Map Filters',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.primaryColor,
                      ),
                    ),
                    const Spacer(),
                    if (_hasActiveFilters())
                      TextButton(
                        onPressed: _clearAllFilters,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red[400],
                          minimumSize: Size.zero,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        ),
                        child: const Text('Clear All', style: TextStyle(fontSize: 12)),
                      ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _isExpanded = !_isExpanded;
                        });
                      },
                      icon: Icon(
                        _isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: theme.primaryColor,
                      ),
                      style: IconButton.styleFrom(
                        minimumSize: const Size(32, 32),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Quick Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildQuickFilterChip(
                        'High Quality 💎',
                        _showHighQualityOnly,
                        () {
                          setState(() {
                            _showHighQualityOnly = !_showHighQualityOnly;
                          });
                          widget.onHighQualityToggled(_showHighQualityOnly);
                        },
                        gradient: [Colors.purple.shade400, Colors.purple.shade600],
                      ),
                      const SizedBox(width: 8),
                      _buildQuickFilterChip(
                        'Popular 🔥',
                        _showPopularOnly,
                        () {
                          setState(() {
                            _showPopularOnly = !_showPopularOnly;
                          });
                          widget.onPopularToggled(_showPopularOnly);
                        },
                        gradient: [Colors.orange.shade400, Colors.orange.shade600],
                      ),
                      const SizedBox(width: 8),
                      _buildScoreRangeChip(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Expanded Filters
          if (_isExpanded) ...[
            Container(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey[200]!),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  
                  // Category Filters
                  Text(
                    'Categories',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: GemCategory.values.map((category) {
                      final isSelected = _selectedCategories.contains(category);
                      return _buildCategoryChip(category, isSelected);
                    }).toList(),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Score Range Slider
                  Text(
                    'Hidden Gem Score Range: ${_minScore.round()} - ${_maxScore.round()}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  RangeSlider(
                    values: RangeValues(_minScore, _maxScore),
                    min: 0,
                    max: 100,
                    divisions: 20,
                    labels: RangeLabels(
                      _minScore.round().toString(),
                      _maxScore.round().toString(),
                    ),
                    activeColor: theme.primaryColor,
                    onChanged: (RangeValues values) {
                      setState(() {
                        _minScore = values.start;
                        _maxScore = values.end;
                      });
                      widget.onScoreRangeChanged(values.start, values.end);
                    },
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickFilterChip(
    String label,
    bool isSelected,
    VoidCallback onTap, {
    List<Color>? gradient,
  }) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: isSelected 
              ? LinearGradient(colors: gradient ?? [theme.primaryColor, theme.primaryColor.withOpacity(0.8)])
              : null,
          color: isSelected ? null : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
                ? Colors.transparent 
                : Colors.grey[300]!,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: (gradient?[0] ?? theme.primaryColor).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildScoreRangeChip() {
    final theme = Theme.of(context);
    final hasScoreFilter = _minScore > 0 || _maxScore < 100;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: hasScoreFilter ? theme.primaryColor.withOpacity(0.1) : Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasScoreFilter ? theme.primaryColor.withOpacity(0.3) : Colors.grey[300]!,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.score_rounded,
            size: 16,
            color: hasScoreFilter ? theme.primaryColor : Colors.grey[600],
          ),
          const SizedBox(width: 4),
          Text(
            hasScoreFilter 
                ? '${_minScore.round()}-${_maxScore.round()}' 
                : 'Score: All',
            style: TextStyle(
              color: hasScoreFilter ? theme.primaryColor : Colors.grey[700],
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(GemCategory category, bool isSelected) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedCategories.remove(category);
          } else {
            _selectedCategories.add(category);
          }
        });
        widget.onCategoryFilterChanged(_selectedCategories);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? theme.primaryColor : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? theme.primaryColor : Colors.grey[300]!,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getCategoryIcon(category),
              size: 16,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
            const SizedBox(width: 6),
            Text(
              category.displayName,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(GemCategory category) {
    switch (category) {
      case GemCategory.restaurant:
        return Icons.restaurant_rounded;
      case GemCategory.cafe:
        return Icons.coffee_rounded;
      case GemCategory.park:
        return Icons.park_rounded;
      case GemCategory.museum:
        return Icons.museum_rounded;
      case GemCategory.shopping:
        return Icons.shopping_bag_rounded;
      case GemCategory.entertainment:
        return Icons.theater_comedy_rounded;
      case GemCategory.historical:
        return Icons.account_balance_rounded;
      case GemCategory.viewpoint:
        return Icons.visibility_rounded;
    }
  }

  bool _hasActiveFilters() {
    return _selectedCategories.isNotEmpty ||
           _showHighQualityOnly ||
           _showPopularOnly ||
           _minScore > 0 ||
           _maxScore < 100;
  }

  void _clearAllFilters() {
    setState(() {
      _selectedCategories.clear();
      _showHighQualityOnly = false;
      _showPopularOnly = false;
      _minScore = 0.0;
      _maxScore = 100.0;
    });
    
    widget.onCategoryFilterChanged(_selectedCategories);
    widget.onHighQualityToggled(false);
    widget.onPopularToggled(false);
    widget.onScoreRangeChanged(0.0, 100.0);
  }
} 