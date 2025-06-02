import praw
import pandas as pd
import re
from datetime import datetime, timedelta
from textblob import TextBlob
import time
from praw.models import MoreComments
from tqdm import tqdm
import sys
import os
sys.path.append(os.path.join(os.path.dirname(__file__), '..', '..'))
from config.config import *

class RedditEventsCollector:
    def __init__(self):
        """Initialize Reddit API connection for event collection"""
        self.reddit = praw.Reddit(
            client_id=REDDIT_CLIENT_ID,
            client_secret=REDDIT_CLIENT_SECRET,
            user_agent=REDDIT_USER_AGENT
        )
        
        # Event detection patterns
        self.event_patterns = [
            # Direct event mentions
            r'(?:event|happening|going on)\s+(?:on|this|next|tomorrow|tonight)',
            r'(?:concert|show|festival|party|gathering|meetup)',
            r'(?:tonight|tomorrow|this weekend|next week)',
            r'(?:what\'s|whats)\s+(?:happening|going on|on)',
            
            # Date patterns
            r'(?:january|february|march|april|may|june|july|august|september|october|november|december)\s+\d{1,2}',
            r'\d{1,2}\/\d{1,2}(?:\/\d{2,4})?',
            r'(?:mon|tue|wed|thu|fri|sat|sun)day',
            
            # Time patterns
            r'\d{1,2}:\d{2}\s*(?:am|pm)',
            r'\d{1,2}\s*(?:am|pm)',
            
            # Venue/location patterns
            r'(?:at|@)\s+[A-Z][a-zA-Z\s&\'-]+',
            r'(?:downtown|uptown|midtown|north|south|east|west)\s+toronto',
            r'(?:harbourfront|distillery|entertainment district|king st|queen st)',
        ]
        
        # Event type indicators
        self.event_type_indicators = {
            'music': [
                'concert', 'show', 'band', 'singer', 'musician', 'dj', 'live music',
                'album release', 'tour', 'acoustic', 'jazz', 'rock', 'electronic',
                'classical', 'opera', 'symphony', 'hip hop', 'indie', 'folk'
            ],
            'food': [
                'food festival', 'wine tasting', 'beer festival', 'farmers market',
                'food truck', 'pop up', 'restaurant opening', 'chef', 'cooking',
                'brunch', 'dinner', 'tasting menu', 'culinary', 'foodie'
            ],
            'art': [
                'art show', 'gallery', 'exhibition', 'museum', 'installation',
                'artist', 'painting', 'sculpture', 'photography', 'design',
                'creative', 'art opening', 'studio tour'
            ],
            'nightlife': [
                'party', 'club', 'bar', 'nightlife', 'dancing', 'cocktail',
                'late night', 'after hours', 'lounge', 'pub crawl', 'rooftop'
            ],
            'outdoor': [
                'outdoor', 'park', 'beach', 'hiking', 'cycling', 'festival',
                'market', 'street fair', 'patio', 'garden', 'summer', 'picnic'
            ],
            'community': [
                'meetup', 'community', 'networking', 'volunteer', 'charity',
                'fundraiser', 'workshop', 'seminar', 'talk', 'lecture'
            ],
            'sports': [
                'game', 'match', 'tournament', 'sports', 'hockey', 'basketball',
                'baseball', 'soccer', 'football', 'tennis', 'running', 'marathon'
            ],
            'cultural': [
                'cultural', 'heritage', 'traditional', 'ethnic', 'festival',
                'celebration', 'parade', 'ceremony', 'religious', 'multicultural'
            ]
        }
        
        # Location extraction patterns
        self.venue_patterns = [
            r'(?:at|@)\s+([A-Z][a-zA-Z\s&\'-]{3,40})(?:\s|$|,|\.|!|\?)',
            r'([A-Z][a-zA-Z\s&\'-]{3,40})\s+(?:venue|hall|centre|center|theatre|theater|stadium|arena)',
            r'(?:venue|hall|centre|center|theatre|theater)\s+([A-Z][a-zA-Z\s&\'-]{3,40})',
            r'([A-Z][a-zA-Z\s&\'-]{3,40})\s+(?:on|at)\s+(?:[A-Z][a-zA-Z\s]+(?:street|st|avenue|ave|road|rd))',
        ]
    
    def is_event_post(self, title, text=""):
        """Check if a post is about an event"""
        full_text = (title + " " + text).lower()
        
        # Check for event keywords
        event_keywords = [
            'event', 'happening', 'concert', 'show', 'festival', 'party',
            'meetup', 'gathering', 'workshop', 'exhibition', 'performance',
            'tonight', 'tomorrow', 'this weekend', 'next week', 'going on'
        ]
        
        has_event_keyword = any(keyword in full_text for keyword in event_keywords)
        
        # Check for event patterns
        has_event_pattern = any(re.search(pattern, full_text, re.IGNORECASE) for pattern in self.event_patterns)
        
        # Check for question indicators about events
        question_indicators = ['what', 'where', 'when', 'any', 'anyone know']
        has_question = any(indicator in full_text for indicator in question_indicators)
        
        return has_event_keyword or has_event_pattern or (has_question and 'event' in full_text)
    
    def extract_event_type(self, text):
        """Extract event type from text"""
        text_lower = text.lower()
        detected_types = []
        
        for event_type, keywords in self.event_type_indicators.items():
            score = sum(1 for keyword in keywords if keyword in text_lower)
            if score > 0:
                detected_types.append((event_type, score))
        
        # Return the type with highest score, or 'general' if none found
        if detected_types:
            return max(detected_types, key=lambda x: x[1])[0]
        return 'general'
    
    def extract_venue_mentions(self, text):
        """Extract venue names from text"""
        venues = []
        
        for pattern in self.venue_patterns:
            matches = re.findall(pattern, text, re.IGNORECASE)
            for match in matches:
                if isinstance(match, tuple):
                    match = match[0] if match[0] else match[1]
                
                venue = match.strip()
                if self.is_valid_venue_name(venue):
                    venues.append(venue)
        
        return list(set(venues))
    
    def is_valid_venue_name(self, name):
        """Check if extracted name is likely a valid venue name"""
        name_lower = name.lower()
        
        # Filter out common false positives
        false_positives = [
            'the', 'and', 'or', 'but', 'with', 'for', 'from', 'they', 'you', 'it',
            'this', 'that', 'there', 'here', 'what', 'where', 'when', 'how', 'why',
            'good', 'great', 'best', 'amazing', 'perfect', 'nice', 'event',
            'toronto', 'ontario', 'canada', 'downtown', 'uptown', 'midtown'
        ]
        
        if len(name) < 3 or len(name) > 50:
            return False
        
        if not name[0].isupper():
            return False
        
        if name_lower in false_positives:
            return False
        
        if not any(c.isalpha() for c in name):
            return False
        
        if name.isupper() and len(name) > 3:
            return False
        
        return True
    
    def extract_date_mentions(self, text):
        """Extract date/time mentions from text"""
        date_patterns = [
            r'(?:january|february|march|april|may|june|july|august|september|october|november|december)\s+\d{1,2}(?:st|nd|rd|th)?',
            r'\d{1,2}\/\d{1,2}(?:\/\d{2,4})?',
            r'(?:mon|tue|wed|thu|fri|sat|sun)day',
            r'(?:tonight|tomorrow|today|this weekend|next week|next weekend)',
            r'\d{1,2}:\d{2}\s*(?:am|pm)',
            r'\d{1,2}\s*(?:am|pm)',
        ]
        
        date_mentions = []
        for pattern in date_patterns:
            matches = re.findall(pattern, text, re.IGNORECASE)
            date_mentions.extend(matches)
        
        return date_mentions
    
    def analyze_event_sentiment(self, text):
        """Analyze sentiment of event post"""
        try:
            blob = TextBlob(text)
            return blob.sentiment.polarity
        except:
            return 0.0
    
    def analyze_event_buzz(self, post_data, comments_data):
        """Analyze how much buzz/interest an event is generating"""
        buzz_score = 0
        
        # Post engagement metrics
        buzz_score += min(post_data.get('score', 0) / 10, 50)  # Upvotes (max 50 points)
        buzz_score += min(post_data.get('num_comments', 0) * 2, 30)  # Comments (max 30 points)
        
        # Comment engagement
        if comments_data:
            avg_comment_score = sum(c.get('score', 0) for c in comments_data) / len(comments_data)
            buzz_score += min(avg_comment_score * 5, 20)  # Comment quality (max 20 points)
        
        return min(buzz_score, 100)
    
    def analyze_event_mood(self, title, text, event_type):
        """Analyze event mood/vibe"""
        full_text = (title + " " + text).lower()
        mood_tags = []
        
        # Mood indicators based on keywords
        mood_indicators = {
            'exciting': ['exciting', 'amazing', 'incredible', 'epic', 'awesome', 'fantastic'],
            'chill': ['chill', 'relaxed', 'casual', 'laid back', 'easy going', 'low key'],
            'romantic': ['romantic', 'intimate', 'date', 'couples', 'cozy', 'candlelit'],
            'family': ['family', 'kids', 'children', 'all ages', 'family friendly'],
            'underground': ['underground', 'hidden', 'secret', 'exclusive', 'invite only'],
            'mainstream': ['popular', 'famous', 'well known', 'big name', 'major'],
            'artistic': ['creative', 'artistic', 'avant garde', 'experimental', 'indie'],
            'social': ['social', 'networking', 'meet people', 'community', 'friendly']
        }
        
        for mood, keywords in mood_indicators.items():
            if any(keyword in full_text for keyword in keywords):
                mood_tags.append(mood.title())
        
        # Add event type as mood
        if event_type != 'general':
            mood_tags.append(event_type.title())
        
        # Time-based moods
        if any(time_word in full_text for time_word in ['night', 'evening', 'late']):
            mood_tags.append('Evening')
        if any(time_word in full_text for time_word in ['morning', 'brunch', 'early']):
            mood_tags.append('Morning')
        if any(time_word in full_text for time_word in ['weekend', 'saturday', 'sunday']):
            mood_tags.append('Weekend')
        
        # Price-based moods
        if any(price_word in full_text for price_word in ['free', 'no cost', 'gratis']):
            mood_tags.append('Free')
        if any(price_word in full_text for price_word in ['cheap', 'affordable', 'budget']):
            mood_tags.append('Budget')
        if any(price_word in full_text for price_word in ['expensive', 'premium', 'luxury']):
            mood_tags.append('Premium')
        
        return list(set(mood_tags)) if mood_tags else ['General']
    
    def collect_post_comments(self, submission, max_comments=20):
        """Collect comments from an event post"""
        comments_data = []
        
        try:
            submission.comments.replace_more(limit=5)
            all_comments = submission.comments.list()[:max_comments]
            
            for comment in all_comments:
                if isinstance(comment, MoreComments):
                    continue
                
                # Look for event-related information in comments
                venues = self.extract_venue_mentions(comment.body)
                dates = self.extract_date_mentions(comment.body)
                sentiment = self.analyze_event_sentiment(comment.body)
                
                comment_data = {
                    'comment_id': comment.id,
                    'post_id': submission.id,
                    'comment_body': comment.body,
                    'comment_score': comment.score,
                    'venues_mentioned': venues,
                    'dates_mentioned': dates,
                    'sentiment_score': sentiment,
                    'created_utc': datetime.fromtimestamp(comment.created_utc),
                    'author': str(comment.author) if comment.author else '[deleted]'
                }
                
                comments_data.append(comment_data)
        
        except Exception as e:
            print(f"Error processing comments for post {submission.id}: {e}")
        
        return comments_data
    
    def collect_subreddit_events(self, subreddit_name, limit=50, time_filter='week'):
        """Collect event posts from a specific subreddit"""
        print(f"Collecting events from r/{subreddit_name}...")
        
        try:
            subreddit = self.reddit.subreddit(subreddit_name)
            posts_data = []
            comments_data = []
            
            # Get posts from multiple sources
            posts_to_check = []
            
            # Hot posts
            posts_to_check.extend(list(subreddit.hot(limit=limit//3)))
            
            # New posts (for recent events)
            posts_to_check.extend(list(subreddit.new(limit=limit//3)))
            
            # Top posts from time period
            posts_to_check.extend(list(subreddit.top(time_filter=time_filter, limit=limit//3)))
            
            for post in tqdm(posts_to_check, desc=f"Processing r/{subreddit_name}", unit="post"):
                if self.is_event_post(post.title, post.selftext):
                    print(f"  ✅ Found event post: {post.title[:60]}...")
                    
                    # Extract event details
                    event_type = self.extract_event_type(post.title + " " + (post.selftext or ""))
                    venues = self.extract_venue_mentions(post.title + " " + (post.selftext or ""))
                    dates = self.extract_date_mentions(post.title + " " + (post.selftext or ""))
                    sentiment = self.analyze_event_sentiment(post.title + " " + (post.selftext or ""))
                    
                    # Collect post comments
                    post_comments = self.collect_post_comments(post)
                    
                    # Calculate buzz score
                    buzz_score = self.analyze_event_buzz(
                        {'score': post.score, 'num_comments': post.num_comments},
                        post_comments
                    )
                    
                    # Analyze mood
                    mood_tags = self.analyze_event_mood(
                        post.title, 
                        post.selftext or "", 
                        event_type
                    )
                    
                    post_data = {
                        'post_id': post.id,
                        'subreddit': subreddit_name,
                        'title': post.title,
                        'text': post.selftext or "",
                        'score': post.score,
                        'num_comments': post.num_comments,
                        'created_utc': datetime.fromtimestamp(post.created_utc),
                        'url': post.url,
                        'author': str(post.author) if post.author else '[deleted]',
                        'upvote_ratio': getattr(post, 'upvote_ratio', 0.5),
                        'event_type': event_type,
                        'venues_mentioned': venues,
                        'dates_mentioned': dates,
                        'sentiment_score': sentiment,
                        'buzz_score': buzz_score,
                        'mood_tags': mood_tags,
                        'is_event_post': True
                    }
                    
                    posts_data.append(post_data)
                    comments_data.extend(post_comments)
                    
                    # Rate limiting
                    time.sleep(1)
            
            print(f"  Found {len(posts_data)} event posts with {len(comments_data)} comments")
            return posts_data, comments_data
            
        except Exception as e:
            print(f"Error collecting from r/{subreddit_name}: {e}")
            return [], []
    
    def collect_all_events(self, limit_per_subreddit=30):
        """Collect events from all relevant Toronto subreddits"""
        
        all_posts = []
        all_comments = []
        
        print(f"🎭 Collecting events from {len(EVENT_SUBREDDITS)} Toronto subreddits...")
        
        for subreddit in tqdm(EVENT_SUBREDDITS, desc="Subreddits", unit="subreddit"):
            posts, comments = self.collect_subreddit_events(subreddit, limit_per_subreddit)
            all_posts.extend(posts)
            all_comments.extend(comments)
            
            # Rate limiting between subreddits
            time.sleep(2)
        
        print(f"🎉 Collection complete! Found {len(all_posts)} event posts with {len(all_comments)} comments")
        return all_posts, all_comments
    
    def save_events_data(self, posts, comments, timestamp=None):
        """Save collected events data to CSV files"""
        if timestamp is None:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        
        # Save posts
        if posts:
            posts_df = pd.DataFrame(posts)
            posts_filename = f"data/reddit_event_posts_{timestamp}.csv"
            posts_df.to_csv(posts_filename, index=False)
            print(f"Saved {len(posts)} event posts to {posts_filename}")
        
        # Save comments
        if comments:
            comments_df = pd.DataFrame(comments)
            comments_filename = f"data/reddit_event_comments_{timestamp}.csv"
            comments_df.to_csv(comments_filename, index=False)
            print(f"Saved {len(comments)} event comments to {comments_filename}")
        
        return posts_filename if posts else None, comments_filename if comments else None

if __name__ == "__main__":
    collector = RedditEventsCollector()
    
    print("🎭 Collecting event information from Reddit...")
    posts, comments = collector.collect_all_events(limit_per_subreddit=25)
    
    if posts or comments:
        # Save the data
        posts_file, comments_file = collector.save_events_data(posts, comments)
        
        # Show sample events
        if posts:
            print(f"\n🎉 Sample Events Found:")
            for i, post in enumerate(posts[:5], 1):
                print(f"{i}. {post['title']}")
                print(f"   🎭 Type: {post['event_type']}")
                print(f"   📍 Venues: {', '.join(post['venues_mentioned'][:2]) if post['venues_mentioned'] else 'N/A'}")
                print(f"   📅 Dates: {', '.join(post['dates_mentioned'][:2]) if post['dates_mentioned'] else 'N/A'}")
                print(f"   🎯 Buzz Score: {post['buzz_score']:.1f}")
                print(f"   🎨 Moods: {', '.join(post['mood_tags'])}")
                print(f"   👍 Score: {post['score']} ({post['num_comments']} comments)")
                print()
    else:
        print("No event data collected.") 