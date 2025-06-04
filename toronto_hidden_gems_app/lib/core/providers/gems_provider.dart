import 'package:flutter/foundation.dart';
import '../models/hidden_gem.dart';
import '../services/api_service.dart';

enum GemsLoadingState {
  idle,
  loading,
  loaded,
  error,
}

// Add navigation context enum
enum NavigationContext {
  home,
  gemsList,
  gemsListWithFilters,
  map,
  mapWithFilters,
  emotionalExploration,
  search,
}

class GemsProvider extends ChangeNotifier {
  final ApiService _apiService;
  
  // State
  GemsLoadingState _loadingState = GemsLoadingState.idle;
  List<HiddenGem> _allGems = [];
  List<HiddenGem> _featuredGems = [];
  List<HiddenGem> _topGems = [];
  List<HiddenGem> _filteredGems = [];
  List<HiddenGem> _nearbyGems = [];
  List<String> _availableMoods = [];
  Map<String, dynamic> _stats = {};
  
  // Current filters
  String? _currentMoodFilter;
  String? _currentTypeFilter;
  double? _currentMinScore;
  String _currentSearchQuery = '';
  GemCategory? _currentCategoryFilter;
  
  // Navigation context tracking
  NavigationContext _lastNavigationContext = NavigationContext.home;
  Map<String, dynamic> _navigationData = {};
  
  // Error handling
  String? _error;
  
  GemsProvider({required ApiService apiService}) : _apiService = apiService;

  // Getters
  GemsLoadingState get loadingState => _loadingState;
  List<HiddenGem> get allGems => _allGems;
  List<HiddenGem> get featuredGems => _featuredGems;
  List<HiddenGem> get topGems => _topGems;
  List<HiddenGem> get filteredGems => _filteredGems;
  List<HiddenGem> get nearbyGems => _nearbyGems;
  List<String> get availableMoods => _availableMoods;
  Map<String, dynamic> get stats => _stats;
  String? get currentMoodFilter => _currentMoodFilter;
  String? get currentTypeFilter => _currentTypeFilter;
  double? get currentMinScore => _currentMinScore;
  String get currentSearchQuery => _currentSearchQuery;
  GemCategory? get currentCategoryFilter => _currentCategoryFilter;
  String? get error => _error;
  
  // Navigation context getters
  NavigationContext get lastNavigationContext => _lastNavigationContext;
  Map<String, dynamic> get navigationData => _navigationData;
  
  bool get isLoading => _loadingState == GemsLoadingState.loading;
  bool get hasError => _loadingState == GemsLoadingState.error;
  bool get hasData => _loadingState == GemsLoadingState.loaded;
  bool get hasFilters => _currentMoodFilter != null || 
                        _currentTypeFilter != null || 
                        _currentMinScore != null ||
                        _currentCategoryFilter != null ||
                        _currentSearchQuery.isNotEmpty;

  // Navigation context methods
  void setNavigationContext(NavigationContext context, {Map<String, dynamic>? data}) {
    _lastNavigationContext = context;
    _navigationData = data ?? {};
    notifyListeners();
  }

  String getBackNavigationRoute() {
    switch (_lastNavigationContext) {
      case NavigationContext.home:
        return '/home';
      case NavigationContext.gemsList:
      case NavigationContext.gemsListWithFilters:
        return '/gems';
      case NavigationContext.map:
      case NavigationContext.mapWithFilters:
        return '/map';
      case NavigationContext.emotionalExploration:
        return '/gems'; // Go to gems list to show filtered results
      case NavigationContext.search:
        return '/gems';
      default:
        return '/home';
    }
  }

  // Initialize data
  Future<void> initialize() async {
    print('💎 GemsProvider: Initialize called');
    print('💎 GemsProvider: Current state - ${_loadingState}, gems count: ${_allGems.length}');
    
    if (_loadingState == GemsLoadingState.loaded && _allGems.isNotEmpty) {
      print('💎 GemsProvider: Already loaded, skipping initialization');
      return; // Already loaded
    }
    
    print('💎 GemsProvider: Starting initialization...');
    await loadAllGems();
    print('💎 GemsProvider: Initialization complete. Final gems count: ${_allGems.length}');
  }

