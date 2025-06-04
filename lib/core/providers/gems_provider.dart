import 'package:flutter/foundation.dart';
import '../models/hidden_gem.dart';
import '../services/api_service.dart';

enum GemsLoadingState {
  idle,
  loading,
  loaded,
  error,
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
  
  bool get isLoading => _loadingState == GemsLoadingState.loading;
  bool get hasError => _loadingState == GemsLoadingState.error;
  bool get hasData => _loadingState == GemsLoadingState.loaded;
  bool get hasFilters => _currentMoodFilter != null || 
                        _currentTypeFilter != null || 
                        _currentMinScore != null ||
                        _currentCategoryFilter != null ||
                        _currentSearchQuery.isNotEmpty;

  // Initialize data
  Future<void> initialize() async {
    if (_loadingState == GemsLoadingState.loaded && _allGems.isNotEmpty) {
      return; // Already loaded
    }
    
    await loadAllGems();
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
      
      // Make individual API calls with better error handling
      print('💎 GemsProvider: Calling getAllGems...');
      final allGemsResponse = await _apiService.getAllGems();
      print('💎 GemsProvider: getAllGems returned ${allGemsResponse.data.length} gems');
      
      print('💎 GemsProvider: Calling getTopGems...');
      final topGemsResponse = await _apiService.getTopGems();
      print('💎 GemsProvider: getTopGems returned ${topGemsResponse.data.length} gems');
      
      print('💎 GemsProvider: Calling getFeaturedGems...');
      final featuredGemsList = await _apiService.getFeaturedGems();
      print('💎 GemsProvider: getFeaturedGems returned ${featuredGemsList.length} gems');
      
      print('💎 GemsProvider: Calling getAllMoods...');
      final moodsList = await _apiService.getAllMoods();
      print('💎 GemsProvider: getAllMoods returned ${moodsList.length} moods');
      
      print('💎 GemsProvider: Calling getGemsStats...');
      final statsMap = await _apiService.getGemsStats();
      print('💎 GemsProvider: getGemsStats returned: $statsMap');
      
      print('💎 GemsProvider: API calls completed successfully');
      
      // Assign the results
      _allGems = allGemsResponse.data;
      _topGems = topGemsResponse.data;
      _featuredGems = featuredGemsList;
      _availableMoods = List<String>.from(moodsList);
      _stats = statsMap;
      
      print('💎 GemsProvider: Data processed - ${_allGems.length} total gems, ${_topGems.length} top gems');
      print('💎 GemsProvider: Sample gem names: ${_allGems.take(3).map((g) => g.name).toList()}');
      
      _filteredGems = List.from(_allGems);
      _error = null;
      _setLoadingState(GemsLoadingState.loaded);
    } catch (e, stackTrace) {
      print('💎 GemsProvider: Error loading gems: $e');
      print('💎 GemsProvider: Stack trace: $stackTrace');
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
    if (category == null) {
      _filteredGems = List.from(_allGems);
    } else {
      _filteredGems = _allGems.where((gem) => gem.category == category).toList();
    }
    notifyListeners();
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

  // Apply current filters to all gems
  void _applyCurrentFilters() {
    var filteredList = List<HiddenGem>.from(_allGems);
    
    // Apply mood filter
    if (_currentMoodFilter != null) {
      filteredList = filteredList.where((gem) {
        return gem.moodTagsList.any((tag) => 
          tag.toLowerCase().contains(_currentMoodFilter!.toLowerCase()));
      }).toList();
    }
    
    // Apply type filter
    if (_currentTypeFilter != null) {
      filteredList = filteredList.where((gem) {
        return gem.type.toLowerCase().contains(_currentTypeFilter!.toLowerCase());
      }).toList();
    }

    // Apply category filter
    if (_currentCategoryFilter != null) {
      filteredList = filteredList.where((gem) {
        return gem.category == _currentCategoryFilter;
      }).toList();
    }
    
    // Apply minimum score filter
    if (_currentMinScore != null) {
      filteredList = filteredList.where((gem) {
        return gem.hiddenGemScore >= _currentMinScore!;
      }).toList();
    }
    
    _filteredGems = filteredList;
    notifyListeners();
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