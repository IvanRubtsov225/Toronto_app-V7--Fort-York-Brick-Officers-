#!/usr/bin/env python3
"""
Toronto Hidden Gems Finder - Main Runner Script

This script provides an easy way to run different components of the application.
"""

import sys
import argparse
from datetime import datetime

def run_dashboard():
    """Run the interactive dashboard"""
    print("🚀 Starting Toronto Hidden Gems Dashboard...")
    print("📍 Dashboard will be available at: http://localhost:8050")
    print("⏳ Loading data and starting server...")
    
    import sys
    import os
    sys.path.append(os.path.join(os.path.dirname(__file__), '..'))
    
    from src.dashboard.dashboard import HiddenGemsDashboard
    dashboard = HiddenGemsDashboard()
    dashboard.run(debug=False, port=8050)

def run_data_collection():
    """Collect Reddit data"""
    print("📡 Collecting Reddit data from Toronto subreddits...")
    
    import sys
    import os
    sys.path.append(os.path.join(os.path.dirname(__file__), '..'))
    
    from src.collectors.reddit_collector_readonly import RedditCollectorReadOnly as RedditCollector
    collector = RedditCollector()
    posts, comments = collector.collect_all_data(limit_per_subreddit=100)
    
    if posts and comments:
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        posts_file, comments_file = collector.save_data(posts, comments, timestamp)
        print(f"✅ Data collection complete!")
        print(f"📄 Posts saved to: {posts_file}")
        print(f"💬 Comments saved to: {comments_file}")
    else:
        print("❌ No data collected. Check your Reddit API credentials.")

def run_recommendation_collection():
    """Collect recommendation-focused Reddit data"""
    print("🎯 Collecting recommendation data from Toronto food subreddits...")
    
    import sys
    import os
    sys.path.append(os.path.join(os.path.dirname(__file__), '..'))
    
    from src.collectors.reddit_collector_recommendations import RedditRecommendationCollector
    collector = RedditRecommendationCollector()
    posts, comments = collector.collect_all_recommendations(limit_per_subreddit=30)
    
    if posts or comments:
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        posts_file, comments_file = collector.save_recommendation_data(posts, comments, timestamp)
        print(f"✅ Recommendation data collection complete!")
        print(f"📄 Posts saved to: {posts_file}")
        print(f"💬 Comments saved to: {comments_file}")
        
        # Analyze recommendations
        if comments:
            print("\n📊 Analyzing recommendations...")
            restaurant_stats = collector.analyze_recommendations(comments)
            
            if restaurant_stats:
                sorted_restaurants = sorted(
                    restaurant_stats.items(), 
                    key=lambda x: x[1]['recommendation_score'], 
                    reverse=True
                )
                
                print(f"\n🏆 Top 10 Recommended Restaurants:")
                for i, (name, stats) in enumerate(sorted_restaurants[:10], 1):
                    print(f"{i:2d}. {name}")
                    print(f"    Mentions: {stats['mention_count']}")
                    print(f"    Avg Sentiment: {stats['avg_sentiment']:.2f}")
                    print(f"    Recommendation Score: {stats['recommendation_score']:.1f}")
                    print()
    else:
        print("❌ No recommendation data collected. Check your Reddit API credentials.")

def run_event_collection():
    """Collect event data from Reddit and Ticketmaster"""
    print("🎭 Collecting event data from Reddit and Ticketmaster...")
    
    import sys
    import os
    sys.path.append(os.path.join(os.path.dirname(__file__), '..'))
    
    # Collect Reddit events
    print("\n📱 Collecting events from Reddit...")
    from src.collectors.reddit_events_collector import RedditEventsCollector
    reddit_collector = RedditEventsCollector()
    reddit_posts, reddit_comments = reddit_collector.collect_all_events(limit_per_subreddit=25)
    
    if reddit_posts or reddit_comments:
        reddit_collector.save_events_data(reddit_posts, reddit_comments)
    
    # Collect Ticketmaster events
    print("\n🎫 Collecting events from Ticketmaster...")
    from src.collectors.ticketmaster_collector import TicketmasterCollector
    tm_collector = TicketmasterCollector()
    tm_events = tm_collector.collect_toronto_events(
        days_ahead=30,
        keywords=['food', 'wine', 'beer', 'culinary', 'festival', 'market', 'art', 'music']
    )
    
    if tm_events:
        tm_collector.save_events_data(tm_events)
    
    print(f"\n✅ Event collection complete!")
    print(f"📱 Reddit events: {len(reddit_posts)}")
    print(f"🎫 Ticketmaster events: {len(tm_events)}")

