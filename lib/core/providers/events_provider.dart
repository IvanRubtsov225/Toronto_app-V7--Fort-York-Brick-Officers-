import 'package:flutter/foundation.dart';
import '../models/toronto_event.dart';
import '../services/api_service.dart';

enum EventsLoadingState {
  idle,
  loading,
  loaded,
  error,
}

class EventsProvider extends ChangeNotifier {
  final ApiService _apiService;
  
  // State
  EventsLoadingState _loadingState = EventsLoadingState.idle;
  List<TorontoEvent> _allEvents = [];
  List<TorontoEvent> _filteredEvents = [];
  List<TorontoEvent> _upcomingEvents = [];
  List<TorontoEvent> _todayEvents = [];
  List<TorontoEvent> _freeEvents = [];
  Map<String, dynamic> _stats = {};
  
  // Current filters
  String? _currentMoodFilter;
  String? _currentTypeFilter;
  EventCategory? _currentCategoryFilter;
  bool _showOnlyFree = false;
  bool _showOnlyUpcoming = true;
  String _currentSearchQuery = '';
  
  // Error handling
  String? _error;
  
  EventsProvider({required ApiService apiService}) : _apiService = apiService;

  // Getters
  EventsLoadingState get loadingState => _loadingState;
  List<TorontoEvent> get allEvents => _allEvents;
  List<TorontoEvent> get filteredEvents => _filteredEvents;
  List<TorontoEvent> get upcomingEvents => _upcomingEvents;
  List<TorontoEvent> get todayEvents => _todayEvents;
  List<TorontoEvent> get freeEvents => _freeEvents;
  Map<String, dynamic> get stats => _stats;
  String? get currentMoodFilter => _currentMoodFilter;
  String? get currentTypeFilter => _currentTypeFilter;
  EventCategory? get currentCategoryFilter => _currentCategoryFilter;
  bool get showOnlyFree => _showOnlyFree;
  bool get showOnlyUpcoming => _showOnlyUpcoming;
  String get currentSearchQuery => _currentSearchQuery;
  String? get error => _error;
  
  bool get isLoading => _loadingState == EventsLoadingState.loading;
  bool get hasError => _loadingState == EventsLoadingState.error;
  bool get hasData => _loadingState == EventsLoadingState.loaded;
  bool get hasFilters => _currentMoodFilter != null || 
                        _currentTypeFilter != null || 
                        _currentCategoryFilter != null ||
                        _showOnlyFree ||
                        !_showOnlyUpcoming ||
                        _currentSearchQuery.isNotEmpty;

  // Initialize data
  Future<void> initialize() async {
    if (_loadingState == EventsLoadingState.loaded && _allEvents.isNotEmpty) {
      return; // Already loaded
    }
    
    await loadAllEvents();
  }

  // Load all events data (deprecated - use loadAllEvents)
  Future<void> loadAllData() async {
    await loadAllEvents();
  }

  // Load all events (alias for compatibility)
  Future<void> loadAllEvents() async {
    _setLoadingState(EventsLoadingState.loading);
    
    try {
      final results = await Future.wait([
        _apiService.getAllEvents(),
        _apiService.getEventsStats(),
      ]);
      
      // Handle ApiResponse types correctly
      _allEvents = (results[0] as ApiResponse<List<TorontoEvent>>).data;
      _stats = results[1] as Map<String, dynamic>;
      
      _filteredEvents = List.from(_allEvents);
      _updateEventLists();
      _error = null;
      _setLoadingState(EventsLoadingState.loaded);
    } catch (e) {
      print('Error loading events: $e');
      _error = 'Failed to load events: $e';
      _setLoadingState(EventsLoadingState.error);
    }
    notifyListeners();
  }