  // Load all gems data (deprecated - use loadAllGems)
  Future<void> loadAllData() async {
    await loadAllGems();
  }

  // Load all gems (alias for compatibility)
  Future<void> loadAllGems() async {
    print('💎 GemsProvider: loadAllGems called');
    _setLoadingState(GemsLoadingState.loading);
    
    try {
      print('💎 GemsProvider: Making API calls...');
      final results = await Future.wait([
        _apiService.getAllGems(),
        _apiService.getTopGems(),
        _apiService.getAllMoods(),
        _apiService.getGemsStats(),
      ]);
      
      print('💎 GemsProvider: API calls completed successfully');
      
      // Handle ApiResponse types correctly
      _allGems = (results[0] as ApiResponse<List<HiddenGem>>).data;
      _topGems = (results[1] as ApiResponse<List<HiddenGem>>).data;
      _availableMoods = List<String>.from(results[2] as List);
      _stats = results[3] as Map<String, dynamic>;
      
      // Create featured gems from top gems (high quality + popular)
      _featuredGems = _topGems.where((gem) => gem.isHighQuality).take(5).toList();
      
      print('💎 GemsProvider: Data processed - ${_allGems.length} total gems, ${_topGems.length} top gems, ${_featuredGems.length} featured gems');
      
      _filteredGems = List.from(_allGems);
      _error = null;
      _setLoadingState(GemsLoadingState.loaded);
    } catch (e) {
      print('💎 GemsProvider: Error loading gems: $e');
      _error = 'Failed to load gems: $e';
      _setLoadingState(GemsLoadingState.error);
    }
    notifyListeners();
  }

  // Load nearby gems
  Future<void> loadNearbyGems({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
  }) async {
    if (_allGems.isEmpty) {
      await loadAllGems();
    }

    try {
      _nearbyGems = _allGems.where((gem) {
        final distance = gem.calculateDistance(latitude, longitude);
        return distance <= radiusKm;
      }).toList();
      
      // Sort by distance
      _nearbyGems.sort((a, b) {
        final distanceA = a.calculateDistance(latitude, longitude);
        final distanceB = b.calculateDistance(latitude, longitude);
        return distanceA.compareTo(distanceB);
      });
      
      notifyListeners();
    } catch (e) {
      print('Error loading nearby gems: $e');
    }
  }

  // Sort gems
  void sortGems(GemSortOption sortOption, {double? userLat, double? userLng}) {
    switch (sortOption) {
      case GemSortOption.distance:
        if (userLat != null && userLng != null) {
          _filteredGems.sort((a, b) {
            final distanceA = a.calculateDistance(userLat, userLng);
            final distanceB = b.calculateDistance(userLat, userLng);
            return distanceA.compareTo(distanceB);
          });
        }
        break;
      case GemSortOption.rating:
        _filteredGems.sort((a, b) {
          final ratingA = a.rating ?? 0;
          final ratingB = b.rating ?? 0;
          return ratingB.compareTo(ratingA); // Descending
        });
        break;
      case GemSortOption.popularity:
        _filteredGems.sort((a, b) => b.mentionCount.compareTo(a.mentionCount));
        break;
      case GemSortOption.newest:
        _filteredGems.sort((a, b) => b.hiddenGemScore.compareTo(a.hiddenGemScore));
        break;
    }
    notifyListeners();
  }

  // Filter by category
  void filterByCategory(GemCategory? category) {
    _currentCategoryFilter = category;
    _applyCurrentFilters();
  }

