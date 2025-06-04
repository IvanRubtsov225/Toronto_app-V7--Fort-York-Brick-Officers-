import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/hidden_gem.dart';
import '../../core/models/gem_filters.dart';
import '../../core/providers/gems_provider.dart';

class ComprehensiveFilterPanel extends StatefulWidget {
  final GemFilters initialFilters;
  final Function(GemFilters) onFiltersChanged;
  final VoidCallback onClose;

  const ComprehensiveFilterPanel({
    super.key,
    required this.initialFilters,
    required this.onFiltersChanged,
    required this.onClose,
  });

  @override
  State<ComprehensiveFilterPanel> createState() => _ComprehensiveFilterPanelState();
}

class _ComprehensiveFilterPanelState extends State<ComprehensiveFilterPanel>
    with TickerProviderStateMixin {
  late GemFilters _currentFilters;
  late TabController _tabController;
  
  final List<String> _tabs = [
    'Quick',
    'Categories',
    'Quality',
    'Price',
    'Location',
    'Advanced'
  ];

  @override
  void initState() {
    super.initState();
    _currentFilters = widget.initialFilters;
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _updateFilters(GemFilters newFilters) {
    setState(() {
      _currentFilters = newFilters;
    });
    widget.onFiltersChanged(newFilters);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    
    return Container(
      height: mediaQuery.size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle and Header
          _buildHeader(theme),
          
          // Tab Bar
          _buildTabBar(theme),
          
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildQuickFiltersTab(),
                _buildCategoriesTab(),
                _buildQualityTab(),
                _buildPriceTab(),
                _buildLocationTab(),
                _buildAdvancedTab(),
              ],
            ),
          ),
          
          // Action Buttons
          _buildActionButtons(theme),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Header row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Filter & Sort',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.primaryColor,
                      ),
                    ),
                    Text(
                      '${_currentFilters.activeFilterCount} active filters',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Clear all button
              if (_currentFilters.hasActiveFilters)
                TextButton.icon(
                  onPressed: () => _updateFilters(_currentFilters.clear()),
                  icon: const Icon(Icons.clear_all_rounded, size: 18),
                  label: const Text('Clear All'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red[400],
                  ),
                ),
              
              // Close button
              IconButton(
                onPressed: widget.onClose,
                icon: const Icon(Icons.close_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.grey[100],
                  shape: const CircleBorder(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicator: BoxDecoration(
          color: theme.primaryColor,
          borderRadius: BorderRadius.circular(8),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[600],
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        tabs: _tabs.map((tab) => Tab(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(tab),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildQuickFiltersTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Popular Quick Filters
          _buildSectionTitle('🔥 Popular Filters'),
          const SizedBox(height: 16),
          
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildQuickFilterChip(
                'High Quality 💎',
                _currentFilters.qualityFilters.contains(QualityFilter.highQuality),
                () => _toggleQualityFilter(QualityFilter.highQuality),
                gradient: [Colors.purple.shade400, Colors.purple.shade600],
              ),
              _buildQuickFilterChip(
                'Popular 🔥',
                _currentFilters.qualityFilters.contains(QualityFilter.popular),
                () => _toggleQualityFilter(QualityFilter.popular),
                gradient: [Colors.red.shade400, Colors.red.shade600],
              ),
              _buildQuickFilterChip(
                'Highly Rated ⭐',
                _currentFilters.minRating >= 4.0,
                () => _toggleRatingFilter(4.0),
                gradient: [Colors.amber.shade400, Colors.amber.shade600],
              ),
              _buildQuickFilterChip(
                'Budget Friendly 💰',
                _currentFilters.priceRanges.contains(PriceRange.budget),
                () => _togglePriceRange(PriceRange.budget),
                gradient: [Colors.green.shade400, Colors.green.shade600],
              ),
              _buildQuickFilterChip(
                'Trending 📈',
                _currentFilters.qualityFilters.contains(QualityFilter.trending),
                () => _toggleQualityFilter(QualityFilter.trending),
                gradient: [Colors.cyan.shade400, Colors.cyan.shade600],
              ),
              _buildQuickFilterChip(
                'Hidden Gems 🎭',
                _currentFilters.qualityFilters.contains(QualityFilter.hidden),
                () => _toggleQualityFilter(QualityFilter.hidden),
                gradient: [Colors.indigo.shade400, Colors.indigo.shade600],
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Mood-based Filters
          _buildSectionTitle('💖 Mood Filters'),
          const SizedBox(height: 16),
          
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              'Romantic', 'Foodie', 'Adventure', 'Relaxing', 'Cultural', 'Nightlife', 'Family'
            ].map((mood) => _buildMoodChip(mood)).toList(),
          ),
          
          const SizedBox(height: 32),
          
          // Sentiment Filters
          _buildSectionTitle('😊 Vibe Check'),
          const SizedBox(height: 16),
          
          Row(
            children: SentimentFilter.values.map((sentiment) {
              final isSelected = _currentFilters.sentiments.contains(sentiment);
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: GestureDetector(
                    onTap: () => _toggleSentiment(sentiment),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? sentiment.color : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? sentiment.color : Colors.grey[300]!,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            sentiment.emoji,
                            style: const TextStyle(fontSize: 20),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            sentiment.displayName.split(' ').first,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.grey[700],
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('🏷️ Categories'),
          const SizedBox(height: 16),
          
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: GemCategory.values.length,
            itemBuilder: (context, index) {
              final category = GemCategory.values[index];
              final isSelected = _currentFilters.categories.contains(category);
              
              return GestureDetector(
                onTap: () => _toggleCategory(category),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: isSelected ? LinearGradient(
                      colors: [
                        Theme.of(context).primaryColor,
                        Theme.of(context).primaryColor.withOpacity(0.8),
                      ],
                    ) : null,
                    color: isSelected ? null : Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected 
                          ? Theme.of(context).primaryColor 
                          : Colors.grey[200]!,
                    ),
                    boxShadow: isSelected ? [
                      BoxShadow(
                        color: Theme.of(context).primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ] : null,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getCategoryIcon(category),
                        color: isSelected ? Colors.white : Colors.grey[600],
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          category.displayName,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey[800],
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQualityTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('✨ Quality Indicators'),
          const SizedBox(height: 16),
          
          ...QualityFilter.values.map((quality) {
            final isSelected = _currentFilters.qualityFilters.contains(quality);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () => _toggleQualityFilter(quality),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: isSelected ? LinearGradient(
                      colors: [quality.color, quality.color.withOpacity(0.8)],
                    ) : null,
                    color: isSelected ? null : Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? quality.color : Colors.grey[200]!,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? Colors.white.withOpacity(0.2)
                              : quality.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          quality.emoji,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              quality.displayName,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.grey[800],
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              _getQualityDescription(quality),
                              style: TextStyle(
                                color: isSelected 
                                    ? Colors.white.withOpacity(0.9) 
                                    : Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        const Icon(
                          Icons.check_circle_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildPriceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('💰 Price Range'),
          const SizedBox(height: 16),
          
          ...PriceRange.values.map((price) {
            final isSelected = _currentFilters.priceRanges.contains(price);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () => _togglePriceRange(price),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: isSelected ? LinearGradient(
                      colors: [price.color, price.color.withOpacity(0.8)],
                    ) : null,
                    color: isSelected ? null : Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? price.color : Colors.grey[200]!,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? Colors.white.withOpacity(0.2)
                              : price.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          price.emoji,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${price.symbol} ${price.displayName}',
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.grey[800],
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              _getPriceDescription(price),
                              style: TextStyle(
                                color: isSelected 
                                    ? Colors.white.withOpacity(0.9) 
                                    : Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        const Icon(
                          Icons.check_circle_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildLocationTab() {
    final neighborhoods = [
      'Entertainment District',
      'Distillery District',
      'King West',
      'Queen West',
      'Kensington Market',
      'Chinatown',
      'Toronto'
    ];
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('📍 Neighborhoods'),
          const SizedBox(height: 16),
          
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: neighborhoods.map((neighborhood) {
              final isSelected = _currentFilters.neighborhoods.contains(neighborhood);
              return GestureDetector(
                onTap: () => _toggleNeighborhood(neighborhood),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: isSelected ? LinearGradient(
                      colors: [
                        Theme.of(context).primaryColor,
                        Theme.of(context).primaryColor.withOpacity(0.8),
                      ],
                    ) : null,
                    color: isSelected ? null : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected 
                          ? Theme.of(context).primaryColor 
                          : Colors.grey[300]!,
                    ),
                  ),
                  child: Text(
                    neighborhood,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 32),
          
          // Distance Filter
          _buildSectionTitle('🚶‍♂️ Distance'),
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Maximum Distance: ${_currentFilters.maxDistance?.toStringAsFixed(1) ?? 'Any'} km',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('0 km'),
                    Expanded(
                      child: Slider(
                        value: _currentFilters.maxDistance ?? 10.0,
                        min: 0.5,
                        max: 10.0,
                        divisions: 19,
                        activeColor: Theme.of(context).primaryColor,
                        onChanged: (value) {
                          _updateFilters(_currentFilters.copyWith(
                            maxDistance: value,
                          ));
                        },
                      ),
                    ),
                    const Text('10 km'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rating Filter
          _buildSectionTitle('⭐ Rating Range'),
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rating: ${_currentFilters.minRating.toStringAsFixed(1)} - ${_currentFilters.maxRating.toStringAsFixed(1)} ⭐',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                RangeSlider(
                  values: RangeValues(_currentFilters.minRating, _currentFilters.maxRating),
                  min: 0,
                  max: 5,
                  divisions: 10,
                  activeColor: Colors.amber,
                  labels: RangeLabels(
                    _currentFilters.minRating.toStringAsFixed(1),
                    _currentFilters.maxRating.toStringAsFixed(1),
                  ),
                  onChanged: (values) {
                    _updateFilters(_currentFilters.copyWith(
                      minRating: values.start,
                      maxRating: values.end,
                    ));
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Hidden Gem Score Filter
          _buildSectionTitle('💎 Hidden Gem Score'),
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Score: ${_currentFilters.minScore.toStringAsFixed(0)} - ${_currentFilters.maxScore.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                RangeSlider(
                  values: RangeValues(_currentFilters.minScore, _currentFilters.maxScore),
                  min: 0,
                  max: 100,
                  divisions: 20,
                  activeColor: Theme.of(context).primaryColor,
                  labels: RangeLabels(
                    _currentFilters.minScore.toStringAsFixed(0),
                    _currentFilters.maxScore.toStringAsFixed(0),
                  ),
                  onChanged: (values) {
                    _updateFilters(_currentFilters.copyWith(
                      minScore: values.start,
                      maxScore: values.end,
                    ));
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Popularity Filter
          _buildSectionTitle('🔥 Popularity (Mention Count)'),
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mentions: ${_currentFilters.minMentionCount} - ${_currentFilters.maxMentionCount == 999999 ? "Any" : _currentFilters.maxMentionCount.toString()}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                RangeSlider(
                  values: RangeValues(
                    _currentFilters.minMentionCount.toDouble(),
                    _currentFilters.maxMentionCount == 999999 
                        ? 50.0 
                        : _currentFilters.maxMentionCount.toDouble(),
                  ),
                  min: 0,
                  max: 50,
                  divisions: 50,
                  activeColor: Colors.orange,
                  labels: RangeLabels(
                    _currentFilters.minMentionCount.toString(),
                    _currentFilters.maxMentionCount == 999999 
                        ? "50+" 
                        : _currentFilters.maxMentionCount.toString(),
                  ),
                  onChanged: (values) {
                    _updateFilters(_currentFilters.copyWith(
                      minMentionCount: values.start.toInt(),
                      maxMentionCount: values.end == 50.0 ? 999999 : values.end.toInt(),
                    ));
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Sort Options
          _buildSectionTitle('📊 Sort By'),
          const SizedBox(height: 16),
          
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: GemSortOption.values.map((sort) {
              final isSelected = _currentFilters.sortOption == sort;
              return GestureDetector(
                onTap: () => _updateFilters(_currentFilters.copyWith(sortOption: sort)),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: isSelected ? LinearGradient(
                      colors: [
                        Theme.of(context).primaryColor,
                        Theme.of(context).primaryColor.withOpacity(0.8),
                      ],
                    ) : null,
                    color: isSelected ? null : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected 
                          ? Theme.of(context).primaryColor 
                          : Colors.grey[300]!,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getSortIcon(sort),
                        color: isSelected ? Colors.white : Colors.grey[600],
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        sort.displayName,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildMoodChip(String mood) {
    final isSelected = _currentFilters.moodTags.contains(mood);
    final moodEmoji = _getMoodEmoji(mood);
    final moodColor = _getMoodColor(mood);
    
    return GestureDetector(
      onTap: () => _toggleMoodTag(mood),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected ? LinearGradient(
            colors: [moodColor, moodColor.withOpacity(0.8)],
          ) : null,
          color: isSelected ? null : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? moodColor : Colors.grey[300]!,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(moodEmoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Text(
              mood,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Consumer<GemsProvider>(
        builder: (context, gemsProvider, child) {
          return Row(
            children: [
              // Results count
              Expanded(
                child: Text(
                  '${_getFilteredGemsCount(gemsProvider)} gems found',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              
              // Apply button
              ElevatedButton(
                onPressed: widget.onClose,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Show Results',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Helper methods
  void _toggleCategory(GemCategory category) {
    final categories = Set<GemCategory>.from(_currentFilters.categories);
    if (categories.contains(category)) {
      categories.remove(category);
    } else {
      categories.add(category);
    }
    _updateFilters(_currentFilters.copyWith(categories: categories));
  }

  void _toggleQualityFilter(QualityFilter quality) {
    final qualityFilters = Set<QualityFilter>.from(_currentFilters.qualityFilters);
    if (qualityFilters.contains(quality)) {
      qualityFilters.remove(quality);
    } else {
      qualityFilters.add(quality);
    }
    _updateFilters(_currentFilters.copyWith(qualityFilters: qualityFilters));
  }

  void _togglePriceRange(PriceRange price) {
    final priceRanges = Set<PriceRange>.from(_currentFilters.priceRanges);
    if (priceRanges.contains(price)) {
      priceRanges.remove(price);
    } else {
      priceRanges.add(price);
    }
    _updateFilters(_currentFilters.copyWith(priceRanges: priceRanges));
  }

  void _toggleNeighborhood(String neighborhood) {
    final neighborhoods = Set<String>.from(_currentFilters.neighborhoods);
    if (neighborhoods.contains(neighborhood)) {
      neighborhoods.remove(neighborhood);
    } else {
      neighborhoods.add(neighborhood);
    }
    _updateFilters(_currentFilters.copyWith(neighborhoods: neighborhoods));
  }

  void _toggleSentiment(SentimentFilter sentiment) {
    final sentiments = Set<SentimentFilter>.from(_currentFilters.sentiments);
    if (sentiments.contains(sentiment)) {
      sentiments.remove(sentiment);
    } else {
      sentiments.add(sentiment);
    }
    _updateFilters(_currentFilters.copyWith(sentiments: sentiments));
  }

  void _toggleMoodTag(String mood) {
    final moodTags = Set<String>.from(_currentFilters.moodTags);
    if (moodTags.contains(mood)) {
      moodTags.remove(mood);
    } else {
      moodTags.add(mood);
    }
    _updateFilters(_currentFilters.copyWith(moodTags: moodTags));
  }

  void _toggleRatingFilter(double minRating) {
    if (_currentFilters.minRating >= minRating) {
      _updateFilters(_currentFilters.copyWith(minRating: 0.0));
    } else {
      _updateFilters(_currentFilters.copyWith(minRating: minRating));
    }
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

  IconData _getSortIcon(GemSortOption sort) {
    switch (sort) {
      case GemSortOption.distance:
        return Icons.near_me_rounded;
      case GemSortOption.rating:
        return Icons.star_rounded;
      case GemSortOption.popularity:
        return Icons.trending_up_rounded;
      case GemSortOption.newest:
        return Icons.new_releases_rounded;
    }
  }

  String _getQualityDescription(QualityFilter quality) {
    switch (quality) {
      case QualityFilter.highQuality:
        return 'Top-rated gems with excellent scores';
      case QualityFilter.popular:
        return 'Frequently mentioned and loved spots';
      case QualityFilter.unique:
        return 'One-of-a-kind experiences';
      case QualityFilter.hidden:
        return 'Lesser-known local secrets';
      case QualityFilter.trending:
        return 'Recently discovered hotspots';
    }
  }

  String _getPriceDescription(PriceRange price) {
    switch (price) {
      case PriceRange.budget:
        return 'Great value for money';
      case PriceRange.moderate:
        return 'Good balance of quality and price';
      case PriceRange.expensive:
        return 'Premium experiences';
      case PriceRange.luxury:
        return 'Exclusive high-end spots';
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
      case 'family':
        return Colors.amber;
      default:
        return Theme.of(context).primaryColor;
    }
  }

  int _getFilteredGemsCount(GemsProvider gemsProvider) {
    return gemsProvider.allGems.where((gem) => _currentFilters.matches(gem)).length;
  }
} 