import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/gems_provider.dart';

class ModernSearchBar extends StatefulWidget {
  final String? initialQuery;
  final Function(String) onSearchChanged;
  final VoidCallback onFilterPressed;
  final bool hasActiveFilters;

  const ModernSearchBar({
    super.key,
    this.initialQuery,
    required this.onSearchChanged,
    required this.onFilterPressed,
    this.hasActiveFilters = false,
  });

  @override
  State<ModernSearchBar> createState() => _ModernSearchBarState();
}

class _ModernSearchBarState extends State<ModernSearchBar>
    with SingleTickerProviderStateMixin {
  late TextEditingController _controller;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late FocusNode _focusNode;

  bool _isSearchActive = false;
  bool _showSuggestions = false;
  List<String> _suggestions = [];

  // Popular search suggestions
  final List<String> _popularSearches = [
    'romantic dinner',
    'coffee shops',
    'hidden restaurants',
    'rooftop views',
    'art galleries',
    'local markets',
    'brunch spots',
    'craft beer',
    'vintage shops',
    'food trucks',
    'night life',
    'family activities',
  ];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
    _focusNode = FocusNode();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _controller.addListener(_onSearchChanged);
    _focusNode.addListener(_onFocusChanged);
    _updateSuggestions('');
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    setState(() {
      _showSuggestions = _focusNode.hasFocus && _suggestions.isNotEmpty;
    });
    
    if (_showSuggestions) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  void _onSearchChanged() {
    final query = _controller.text;
    setState(() {
      _isSearchActive = query.isNotEmpty;
    });
    
    _updateSuggestions(query);
    widget.onSearchChanged(query);
  }

  void _updateSuggestions(String query) {
    if (query.isEmpty) {
      setState(() {
        _suggestions = _popularSearches.take(6).toList();
        _showSuggestions = _focusNode.hasFocus;
      });
      return;
    }

    final gemsProvider = context.read<GemsProvider>();
    final allGems = gemsProvider.allGems;
    
    Set<String> suggestions = {};
    
    // Add matching gem names
    for (final gem in allGems) {
      if (gem.name.toLowerCase().contains(query.toLowerCase())) {
        suggestions.add(gem.name);
      }
      
      // Add matching neighborhoods
      if (gem.neighborhood.toLowerCase().contains(query.toLowerCase())) {
        suggestions.add(gem.neighborhood);
      }
      
      // Add matching features
      for (final feature in gem.features) {
        if (feature.toLowerCase().contains(query.toLowerCase())) {
          suggestions.add(feature);
        }
      }
      
      // Add matching mood tags
      for (final mood in gem.moodTagsList) {
        if (mood.toLowerCase().contains(query.toLowerCase())) {
          suggestions.add(mood);
        }
      }
    }
    
    // Add popular searches that match
    for (final popular in _popularSearches) {
      if (popular.toLowerCase().contains(query.toLowerCase())) {
        suggestions.add(popular);
      }
    }
    
    setState(() {
      _suggestions = suggestions.take(8).toList();
      _showSuggestions = _focusNode.hasFocus && _suggestions.isNotEmpty;
    });
    
    if (_showSuggestions) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: () {
        // Hide suggestions when tapping outside
        if (_showSuggestions) {
          _focusNode.unfocus();
          setState(() {
            _showSuggestions = false;
          });
          _animationController.reverse();
        }
      },
      child: Column(
        children: [
          // Search Bar
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                // Search input
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search Toronto\'s gems...',
                      hintStyle: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 16,
                      ),
                      prefixIcon: AnimatedBuilder(
                        animation: _animationController,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _isSearchActive ? 1.1 : 1.0,
                            child: Icon(
                              Icons.search_rounded,
                              color: _isSearchActive ? theme.primaryColor : Colors.grey[400],
                              size: 24,
                            ),
                          );
                        },
                      ),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Clear button
                          if (_isSearchActive)
                            AnimatedBuilder(
                              animation: _fadeAnimation,
                              builder: (context, child) {
                                return Opacity(
                                  opacity: _fadeAnimation.value,
                                  child: IconButton(
                                    onPressed: () {
                                      _controller.clear();
                                      _onSearchChanged();
                                    },
                                    icon: Icon(
                                      Icons.clear_rounded,
                                      color: Colors.grey[500],
                                      size: 20,
                                    ),
                                  ),
                                );
                              },
                            ),
                          
                          // Voice search button
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            child: IconButton(
                              onPressed: _startVoiceSearch,
                              icon: Icon(
                                Icons.mic_rounded,
                                color: Colors.grey[500],
                                size: 22,
                              ),
                              tooltip: 'Voice search',
                            ),
                          ),
                          
                          // Filter button
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              gradient: widget.hasActiveFilters 
                                  ? LinearGradient(
                                      colors: [theme.primaryColor, theme.primaryColor.withOpacity(0.8)],
                                    )
                                  : null,
                              color: widget.hasActiveFilters ? null : Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              onPressed: widget.onFilterPressed,
                              icon: Icon(
                                Icons.tune_rounded,
                                color: widget.hasActiveFilters ? Colors.white : Colors.grey[600],
                                size: 22,
                              ),
                              tooltip: 'Filters',
                            ),
                          ),
                        ],
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Suggestions - only show when focused and have suggestions
          if (_showSuggestions)
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      margin: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        bottom: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Header
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              _isSearchActive ? 'Suggestions' : 'Popular Searches',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.primaryColor,
                              ),
                            ),
                          ),
                          
                          // Suggestion items
                          ..._suggestions.take(6).map((suggestion) => 
                            _buildSuggestionItem(context, suggestion)
                          ).toList(),
                          
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSuggestionItem(BuildContext context, String suggestion) {
    final theme = Theme.of(context);
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          _controller.text = suggestion;
          widget.onSearchChanged(suggestion);
          
          // Hide suggestions and remove focus
          _focusNode.unfocus();
          setState(() {
            _isSearchActive = true;
            _showSuggestions = false;
          });
          _animationController.reverse();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                _getSuggestionIcon(suggestion),
                color: Colors.grey[500],
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  suggestion,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                Icons.north_west_rounded,
                color: Colors.grey[400],
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getSuggestionIcon(String suggestion) {
    final lower = suggestion.toLowerCase();
    
    if (lower.contains('restaurant') || lower.contains('food') || lower.contains('dinner')) {
      return Icons.restaurant_rounded;
    }
    if (lower.contains('coffee') || lower.contains('cafe')) {
      return Icons.coffee_rounded;
    }
    if (lower.contains('shop') || lower.contains('market')) {
      return Icons.shopping_bag_rounded;
    }
    if (lower.contains('art') || lower.contains('gallery') || lower.contains('museum')) {
      return Icons.museum_rounded;
    }
    if (lower.contains('park') || lower.contains('garden')) {
      return Icons.park_rounded;
    }
    if (lower.contains('view') || lower.contains('rooftop')) {
      return Icons.visibility_rounded;
    }
    if (lower.contains('night') || lower.contains('bar')) {
      return Icons.nightlife_rounded;
    }
    if (lower.contains('family') || lower.contains('kid')) {
      return Icons.family_restroom_rounded;
    }
    if (lower.contains('romantic') || lower.contains('date')) {
      return Icons.favorite_rounded;
    }
    
    return Icons.search_rounded;
  }

  void _startVoiceSearch() {
    // TODO: Implement voice search
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Voice search coming soon! 🎤'),
        backgroundColor: Theme.of(context).primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }
} 