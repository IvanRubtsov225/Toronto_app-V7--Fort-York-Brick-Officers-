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
    'http://localhost:8000/api',        // Works on device
    'http://127.0.0.1:8000/api',       // Alternative localhost
    'http://172.16.20.97:8000/api',    // Local network IP for simulator
  ];
  
  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
            'User-Agent': 'TorontoApp/1.0',
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
        'count': 15,
        'data': [
          {
            'name': 'The Hidden Teahouse',
            'address': '123 Queen St W, Toronto, ON',
            'type': 'Cafe',
            'latitude': 43.6532,
            'longitude': -79.3832,
            'hidden_gem_score': 85.5,
            'dinesafe_score': 95.0,
            'recommendation_score': 88.0,
            'uniqueness_score': 82.0,
            'mention_count': 12,
            'avg_sentiment': 0.8,
            'mood_tags': 'Cozy, Romantic, Quiet',
            'positive_indicators': 8,
            'negative_indicators': 1,
            'establishment_id': 'sample001',
            'neighborhood': 'Entertainment District',
            'description': 'A charming hidden teahouse tucked away in downtown Toronto, perfect for intimate conversations and authentic tea ceremonies.',
            'features': ['WiFi', 'Quiet', 'Date Spot'],
            'rating': 4.7,
            'price_level': '\$\$',
            'image_url': 'https://picsum.photos/400/300?random=1'
          },
          {
            'name': 'Rustic Ramen Corner',
            'address': '456 College St, Toronto, ON',
            'type': 'Restaurant',
            'latitude': 43.6567,
            'longitude': -79.4103,
            'hidden_gem_score': 78.2,
            'dinesafe_score': 92.0,
            'recommendation_score': 85.0,
            'uniqueness_score': 75.0,
            'mention_count': 8,
            'avg_sentiment': 0.7,
            'mood_tags': 'Foodie, Authentic, Cozy',
            'positive_indicators': 6,
            'negative_indicators': 0,
            'establishment_id': 'sample002',
            'neighborhood': 'Little Italy',
            'description': 'Authentic Japanese ramen in a cozy corner spot, frequented by locals who know where to find the real deal.',
            'features': ['Authentic', 'Small Portions', 'Quick Service'],
            'rating': 4.5,
            'price_level': '\$\$',
            'image_url': 'https://picsum.photos/400/300?random=2'
          },
          {
            'name': 'Sunset Rooftop Garden',
            'address': '789 King St E, Toronto, ON',
            'type': 'Bar',
            'latitude': 43.6426,
            'longitude': -79.3656,
            'hidden_gem_score': 92.1,
            'dinesafe_score': 98.0,
            'recommendation_score': 91.0,
            'uniqueness_score': 89.0,
            'mention_count': 15,
            'avg_sentiment': 0.9,
            'mood_tags': 'Romantic, Nightlife, Scenic',
            'positive_indicators': 12,
            'negative_indicators': 0,
            'establishment_id': 'sample003',
            'neighborhood': 'Distillery District',
            'description': 'A secret rooftop garden bar with stunning city views, perfect for watching Toronto sunsets with craft cocktails.',
            'features': ['Rooftop', 'City Views', 'Craft Cocktails'],
            'rating': 4.9,
            'price_level': '\$\$\$',
            'image_url': 'https://picsum.photos/400/300?random=3'
          },
          {
            'name': 'Underground Jazz Lounge',
            'address': '321 Spadina Ave, Toronto, ON',
            'type': 'Music Venue',
            'latitude': 43.6563,
            'longitude': -79.4005,
            'hidden_gem_score': 87.3,
            'dinesafe_score': 90.0,
            'recommendation_score': 89.0,
            'uniqueness_score': 86.0,
            'mention_count': 10,
            'avg_sentiment': 0.85,
            'mood_tags': 'Cultural, Nightlife, Musical',
            'positive_indicators': 9,
            'negative_indicators': 1,
            'establishment_id': 'sample004',
            'neighborhood': 'Chinatown',
            'description': 'An intimate underground venue featuring live jazz performances and craft cocktails in a speakeasy atmosphere.',
            'features': ['Live Music', 'Intimate Setting', 'Craft Cocktails'],
            'rating': 4.6,
            'price_level': '\$\$\$',
            'image_url': 'https://picsum.photos/400/300?random=4'
          },
          {
            'name': 'Artisan Coffee Roastery',
            'address': '234 Ossington Ave, Toronto, ON',
            'type': 'Cafe',
            'latitude': 43.6511,
            'longitude': -79.4198,
            'hidden_gem_score': 83.7,
            'dinesafe_score': 96.0,
            'recommendation_score': 86.0,
            'uniqueness_score': 81.0,
            'mention_count': 14,
            'avg_sentiment': 0.75,
            'mood_tags': 'Cozy, Foodie, Relaxing',
            'positive_indicators': 11,
            'negative_indicators': 2,
            'establishment_id': 'sample005',
            'neighborhood': 'Trinity Bellwoods',
            'description': 'Small-batch coffee roaster with beans sourced directly from farmers, perfect for coffee enthusiasts.',
            'features': ['Specialty Coffee', 'Local Roasted', 'WiFi'],
            'rating': 4.4,
            'price_level': '\$\$',
            'image_url': 'https://picsum.photos/400/300?random=5'
          },
          {
            'name': 'Secret Garden Patio',
            'address': '567 Harbord St, Toronto, ON',
            'type': 'Restaurant',
            'latitude': 43.6622,
            'longitude': -79.4031,
            'hidden_gem_score': 89.4,
            'dinesafe_score': 94.0,
            'recommendation_score': 90.0,
            'uniqueness_score': 88.0,
            'mention_count': 7,
            'avg_sentiment': 0.88,
            'mood_tags': 'Romantic, Relaxing, Seasonal',
            'positive_indicators': 6,
            'negative_indicators': 0,
            'establishment_id': 'sample006',
            'neighborhood': 'Annex',
            'description': 'Hidden patio restaurant with garden seating, serving farm-to-table cuisine in a magical outdoor setting.',
            'features': ['Patio', 'Farm-to-Table', 'Seasonal Menu'],
            'rating': 4.8,
            'price_level': '\$\$\$',
            'image_url': 'https://picsum.photos/400/300?random=6'
          },
          {
            'name': 'Vintage Vinyl Record Shop',
            'address': '890 Kensington Ave, Toronto, ON',
            'type': 'Retail',
            'latitude': 43.6544,
            'longitude': -79.4008,
            'hidden_gem_score': 76.8,
            'dinesafe_score': 100.0,
            'recommendation_score': 79.0,
            'uniqueness_score': 95.0,
            'mention_count': 5,
            'avg_sentiment': 0.92,
            'mood_tags': 'Cultural, Nostalgic, Unique',
            'positive_indicators': 5,
            'negative_indicators': 0,
            'establishment_id': 'sample007',
            'neighborhood': 'Kensington Market',
            'description': 'Curated collection of rare and vintage vinyl records, a treasure trove for music lovers and collectors.',
            'features': ['Vinyl Records', 'Rare Finds', 'Knowledgeable Staff'],
            'rating': 4.3,
            'price_level': '\$\$',
            'image_url': 'https://picsum.photos/400/300?random=7'
          },
          {
            'name': 'Midnight Burger Joint',
            'address': '111 Augusta Ave, Toronto, ON',
            'type': 'Restaurant',
            'latitude': 43.6558,
            'longitude': -79.4010,
            'hidden_gem_score': 81.2,
            'dinesafe_score': 88.0,
            'recommendation_score': 82.0,
            'uniqueness_score': 80.0,
            'mention_count': 9,
            'avg_sentiment': 0.73,
            'mood_tags': 'Nightlife, Budget, Casual',
            'positive_indicators': 7,
            'negative_indicators': 1,
            'establishment_id': 'sample008',
            'neighborhood': 'Kensington Market',
            'description': 'Late-night burger spot serving gourmet burgers until 3 AM, perfect for night owls and party-goers.',
            'features': ['Late Night', 'Gourmet Burgers', 'Casual'],
            'rating': 4.2,
            'price_level': '\$',
            'image_url': 'https://picsum.photos/400/300?random=8'
          }
        ]
      };
    } else if (endpoint.contains('/events')) {
      return {
        'status': 'success',
        'count': 8,
        'data': [
          {
            'name': 'Toronto Jazz Festival',
            'venue': 'Nathan Phillips Square',
            'date': '2024-07-15',
            'time': '19:00',
            'price_range': 'Free',
            'mood_tags': 'Cultural, Musical, Free',
            'reddit_buzz_score': 85.0,
            'hidden_gem_score': 78.5,
            'ticketmaster_url': 'https://www.ticketmaster.ca/toronto-jazz-festival',
            'category': 'music',
            'description': 'Annual jazz festival featuring local and international artists in the heart of downtown Toronto.',
            'neighborhood': 'Downtown Core',
            'is_free': true,
            'is_hidden_gem': true,
            'genre': 'Music',
            'segment': 'Arts & Theatre'
          },
          {
            'name': 'Night Market in Kensington',
            'venue': 'Kensington Market',
            'date': '2024-07-20',
            'time': '18:00',
            'price_range': 'Budget',
            'mood_tags': 'Foodie, Cultural, Nightlife',
            'reddit_buzz_score': 72.0,
            'hidden_gem_score': 88.2,
            'ticketmaster_url': '',
            'category': 'food',
            'description': 'Monthly night market featuring diverse street food, local vendors, and live music in Toronto\'s most eclectic neighborhood.',
            'neighborhood': 'Kensington Market',
            'is_free': false,
            'is_hidden_gem': true,
            'genre': 'Food & Drink',
            'segment': 'Food & Drink',
            'price_min': 10.0,
            'price_max': 30.0
          },
          {
            'name': 'CN Tower EdgeWalk',
            'venue': 'CN Tower',
            'date': '2024-07-25',
            'time': '14:00',
            'price_range': 'Premium',
            'mood_tags': 'Thrilling, Adventure, Unique',
            'reddit_buzz_score': 95.0,
            'hidden_gem_score': 65.0,
            'ticketmaster_url': 'https://www.edgewalkcntower.ca/',
            'category': 'adventure',
            'description': 'Walk around the outside of the CN Tower 116 stories above the ground for the ultimate Toronto experience.',
            'neighborhood': 'Entertainment District',
            'is_free': false,
            'is_hidden_gem': false,
            'genre': 'Sports',
            'segment': 'Sports',
            'price_min': 200.0,
            'price_max': 250.0
          },
          {
            'name': 'Underground Art Gallery Opening',
            'venue': 'Graffiti Alley',
            'date': '2024-07-18',
            'time': '20:00',
            'price_range': 'Free',
            'mood_tags': 'Cultural, Artistic, Free',
            'reddit_buzz_score': 68.0,
            'hidden_gem_score': 92.3,
            'ticketmaster_url': '',
            'category': 'art',
            'description': 'Exclusive underground art gallery featuring local street artists in Toronto\'s famous Graffiti Alley.',
            'neighborhood': 'Fashion District',
            'is_free': true,
            'is_hidden_gem': true,
            'genre': 'Arts & Theatre',
            'segment': 'Arts & Theatre',
            'price_min': 0.0,
            'price_max': 0.0
          },
          {
            'name': 'Rooftop Cinema Experience',
            'venue': 'Rooftop Bar on King',
            'date': '2024-07-22',
            'time': '21:00',
            'price_range': 'Budget',
            'mood_tags': 'Romantic, Nightlife, Unique',
            'reddit_buzz_score': 89.0,
            'hidden_gem_score': 85.7,
            'ticketmaster_url': 'https://www.ticketmaster.ca/rooftop-cinema',
            'category': 'entertainment',
            'description': 'Watch classic movies under the stars on a secret rooftop location with panoramic city views.',
            'neighborhood': 'King West',
            'is_free': false,
            'is_hidden_gem': true,
            'genre': 'Film',
            'segment': 'Arts & Theatre',
            'price_min': 25.0,
            'price_max': 40.0
          },
          {
            'name': 'Secret Speakeasy Tour',
            'venue': 'Various Locations',
            'date': '2024-07-26',
            'time': '19:30',
            'price_range': 'Premium',
            'mood_tags': 'Nightlife, Historical, Exclusive',
            'reddit_buzz_score': 77.0,
            'hidden_gem_score': 90.1,
            'ticketmaster_url': '',
            'category': 'tour',
            'description': 'Guided tour of Toronto\'s hidden speakeasies and prohibition-era bars with tastings and historical stories.',
            'neighborhood': 'Downtown',
            'is_free': false,
            'is_hidden_gem': true,
            'genre': 'Miscellaneous',
            'segment': 'Miscellaneous',
            'price_min': 75.0,
            'price_max': 95.0
          }
        ]
      };
    } else if (endpoint.contains('/stats')) {
      return {
        'status': 'success',
        'data': {
          'total_gems': 127,
          'average_score': 82.4,
          'average_sentiment': 0.75,
          'mood_distribution': {
            'romantic': 23,
            'foodie': 45,
            'nightlife': 18,
            'cultural': 25,
            'relaxing': 16,
            'budget': 32,
            'unique': 28,
            'cozy': 38
          },
          'score_ranges': {
            '90-100': 15,
            '80-89': 42,
            '70-79': 35,
            '60-69': 25,
            'below_60': 10
          }
        }
      };
    } else if (endpoint.contains('/flutter/moods')) {
      return {
        'status': 'success',
        'count': 8,
        'data': ['romantic', 'foodie', 'nightlife', 'cultural', 'relaxing', 'budget', 'unique', 'cozy']
      };
    } else if (endpoint.contains('/flutter/random-gem')) {
      // Return a random gem from the sample data
      final gemsData = _getSampleData('/gems')['data'] as List;
      final randomGem = gemsData[(DateTime.now().millisecondsSinceEpoch % gemsData.length)];
      return {
        'status': 'success',
        'data': randomGem
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
    
    final gems = gemsData.map((json) => HiddenGem.fromJson(json)).toList();
    print('🔗 ApiService: Successfully converted ${gems.length} gems');
    
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

  // GET /api/gems/type/{type} - Get gems by type (Updated to match backend)
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

  // GET /api/events - Get all events (Updated to match backend)
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

  // GET /api/events/top - Get top-rated events (New endpoint from backend)
  Future<ApiResponse<List<TorontoEvent>>> getTopEvents({int limit = 10}) async {
    final response = await _makeRequest('/events/top?limit=$limit');
    
    final eventsData = response['data'] as List<dynamic>;
    final events = eventsData.map((json) => TorontoEvent.fromJson(json)).toList();
    
    return ApiResponse.fromJson(response, events);
  }

  // GET /api/events/free - Get free events (New endpoint from backend)
  Future<ApiResponse<List<TorontoEvent>>> getFreeEvents({int limit = 10}) async {
    final response = await _makeRequest('/events/free?limit=$limit');
    
    final eventsData = response['data'] as List<dynamic>;
    final events = eventsData.map((json) => TorontoEvent.fromJson(json)).toList();
    
    return ApiResponse.fromJson(response, events);
  }

  // GET /api/events/upcoming - Get upcoming events (New endpoint from backend)
  Future<ApiResponse<List<TorontoEvent>>> getUpcomingEvents({int limit = 10}) async {
    final response = await _makeRequest('/events/upcoming?limit=$limit');
    
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

  // GET /api/events/type/{type} - Get events by type (New endpoint from backend)
  Future<ApiResponse<List<TorontoEvent>>> getEventsByType(String type, {int limit = 10}) async {
    final response = await _makeRequest('/events/type/$type?limit=$limit');
    
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
    Exception? lastException;
    
    for (String baseUrl in baseUrls) {
      try {
        final uri = Uri.parse('$baseUrl/collect-events');
        final response = await http.post(
          uri,
          headers: headers,
        ).timeout(const Duration(minutes: 5)); // Longer timeout for data collection

        if (response.statusCode == 200) {
          return json.decode(response.body) as Map<String, dynamic>;
        } else {
          lastException = ApiException('HTTP ${response.statusCode}: ${response.reasonPhrase}');
        }
      } catch (e) {
        lastException = Exception('Connection failed to $baseUrl: $e');
        continue;
      }
    }
    
    throw lastException ?? ApiException('Failed to trigger events data collection: All endpoints failed');
  }

  // POST /api/collect-data - Trigger comprehensive data collection (New endpoint from backend)
  Future<Map<String, dynamic>> collectAllData() async {
    Exception? lastException;
    
    for (String baseUrl in baseUrls) {
      try {
        final uri = Uri.parse('$baseUrl/collect-data');
        final response = await http.post(
          uri,
          headers: headers,
        ).timeout(const Duration(minutes: 10)); // Longer timeout for comprehensive collection

        if (response.statusCode == 200) {
          return json.decode(response.body) as Map<String, dynamic>;
        } else {
          lastException = ApiException('HTTP ${response.statusCode}: ${response.reasonPhrase}');
        }
      } catch (e) {
        lastException = Exception('Connection failed to $baseUrl: $e');
        continue;
      }
    }
    
    throw lastException ?? ApiException('Failed to trigger comprehensive data collection: All endpoints failed');
  }

  // Flutter-specific endpoints (mentioned in documentation)
  // GET /api/flutter/random-gem - Get a random gem from the 6ix
  Future<HiddenGem> getRandomGem() async {
    final response = await _makeRequest('/flutter/random-gem');
    return HiddenGem.fromJson(response['data']);
  }

  // GET /api/flutter/random-event - Get a random event (New endpoint from backend)
  Future<TorontoEvent> getRandomEvent() async {
    final response = await _makeRequest('/flutter/random-event');
    return TorontoEvent.fromJson(response['data']);
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