def run_event_finder():
    """Find hidden gem events using combined data"""
    print("💎 Finding hidden gem events in Toronto...")
    
    import sys
    import os
    sys.path.append(os.path.join(os.path.dirname(__file__), '..'))
    
    from src.finders.event_finder import EventFinder
    finder = EventFinder()
    
    # Collect all event data
    print("📱 Collecting event data...")
    finder.collect_all_event_data(days_ahead=30)
    
    # Find hidden gem events
    print("🔍 Finding hidden gem events...")
    hidden_gems = finder.find_hidden_gem_events(
        min_hidden_score=50,
        max_price=100,
        mood_filters=['foodie', 'cultural', 'artistic', 'romantic']
    )
    
    if hidden_gems:
        print(f"\n🎉 Found {len(hidden_gems)} hidden gem events!")
        
        # Show statistics
        stats = finder.get_event_statistics()
        print(f"\n📊 Event Statistics:")
        print(f"   Ticketmaster Events: {stats['ticketmaster_events']}")
        print(f"   Reddit Events: {stats['reddit_events']}")
        print(f"   Average Hidden Score: {stats['average_hidden_score']}")
        print(f"   Free Events: {stats['free_events']}")
        print(f"   Average Price: ${stats['average_price']:.2f}")
        
        # Show top events
        print(f"\n🏆 Top 10 Hidden Gem Events:")
        for i, event in enumerate(hidden_gems[:10], 1):
            print(f"{i:2d}. {event['name']}")
            print(f"    📅 {event['date']} at {event['time']}")
            print(f"    📍 {event['venue']}")
            print(f"    💰 ${event['price_min']}-${event['price_max']} {event['currency']}")
            print(f"    🎭 {', '.join(event['mood_tags'])}")
            print(f"    ⭐ Hidden Score: {event['hidden_gem_score']}")
            print(f"    📊 Source: {event['source']}")
            print()
        
        # Show mood examples
        print("\n🎭 Events by Mood:")
        moods_to_show = ['Foodie', 'Cultural', 'Romantic', 'Free']
        for mood in moods_to_show:
            mood_events = finder.filter_by_mood(mood, top_n=3)
            if mood_events:
                print(f"\n💫 Top {mood} Events:")
                for i, event in enumerate(mood_events[:3], 1):
                    print(f"  {i}. {event['name']} - {event['venue']}")
        
        # Export results
        filename = finder.save_events_data()
        print(f"\n📄 Results exported to: {filename}")
    else:
        print("❌ No hidden gem events found. Try adjusting the criteria.")

def run_dinesafe_analysis():
    """Analyze DineSafe data"""
    print("🏥 Analyzing DineSafe inspection data...")
    
    import sys
    import os
    sys.path.append(os.path.join(os.path.dirname(__file__), '..'))
    
    from src.analyzers.dinesafe_analyzer import DineSafeAnalyzer
    analyzer = DineSafeAnalyzer()
    
    # Get top establishments
    top_establishments = analyzer.get_top_rated_establishments(limit=20)
    print(f"\n🏆 Top 20 Establishments by Quality Score:")
    print(top_establishments[['Establishment Name', 'establishment_type', 'quality_score', 'pass_rate']])
    
    # Export analysis
    filename = analyzer.export_analysis()
    print(f"📊 Analysis exported to: {filename}")

def run_hidden_gems_finder():
    """Find hidden gems using read-only approach"""
    print("💎 Finding hidden gems in Toronto...")
    
    import sys
    import os
    sys.path.append(os.path.join(os.path.dirname(__file__), '..'))
    
    from src.finders.hidden_gems_finder_readonly import HiddenGemsFinderReadOnly as HiddenGemsFinder
    finder = HiddenGemsFinder()
    
    # Load or collect Reddit data
    print("📱 Loading Reddit data...")
    finder.load_or_collect_reddit_data(use_existing=False)
    
    # Find hidden gems
    print("🔍 Analyzing data to find hidden gems...")
    hidden_gems = finder.find_hidden_gems(
        min_dinesafe_score=70,
        min_reddit_mentions=1,
        max_reddit_mentions=10
    )
    
    if hidden_gems:
        print(f"\n🎉 Found {len(hidden_gems)} hidden gems!")
        print("\n🏅 Top 10 Hidden Gems:")
        for i, gem in enumerate(hidden_gems[:10], 1):
            print(f"{i:2d}. {gem['name']}")
            print(f"    📍 {gem['address']}")
            print(f"    🏷️  {gem['type']}")
            print(f"    ⭐ Score: {gem['hidden_gem_score']:.1f}")
            print(f"    💬 Reddit Mentions: {gem['mention_count']}")
            print()
        
        # Export results
        filename = finder.export_results()
        print(f"📄 Results exported to: {filename}")
    else:
        print("❌ No hidden gems found. Try adjusting the criteria.")

