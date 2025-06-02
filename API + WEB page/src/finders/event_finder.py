import pandas as pd
import numpy as np
from datetime import datetime, timedelta
from fuzzywuzzy import fuzz
from collections import defaultdict, Counter
import sys
import os
sys.path.append(os.path.join(os.path.dirname(__file__), '..', '..'))

from src.collectors.ticketmaster_collector import TicketmasterCollector
from src.collectors.reddit_events_collector import RedditEventsCollector
from config.config import EVENT_SCORING_WEIGHTS

class EventFinder:
    def __init__(self):
        """Initialize the Event Finder with both collectors"""
        self.ticketmaster_collector = TicketmasterCollector()
        self.reddit_collector = RedditEventsCollector()
        self.ticketmaster_events = None
        self.reddit_events = None
        self.combined_events = None
        
    def collect_all_event_data(self, days_ahead=30):
        """Collect events from both Ticketmaster and Reddit"""
        print("🎭 Starting comprehensive event collection...")
        
        # Collect Ticketmaster events
        print("\n🎫 Collecting from Ticketmaster API...")
        tm_events = self.ticketmaster_collector.collect_toronto_events(
            days_ahead=days_ahead,
            keywords=['food', 'wine', 'beer', 'culinary', 'festival', 'market', 'art', 'music']
        )
        self.ticketmaster_events = tm_events
        
        # Collect Reddit events
        print("\n📱 Collecting from Reddit...")
        reddit_posts, reddit_comments = self.reddit_collector.collect_all_events()
        self.reddit_events = {'posts': reddit_posts, 'comments': reddit_comments}
        
        print(f"\n✅ Collection complete!")
        print(f"   🎫 Ticketmaster: {len(tm_events)} events")
        print(f"   📱 Reddit: {len(reddit_posts)} event posts")
        
        return tm_events, reddit_posts, reddit_comments
    
    def find_event_overlaps(self, similarity_threshold=70):
        """Find events that appear in both Reddit and Ticketmaster"""
        if not self.ticketmaster_events or not self.reddit_events['posts']:
            return []
        
        overlaps = []
        
        for tm_event in self.ticketmaster_events:
            tm_name = tm_event['name'].lower()
            tm_venue = tm_event.get('venue_name', '').lower()
            tm_date = tm_event.get('start_date', '')
            
            for reddit_post in self.reddit_events['posts']:
                reddit_title = reddit_post['title'].lower()
                reddit_text = reddit_post['text'].lower()
                reddit_venues = [v.lower() for v in reddit_post.get('venues_mentioned', [])]
                
                # Check name similarity
                name_similarity = fuzz.partial_ratio(tm_name, reddit_title)
                
                # Check venue similarity
                venue_similarity = 0
                if tm_venue and reddit_venues:
                    venue_similarity = max([fuzz.ratio(tm_venue, rv) for rv in reddit_venues])
                
                # Check if event is mentioned in Reddit text
                text_mention = any(word in reddit_text for word in tm_name.split() if len(word) > 3)
                
                # Combined similarity score
                combined_similarity = max(name_similarity, venue_similarity)
                if text_mention:
                    combined_similarity += 20
                
                if combined_similarity >= similarity_threshold:
                    overlaps.append({
                        'ticketmaster_event': tm_event,
                        'reddit_post': reddit_post,
                        'similarity_score': combined_similarity,
                        'name_similarity': name_similarity,
                        'venue_similarity': venue_similarity,
                        'text_mention': text_mention
                    })
        
        return overlaps
    
    def analyze_event_popularity(self, event):
        """Analyze how popular/mainstream an event is"""
        popularity_score = 0
        
        # Ticketmaster factors
        if 'price_ranges' in event:
            price_min = event['price_ranges'].get('min', 0)
            # Higher prices often indicate more mainstream/popular events
            if price_min > 100:
                popularity_score += 30
            elif price_min > 50:
                popularity_score += 20
            elif price_min == 0:
                popularity_score -= 10  # Free events can be more underground
        
        # Venue size indicators (rough estimation)
        venue_name = event.get('venue_name', '').lower()
        large_venues = [
            'rogers centre', 'scotiabank arena', 'budweiser stage', 'molson amphitheatre',
            'roy thomson hall', 'massey hall', 'air canada centre', 'acc'
        ]
        
        if any(large_venue in venue_name for large_venue in large_venues):
            popularity_score += 40
        
        # Genre factors
        genre = event.get('genre', '').lower()
        mainstream_genres = ['pop', 'rock', 'country', 'r&b', 'hip hop']
        underground_genres = ['experimental', 'avant-garde', 'noise', 'ambient', 'folk']
        
        if any(mg in genre for mg in mainstream_genres):
            popularity_score += 20
        elif any(ug in genre for ug in underground_genres):
            popularity_score -= 20
        
        # Promoter factors
        promoter = event.get('promoter', '').lower()
        major_promoters = ['live nation', 'ticketmaster', 'concert productions international']
        
        if any(mp in promoter for mp in major_promoters):
            popularity_score += 25
        
        return max(0, min(popularity_score, 100))
    
    def calculate_hidden_gem_score(self, event, reddit_buzz=None):
        """Calculate hidden gem score for an event"""
        # Base factors
        popularity = self.analyze_event_popularity(event)
        
        # Price accessibility (lower price = more accessible)
        price_score = 0
        if 'price_ranges' in event:
            price_min = event['price_ranges'].get('min', 0)
            if price_min == 0:
                price_score = 100  # Free events are very accessible
            elif price_min < 30:
                price_score = 80
            elif price_min < 60:
                price_score = 60
            elif price_min < 100:
                price_score = 40
            else:
                price_score = 20
        
        # Venue intimacy (smaller venues = higher score)
        venue_score = 50  # Default
        venue_name = event.get('venue_name', '').lower()
        
        intimate_indicators = ['studio', 'gallery', 'cafe', 'club', 'lounge', 'bar', 'pub']
        large_indicators = ['centre', 'center', 'stadium', 'arena', 'amphitheatre']
        
        if any(ind in venue_name for ind in intimate_indicators):
            venue_score = 80
        elif any(ind in venue_name for ind in large_indicators):
            venue_score = 20
        
        # Reddit buzz factor
        reddit_score = 0
        if reddit_buzz:
            reddit_score = reddit_buzz.get('buzz_score', 0)
            # Moderate buzz is good, too much buzz means not hidden
            if 20 <= reddit_score <= 60:
                reddit_score = reddit_score
            elif reddit_score > 60:
                reddit_score = max(0, 100 - reddit_score)  # Diminishing returns for high buzz
        
        # Uniqueness factors
        uniqueness_score = 50
        
        # Check for unique event indicators
        event_text = (event.get('name', '') + ' ' + event.get('info', '')).lower()
        unique_indicators = [
            'underground', 'intimate', 'exclusive', 'limited', 'small batch',
            'artisan', 'local', 'independent', 'indie', 'emerging', 'debut',
            'secret', 'hidden', 'popup', 'one night only', 'rare'
        ]
        
        for indicator in unique_indicators:
            if indicator in event_text:
                uniqueness_score += 10
        
        uniqueness_score = min(uniqueness_score, 100)
        
        # Calculate final hidden gem score
        # Lower popularity = higher hidden gem potential
        final_score = (
            (100 - popularity) * EVENT_SCORING_WEIGHTS['ticketmaster_popularity'] +
            price_score * 0.2 +
            venue_score * 0.15 +
            reddit_score * EVENT_SCORING_WEIGHTS['reddit_buzz'] +
            uniqueness_score * EVENT_SCORING_WEIGHTS['uniqueness_score']
        )
        
        return min(final_score, 100)
    
    def find_hidden_gem_events(self, 
                              min_hidden_score=60,
                              max_price=100,
                              event_types=None,
                              mood_filters=None):
        """Find hidden gem events based on criteria"""
        if not self.ticketmaster_events and not self.reddit_events:
            print("No event data available. Run collect_all_event_data() first.")
            return []
        
        hidden_gems = []
        
        # Process Ticketmaster events
        if self.ticketmaster_events:
            print("🔍 Analyzing Ticketmaster events for hidden gems...")
            
            for event in self.ticketmaster_events:
                # Apply filters
                if max_price and event.get('price_ranges', {}).get('min', 0) > max_price:
                    continue
                
                if event_types and event.get('segment', '').lower() not in [et.lower() for et in event_types]:
                    continue
                
                if mood_filters:
                    event_moods = [mood.lower() for mood in event.get('mood_tags', [])]
                    if not any(mf.lower() in event_moods for mf in mood_filters):
                        continue
                
                # Find matching Reddit buzz
                reddit_buzz = None
                if self.reddit_events['posts']:
                    for reddit_post in self.reddit_events['posts']:
                        if fuzz.partial_ratio(event['name'].lower(), reddit_post['title'].lower()) > 60:
                            reddit_buzz = reddit_post
                            break
                
                # Calculate hidden gem score
                hidden_score = self.calculate_hidden_gem_score(event, reddit_buzz)
                
                if hidden_score >= min_hidden_score:
                    gem = {
                        'name': event['name'],
                        'type': 'ticketmaster',
                        'source': 'Ticketmaster + Reddit',
                        'date': event.get('start_date', ''),
                        'time': event.get('start_time', ''),
                        'venue': event.get('venue_name', ''),
                        'address': event.get('venue_address', ''),
                        'price_min': event.get('price_ranges', {}).get('min', 0),
                        'price_max': event.get('price_ranges', {}).get('max', 0),
                        'currency': event.get('price_ranges', {}).get('currency', 'CAD'),
                        'genre': event.get('genre', ''),
                        'segment': event.get('segment', ''),
                        'mood_tags': event.get('mood_tags', []),
                        'hidden_gem_score': round(hidden_score, 2),
                        'popularity_score': self.analyze_event_popularity(event),
                        'accessibility_score': event.get('accessibility_score', 0),
                        'family_friendly_score': event.get('family_friendly_score', 0),
                        'url': event.get('url', ''),
                        'info': event.get('info', ''),
                        'reddit_buzz': reddit_buzz['buzz_score'] if reddit_buzz else 0,
                        'reddit_sentiment': reddit_buzz['sentiment_score'] if reddit_buzz else 0,
                        'event_data': event
                    }
                    
                    hidden_gems.append(gem)
        
        # Process Reddit-only events
        if self.reddit_events['posts']:
            print("🔍 Analyzing Reddit events for hidden gems...")
            
            for reddit_post in self.reddit_events['posts']:
                # Skip if already matched with Ticketmaster event
                already_matched = any(
                    fuzz.partial_ratio(reddit_post['title'].lower(), gem['name'].lower()) > 60
                    for gem in hidden_gems
                )
                
                if already_matched:
                    continue
                
                # Apply filters
                if event_types and reddit_post.get('event_type', '').lower() not in [et.lower() for et in event_types]:
                    continue
                
                if mood_filters:
                    reddit_moods = [mood.lower() for mood in reddit_post.get('mood_tags', [])]
                    if not any(mf.lower() in reddit_moods for mf in mood_filters):
                        continue
                
                # Calculate hidden gem score for Reddit events
                # Reddit events are often more underground/hidden by nature
                reddit_score = reddit_post.get('buzz_score', 0)
                sentiment_score = reddit_post.get('sentiment_score', 0)
                
                # Reddit events get bonus for being community-driven
                base_score = 70 + min(sentiment_score * 20, 20)
                
                # Moderate buzz is ideal for hidden gems
                if 10 <= reddit_score <= 50:
                    buzz_bonus = reddit_score / 2
                else:
                    buzz_bonus = max(0, 25 - abs(reddit_score - 30))
                
                hidden_score = min(base_score + buzz_bonus, 100)
                
                if hidden_score >= min_hidden_score:
                    gem = {
                        'name': reddit_post['title'],
                        'type': 'reddit',
                        'source': 'Reddit Community',
                        'date': ', '.join(reddit_post.get('dates_mentioned', [])[:2]) or 'TBD',
                        'time': 'TBD',
                        'venue': ', '.join(reddit_post.get('venues_mentioned', [])[:2]) or 'TBD',
                        'address': '',
                        'price_min': 0,
                        'price_max': 0,
                        'currency': 'CAD',
                        'genre': reddit_post.get('event_type', ''),
                        'segment': reddit_post.get('event_type', ''),
                        'mood_tags': reddit_post.get('mood_tags', []),
                        'hidden_gem_score': round(hidden_score, 2),
                        'popularity_score': max(0, 100 - reddit_score),
                        'accessibility_score': 50,  # Assume moderate accessibility
                        'family_friendly_score': reddit_post.get('family_friendly_score', 30),
                        'url': f"https://reddit.com{reddit_post.get('url', '')}" if reddit_post.get('url') else '',
                        'info': reddit_post.get('text', '')[:200] + '...' if len(reddit_post.get('text', '')) > 200 else reddit_post.get('text', ''),
                        'reddit_buzz': reddit_score,
                        'reddit_sentiment': sentiment_score,
                        'event_data': reddit_post
                    }
                    
                    hidden_gems.append(gem)
        
        # Sort by hidden gem score
        hidden_gems.sort(key=lambda x: x['hidden_gem_score'], reverse=True)
        
        self.combined_events = hidden_gems
        return hidden_gems
    
    def filter_by_mood(self, mood_filter=None, top_n=20):
        """Filter events by mood tags"""
        if self.combined_events is None:
            print("No events available. Run find_hidden_gem_events() first.")
            return []
        
        if mood_filter is None:
            return self.combined_events[:top_n]
        
        mood_filter = mood_filter.lower()
        filtered_events = []
        
        for event in self.combined_events:
            event_moods = [mood.lower() for mood in event.get('mood_tags', [])]
            if mood_filter in event_moods:
                filtered_events.append(event)
        
        return filtered_events[:top_n]
    
    def get_event_statistics(self):
        """Get statistics about collected events"""
        if self.combined_events is None:
            return {}
        
        # Count by type
        tm_count = sum(1 for e in self.combined_events if e['type'] == 'ticketmaster')
        reddit_count = sum(1 for e in self.combined_events if e['type'] == 'reddit')
        
        # Count by mood
        mood_counts = defaultdict(int)
        for event in self.combined_events:
            for mood in event.get('mood_tags', []):
                mood_counts[mood] += 1
        
        # Count by genre/type
        genre_counts = defaultdict(int)
        for event in self.combined_events:
            genre = event.get('genre', 'Unknown')
            genre_counts[genre] += 1
        
        # Price analysis
        paid_events = [e for e in self.combined_events if e['price_min'] > 0]
        avg_price = sum(e['price_min'] for e in paid_events) / len(paid_events) if paid_events else 0
        
        return {
            'total_events': len(self.combined_events),
            'ticketmaster_events': tm_count,
            'reddit_events': reddit_count,
            'average_hidden_score': round(sum(e['hidden_gem_score'] for e in self.combined_events) / len(self.combined_events), 2),
            'average_price': round(avg_price, 2),
            'free_events': sum(1 for e in self.combined_events if e['price_min'] == 0),
            'mood_distribution': dict(sorted(mood_counts.items(), key=lambda x: x[1], reverse=True)[:10]),
            'genre_distribution': dict(sorted(genre_counts.items(), key=lambda x: x[1], reverse=True)[:10])
        }
    
    def save_events_data(self, timestamp=None):
        """Save collected events data to CSV"""
        if self.combined_events is None:
            print("No events to save")
            return None
        
        if timestamp is None:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        
        # Create DataFrame
        events_df = pd.DataFrame(self.combined_events)
        
        # Save to CSV
        filename = f"data/hidden_gem_events_{timestamp}.csv"
        events_df.to_csv(filename, index=False)
        
        print(f"💾 Saved {len(self.combined_events)} hidden gem events to {filename}")
        return filename

if __name__ == "__main__":
    finder = EventFinder()
    
    # Collect all event data
    print("🎭 Starting event discovery...")
    finder.collect_all_event_data(days_ahead=30)
    
    # Find hidden gem events
    print("\n💎 Finding hidden gem events...")
    hidden_gems = finder.find_hidden_gem_events(
        min_hidden_score=50,
        max_price=80,
        mood_filters=['foodie', 'cultural', 'artistic', 'underground']
    )
    
    if hidden_gems:
        # Save results
        finder.save_events_data()
        
        # Show statistics
        stats = finder.get_event_statistics()
        print(f"\n📊 Event Discovery Results:")
        print(f"   Total Hidden Gems: {stats['total_events']}")
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
    else:
        print("No hidden gem events found with current criteria.") 