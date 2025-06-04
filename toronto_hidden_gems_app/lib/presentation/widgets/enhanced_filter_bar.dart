import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/hidden_gem.dart';
import '../../core/providers/gems_provider.dart';

class EnhancedFilterBar extends StatefulWidget {
  final Function(String?) onSearchChanged;
  final Function(GemCategory?) onCategoryChanged;
  final Function() onAdvancedFiltersToggled;
  final bool showAdvancedFilters;

  const EnhancedFilterBar({
    super.key,
    required this.onSearchChanged,
    required this.onCategoryChanged,
    required this.onAdvancedFiltersToggled,
    required this.showAdvancedFilters,
  });

  @override
  State<EnhancedFilterBar> createState() => _EnhancedFilterBarState();
}

class _EnhancedFilterBarState extends State<EnhancedFilterBar> {
  final TextEditingController _searchController = TextEditingController();
  GemCategory? _selectedCategory;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Search Bar
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: widget.onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search hidden gems...',
                hintStyle: TextStyle(color: Colors.grey[500]),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: theme.primaryColor,
                  size: 22,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear_rounded,
                          color: Colors.grey[500],
                          size: 20,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          widget.onSearchChanged('');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
            ),
          ),
          
          // Category Filter Chips with Icons
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildCategoryChip(
                          label: 'All',
                          icon: Icons.apps_rounded,
                          isSelected: _selectedCategory == null,
                          onTap: () {
                            setState(() {
                              _selectedCategory = null;
                            });
                            widget.onCategoryChanged(null);
                          },
                        ),
                        const SizedBox(width: 12),
                        ...GemCategory.values.map((category) => Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: _buildCategoryChip(
                            label: category.displayName,
                            icon: _getCategoryIcon(category),
                            isSelected: _selectedCategory == category,
                            onTap: () {
                              setState(() {
                                _selectedCategory = category;
                              });
                              widget.onCategoryChanged(category);
                            },
                          ),
                        )),
                      ],
                    ),
                  ),
                ),
                // Advanced Filters Toggle
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  child: Material(
                    color: widget.showAdvancedFilters 
                        ? theme.primaryColor 
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: widget.onAdvancedFiltersToggled,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: widget.showAdvancedFilters
                                ? theme.primaryColor
                                : Colors.grey[300]!,
                          ),
                        ),
                        child: Icon(
                          Icons.tune_rounded,
                          color: widget.showAdvancedFilters 
                              ? Colors.white 
                              : Colors.grey[600],
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Filter Status Banner
          Consumer<GemsProvider>(
            builder: (context, gemsProvider, child) {
              if (gemsProvider.currentMoodFilter != null) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _getMoodColor(gemsProvider.currentMoodFilter!),
                        _getMoodColor(gemsProvider.currentMoodFilter!).withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _getMoodEmoji(gemsProvider.currentMoodFilter!),
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${gemsProvider.currentMoodFilter} Vibes',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${gemsProvider.filteredGems.length} gems found',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => gemsProvider.clearFilters(),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                        ),
                        tooltip: 'Clear filter',
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildCategoryChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected 
              ? LinearGradient(
                  colors: [theme.primaryColor, theme.primaryColor.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.grey[300]!,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: theme.primaryColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
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

  Color _getMoodColor(String mood) {
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
      case 'budget':
        return Colors.teal;
      case 'family':
        return Colors.amber;
      default:
        return Theme.of(context).primaryColor;
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
      case 'budget':
        return '💰';
      case 'family':
        return '👨‍👩‍👧‍👦';
      default:
        return '💎';
    }
  }
} 