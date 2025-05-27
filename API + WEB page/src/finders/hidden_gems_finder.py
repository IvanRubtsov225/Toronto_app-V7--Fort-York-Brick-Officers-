import pandas as pd
import numpy as np
from datetime import datetime
from fuzzywuzzy import fuzz
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity
import re
from collections import defaultdict, Counter

from reddit_collector import RedditCollector
from dinesafe_analyzer import DineSafeAnalyzer
from config import SCORING_WEIGHTS

class HiddenGemsFinder:
    def __init__(self):
        """Initialize the Hidden Gems Finder"""
        self.reddit_collector = RedditCollector()
        self.dinesafe_analyzer = DineSafeAnalyzer()
        self.reddit_data = None
        self.dinesafe_scores = None
        self.combined_results = None
        
    def load_or_collect_reddit_data(self, use_existing=True, reddit_posts_file=None, reddit_comments_file=None):
        """Load existing Reddit data or collect new data"""
        if use_existing and reddit_posts_file and reddit_comments_file:
            try:
                posts_df = pd.read_csv(reddit_posts_file)
                comments_df = pd.read_csv(reddit_comments_file)
                self.reddit_data = {'posts': posts_df, 'comments': comments_df}
                print(f"Loaded existing Reddit data: {len(posts_df)} posts, {len(comments_df)} comments")
                return
            except Exception as e:
                print(f"Error loading existing data: {e}")
        
        # Collect new data
        print("Collecting new Reddit data...")
        posts, comments = self.reddit_collector.collect_all_data(limit_per_subreddit=100)
        
        if posts and comments:
            posts_df = pd.DataFrame(posts)
            comments_df = pd.DataFrame(comments)
            self.reddit_data = {'posts': posts_df, 'comments': comments_df}
            
            # Save the data
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            posts_file = f"reddit_posts_{timestamp}.csv"
            comments_file = f"reddit_comments_{timestamp}.csv"
            posts_df.to_csv(posts_file, index=False)
            comments_df.to_csv(comments_file, index=False)
            print(f"Collected and saved: {len(posts)} posts, {len(comments)} comments")
        else:
            print("No Reddit data collected")
            self.reddit_data = {'posts': pd.DataFrame(), 'comments': pd.DataFrame()}
    
    def extract_all_mentioned_locations(self):
        """Extract all locations mentioned in Reddit data"""
        all_locations = []
        
        if self.reddit_data is None:
            return []
        
        # Extract from posts
        for _, post in self.reddit_data['posts'].iterrows():
            if isinstance(post['locations_mentioned'], str):
                # Handle string representation of list
                locations = eval(post['locations_mentioned']) if post['locations_mentioned'].startswith('[') else [post['locations_mentioned']]
            else:
                locations = post['locations_mentioned'] if isinstance(post['locations_mentioned'], list) else []
            
            for location in locations:
                all_locations.append({
                    'name': location,
                    'source': 'post',
                    'post_id': post['post_id'],
                    'sentiment': post['sentiment_score'],
                    'score': post['score'],
                    'is_hidden_gem': post['is_hidden_gem'],
                    'subreddit': post['subreddit']
                })
        
        # Extract from comments
        for _, comment in self.reddit_data['comments'].iterrows():
            if isinstance(comment['locations_mentioned'], str):
                locations = eval(comment['locations_mentioned']) if comment['locations_mentioned'].startswith('[') else [comment['locations_mentioned']]
            else:
                locations = comment['locations_mentioned'] if isinstance(comment['locations_mentioned'], list) else []
            
            for location in locations:
                all_locations.append({
                    'name': location,
                    'source': 'comment',
                    'comment_id': comment['comment_id'],
                    'sentiment': comment['sentiment_score'],
                    'score': comment['score']
                })
        
        return all_locations
    
    def match_reddit_to_dinesafe(self, reddit_locations, similarity_threshold=70):
        """Match Reddit mentions to DineSafe establishments"""
        if not reddit_locations:
            return []
        
        # Get DineSafe establishment scores
        dinesafe_scores = self.dinesafe_analyzer.calculate_establishment_scores()
        
        matches = []
        
        for reddit_loc in reddit_locations:
            reddit_name = reddit_loc['name'].upper().strip()
            best_match = None
            best_score = 0
            
            for _, establishment in dinesafe_scores.iterrows():
                dinesafe_name = establishment['Establishment Name']
                
                # Calculate similarity using multiple methods
                ratio = fuzz.ratio(reddit_name, dinesafe_name)
                partial_ratio = fuzz.partial_ratio(reddit_name, dinesafe_name)
                token_sort_ratio = fuzz.token_sort_ratio(reddit_name, dinesafe_name)
                
                # Use the highest similarity score
                similarity = max(ratio, partial_ratio, token_sort_ratio)
                
                if similarity > best_score and similarity >= similarity_threshold:
                    best_score = similarity
                    best_match = establishment
            
            if best_match is not None:
                match = {
                    'reddit_name': reddit_loc['name'],
                    'dinesafe_name': best_match['Establishment Name'],
                    'establishment_id': best_match['Establishment ID'],
                    'similarity_score': best_score,
                    'reddit_data': reddit_loc,
                    'dinesafe_data': best_match
                }
                matches.append(match)
        
        return matches
    
    def calculate_reddit_scores(self, reddit_locations):
        """Calculate scores based on Reddit mentions and sentiment"""
        location_stats = defaultdict(lambda: {
            'mention_count': 0,
            'total_sentiment': 0,
            'total_score': 0,
            'hidden_gem_mentions': 0,
            'subreddits': set(),
            'sources': []
        })
        
        # Aggregate data by location name
        for loc in reddit_locations:
            name = loc['name'].upper().strip()
            stats = location_stats[name]
            
            stats['mention_count'] += 1
            stats['total_sentiment'] += loc['sentiment']
            stats['total_score'] += loc['score']
            stats['sources'].append(loc)
            
            if loc.get('is_hidden_gem', False):
                stats['hidden_gem_mentions'] += 1
            
            if 'subreddit' in loc:
                stats['subreddits'].add(loc['subreddit'])
        
        # Calculate final scores
        reddit_scores = {}
        for name, stats in location_stats.items():
            avg_sentiment = stats['total_sentiment'] / stats['mention_count']
            avg_score = stats['total_score'] / stats['mention_count']
            
            # Calculate Reddit score (0-100)
            reddit_score = (
                min(stats['mention_count'] * 10, 40) +  # Mention frequency (max 40)
                max(0, avg_sentiment * 30) +           # Sentiment (max 30)
                min(avg_score / 10, 20) +              # Reddit score (max 20)
                stats['hidden_gem_mentions'] * 10      # Hidden gem bonus (max varies)
            )
            
            reddit_scores[name] = {
                'reddit_score': min(reddit_score, 100),
                'mention_count': stats['mention_count'],
                'avg_sentiment': avg_sentiment,
                'avg_reddit_score': avg_score,
                'hidden_gem_mentions': stats['hidden_gem_mentions'],
                'subreddit_diversity': len(stats['subreddits']),
                'sources': stats['sources']
            }
        
        return reddit_scores
    
    def calculate_uniqueness_score(self, establishment_type, mention_count):
        """Calculate uniqueness score based on establishment type and mentions"""
        # Common establishment types get lower uniqueness scores
        common_types = ['Restaurant', 'Take Out', 'Mobile Vendor']
        unique_types = ['Bakery', 'Specialty Food Store', 'Catering', 'Food Depot']
        
        base_score = 50
        
        if any(common in establishment_type for common in common_types):
            base_score = 30
        elif any(unique in establishment_type for unique in unique_types):
            base_score = 70
        
        # Lower mention count = higher uniqueness (hidden gems are less known)
        mention_penalty = min(mention_count * 5, 30)
        uniqueness_score = max(0, base_score - mention_penalty)
        
        return uniqueness_score
    
    def find_hidden_gems(self, min_dinesafe_score=70, min_reddit_mentions=1, max_reddit_mentions=10):
        """Find hidden gems by combining Reddit and DineSafe data"""
        print("Finding hidden gems...")
        
        # Extract Reddit locations
        reddit_locations = self.extract_all_mentioned_locations()
        print(f"Found {len(reddit_locations)} location mentions in Reddit data")
        
        # Calculate Reddit scores
        reddit_scores = self.calculate_reddit_scores(reddit_locations)
        print(f"Calculated scores for {len(reddit_scores)} unique locations")
        
        # Match Reddit mentions to DineSafe data
        matches = self.match_reddit_to_dinesafe(reddit_locations)
        print(f"Matched {len(matches)} Reddit mentions to DineSafe establishments")
        
        # Calculate combined scores
        hidden_gems = []
        
        for match in matches:
            reddit_name = match['reddit_name']
            reddit_data = reddit_scores.get(reddit_name.upper().strip(), {})
            dinesafe_data = match['dinesafe_data']
            
            # Filter based on criteria
            mention_count = reddit_data.get('mention_count', 0)
            dinesafe_score = dinesafe_data['quality_score']
            
            if (mention_count >= min_reddit_mentions and 
                mention_count <= max_reddit_mentions and
                dinesafe_score >= min_dinesafe_score):
                
                # Calculate uniqueness score
                uniqueness_score = self.calculate_uniqueness_score(
                    dinesafe_data['establishment_type'], mention_count
                )
                
                # Calculate final hidden gem score
                final_score = (
                    reddit_data.get('reddit_score', 0) * SCORING_WEIGHTS['reddit_mentions'] +
                    (reddit_data.get('avg_sentiment', 0) + 1) * 50 * SCORING_WEIGHTS['sentiment_score'] +
                    dinesafe_score * SCORING_WEIGHTS['dinesafe_score'] +
                    uniqueness_score * SCORING_WEIGHTS['uniqueness_score']
                )
                
                hidden_gem = {
                    'name': dinesafe_data['Establishment Name'],
                    'address': dinesafe_data['Establishment Address'],
                    'type': dinesafe_data['establishment_type'],
                    'latitude': dinesafe_data['Latitude'],
                    'longitude': dinesafe_data['Longitude'],
                    'hidden_gem_score': round(final_score, 2),
                    'dinesafe_score': round(dinesafe_score, 2),
                    'reddit_score': round(reddit_data.get('reddit_score', 0), 2),
                    'uniqueness_score': round(uniqueness_score, 2),
                    'mention_count': mention_count,
                    'avg_sentiment': round(reddit_data.get('avg_sentiment', 0), 3),
                    'hidden_gem_mentions': reddit_data.get('hidden_gem_mentions', 0),
                    'subreddit_diversity': reddit_data.get('subreddit_diversity', 0),
                    'similarity_score': match['similarity_score'],
                    'establishment_id': dinesafe_data['Establishment ID']
                }
                
                hidden_gems.append(hidden_gem)
        
        # Sort by hidden gem score
        hidden_gems.sort(key=lambda x: x['hidden_gem_score'], reverse=True)
        
        self.combined_results = hidden_gems
        return hidden_gems
    
    def get_top_hidden_gems(self, limit=20, establishment_type=None):
        """Get top hidden gems with optional filtering"""
        if self.combined_results is None:
            self.find_hidden_gems()
        
        results = self.combined_results
        
        if establishment_type:
            results = [gem for gem in results if establishment_type.lower() in gem['type'].lower()]
        
        return results[:limit]
    
    def export_results(self, filename=None):
        """Export hidden gems results to CSV"""
        if self.combined_results is None:
            print("No results to export. Run find_hidden_gems() first.")
            return
        
        if filename is None:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            filename = f"toronto_hidden_gems_{timestamp}.csv"
        
        df = pd.DataFrame(self.combined_results)
        df.to_csv(filename, index=False)
        print(f"Exported {len(self.combined_results)} hidden gems to {filename}")
        
        return filename
    
    def get_gem_details(self, establishment_id):
        """Get detailed information about a specific hidden gem"""
        # Get DineSafe details
        dinesafe_details = self.dinesafe_analyzer.get_establishment_details(establishment_id)
        
        # Find Reddit mentions
        reddit_mentions = []
        reddit_locations = self.extract_all_mentioned_locations()
        
        for loc in reddit_locations:
            # This is a simplified match - in practice, you'd want to store the mapping
            if any(gem['establishment_id'] == establishment_id for gem in self.combined_results or []):
                reddit_mentions.append(loc)
        
        return {
            'dinesafe_details': dinesafe_details,
            'reddit_mentions': reddit_mentions
        }

if __name__ == "__main__":
    # Example usage
    finder = HiddenGemsFinder()
    
    # Load or collect Reddit data
    finder.load_or_collect_reddit_data(use_existing=False)
    
    # Find hidden gems
    hidden_gems = finder.find_hidden_gems(
        min_dinesafe_score=75,
        min_reddit_mentions=2,
        max_reddit_mentions=8
    )
    
    # Display top results
    print(f"\nFound {len(hidden_gems)} hidden gems!")
    print("\nTop 10 Hidden Gems:")
    for i, gem in enumerate(hidden_gems[:10], 1):
        print(f"{i}. {gem['name']}")
        print(f"   Address: {gem['address']}")
        print(f"   Type: {gem['type']}")
        print(f"   Hidden Gem Score: {gem['hidden_gem_score']}")
        print(f"   Reddit Mentions: {gem['mention_count']}")
        print(f"   DineSafe Score: {gem['dinesafe_score']}")
        print()
    
    # Export results
    finder.export_results() 