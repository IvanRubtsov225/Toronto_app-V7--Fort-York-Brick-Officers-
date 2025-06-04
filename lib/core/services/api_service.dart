import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/hidden_gem.dart';
import '../models/toronto_event.dart';

class ApiResponse<T> {
  final String status;
  final int count;
  final T data;

  const ApiResponse({
    required this.status,
    required this.count,
    required this.data,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json, T data) {
    return ApiResponse(
      status: json['status'] ?? 'success',
      count: json['count'] ?? 0,
      data: data,
    );
  }
}

class ApiService {
  // Toronto backend base URLs - Try multiple options for different environments
  static const List<String> baseUrls = [
    'http://localhost:8000/api',        // Works on simulator
    'http://127.0.0.1:8000/api',       // Alternative localhost
    'http://172.16.20.97:8000/api',    // Local network IP for physical device
  ];
  
  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'User-Agent': 'TorontoHiddenGemsApp/1.0',
  };

  // Helper method to handle HTTP requests with multiple URL attempts
  Future<Map<String, dynamic>> _makeRequest(String endpoint) async {
    Map<String, dynamic>? lastResponse;
    Exception? lastException;

    // Try each base URL until one works
    for (String baseUrl in baseUrls) {
      try {
        final uri = Uri.parse('$baseUrl$endpoint');
        print('🌐 Making API request to: $uri');
        
        final response = await http.get(uri, headers: headers).timeout(
          const Duration(seconds: 10),
        );

        print('📡 Response status: ${response.statusCode}');
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body) as Map<String, dynamic>;
          print('✅ Successfully connected to: $baseUrl');
          return data;
        } else {
          print('❌ HTTP ${response.statusCode} from $baseUrl: ${response.reasonPhrase}');
          lastException = ApiException('HTTP ${response.statusCode}: ${response.reasonPhrase}');
        }
      } catch (e) {
        print('❌ Connection failed to $baseUrl: $e');
        lastException = Exception('Connection failed to $baseUrl: $e');
        continue; // Try next URL
      }
    }
    
    print('❌ All API endpoints failed, falling back to sample data...');
    print('🔄 Last error: $lastException');
    
    // Return sample data when all APIs are not available
    return _getSampleData(endpoint);
  }

  // Enhanced sample data for development/testing when backend is not available
  Map<String, dynamic> _getSampleData(String endpoint) {
    // Generate more comprehensive sample data
    if (endpoint.contains('/gems')) {
      return {
        'status': 'success',
        'count': 8,
        'data': [
          {
            'name': 'LAKE INEZ',
            'address': '1471 GERRARD ST E',
            'type': 'Restaurant',
            'latitude': 43.67235,
            'longitude': -79.32069,
            'hidden_gem_score': 85.91,
            'dinesafe_score': 100.0,
            'recommendation_score': 95.11,
            'uniqueness_score': 60.0,
            'mention_count': 4,
            'avg_sentiment': 0.562,
            'mood_tags': 'Foodie',
            'positive_indicators': 3,
            'negative_indicators': 0,
            'establishment_id': '10582327',
            'is_recommendation_based': 'True'
          },
          {
            'name': 'BRICK & BUTTER BAKEHOUSE',
            'address': '28 FINCH AVE W, Unit-116',
            'type': 'Bakery',
            'latitude': 43.77956,
            'longitude': -79.41781,
            'hidden_gem_score': 84.7,
            'dinesafe_score': 100.0,
            'recommendation_score': 58.2,
            'uniqueness_score': 96.64,
            'mention_count': 1,
            'avg_sentiment': 1.0,
            'mood_tags': 'Relaxing',
            'positive_indicators': 1,
            'negative_indicators': 0,
            'establishment_id': '10839962',
            'is_recommendation_based': 'True'
          }
        ]
      };
    }
    
    // Default empty response
    return {
      'status': 'success',
      'count': 0,
      'data': []
    };
  }

  // GET /api/gems - Get all hidden gems
  Future<ApiResponse<List<HiddenGem>>> getAllGems({int? limit}) async {
    final endpoint = limit != null ? '/gems?limit=$limit' : '/gems';
    print('🔗 ApiService: Calling getAllGems with endpoint: $endpoint');
    final response = await _makeRequest(endpoint);
    
    print('🔗 ApiService: Raw response status: ${response['status']}');
    print('🔗 ApiService: Raw response count: ${response['count']}');
    
    final gemsData = response['data'] as List<dynamic>;
    print('🔗 ApiService: Converting ${gemsData.length} gem objects...');
    
    // Add more detailed debugging for parsing
    final gems = <HiddenGem>[];
    for (int i = 0; i < gemsData.length; i++) {
      try {
        final gemJson = gemsData[i] as Map<String, dynamic>;
        print('🔗 ApiService: Processing gem $i: ${gemJson['name']} (${gemJson['establishment_id']})');
        final gem = HiddenGem.fromJson(gemJson);
        gems.add(gem);
        print('🔗 ApiService: Successfully parsed gem: ${gem.name}');
      } catch (e, stackTrace) {
        print('🔗 ApiService: Error parsing gem $i: $e');
        print('🔗 ApiService: Stack trace: $stackTrace');
        print('🔗 ApiService: Problematic gem data: ${gemsData[i]}');
      }
    }
    
    print('🔗 ApiService: Successfully converted ${gems.length} gems');
    
    return ApiResponse.fromJson(response, gems);
  }

  // GET /api/gems/top - Get top-rated gems
  Future<ApiResponse<List<HiddenGem>>> getTopGems({int limit = 10}) async {
    try {
      final response = await _makeRequest('/gems/top?limit=$limit');
      
      final gemsData = response['data'] as List<dynamic>;
      final gems = gemsData.map((json) => HiddenGem.fromJson(json)).toList();
      
      return ApiResponse.fromJson(response, gems);
    } catch (e) {
      print('🔗 ApiService: getTopGems failed, using sample data: $e');
      // Return sample gems to avoid recursion
      final sampleData = _getSampleData('/gems');
      final gemsData = sampleData['data'] as List<dynamic>;
      final gems = gemsData.map((json) => HiddenGem.fromJson(json)).toList();
      return ApiResponse(status: 'success', count: gems.length, data: gems.take(limit).toList());
    }
  }

  // GET /api/gems/mood/{mood} - Get gems by mood
  Future<ApiResponse<List<HiddenGem>>> getGemsByMood(String mood, {int limit = 10}) async {
    try {
      final response = await _makeRequest('/gems/mood/$mood?limit=$limit');
      
      final gemsData = response['data'] as List<dynamic>;
      final gems = gemsData.map((json) => HiddenGem.fromJson(json)).toList();
      
      return ApiResponse.fromJson(response, gems);
    } catch (e) {
      print('🔗 ApiService: getGemsByMood failed, using fallback: $e');
      return ApiResponse(status: 'success', count: 0, data: <HiddenGem>[]);
    }
  }

  // GET /api/gems/type/{type} - Get gems by type
  Future<ApiResponse<List<HiddenGem>>> getGemsByType(String type, {int limit = 10}) async {
    try {
      final response = await _makeRequest('/gems/type/$type?limit=$limit');
      
      final gemsData = response['data'] as List<dynamic>;
      final gems = gemsData.map((json) => HiddenGem.fromJson(json)).toList();
      
      return ApiResponse.fromJson(response, gems);
    } catch (e) {
      print('🔗 ApiService: getGemsByType failed, using fallback: $e');
      return ApiResponse(status: 'success', count: 0, data: <HiddenGem>[]);
    }
  }

  // GET /api/stats - Get gems statistics
  Future<Map<String, dynamic>> getGemsStats() async {
    try {
      final response = await _makeRequest('/stats');
      return response['data'] as Map<String, dynamic>;
    } catch (e) {
      print('🔗 ApiService: getGemsStats failed, using fallback: $e');
      return {
        'total_gems': 8,
        'average_score': 82.4,
        'average_sentiment': 0.75,
      };
    }
  }

  // GET /api/events - Get all events
  Future<ApiResponse<List<TorontoEvent>>> getAllEvents({
    int? limit,
    String? mood,
    String? type,
  }) async {
    var endpoint = '/events';
    final params = <String>[];
    
    if (limit != null) params.add('limit=$limit');
    if (mood != null) params.add('mood=$mood');
    if (type != null) params.add('type=$type');
    
    if (params.isNotEmpty) {
      endpoint += '?${params.join('&')}';
    }
    
    final response = await _makeRequest(endpoint);
    
    final eventsData = response['data'] as List<dynamic>;
    final events = eventsData.map((json) => TorontoEvent.fromJson(json)).toList();
    
    return ApiResponse.fromJson(response, events);
  }

  // GET /api/events/mood/{mood} - Get events by mood
  Future<ApiResponse<List<TorontoEvent>>> getEventsByMood(String mood, {int limit = 10}) async {
    final response = await _makeRequest('/events/mood/$mood?limit=$limit');
    
    final eventsData = response['data'] as List<dynamic>;
    final events = eventsData.map((json) => TorontoEvent.fromJson(json)).toList();
    
    return ApiResponse.fromJson(response, events);
  }

  // GET /api/events/stats - Get events statistics
  Future<Map<String, dynamic>> getEventsStats() async {
    final response = await _makeRequest('/events/stats');
    return response['data'] as Map<String, dynamic>;
  }

  // POST /api/collect-events - Trigger events data collection
  Future<Map<String, dynamic>> collectEventsData() async {
    try {
      final uri = Uri.parse('$baseUrl/collect-events');
      final response = await http.post(
        uri,
        headers: headers,
      ).timeout(const Duration(minutes: 5)); // Longer timeout for data collection

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw ApiException('HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      throw ApiException('Failed to trigger events data collection: $e');
    }
  }

  // Flutter-specific endpoints (mentioned in documentation)
  // GET /api/flutter/random-gem - Get a random gem from the 6ix
  Future<HiddenGem> getRandomGem() async {
    final response = await _makeRequest('/flutter/random-gem');
    return HiddenGem.fromJson(response['data']);
  }

  // GET /api/flutter/moods - Get all unique Toronto moods
  Future<List<String>> getAllMoods() async {
    try {
      final response = await _makeRequest('/flutter/moods');
      return List<String>.from(response['data']);
    } catch (e) {
      print('🔗 ApiService: getAllMoods failed, using fallback: $e');
      return ['Foodie', 'Relaxing', 'Romantic', 'Nightlife', 'Cultural', 'Budget', 'Unique', 'Cozy'];
    }
  }

  // Helper methods for filtering and searching
  Future<List<HiddenGem>> searchGems(String query) async {
    // For now, get all gems and filter locally
    // In production, you'd want a dedicated search endpoint
    final allGemsResponse = await getAllGems();
    final allGems = allGemsResponse.data;
    
    final searchQuery = query.toLowerCase();
    return allGems.where((gem) {
      return gem.name.toLowerCase().contains(searchQuery) ||
             gem.address.toLowerCase().contains(searchQuery) ||
             gem.type.toLowerCase().contains(searchQuery) ||
             gem.moodTags.toLowerCase().contains(searchQuery);
    }).toList();
  }

  // Get gems by multiple criteria
  Future<List<HiddenGem>> getFilteredGems({
    String? mood,
    String? type,
    double? minScore,
    int? limit,
  }) async {
    List<HiddenGem> gems;
    
    if (mood != null) {
      final response = await getGemsByMood(mood, limit: limit ?? 50);
      gems = response.data;
    } else if (type != null) {
      final response = await getGemsByType(type, limit: limit ?? 50);
      gems = response.data;
    } else {
      final response = await getAllGems(limit: limit);
      gems = response.data;
    }

    // Apply additional filters
    if (minScore != null) {
      gems = gems.where((gem) => gem.hiddenGemScore >= minScore).toList();
    }

    return gems;
  }

  // Get featured gems (high quality + popular)
  Future<List<HiddenGem>> getFeaturedGems({int limit = 5}) async {
    try {
      final response = await getTopGems(limit: limit * 2); // Get more to filter
      final topGems = response.data;
      
      // Filter for high quality gems
      final featured = topGems.where((gem) => gem.isHighQuality).take(limit).toList();
      return featured;
    } catch (e) {
      print('🔗 ApiService: getFeaturedGems failed, using fallback: $e');
      final allGems = await getAllGems(limit: limit);
      return allGems.data.take(limit).toList();
    }
  }
}

// Custom exception for API errors
class ApiException implements Exception {
  final String message;
  
  const ApiException(this.message);
  
  @override
  String toString() => 'ApiException: $message';
} 