  // Advanced filtering with multiple criteria
  void applyAdvancedFilters({
    GemCategory? category,
    String? neighborhood,
    double? minScore,
    double? minRating,
    GemSortOption? sortOption,
  }) {
    _currentCategoryFilter = category;
    _currentMinScore = minScore;
    
    // Start with all gems
    List<HiddenGem> filtered = List.from(_allGems);
    
    // Apply category filter
    if (category != null) {
      filtered = filtered.where((gem) => gem.category == category).toList();
    }
    
    // Apply neighborhood filter
    if (neighborhood != null && neighborhood.isNotEmpty) {
      filtered = filtered.where((gem) => gem.neighborhood == neighborhood).toList();
    }
    
    // Apply minimum score filter
    if (minScore != null && minScore > 0) {
      filtered = filtered.where((gem) => gem.hiddenGemScore >= minScore).toList();
    }
    
    // Apply minimum rating filter
    if (minRating != null && minRating > 0) {
      filtered = filtered.where((gem) => 
        gem.rating != null && gem.rating! >= minRating
      ).toList();
    }
    
    // Apply search query if active
    if (_currentSearchQuery.isNotEmpty) {
      filtered = filtered.where((gem) =>
        gem.name.toLowerCase().contains(_currentSearchQuery.toLowerCase()) ||
        gem.address.toLowerCase().contains(_currentSearchQuery.toLowerCase()) ||
        gem.description.toLowerCase().contains(_currentSearchQuery.toLowerCase()) ||
        gem.neighborhood.toLowerCase().contains(_currentSearchQuery.toLowerCase())
      ).toList();
    }
    
    // Apply mood filter if active
    if (_currentMoodFilter != null) {
      filtered = filtered.where((gem) => 
        gem.moodTagsList.any((tag) => 
          tag.toLowerCase().contains(_currentMoodFilter!.toLowerCase())
        )
      ).toList();
    }
    
    // Apply sorting
    if (sortOption != null) {
      _sortFilteredGems(filtered, sortOption);
    }
    
    _filteredGems = filtered;
    notifyListeners();
  }

  void _sortFilteredGems(List<HiddenGem> gems, GemSortOption sortOption) {
    switch (sortOption) {
      case GemSortOption.rating:
        gems.sort((a, b) {
          final ratingA = a.rating ?? 0;
          final ratingB = b.rating ?? 0;
          return ratingB.compareTo(ratingA); // Descending
        });
        break;
      case GemSortOption.popularity:
        gems.sort((a, b) => b.mentionCount.compareTo(a.mentionCount));
        break;
      case GemSortOption.newest:
        gems.sort((a, b) => b.hiddenGemScore.compareTo(a.hiddenGemScore));
        break;
      case GemSortOption.distance:
        // Distance sorting requires user location - will be handled separately
        gems.sort((a, b) => b.hiddenGemScore.compareTo(a.hiddenGemScore));
        break;
    }
  }

  void _applyCurrentFilters() {
    applyAdvancedFilters(
      category: _currentCategoryFilter,
      minScore: _currentMinScore,
    );
  }

  // Refresh data
  Future<void> refresh() async {
    _allGems.clear();
    _topGems.clear();
    _featuredGems.clear();
    _filteredGems.clear();
    _nearbyGems.clear();
    _availableMoods.clear();
    _stats.clear();
    
    await loadAllGems();
  }

  // Search gems
  Future<void> searchGems(String query) async {
    _currentSearchQuery = query;
    
    if (query.isEmpty) {
      _applyCurrentFilters();
      return;
    }
    
    _setLoadingState(GemsLoadingState.loading);
    
    try {
      final searchResults = await _apiService.searchGems(query);
      _filteredGems = searchResults;
      _error = null;
      _setLoadingState(GemsLoadingState.loaded);
    } catch (e) {
      _error = 'Search failed: $e';
      _setLoadingState(GemsLoadingState.error);
    }
  }

  // Filter by mood
  Future<void> filterByMood(String? mood) async {
    _currentMoodFilter = mood;
    _currentSearchQuery = '';
    
    if (mood == null) {
      _applyCurrentFilters();
      return;
    }
    
    _setLoadingState(GemsLoadingState.loading);
    
    try {
      final response = await _apiService.getGemsByMood(mood, limit: 50);
      _filteredGems = response.data;
      _error = null;
      _setLoadingState(GemsLoadingState.loaded);
    } catch (e) {
      _error = 'Failed to filter by mood: $e';
      _setLoadingState(GemsLoadingState.error);
    }
  }