def run_recommendation_gems_finder():
    """Find hidden gems using recommendation-focused approach"""
    print("🎯 Finding hidden gems using recommendation data...")
    
    import sys
    import os
    sys.path.append(os.path.join(os.path.dirname(__file__), '..'))
    
    from src.finders.hidden_gems_finder_recommendations import HiddenGemsFinderRecommendations
    finder = HiddenGemsFinderRecommendations()
    
    # Load or collect recommendation data
    print("📱 Loading recommendation data...")
    finder.load_or_collect_recommendation_data(use_existing=False)
    
    # Find hidden gems
    print("🔍 Analyzing recommendation data to find hidden gems...")
    hidden_gems = finder.find_hidden_gems(
        min_dinesafe_score=65,
        min_recommendation_mentions=1,
        max_recommendation_mentions=6
    )
    
    if hidden_gems:
        print(f"\n🎉 Found {len(hidden_gems)} recommendation-based hidden gems!")
        print("\n🏅 Top 10 Hidden Gems (Based on Reddit Recommendations):")
        for i, gem in enumerate(hidden_gems[:10], 1):
            print(f"{i:2d}. {gem['name']}")
            print(f"    📍 {gem['address']}")
            print(f"    🏷️  {gem['type']}")
            print(f"    ⭐ Hidden Gem Score: {gem['hidden_gem_score']}")
            print(f"    💬 Recommendation Score: {gem['recommendation_score']}")
            print(f"    🍽️ DineSafe Score: {gem['dinesafe_score']}")
            print(f"    📊 Mentions: {gem['mention_count']}")
            print(f"    😊 Avg Sentiment: {gem['avg_sentiment']:.2f}")
            print(f"    🎭 Mood Tags: {', '.join(gem.get('mood_tags', []))}")
            print()
        
        # Show mood statistics
        print("\n📊 Mood Distribution:")
        mood_stats = finder.get_mood_statistics()
        for mood, count in mood_stats.items():
            if count > 0:
                print(f"    {mood}: {count} places")
        
        # Show examples of mood filtering
        print("\n🎭 Examples by Mood:")
        moods_to_show = ['Romantic', 'Foodie', 'Budget', 'Cultural']
        for mood in moods_to_show:
            mood_gems = finder.filter_by_mood(mood, top_n=3)
            if mood_gems:
                print(f"\n💝 Top {mood} Places:")
                for i, gem in enumerate(mood_gems[:3], 1):
                    print(f"  {i}. {gem['name']} - {gem['address']}")
        
        # Export results
        filename = finder.export_results()
        print(f"📄 Results exported to: {filename}")
    else:
        print("❌ No recommendation-based hidden gems found. Try adjusting the criteria.")

def run_quick_demo():
    """Run a quick demo with sample data"""
    print("🎬 Running quick demo with sample data...")
    print("📍 Starting dashboard with sample data...")
    
    import sys
    import os
    sys.path.append(os.path.join(os.path.dirname(__file__), '..'))
    
    from src.dashboard.dashboard import HiddenGemsDashboard
    dashboard = HiddenGemsDashboard()
    # Force sample data creation
    dashboard.create_sample_data()
    dashboard.run(debug=False, port=8050)

def run_test_recommendations():
    """Test the recommendation system"""
    print("🧪 Testing recommendation system...")
    
    import sys
    import os
    sys.path.append(os.path.join(os.path.dirname(__file__), '..'))
    
    from tests.test_recommendation_system import main as test_main
    test_main()

def main():
    parser = argparse.ArgumentParser(
        description="Toronto Hidden Gems & Events Finder",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python run.py dashboard          # Start interactive dashboard
  python run.py collect           # Collect general Reddit data
  python run.py recommendations   # Collect recommendation-focused data
  python run.py events            # Collect event data (Reddit + Ticketmaster)
  python run.py find-events       # Find hidden gem events
  python run.py analyze           # Analyze DineSafe data
  python run.py find              # Find hidden gems (general approach)
  python run.py find-recs         # Find hidden gems (recommendation-focused)
  python run.py test-recs         # Test recommendation system
  python run.py demo              # Quick demo with sample data
        """
    )
    
    parser.add_argument(
        'mode',
        choices=['dashboard', 'collect', 'recommendations', 'events', 'find-events', 'analyze', 'find', 'find-recs', 'test-recs', 'demo'],
        help='Mode to run the application in'
    )
    
    if len(sys.argv) == 1:
        # No arguments provided, show help and run dashboard
        parser.print_help()
        print("\n🚀 No mode specified, starting dashboard by default...")
        run_dashboard()
        return
    
    args = parser.parse_args()
    
    print("🎭 Toronto Hidden Gems & Events Finder")
    print("=" * 50)
    
    try:
        if args.mode == 'dashboard':
            run_dashboard()
        elif args.mode == 'collect':
            run_data_collection()
        elif args.mode == 'recommendations':
            run_recommendation_collection()
        elif args.mode == 'events':
            run_event_collection()
        elif args.mode == 'find-events':
            run_event_finder()
        elif args.mode == 'analyze':
            run_dinesafe_analysis()
        elif args.mode == 'find':
            run_hidden_gems_finder()
        elif args.mode == 'find-recs':
            run_recommendation_gems_finder()
        elif args.mode == 'test-recs':
            run_test_recommendations()
        elif args.mode == 'demo':
            run_quick_demo()
    except KeyboardInterrupt:
        print("\n\n👋 Goodbye! Thanks for using Toronto Hidden Gems & Events Finder!")
    except Exception as e:
        print(f"\n❌ Error: {e}")
        print("💡 Make sure you have:")
        print("   - Installed all dependencies (pip install -r requirements.txt)")
        print("   - Set up Reddit API credentials in config.py")
        print("   - Ticketmaster API credentials are valid")
        print("   - DineSafe data file is present")

if __name__ == "__main__":
    main() 