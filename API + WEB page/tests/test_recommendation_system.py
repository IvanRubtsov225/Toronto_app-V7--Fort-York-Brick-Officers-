#!/usr/bin/env python3
"""
Test the new recommendation-focused Reddit collection and hidden gems finding system
"""

import sys
import os
sys.path.append(os.path.join(os.path.dirname(__file__), '..'))

from src.collectors.reddit_collector_recommendations import RedditRecommendationCollector
from src.finders.hidden_gems_finder_recommendations import HiddenGemsFinderRecommendations

def test_recommendation_patterns():
    """Test the recommendation pattern detection"""
    print("🧪 Testing recommendation pattern detection...")
    
    collector = RedditRecommendationCollector()
    
    # Test cases - these should be detected as recommendation posts
    positive_cases = [
        ("Best Korean BBQ in the city?", "Looking for recommendations"),
        ("Where do you go for the best matcha latte in the city?", ""),
        ("Good all-you-can-eat hotpot places?", "Need suggestions"),
        ("Any hidden gems for authentic Italian food?", ""),
        ("What's your favorite brunch spot downtown?", ""),
        ("Looking for a good sushi place near Yonge and Bloor", ""),
        ("Recommend me some good Thai restaurants", ""),
        ("Where can I find the best pizza in Toronto?", "")
    ]
    
    # Test cases - these should NOT be detected as recommendation posts
    negative_cases = [
        ("I went to this amazing restaurant yesterday", "It was great"),
        ("Restaurant review: XYZ Cafe", "Here's my experience"),
        ("New restaurant opening on Queen Street", ""),
        ("Food truck festival this weekend", ""),
        ("Cooking tips for beginners", "")
    ]
    
    print("✅ Testing positive cases (should be detected as recommendations):")
    for title, text in positive_cases:
        is_rec = collector.is_recommendation_post(title, text)
        status = "✅" if is_rec else "❌"
        print(f"  {status} '{title}' -> {is_rec}")
    
    print("\n❌ Testing negative cases (should NOT be detected as recommendations):")
    for title, text in negative_cases:
        is_rec = collector.is_recommendation_post(title, text)
        status = "✅" if not is_rec else "❌"
        print(f"  {status} '{title}' -> {is_rec}")

def test_restaurant_extraction():
    """Test restaurant name extraction from comments"""
    print("\n🧪 Testing restaurant name extraction...")
    
    collector = RedditRecommendationCollector()
    
    # Test comments with restaurant mentions
    test_comments = [
        "I highly recommend Pai Northern Thai Kitchen on Duncan Street. Amazing pad thai!",
        "Try Kinka Izakaya - they have the best ramen in the city",
        "Richmond Station is excellent for fine dining",
        "You should check out Sukhothai for authentic Thai food",
        "Momofuku Noodle Bar has great pork buns",
        "The Stockyards is my go-to for burgers",
        "Cafe Diplomatico on College Street has amazing coffee",
        "I love going to Terroni for Italian food",
        "Buca Osteria & Bar downtown is fantastic",
        "Seven Lives Tacos Al Pastor is a hidden gem"
    ]
    
    for comment in test_comments:
        restaurants = collector.extract_restaurant_names(comment)
        print(f"Comment: '{comment[:50]}...'")
        print(f"  Extracted: {restaurants}")
        print()

def test_quality_indicators():
    """Test quality indicator extraction"""
    print("🧪 Testing quality indicator extraction...")
    
    collector = RedditRecommendationCollector()
    
    test_comments = [
        "This place is absolutely amazing! Best food I've ever had.",
        "Terrible service and overpriced food. Avoid at all costs.",
        "Pretty good, nothing special but worth a try.",
        "Outstanding quality, fresh ingredients, highly recommend!",
        "Disappointing experience, food was cold and bland."
    ]
    
    for comment in test_comments:
        indicators = collector.extract_quality_indicators(comment)
        print(f"Comment: '{comment}'")
        print(f"  Positive: {indicators['positive_indicators']}")
        print(f"  Negative: {indicators['negative_indicators']}")
        print(f"  Quality Score: {indicators['quality_score']}")
        print()

def test_full_recommendation_system():
    """Test the complete recommendation-based hidden gems system"""
    print("🧪 Testing complete recommendation system...")
    
    try:
        # Initialize the recommendation-based finder
        finder = HiddenGemsFinderRecommendations()
        
        print("✅ Successfully initialized HiddenGemsFinderRecommendations")
        
        # Test data collection (with very limited scope for testing)
        print("\n📡 Testing recommendation data collection...")
        posts, comments = finder.reddit_collector.collect_subreddit_recommendations('FoodToronto', limit=5)
        
        if posts or comments:
            print(f"✅ Successfully collected {len(posts)} posts and {len(comments)} comments")
            
            # Test recommendation analysis
            if comments:
                print("\n📊 Testing recommendation analysis...")
                restaurant_stats = finder.reddit_collector.analyze_recommendations(comments)
                
                if restaurant_stats:
                    print(f"✅ Analyzed {len(restaurant_stats)} unique restaurants")
                    
                    # Show top 3 recommendations
                    sorted_restaurants = sorted(
                        restaurant_stats.items(), 
                        key=lambda x: x[1]['recommendation_score'], 
                        reverse=True
                    )
                    
                    print("\n🏆 Top 3 Recommended Restaurants from Test:")
                    for i, (name, stats) in enumerate(sorted_restaurants[:3], 1):
                        print(f"{i}. {name}")
                        print(f"   Mentions: {stats['mention_count']}")
                        print(f"   Avg Sentiment: {stats['avg_sentiment']:.2f}")
                        print(f"   Recommendation Score: {stats['recommendation_score']:.1f}")
                else:
                    print("⚠️ No restaurant statistics generated")
            else:
                print("⚠️ No comments with restaurant mentions found")
        else:
            print("⚠️ No recommendation data collected (this might be normal for testing)")
            
    except Exception as e:
        print(f"❌ Error in recommendation system test: {e}")
        print("💡 This might be due to Reddit API authentication issues")

def main():
    """Run all tests"""
    print("🍽️ Toronto Hidden Gems - Recommendation System Tests")
    print("=" * 60)
    
    # Test individual components
    test_recommendation_patterns()
    test_restaurant_extraction()
    test_quality_indicators()
    
    # Test full system (might fail due to Reddit API)
    test_full_recommendation_system()
    
    print("\n🎉 Recommendation system tests completed!")
    print("\n💡 Key improvements in the new system:")
    print("   • Targets recommendation posts specifically")
    print("   • Extracts restaurant names from comment responses")
    print("   • Analyzes sentiment and quality indicators")
    print("   • Focuses on user-generated recommendations")
    print("   • Better pattern matching for restaurant names")

if __name__ == "__main__":
    main() 