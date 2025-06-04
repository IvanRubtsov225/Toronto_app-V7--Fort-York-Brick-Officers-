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
  // Toronto backend base URL - Update with your actual backend URL
  static const String baseUrl = 'http://localhost:8000/api';
  
  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'User-Agent': 'TorontoHiddenGemsApp/1.0',
  };

  // Helper method to handle HTTP requests
  Future<Map<String, dynamic>> _makeRequest(String endpoint) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      print('🌐 Making API request to: $uri');
      
      final response = await http.get(uri, headers: headers).timeout(
        const Duration(seconds: 10),
      );

      print('📡 Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return data;
      } else {
        throw ApiException('HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('❌ API Error: $e');
      throw ApiException('Failed to connect to Toronto Hidden Gems API: $e');
    }
  }

  // GET /api/gems - Get all hidden gems
  Future<ApiResponse<List<HiddenGem>>> getAllGems({int? limit}) async {
    final endpoint = limit != null ? '/gems?limit=$limit' : '/gems';
    final response = await _makeRequest(endpoint);
    
    final gemsData = response['data'] as List<dynamic>;
    final gems = gemsData.map((json) => HiddenGem.fromJson(json)).toList();
    
    return ApiResponse.fromJson(response, gems);
  }

  // GET /api/gems/top - Get top-rated gems
  Future<ApiResponse<List<HiddenGem>>> getTopGems({int limit = 10}) async {
    final response = await _makeRequest('/gems/top?limit=$limit');
    
    final gemsData = response['data'] as List<dynamic>;
    final gems = gemsData.map((json) => HiddenGem.fromJson(json)).toList();
    
    return ApiResponse.fromJson(response, gems);
  }

  // GET /api/gems/mood/{mood} - Get gems by mood
  Future<ApiResponse<List<HiddenGem>>> getGemsByMood(String mood, {int limit = 10}) async {
    final response = await _makeRequest('/gems/mood/$mood?limit=$limit');
    
    final gemsData = response['data'] as List<dynamic>;
    final gems = gemsData.map((json) => HiddenGem.fromJson(json)).toList();
    
    return ApiResponse.fromJson(response, gems);
  }

  // GET /api/gems/type/{type} - Get gems by type
  Future<ApiResponse<List<HiddenGem>>> getGemsByType(String type, {int limit = 10}) async {
    final response = await _makeRequest('/gems/type/$type?limit=$limit');
    
    final gemsData = response['data'] as List<dynamic>;
    final gems = gemsData.map((json) => HiddenGem.fromJson(json)).toList();
    
    return ApiResponse.fromJson(response, gems);
  }

  // GET /api/stats - Get gems statistics
  Future<Map<String, dynamic>> getGemsStats() async {
    final response = await _makeRequest('/stats');
    return response['data'] as Map<String, dynamic>;
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
    final response = await _makeRequest('/flutter/moods');
    return List<String>.from(response['data']);
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
    final response = await getTopGems(limit: limit * 2); // Get more to filter
    final topGems = response.data;
    
    // Filter for high quality gems
    final featured = topGems.where((gem) => gem.isHighQuality).take(limit).toList();
    return featured;
  }
}

// Custom exception for API errors
class ApiException implements Exception {
  final String message;
  
  const ApiException(this.message);
  
  @override
  String toString() => 'ApiException: $message';
} 