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

class RedditRecommendationCollector:
    def __init__(self):
        """Initialize Reddit API connection for recommendation collection"""
        self.reddit = praw.Reddit(
            client_id=REDDIT_CLIENT_ID,
            client_secret=REDDIT_CLIENT_SECRET,
            user_agent=REDDIT_USER_AGENT
        )
        
        # Keywords that indicate recommendation requests
        self.recommendation_keywords = [
            'best', 'recommend', 'suggestion', 'where to', 'where can i', 'where do you',
            'looking for', 'need help finding', 'any good', 'favorite', 'favourites',
            'top', 'must try', 'hidden gem', 'underrated', 'worth it',
            'good place', 'great place', 'amazing', 'excellent',
            'what are some', 'anyone know', 'help me find', 'suggestions',
            'recommendations', 'advice', 'opinions', 'thoughts'
        ]
        
        # Food-specific recommendation patterns
        self.food_recommendation_patterns = [
            r'best\s+(?:place|spot|restaurant|cafe|bar|pub|bakery|deli)\s+for',
            r'where\s+(?:to|can\s+i)\s+(?:get|find|eat)',
            r'(?:recommend|suggestion).*(?:restaurant|food|eat|dining)',
            r'looking\s+for.*(?:restaurant|food|place\s+to\s+eat)',
            r'good\s+(?:restaurant|food|place).*(?:in|near|around)',
            r'favorite.*(?:restaurant|spot|place)',
            r'hidden\s+gem.*(?:restaurant|food|eating)',
            r'underrated.*(?:restaurant|food|place)',
            r'best.*(?:korean|chinese|italian|indian|thai|japanese|mexican|pizza|burger|sushi|bbq|hotpot|ramen|pho|dim\s+sum|shawarma|falafel|tacos|wings|steak|seafood|brunch|breakfast|lunch|dinner|coffee|dessert|ice\s+cream|bakery|deli)'
        ]
        
        # Enhanced location extraction patterns
        self.location_patterns = [
            # Direct mentions with context (improved)
            r'(?:try|go\s+to|check\s+out|recommend|visit)\s+([A-Z][a-zA-Z\s&\'-]{3,35})(?:\s+(?:on|at|in|near|for|they|you|it|\.|!|\?|,))',
            r'([A-Z][a-zA-Z\s&\'-]{3,35})\s+(?:is|has|serves|makes|does)\s+(?:amazing|great|excellent|good|the\s+best|fantastic|incredible)',
            r'(?:at|@)\s+([A-Z][a-zA-Z\s&\'-]{3,35})(?:\s+(?:they|you|it|for|on|in|\.|!|\?|,))',
            
            # Restaurant names with descriptors (improved)
            r'([A-Z][a-zA-Z\s&\'-]{3,35})\s+(?:restaurant|cafe|bar|pub|bistro|eatery|kitchen|grill|house)',
            r'(?:restaurant|cafe|bar|pub|bistro|eatery|kitchen|grill|house)\s+(?:called|named)\s+([A-Z][a-zA-Z\s&\'-]{3,35})',
            
            # Location with address indicators (improved)
            r'([A-Z][a-zA-Z\s&\'-]{3,35})\s+(?:on|at)\s+(?:[A-Z][a-zA-Z\s]+(?:street|st|avenue|ave|road|rd|blvd|boulevard|drive|dr))',
            
            # Quoted or emphasized names
            r'"([A-Z][a-zA-Z\s&\'-]{3,35})"',
            r'\*([A-Z][a-zA-Z\s&\'-]{3,35})\*',
            
            # Names followed by location indicators
            r'([A-Z][a-zA-Z\s&\'-]{3,35})\s+(?:in|near|around|downtown|uptown|midtown)',
            
            # Simple capitalized names (more conservative)
            r'\b([A-Z][a-zA-Z]{2,}\s+[A-Z][a-zA-Z]{2,}(?:\s+[A-Z][a-zA-Z]{2,})?)\b',
            
            # Names with common restaurant words
            r'\b([A-Z][a-zA-Z\s&\'-]{3,35}(?:\s+(?:Restaurant|Cafe|Bar|Pub|Bistro|Kitchen|Grill|House|Eatery|Deli|Bakery)))\b',
        ]
    
    def is_recommendation_post(self, title, text=""):
        """Check if a post is asking for recommendations"""
        full_text = (title + " " + text).lower()
        
        # Check for question indicators
        has_question = any(indicator in full_text for indicator in ['?', 'where', 'what', 'which', 'how', 'any'])
        
        # Check for recommendation keywords
        has_rec_keyword = any(keyword in full_text for keyword in self.recommendation_keywords)
        
        # Check for food-specific patterns
        has_food_pattern = any(re.search(pattern, full_text, re.IGNORECASE) for pattern in self.food_recommendation_patterns)
        
        return has_question and (has_rec_keyword or has_food_pattern)
    
    def extract_restaurant_names(self, text):
        """Extract restaurant names from text using enhanced patterns"""
        restaurants = []
        
        for pattern in self.location_patterns:
            matches = re.findall(pattern, text, re.IGNORECASE)
            for match in matches:
                if isinstance(match, tuple):
                    match = match[0] if match[0] else match[1]
                
                # Clean up the match
                restaurant = match.strip()
                
                # Filter out common false positives
                if self.is_valid_restaurant_name(restaurant):
                    restaurants.append(restaurant)
        
        return list(set(restaurants))  # Remove duplicates
    
    def is_valid_restaurant_name(self, name):
        """Check if extracted name is likely a valid restaurant name"""
        name_lower = name.lower()
        
        # Filter out common false positives
        false_positives = [
            'the', 'and', 'or', 'but', 'with', 'for', 'from', 'they', 'you', 'it',
            'this', 'that', 'there', 'here', 'what', 'where', 'when', 'how', 'why',
            'good', 'great', 'best', 'amazing', 'excellent', 'perfect', 'nice',
            'toronto', 'ontario', 'canada', 'downtown', 'uptown', 'midtown',
            'north', 'south', 'east', 'west', 'street', 'avenue', 'road',
            'place', 'spot', 'location', 'area', 'neighborhood', 'district'
        ]
        
        # Must be reasonable length
        if len(name) < 3 or len(name) > 50:
            return False
        
        # Must start with capital letter
        if not name[0].isupper():
            return False
        
        # Must not be a common false positive
        if name_lower in false_positives:
            return False
        
        # Must contain at least one letter
        if not any(c.isalpha() for c in name):
            return False
        
        # Must not be all caps (likely acronym or shouting)
        if name.isupper() and len(name) > 3:
            return False
        
        return True
    
    def analyze_sentiment(self, text):
        """Analyze sentiment of the text"""
        try:
            blob = TextBlob(text)
            return blob.sentiment.polarity
        except:
            return 0.0
    
    def extract_quality_indicators(self, text):
        """Extract quality indicators from text"""
        text_lower = text.lower()
        
        positive_indicators = [
            'amazing', 'excellent', 'outstanding', 'incredible', 'fantastic',
            'perfect', 'love', 'favorite', 'best', 'great', 'awesome',
            'delicious', 'tasty', 'fresh', 'authentic', 'hidden gem',
            'must try', 'highly recommend', 'worth it', 'go-to place'
        ]
        
        negative_indicators = [
            'terrible', 'awful', 'horrible', 'disgusting', 'overpriced',
            'disappointing', 'worst', 'avoid', 'not worth it', 'overrated',
            'bland', 'cold', 'stale', 'rude', 'slow service'
        ]
        
        positive_count = sum(1 for indicator in positive_indicators if indicator in text_lower)
        negative_count = sum(1 for indicator in negative_indicators if indicator in text_lower)
        
        return {
            'positive_indicators': positive_count,
            'negative_indicators': negative_count,
            'quality_score': positive_count - negative_count
        }
    
    def collect_post_comments(self, submission):
        """Collect and analyze comments from a recommendation post"""
        comments_data = []
        
        try:
            # Replace MoreComments to get all comments
            submission.comments.replace_more(limit=10)  # Limit to avoid too many API calls
            
            # Get all comments as a flat list
            all_comments = submission.comments.list()
            
            for comment in all_comments:
                if isinstance(comment, MoreComments):
                    continue
                
                # Extract restaurant names from comment
                restaurants = self.extract_restaurant_names(comment.body)
                
                if restaurants:  # Only process comments with restaurant mentions
                    sentiment = self.analyze_sentiment(comment.body)
                    quality_indicators = self.extract_quality_indicators(comment.body)
                    
                    comment_data = {
                        'comment_id': comment.id,
                        'post_id': submission.id,
                        'post_title': submission.title,
                        'subreddit': submission.subreddit.display_name,
                        'comment_body': comment.body,
                        'comment_score': comment.score,
                        'restaurants_mentioned': restaurants,
                        'sentiment_score': sentiment,
                        'positive_indicators': quality_indicators['positive_indicators'],
                        'negative_indicators': quality_indicators['negative_indicators'],
                        'quality_score': quality_indicators['quality_score'],
                        'created_utc': datetime.fromtimestamp(comment.created_utc),
                        'author': str(comment.author) if comment.author else '[deleted]',
                        'is_recommendation': True
                    }
                    
                    comments_data.append(comment_data)
        
        except Exception as e:
            print(f"Error processing comments for post {submission.id}: {e}")
        
        return comments_data
    
    def collect_subreddit_recommendations(self, subreddit_name, limit=50, time_filter='month'):
        """Collect recommendation posts and their comments from a subreddit"""
        print(f"Collecting recommendations from r/{subreddit_name}...")
        
        try:
            subreddit = self.reddit.subreddit(subreddit_name)
            posts_data = []
            comments_data = []
            
            # Search through hot and top posts
            posts_to_check = []
            
            # Get hot posts
            posts_to_check.extend(list(subreddit.hot(limit=limit//2)))
            
            # Get top posts from time period
            posts_to_check.extend(list(subreddit.top(time_filter=time_filter, limit=limit//2)))
            
            for post in tqdm(posts_to_check, desc=f"Processing r/{subreddit_name}", unit="post"):
                # Check if this is a recommendation post
                if self.is_recommendation_post(post.title, post.selftext):
                    print(f"  ✅ Found recommendation post: {post.title[:60]}...")
                    
                    # Collect post data
                    post_data = {
                        'post_id': post.id,
                        'subreddit': subreddit_name,
                        'title': post.title,
                        'text': post.selftext,
                        'score': post.score,
                        'num_comments': post.num_comments,
                        'created_utc': datetime.fromtimestamp(post.created_utc),
                        'url': post.url,
                        'author': str(post.author) if post.author else '[deleted]',
                        'upvote_ratio': getattr(post, 'upvote_ratio', 0.5),
                        'is_recommendation_request': True
                    }
                    posts_data.append(post_data)
                    
                    # Collect comments from this post
                    post_comments = self.collect_post_comments(post)
                    comments_data.extend(post_comments)
                    
                    # Rate limiting
                    time.sleep(2)  # Be respectful to Reddit's API
            
            print(f"  Found {len(posts_data)} recommendation posts with {len(comments_data)} relevant comments")
            return posts_data, comments_data
            
        except Exception as e:
            print(f"Error collecting from r/{subreddit_name}: {e}")
            return [], []
    
    def collect_all_recommendations(self, limit_per_subreddit=30):
        """Collect recommendations from all Toronto food subreddits"""
        # Focus on food-specific subreddits for better results
        food_subreddits = [
            'FoodToronto',
            'askTO',
            'toronto',
            'TorontoEats',
            'TorontoEvents'
        ]
        
        all_posts = []
        all_comments = []
        
        print(f"🍽️ Collecting recommendations from {len(food_subreddits)} Toronto subreddits...")
        
        for subreddit in tqdm(food_subreddits, desc="Subreddits", unit="subreddit"):
            posts, comments = self.collect_subreddit_recommendations(subreddit, limit_per_subreddit)
            all_posts.extend(posts)
            all_comments.extend(comments)
            
            # Rate limiting between subreddits
            time.sleep(3)
        
        print(f"🎉 Collection complete! Found {len(all_posts)} recommendation posts with {len(all_comments)} relevant comments")
        return all_posts, all_comments
    
    def save_recommendation_data(self, posts, comments, timestamp=None):
        """Save collected recommendation data to CSV files"""
        if timestamp is None:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        
        # Save posts
        if posts:
            posts_df = pd.DataFrame(posts)
            posts_filename = f"data/reddit_recommendation_posts_{timestamp}.csv"
            posts_df.to_csv(posts_filename, index=False)
            print(f"Saved {len(posts)} recommendation posts to {posts_filename}")
        
        # Save comments
        if comments:
            comments_df = pd.DataFrame(comments)
            comments_filename = f"data/reddit_recommendation_comments_{timestamp}.csv"
            comments_df.to_csv(comments_filename, index=False)
            print(f"Saved {len(comments)} recommendation comments to {comments_filename}")
        
        return posts_filename if posts else None, comments_filename if comments else None
    
    def analyze_recommendations(self, comments_data):
        """Analyze the collected recommendations to find patterns"""
        if not comments_data:
            return {}
        
        # Flatten restaurant mentions
        all_restaurants = []
        for comment in comments_data:
            for restaurant in comment['restaurants_mentioned']:
                all_restaurants.append({
                    'name': restaurant,
                    'sentiment': comment['sentiment_score'],
                    'quality_score': comment['quality_score'],
                    'comment_score': comment['comment_score'],
                    'subreddit': comment['subreddit']
                })
        
        # Aggregate by restaurant name
        restaurant_stats = {}
        for restaurant in all_restaurants:
            name = restaurant['name'].upper().strip()
            if name not in restaurant_stats:
                restaurant_stats[name] = {
                    'mention_count': 0,
                    'total_sentiment': 0,
                    'total_quality': 0,
                    'total_comment_score': 0,
                    'subreddits': set()
                }
            
            stats = restaurant_stats[name]
            stats['mention_count'] += 1
            stats['total_sentiment'] += restaurant['sentiment']
            stats['total_quality'] += restaurant['quality_score']
            stats['total_comment_score'] += restaurant['comment_score']
            stats['subreddits'].add(restaurant['subreddit'])
        
        # Calculate averages and scores
        for name, stats in restaurant_stats.items():
            stats['avg_sentiment'] = stats['total_sentiment'] / stats['mention_count']
            stats['avg_quality'] = stats['total_quality'] / stats['mention_count']
            stats['avg_comment_score'] = stats['total_comment_score'] / stats['mention_count']
            stats['subreddit_diversity'] = len(stats['subreddits'])
            
            # Calculate recommendation score
            stats['recommendation_score'] = (
                stats['mention_count'] * 10 +
                max(0, stats['avg_sentiment']) * 30 +
                max(0, stats['avg_quality']) * 20 +
                stats['avg_comment_score'] / 10 +
                stats['subreddit_diversity'] * 5
            )
        
        return restaurant_stats

if __name__ == "__main__":
    collector = RedditRecommendationCollector()
    
    print("🍽️ Collecting restaurant recommendations from Reddit...")
    posts, comments = collector.collect_all_recommendations(limit_per_subreddit=20)
    
    if posts or comments:
        # Save the data
        posts_file, comments_file = collector.save_recommendation_data(posts, comments)
        
        # Analyze recommendations
        if comments:
            print("\n📊 Analyzing recommendations...")
            restaurant_stats = collector.analyze_recommendations(comments)
            
            # Show top recommendations
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
                print(f"    Quality Score: {stats['avg_quality']:.1f}")
                print(f"    Recommendation Score: {stats['recommendation_score']:.1f}")
                print()
    else:
        print("No recommendation data collected.") 