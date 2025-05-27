import praw
import pandas as pd
import re
from datetime import datetime, timedelta
from textblob import TextBlob
import time
from config import *

class RedditCollector:
    def __init__(self):
        """Initialize Reddit API connection"""
        self.reddit = praw.Reddit(
            client_id=REDDIT_CLIENT_ID,
            client_secret=REDDIT_CLIENT_SECRET,
            username=REDDIT_USERNAME,
            password=REDDIT_PASSWORD,
            user_agent=REDDIT_USER_AGENT
        )
        
    def extract_location_mentions(self, text):
        """Extract potential restaurant/location names from text"""
        # Common patterns for restaurant mentions
        patterns = [
            r'(?:at|@)\s+([A-Z][a-zA-Z\s&\'-]+?)(?:\s+(?:on|in|near|at)\s+)',
            r'([A-Z][a-zA-Z\s&\'-]+?)\s+(?:restaurant|cafe|bar|pub|bistro)',
            r'(?:restaurant|cafe|bar|pub|bistro)\s+([A-Z][a-zA-Z\s&\'-]+)',
            r'([A-Z][a-zA-Z\s&\'-]{3,})\s+(?:is|has|serves|makes)',
        ]
        
        locations = []
        for pattern in patterns:
            matches = re.findall(pattern, text, re.IGNORECASE)
            locations.extend(matches)
        
        # Clean up extracted locations
        cleaned_locations = []
        for loc in locations:
            loc = loc.strip()
            if len(loc) > 3 and len(loc) < 50:  # Reasonable length
                cleaned_locations.append(loc)
        
        return list(set(cleaned_locations))
    
    def analyze_sentiment(self, text):
        """Analyze sentiment of the text"""
        blob = TextBlob(text)
        return blob.sentiment.polarity
    
    def contains_hidden_gem_keywords(self, text):
        """Check if text contains hidden gem related keywords"""
        text_lower = text.lower()
        return any(keyword in text_lower for keyword in HIDDEN_GEM_KEYWORDS)
    
    def contains_food_keywords(self, text):
        """Check if text contains food-related keywords"""
        text_lower = text.lower()
        return any(keyword in text_lower for keyword in FOOD_KEYWORDS)
    
    def collect_subreddit_data(self, subreddit_name, limit=100, time_filter='month'):
        """Collect data from a specific subreddit"""
        print(f"Collecting data from r/{subreddit_name}...")
        
        try:
            subreddit = self.reddit.subreddit(subreddit_name)
            posts_data = []
            
            # Get hot posts
            for post in subreddit.hot(limit=limit//2):
                if self.contains_food_keywords(post.title + " " + post.selftext):
                    post_data = self.process_post(post, subreddit_name)
                    if post_data:
                        posts_data.append(post_data)
            
            # Get top posts from the specified time period
            for post in subreddit.top(time_filter=time_filter, limit=limit//2):
                if self.contains_food_keywords(post.title + " " + post.selftext):
                    post_data = self.process_post(post, subreddit_name)
                    if post_data:
                        posts_data.append(post_data)
            
            return posts_data
            
        except Exception as e:
            print(f"Error collecting from r/{subreddit_name}: {e}")
            return []
    
    def process_post(self, post, subreddit_name):
        """Process individual post and extract relevant information"""
        full_text = post.title + " " + post.selftext
        
        # Extract locations mentioned
        locations = self.extract_location_mentions(full_text)
        
        # Analyze sentiment
        sentiment = self.analyze_sentiment(full_text)
        
        # Check for hidden gem indicators
        is_hidden_gem = self.contains_hidden_gem_keywords(full_text)
        
        if locations or is_hidden_gem:
            return {
                'post_id': post.id,
                'subreddit': subreddit_name,
                'title': post.title,
                'text': post.selftext,
                'score': post.score,
                'num_comments': post.num_comments,
                'created_utc': datetime.fromtimestamp(post.created_utc),
                'url': post.url,
                'locations_mentioned': locations,
                'sentiment_score': sentiment,
                'is_hidden_gem': is_hidden_gem,
                'upvote_ratio': post.upvote_ratio
            }
        
        return None
    
    def collect_comments(self, post_id, max_comments=50):
        """Collect comments from a specific post"""
        try:
            submission = self.reddit.submission(id=post_id)
            submission.comments.replace_more(limit=0)
            
            comments_data = []
            for comment in submission.comments.list()[:max_comments]:
                if hasattr(comment, 'body') and self.contains_food_keywords(comment.body):
                    locations = self.extract_location_mentions(comment.body)
                    sentiment = self.analyze_sentiment(comment.body)
                    
                    if locations:
                        comments_data.append({
                            'comment_id': comment.id,
                            'post_id': post_id,
                            'body': comment.body,
                            'score': comment.score,
                            'created_utc': datetime.fromtimestamp(comment.created_utc),
                            'locations_mentioned': locations,
                            'sentiment_score': sentiment
                        })
            
            return comments_data
            
        except Exception as e:
            print(f"Error collecting comments for post {post_id}: {e}")
            return []
    
    def collect_all_data(self, limit_per_subreddit=100):
        """Collect data from all Toronto subreddits"""
        all_posts = []
        all_comments = []
        
        for subreddit in TORONTO_SUBREDDITS:
            posts = self.collect_subreddit_data(subreddit, limit_per_subreddit)
            all_posts.extend(posts)
            
            # Collect comments for posts that mention locations
            for post in posts:
                if post['locations_mentioned']:
                    comments = self.collect_comments(post['post_id'])
                    all_comments.extend(comments)
            
            # Rate limiting
            time.sleep(1)
        
        return all_posts, all_comments
    
    def save_data(self, posts, comments, timestamp=None):
        """Save collected data to CSV files"""
        if timestamp is None:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        
        # Save posts
        posts_df = pd.DataFrame(posts)
        posts_filename = f"reddit_posts_{timestamp}.csv"
        posts_df.to_csv(posts_filename, index=False)
        print(f"Saved {len(posts)} posts to {posts_filename}")
        
        # Save comments
        comments_df = pd.DataFrame(comments)
        comments_filename = f"reddit_comments_{timestamp}.csv"
        comments_df.to_csv(comments_filename, index=False)
        print(f"Saved {len(comments)} comments to {comments_filename}")
        
        return posts_filename, comments_filename

if __name__ == "__main__":
    collector = RedditCollector()
    posts, comments = collector.collect_all_data(limit_per_subreddit=50)
    collector.save_data(posts, comments) 