  void _updateEventLists() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    _upcomingEvents = _allEvents.where((event) => event.isUpcoming).toList();
    _todayEvents = _allEvents.where((event) => event.isToday).toList();
    _freeEvents = _allEvents.where((event) => event.isFree).toList();
  }

  // Filter by category
  void filterByCategory(EventCategory? category) {
    _currentCategoryFilter = category;
    if (category == null) {
      _filteredEvents = List.from(_allEvents);
    } else {
      _filteredEvents = _allEvents.where((event) => event.category == category).toList();
    }
    notifyListeners();
  }

  // Process events into different categories
  void _processEvents() {
    _upcomingEvents = _allEvents.where((event) => event.isUpcoming).toList();
    _todayEvents = _allEvents.where((event) => event.isToday).toList();
    _freeEvents = _allEvents.where((event) => event.isFree).toList();
    
    // Sort upcoming events by date
    _upcomingEvents.sort((a, b) {
      final dateA = a.eventDateTime;
      final dateB = b.eventDateTime;
      if (dateA == null && dateB == null) return 0;
      if (dateA == null) return 1;
      if (dateB == null) return -1;
      return dateA.compareTo(dateB);
    });
  }

  // Refresh data
  Future<void> refresh() async {
    _allEvents.clear();
    _filteredEvents.clear();
    _upcomingEvents.clear();
    _todayEvents.clear();
    _freeEvents.clear();
    _stats.clear();
    
    await loadAllEvents();
  }

  // Search events
  void searchEvents(String query) {
    _currentSearchQuery = query;
    _applyCurrentFilters();
  }

  // Filter by mood
  Future<void> filterByMood(String? mood) async {
    _currentMoodFilter = mood;
    _currentSearchQuery = '';
    
    if (mood == null) {
      _applyCurrentFilters();
      return;
    }
    
    _setLoadingState(EventsLoadingState.loading);
    
    try {
      final response = await _apiService.getEventsByMood(mood, limit: 50);
      _filteredEvents = response.data;
      
      // Apply additional filters
      _applyAdditionalFilters();
      
      _error = null;
      _setLoadingState(EventsLoadingState.loaded);
    } catch (e) {
      _error = 'Failed to filter events by mood: $e';
      _setLoadingState(EventsLoadingState.error);
    }
  }

  // Filter by type
  void filterByType(String? type) {
    _currentTypeFilter = type;
    _currentSearchQuery = '';
    _applyCurrentFilters();
  }

  // Toggle free events filter
  void toggleFreeEventsFilter() {
    _showOnlyFree = !_showOnlyFree;
    _applyCurrentFilters();
  }

  // Toggle upcoming events filter
  void toggleUpcomingEventsFilter() {
    _showOnlyUpcoming = !_showOnlyUpcoming;
    _applyCurrentFilters();
  }

  // Apply current filters to all events
  void _applyCurrentFilters() {
    var filteredList = List<TorontoEvent>.from(_allEvents);
    
    // Apply search filter
    if (_currentSearchQuery.isNotEmpty) {
      final searchQuery = _currentSearchQuery.toLowerCase();
      filteredList = filteredList.where((event) {
        return event.name.toLowerCase().contains(searchQuery) ||
               event.venue.toLowerCase().contains(searchQuery) ||
               event.moodTags.toLowerCase().contains(searchQuery);
      }).toList();
    }
    
    // Apply mood filter
    if (_currentMoodFilter != null) {
      filteredList = filteredList.where((event) {
        return event.moodTagsList.any((tag) => 
          tag.toLowerCase().contains(_currentMoodFilter!.toLowerCase()));
      }).toList();
    }
    
    // Apply type filter (if implemented in backend)
    if (_currentTypeFilter != null) {
      filteredList = filteredList.where((event) {
        return event.name.toLowerCase().contains(_currentTypeFilter!.toLowerCase()) ||
               event.venue.toLowerCase().contains(_currentTypeFilter!.toLowerCase());
      }).toList();
    }

    // Apply category filter
    if (_currentCategoryFilter != null) {
      filteredList = filteredList.where((event) {
        return event.category == _currentCategoryFilter;
      }).toList();
    }
    
    // Apply free events filter
    if (_showOnlyFree) {
      filteredList = filteredList.where((event) => event.isFree).toList();
    }
    
    // Apply upcoming events filter
    if (_showOnlyUpcoming) {
      filteredList = filteredList.where((event) => event.isUpcoming).toList();
    }
    
    _filteredEvents = filteredList;
    notifyListeners();
  }

  // Apply additional filters to already filtered list
  void _applyAdditionalFilters() {
    var filteredList = List<TorontoEvent>.from(_filteredEvents);
    
    // Apply category filter
    if (_currentCategoryFilter != null) {
      filteredList = filteredList.where((event) {
        return event.category == _currentCategoryFilter;
      }).toList();
    }
    
    // Apply free events filter
    if (_showOnlyFree) {
      filteredList = filteredList.where((event) => event.isFree).toList();
    }
    
    // Apply upcoming events filter
    if (_showOnlyUpcoming) {
      filteredList = filteredList.where((event) => event.isUpcoming).toList();
    }
    
    _filteredEvents = filteredList;
  }

  // Clear all filters
  void clearFilters() {
    _currentMoodFilter = null;
    _currentTypeFilter = null;
    _currentCategoryFilter = null;
    _showOnlyFree = false;
    _showOnlyUpcoming = true;
    _currentSearchQuery = '';
    _applyCurrentFilters();
  }

  // Get high buzz events
  List<TorontoEvent> getHighBuzzEvents() {
    return _allEvents.where((event) => event.isHighBuzz).toList();
  }

  // Get hidden gem events
  List<TorontoEvent> getHiddenGemEvents() {
    return _allEvents.where((event) => event.isHiddenGem).toList();
  }

  // Get events by price range
  List<TorontoEvent> getEventsByPriceRange(String priceRange) {
    return _allEvents.where((event) {
      return event.priceRange.toLowerCase() == priceRange.toLowerCase();
    }).toList();
  }

  // Get events by buzz level
  List<TorontoEvent> getEventsByBuzzLevel(String buzzLevel) {
    return _allEvents.where((event) {
      return event.buzzLevel.toLowerCase() == buzzLevel.toLowerCase();
    }).toList();
  }

  // Get unique event moods
  List<String> getUniqueEventMoods() {
    final moods = <String>{};
    for (final event in _allEvents) {
      moods.addAll(event.moodTagsList);
    }
    return moods.toList()..sort();
  }

  // Get unique venues
  List<String> getUniqueVenues() {
    return _allEvents.map((event) => event.venue).toSet().toList()..sort();
  }

  // Trigger events data collection
  Future<void> collectEventsData() async {
    _setLoadingState(EventsLoadingState.loading);
    
    try {
      await _apiService.collectEventsData();
      
      // Refresh data after collection
      await loadAllEvents();
    } catch (e) {
      _error = 'Failed to collect events data: $e';
      _setLoadingState(EventsLoadingState.error);
    }
  }

  // Get events happening this week
  List<TorontoEvent> getThisWeekEvents() {
    final now = DateTime.now();
    final weekFromNow = now.add(const Duration(days: 7));
    
    return _allEvents.where((event) {
      final eventDate = event.eventDateTime;
      if (eventDate == null) return false;
      
      return eventDate.isAfter(now) && eventDate.isBefore(weekFromNow);
    }).toList();
  }

  // Get events happening this month
  List<TorontoEvent> getThisMonthEvents() {
    final now = DateTime.now();
    final monthFromNow = DateTime(now.year, now.month + 1, now.day);
    
    return _allEvents.where((event) {
      final eventDate = event.eventDateTime;
      if (eventDate == null) return false;
      
      return eventDate.isAfter(now) && eventDate.isBefore(monthFromNow);
    }).toList();
  }

  // Get current filter summary
  Map<String, dynamic> getFilterSummary() {
    return {
      'totalEvents': _allEvents.length,
      'filteredEvents': _filteredEvents.length,
      'upcomingEvents': _upcomingEvents.length,
      'todayEvents': _todayEvents.length,
      'freeEvents': _freeEvents.length,
      'currentFilters': {
        'mood': _currentMoodFilter,
        'type': _currentTypeFilter,
        'category': _currentCategoryFilter?.displayName,
        'showOnlyFree': _showOnlyFree,
        'showOnlyUpcoming': _showOnlyUpcoming,
        'search': _currentSearchQuery.isNotEmpty ? _currentSearchQuery : null,
      },
      'hasFilters': hasFilters,
    };
  }

  // Private helper to set loading state
  void _setLoadingState(EventsLoadingState state) {
    _loadingState = state;
    notifyListeners();
  }
} 