  // Filter by type
  Future<void> filterByType(String? type) async {
    _currentTypeFilter = type;
    _currentSearchQuery = '';
    
    if (type == null) {
      _applyCurrentFilters();
      return;
    }
    
    _setLoadingState(GemsLoadingState.loading);
    
    try {
      final response = await _apiService.getGemsByType(type, limit: 50);
      _filteredGems = response.data;
      _error = null;
      _setLoadingState(GemsLoadingState.loaded);
    } catch (e) {
      _error = 'Failed to filter by type: $e';
      _setLoadingState(GemsLoadingState.error);
    }
  }

  // Filter by minimum score
  void filterByMinScore(double? minScore) {
    _currentMinScore = minScore;
    _currentSearchQuery = '';
    _applyCurrentFilters();
  }

  // Clear all filters
  void clearFilters() {
    _currentMoodFilter = null;
    _currentTypeFilter = null;
    _currentMinScore = null;
    _currentCategoryFilter = null;
    _currentSearchQuery = '';
    _filteredGems = List.from(_allGems);
    notifyListeners();
  }

  // Get gem by ID
  Future<HiddenGem?> getGemById(String id) async {
    try {
      // First check in loaded gems
      final gem = _allGems.cast<HiddenGem?>().firstWhere(
        (gem) => gem?.id == id || gem?.establishmentId == id,
        orElse: () => null,
      );
      if (gem != null) return gem;

      // If not found, try to load it (this would require an API endpoint)
      // For now, return null
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get random gem
  Future<HiddenGem?> getRandomGem() async {
    try {
      return await _apiService.getRandomGem();
    } catch (e) {
      _error = 'Failed to get random gem: $e';
      notifyListeners();
      return null;
    }
  }

  // Get gems by multiple criteria
  Future<void> getFilteredGems({
    String? mood,
    String? type,
    double? minScore,
    int? limit,
  }) async {
    _setLoadingState(GemsLoadingState.loading);
    
    try {
      final gems = await _apiService.getFilteredGems(
        mood: mood,
        type: type,
        minScore: minScore,
        limit: limit,
      );
      
      _filteredGems = gems;
      _currentMoodFilter = mood;
      _currentTypeFilter = type;
      _currentMinScore = minScore;
      _currentSearchQuery = '';
      _error = null;
      _setLoadingState(GemsLoadingState.loaded);
    } catch (e) {
      _error = 'Failed to get filtered gems: $e';
      _setLoadingState(GemsLoadingState.error);
    }
  }

  // Get unique gem types
  List<String> getUniqueTypes() {
    return _allGems.map((gem) => gem.type).toSet().toList()..sort();
  }

  // Get gems by score range
  List<HiddenGem> getGemsByScoreRange(double minScore, double maxScore) {
    return _allGems.where((gem) {
      return gem.hiddenGemScore >= minScore && gem.hiddenGemScore <= maxScore;
    }).toList();
  }

  // Get high quality gems
  List<HiddenGem> getHighQualityGems() {
    return _allGems.where((gem) => gem.isHighQuality).toList();
  }

  // Get popular gems
  List<HiddenGem> getPopularGems() {
    return _allGems.where((gem) => gem.isPopular).toList();
  }

  // Get unique gems
  List<HiddenGem> getUniqueGems() {
    return _allGems.where((gem) => gem.isUnique).toList();
  }

  // Get gems by sentiment
  List<HiddenGem> getGemsBySentiment(String sentiment) {
    return _allGems.where((gem) {
      return gem.sentimentDescription.toLowerCase() == sentiment.toLowerCase();
    }).toList();
  }

  // Get current filter summary
  Map<String, dynamic> getFilterSummary() {
    return {
      'totalGems': _allGems.length,
      'filteredGems': _filteredGems.length,
      'currentFilters': {
        'mood': _currentMoodFilter,
        'type': _currentTypeFilter,
        'category': _currentCategoryFilter?.displayName,
        'minScore': _currentMinScore,
        'search': _currentSearchQuery.isNotEmpty ? _currentSearchQuery : null,
      },
      'hasFilters': hasFilters,
    };
  }

  // Private helper to set loading state
  void _setLoadingState(GemsLoadingState state) {
    _loadingState = state;
    notifyListeners();
  }
} 