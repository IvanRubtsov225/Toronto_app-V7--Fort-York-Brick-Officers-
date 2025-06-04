enum EventCategory {
  cultural,
  music,
  food,
  art,
  sports,
  festival,
  nightlife,
  community;

  String get displayName {
    switch (this) {
      case EventCategory.cultural:
        return 'Cultural';
      case EventCategory.music:
        return 'Music';
      case EventCategory.food:
        return 'Food';
      case EventCategory.art:
        return 'Art';
      case EventCategory.sports:
        return 'Sports';
      case EventCategory.festival:
        return 'Festival';
      case EventCategory.nightlife:
        return 'Nightlife';
      case EventCategory.community:
        return 'Community';
    }
  }
}

class TorontoEvent {
  final String name;
  final String venue;
  final String date;
  final String time;
  final String priceRange;
  final String moodTags;
  final double redditBuzzScore;
  final double hiddenGemScore;
  final String? ticketmasterUrl;
  
  // Additional properties for UI
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime? endTime;
  final String neighborhood;
  final EventCategory category;
  final double? price;
  final List<String> features;
  final String? imageUrl;

  const TorontoEvent({
    required this.name,
    required this.venue,
    required this.date,
    required this.time,
    required this.priceRange,
    required this.moodTags,
    required this.redditBuzzScore,
    required this.hiddenGemScore,
    this.ticketmasterUrl,
    required this.title,
    required this.description,
    required this.startTime,
    this.endTime,
    required this.neighborhood,
    required this.category,
    this.price,
    this.features = const [],
    this.imageUrl,
  });

  factory TorontoEvent.fromJson(Map<String, dynamic> json) {
    final startDateTime = _parseDateTime(json['date'], json['time']);
    
    return TorontoEvent(
      name: json['name'] ?? '',
      venue: json['venue'] ?? '',
      date: json['date'] ?? '',
      time: json['time'] ?? '',
      priceRange: json['price_range'] ?? '',
      moodTags: json['mood_tags'] ?? '',
      redditBuzzScore: (json['reddit_buzz_score'] ?? 0.0).toDouble(),
      hiddenGemScore: (json['hidden_gem_score'] ?? 0.0).toDouble(),
      ticketmasterUrl: json['ticketmaster_url'],
      title: json['title'] ?? json['name'] ?? '',
      description: json['description'] ?? 'A Toronto event',
      startTime: startDateTime,
      endTime: json['end_time'] != null ? DateTime.parse(json['end_time']) : null,
      neighborhood: json['neighborhood'] ?? 'Toronto',
      category: _getCategoryFromName(json['name'] ?? ''),
      price: json['price']?.toDouble(),
      features: List<String>.from(json['features'] ?? []),
      imageUrl: json['image_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'venue': venue,
      'date': date,
      'time': time,
      'price_range': priceRange,
      'mood_tags': moodTags,
      'reddit_buzz_score': redditBuzzScore,
      'hidden_gem_score': hiddenGemScore,
      'ticketmaster_url': ticketmasterUrl,
      'title': title,
      'description': description,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'neighborhood': neighborhood,
      'category': category.name,
      'price': price,
      'features': features,
      'image_url': imageUrl,
    };
  }

  // Helper getters
  List<String> get moodTagsList {
    return moodTags.split(',').map((tag) => tag.trim()).where((tag) => tag.isNotEmpty).toList();
  }

  bool get isFree => priceRange.toLowerCase().contains('free') || price == 0;
  bool get isBudgetFriendly => priceRange.toLowerCase().contains('budget');
  bool get isPremium => priceRange.toLowerCase().contains('premium');

  bool get isHighBuzz => redditBuzzScore >= 70;
  bool get isHiddenGem => hiddenGemScore >= 75;

  String get buzzLevel {
    if (redditBuzzScore >= 80) return 'Very High';
    if (redditBuzzScore >= 60) return 'High';
    if (redditBuzzScore >= 40) return 'Medium';
    if (redditBuzzScore >= 20) return 'Low';
    return 'Very Low';
  }

  DateTime? get eventDateTime {
    return startTime;
  }

  bool get isUpcoming {
    return startTime.isAfter(DateTime.now());
  }

  bool get isToday {
    final now = DateTime.now();
    return startTime.year == now.year &&
           startTime.month == now.month &&
           startTime.day == now.day;
  }

  static DateTime _parseDateTime(String? date, String? time) {
    if (date == null) return DateTime.now();
    
    try {
      if (time != null && time.isNotEmpty) {
        return DateTime.parse('$date $time');
      } else {
        return DateTime.parse(date);
      }
    } catch (e) {
      return DateTime.now();
    }
  }

  static EventCategory _getCategoryFromName(String name) {
    final lowerName = name.toLowerCase();
    if (lowerName.contains('music') || lowerName.contains('concert')) {
      return EventCategory.music;
    }
    if (lowerName.contains('food') || lowerName.contains('dining')) {
      return EventCategory.food;
    }
    if (lowerName.contains('art') || lowerName.contains('gallery')) {
      return EventCategory.art;
    }
    if (lowerName.contains('sport') || lowerName.contains('game')) {
      return EventCategory.sports;
    }
    if (lowerName.contains('festival') || lowerName.contains('celebration')) {
      return EventCategory.festival;
    }
    if (lowerName.contains('night') || lowerName.contains('club')) {
      return EventCategory.nightlife;
    }
    if (lowerName.contains('community') || lowerName.contains('neighborhood')) {
      return EventCategory.community;
    }
    return EventCategory.cultural; // Default
  }

  @override
  String toString() {
    return 'TorontoEvent(name: $name, date: $date)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TorontoEvent && 
           other.name == name && 
           other.venue == venue && 
           other.date == date;
  }

  @override
  int get hashCode => Object.hash(name, venue, date);
} 