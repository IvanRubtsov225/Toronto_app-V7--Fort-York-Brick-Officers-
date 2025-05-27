import pandas as pd
import numpy as np
from datetime import datetime
from fuzzywuzzy import fuzz
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity
import re
from collections import defaultdict, Counter
from tqdm import tqdm

import sys
import os
sys.path.append(os.path.join(os.path.dirname(__file__), '..', '..'))

from src.collectors.reddit_collector_recommendations import RedditRecommendationCollector
from src.analyzers.dinesafe_analyzer import DineSafeAnalyzer
from config.config import SCORING_WEIGHTS

class HiddenGemsFinderRecommendations:
    def __init__(self):
        """Initialize the Enhanced Hidden Gems Finder with recommendation focus"""
        self.reddit_collector = RedditRecommendationCollector()
        self.dinesafe_analyzer = DineSafeAnalyzer()
        self.recommendation_data = None
        self.dinesafe_scores = None
        self.combined_results = None
        
    def load_or_collect_recommendation_data(self, use_existing=True, posts_file=None, comments_file=None):
        """Load existing recommendation data or collect new data"""
        if use_existing and posts_file and comments_file:
            try:
                posts_df = pd.read_csv(posts_file)
                comments_df = pd.read_csv(comments_file)
                self.recommendation_data = {'posts': posts_df, 'comments': comments_df}
                print(f"Loaded existing recommendation data: {len(posts_df)} posts, {len(comments_df)} comments")
                return
            except Exception as e:
                print(f"Error loading existing data: {e}")
        
        # Collect new recommendation data
        print("Collecting new recommendation data from Reddit...")
        posts, comments = self.reddit_collector.collect_all_recommendations(limit_per_subreddit=25)
        
        if posts or comments:
            posts_df = pd.DataFrame(posts) if posts else pd.DataFrame()
            comments_df = pd.DataFrame(comments) if comments else pd.DataFrame()
            self.recommendation_data = {'posts': posts_df, 'comments': comments_df}
            
            # Save the data
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            posts_file, comments_file = self.reddit_collector.save_recommendation_data(posts, comments, timestamp)
            print(f"Collected and saved: {len(posts)} recommendation posts, {len(comments)} recommendation comments")
        else:
            print("No recommendation data collected")
            self.recommendation_data = {'posts': pd.DataFrame(), 'comments': pd.DataFrame()}
    
    def extract_restaurant_recommendations(self):
        """Extract restaurant recommendations from the collected data"""
        recommendations = []
        
        if self.recommendation_data is None or self.recommendation_data['comments'].empty:
            return []
        
        # Process each comment with restaurant mentions
        for _, comment in self.recommendation_data['comments'].iterrows():
            if isinstance(comment['restaurants_mentioned'], str):
                # Handle string representation of list
                try:
                    restaurants = eval(comment['restaurants_mentioned']) if comment['restaurants_mentioned'].startswith('[') else [comment['restaurants_mentioned']]
                except:
                    restaurants = [comment['restaurants_mentioned']] if comment['restaurants_mentioned'] else []
            else:
                restaurants = comment['restaurants_mentioned'] if isinstance(comment['restaurants_mentioned'], list) else []
            
            for restaurant in restaurants:
                if restaurant and len(str(restaurant).strip()) > 0:
                    recommendations.append({
                        'name': str(restaurant),
                        'source': 'recommendation_comment',
                        'comment_id': comment['comment_id'],
                        'post_id': comment['post_id'],
                        'post_title': comment['post_title'],
                        'sentiment': comment['sentiment_score'],
                        'quality_score': comment['quality_score'],
                        'comment_score': comment['comment_score'],
                        'positive_indicators': comment['positive_indicators'],
                        'negative_indicators': comment['negative_indicators'],
                        'subreddit': comment['subreddit'],
                        'is_recommendation': True,
                        'created_utc': comment['created_utc']
                    })
        
        return recommendations
    
    def match_recommendations_to_dinesafe(self, recommendations, similarity_threshold=70):
        """Match Reddit recommendations to DineSafe establishments"""
        if not recommendations:
            return []
        
        # Get DineSafe establishment scores
        print("🔗 Loading DineSafe establishment data...")
        dinesafe_scores = self.dinesafe_analyzer.calculate_establishment_scores()
        
        # Create a lookup dictionary for faster matching
        print("🚀 Optimizing establishment lookup...")
        establishment_names = dinesafe_scores['Establishment Name'].tolist()
        
        matches = []
        
        print(f"🔍 Matching {len(recommendations)} recommendations to {len(establishment_names)} DineSafe establishments...")
        
        # Use tqdm for progress bar
        for rec in tqdm(recommendations, desc="🍽️ Matching restaurants", unit="restaurant", colour="green"):
            reddit_name = rec['name'].upper().strip()
            best_match = None
            best_score = 0
            
            # Quick pre-filter: only check establishments that share at least one word
            reddit_words = set(reddit_name.split())
            candidate_establishments = []
            
            for idx, establishment in dinesafe_scores.iterrows():
                dinesafe_name = establishment['Establishment Name']
                dinesafe_words = set(dinesafe_name.split())
                
                # If they share at least one word (case-insensitive), consider it
                if reddit_words.intersection(dinesafe_words):
                    candidate_establishments.append((idx, establishment))
            
            # If no word overlap, fall back to checking all (for partial matches)
            if not candidate_establishments:
                candidate_establishments = [(idx, establishment) for idx, establishment in dinesafe_scores.iterrows()]
            
            # Only check top 100 candidates to speed up
            candidate_establishments = candidate_establishments[:100]
            
            for idx, establishment in candidate_establishments:
                dinesafe_name = establishment['Establishment Name']
                
                # Quick ratio check first (fastest)
                quick_ratio = fuzz.ratio(reddit_name, dinesafe_name)
                if quick_ratio < similarity_threshold - 20:  # Skip if too low
                    continue
                
                # Calculate similarity using multiple methods
                partial_ratio = fuzz.partial_ratio(reddit_name, dinesafe_name)
                token_sort_ratio = fuzz.token_sort_ratio(reddit_name, dinesafe_name)
                token_set_ratio = fuzz.token_set_ratio(reddit_name, dinesafe_name)
                
                # Use the highest similarity score
                similarity = max(quick_ratio, partial_ratio, token_sort_ratio, token_set_ratio)
                
                if similarity > best_score and similarity >= similarity_threshold:
                    best_score = similarity
                    best_match = establishment
            
            if best_match is not None:
                match = {
                    'reddit_name': rec['name'],
                    'dinesafe_name': best_match['Establishment Name'],
                    'establishment_id': best_match['Establishment ID'],
                    'similarity_score': best_score,
                    'recommendation_data': rec,
                    'dinesafe_data': best_match
                }
                matches.append(match)
        
        return matches
    
    def calculate_recommendation_scores(self, recommendations):
        """Calculate scores based on Reddit recommendations"""
        restaurant_stats = defaultdict(lambda: {
            'mention_count': 0,
            'total_sentiment': 0,
            'total_quality': 0,
            'total_comment_score': 0,
            'positive_indicators': 0,
            'negative_indicators': 0,
            'subreddits': set(),
            'post_titles': set(),
            'sources': []
        })
        
        # Aggregate data by restaurant name
        for rec in recommendations:
            name = rec['name'].upper().strip()
            stats = restaurant_stats[name]
            
            stats['mention_count'] += 1
            stats['total_sentiment'] += rec['sentiment']
            stats['total_quality'] += rec['quality_score']
            stats['total_comment_score'] += rec['comment_score']
            stats['positive_indicators'] += rec['positive_indicators']
            stats['negative_indicators'] += rec['negative_indicators']
            stats['sources'].append(rec)
            
            if 'subreddit' in rec:
                stats['subreddits'].add(rec['subreddit'])
            if 'post_title' in rec:
                stats['post_titles'].add(rec['post_title'])
        
        # Calculate final scores
        recommendation_scores = {}
        for name, stats in restaurant_stats.items():
            avg_sentiment = stats['total_sentiment'] / stats['mention_count']
            avg_quality = stats['total_quality'] / stats['mention_count']
            avg_comment_score = stats['total_comment_score'] / stats['mention_count']
            
            # Enhanced recommendation score calculation
            recommendation_score = (
                min(stats['mention_count'] * 15, 60) +     # Mention frequency (max 60)
                max(0, avg_sentiment * 25) +              # Sentiment (max 25)
                max(0, avg_quality * 10) +                # Quality indicators (max varies)
                min(avg_comment_score / 5, 15) +          # Comment score (max 15)
                len(stats['subreddits']) * 5 +            # Subreddit diversity
                len(stats['post_titles']) * 3             # Post diversity
            )
            
            recommendation_scores[name] = {
                'recommendation_score': min(recommendation_score, 100),
                'mention_count': stats['mention_count'],
                'avg_sentiment': avg_sentiment,
                'avg_quality_score': avg_quality,
                'avg_comment_score': avg_comment_score,
                'positive_indicators': stats['positive_indicators'],
                'negative_indicators': stats['negative_indicators'],
                'subreddit_diversity': len(stats['subreddits']),
                'post_diversity': len(stats['post_titles']),
                'sources': stats['sources']
            }
        
        return recommendation_scores
    
    def analyze_mood_tags(self, establishment_type, recommendation_sources, establishment_name, address):
        """Analyze and assign mood tags based on establishment data and Reddit comments"""
        mood_scores = {
            'romantic': 0,
            'adventure': 0,
            'relaxing': 0,
            'family': 0,
            'cultural': 0,
            'foodie': 0,
            'nightlife': 0,
            'budget': 0
        }
        
        # Establishment type-based mood scoring
        type_moods = {
            'romantic': ['Fine Dining', 'Wine Bar', 'Cocktail Bar', 'Bistro', 'Private Club'],
            'adventure': ['Food Truck', 'Mobile Vendor', 'Ethnic Restaurant', 'Street Food'],
            'relaxing': ['Cafe', 'Coffee Shop', 'Tea House', 'Bakery', 'Spa'],
            'family': ['Family Restaurant', 'Pizza', 'Ice Cream', 'Buffet', 'Child Care'],
            'cultural': ['Ethnic Restaurant', 'Cultural Centre', 'Museum', 'Heritage'],
            'foodie': ['Fine Dining', 'Specialty Food Store', 'Gourmet', 'Artisan', 'Chef'],
            'nightlife': ['Bar', 'Pub', 'Cocktail Bar', 'Club', 'Late Night'],
            'budget': ['Take Out', 'Food Court', 'Street Food', 'Convenience']
        }
        
        # Score based on establishment type
        for mood, keywords in type_moods.items():
            for keyword in keywords:
                if keyword.lower() in establishment_type.lower():
                    mood_scores[mood] += 30
        
        # Analyze Reddit comments for mood indicators
        comment_mood_keywords = {
            'romantic': [
                'date', 'romantic', 'intimate', 'cozy', 'candlelit', 'anniversary', 
                'special occasion', 'wine', 'atmosphere', 'ambiance', 'perfect for couples'
            ],
            'adventure': [
                'unique', 'unusual', 'exotic', 'authentic', 'hole in the wall', 
                'off the beaten path', 'discovery', 'adventure', 'try something new'
            ],
            'relaxing': [
                'chill', 'relaxing', 'peaceful', 'quiet', 'calm', 'serene',
                'laid back', 'comfortable', 'cozy', 'unwind'
            ],
            'family': [
                'family', 'kids', 'children', 'kid-friendly', 'family-friendly',
                'bring the kids', 'good for families', 'playground'
            ],
            'cultural': [
                'authentic', 'traditional', 'cultural', 'heritage', 'ethnic',
                'immigrant', 'community', 'cultural experience', 'traditional recipes'
            ],
            'foodie': [
                'gourmet', 'artisan', 'chef', 'culinary', 'sophisticated',
                'food lover', 'foodie', 'gastronomy', 'fine dining', 'exquisite'
            ],
            'nightlife': [
                'late night', 'after hours', 'drinks', 'cocktails', 'party',
                'nightlife', 'bar scene', 'evening', 'night out'
            ],
            'budget': [
                'cheap', 'affordable', 'budget', 'inexpensive', 'good value',
                'bang for buck', 'reasonable', 'student budget', 'under $'
            ]
        }
        
        # Analyze all recommendation sources
        for source in recommendation_sources:
            comment_text = source.get('post_title', '') + ' ' + str(source.get('comment_body', ''))
            comment_text = comment_text.lower()
            
            for mood, keywords in comment_mood_keywords.items():
                for keyword in keywords:
                    if keyword in comment_text:
                        mood_scores[mood] += 15
        
        # Location-based mood adjustments
        location_moods = {
            'romantic': ['king st', 'queen st', 'ossington', 'kensington', 'distillery'],
            'nightlife': ['entertainment district', 'king st w', 'adelaide', 'richmond'],
            'cultural': ['chinatown', 'little italy', 'greektown', 'koreatown', 'india bazaar'],
            'budget': ['food court', 'chinatown', 'kensington', 'college st'],
            'foodie': ['king st', 'queen st', 'ossington', 'dundas west']
        }
        
        address_lower = address.lower()
        for mood, locations in location_moods.items():
            for location in locations:
                if location in address_lower:
                    mood_scores[mood] += 10
        
        # Name-based mood indicators
        name_lower = establishment_name.lower()
        name_moods = {
            'romantic': ['bistro', 'wine', 'rose', 'amor', 'bella', 'chez'],
            'adventure': ['street', 'authentic', 'original', 'traditional'],
            'relaxing': ['cafe', 'garden', 'peaceful', 'zen', 'calm'],
            'family': ['family', 'kids', 'home', 'mama', 'papa'],
            'cultural': ['authentic', 'traditional', 'heritage', 'cultural'],
            'foodie': ['gourmet', 'artisan', 'chef', 'kitchen', 'culinary'],
            'nightlife': ['bar', 'pub', 'club', 'lounge', 'night'],
            'budget': ['express', 'quick', 'fast', 'value', 'economy']
        }
        
        for mood, keywords in name_moods.items():
            for keyword in keywords:
                if keyword in name_lower:
                    mood_scores[mood] += 20
        
        # Convert scores to tags (threshold-based)
        mood_tags = []
        for mood, score in mood_scores.items():
            if score >= 25:  # Threshold for inclusion
                mood_tags.append(mood.title())
        
        # Ensure at least one tag (default to most likely based on type)
        if not mood_tags:
            if 'restaurant' in establishment_type.lower():
                mood_tags.append('Foodie')
            elif 'bar' in establishment_type.lower() or 'pub' in establishment_type.lower():
                mood_tags.append('Nightlife')
            elif 'cafe' in establishment_type.lower() or 'coffee' in establishment_type.lower():
                mood_tags.append('Relaxing')
            else:
                mood_tags.append('Adventure')
        
        return mood_tags, mood_scores

    def calculate_uniqueness_score(self, establishment_type, mention_count, recommendation_score):
        """Calculate uniqueness score based on establishment type and recommendation patterns"""
        # Common establishment types get lower uniqueness scores
        common_types = ['Restaurant', 'Take Out', 'Mobile Vendor', 'Chain Restaurant']
        unique_types = ['Bakery', 'Specialty Food Store', 'Catering', 'Food Depot', 'Private Club']
        
        base_score = 50
        
        if any(common in establishment_type for common in common_types):
            base_score = 25
        elif any(unique in establishment_type for unique in unique_types):
            base_score = 75
        
        # For recommendations, moderate mention count is ideal (not too unknown, not too mainstream)
        if mention_count >= 2 and mention_count <= 5:
            mention_bonus = 20
        elif mention_count == 1:
            mention_bonus = 10  # Single mention might be less reliable
        else:
            mention_bonus = max(0, 20 - (mention_count - 5) * 3)  # Penalty for being too popular
        
        # High recommendation score increases uniqueness (quality hidden gem)
        quality_bonus = min(recommendation_score / 5, 15)
        
        uniqueness_score = base_score + mention_bonus + quality_bonus
        return min(uniqueness_score, 100)
    
    def find_hidden_gems(self, min_dinesafe_score=70, min_recommendation_mentions=1, max_recommendation_mentions=8):
        """Find hidden gems using recommendation data"""
        print("💎 Finding hidden gems using recommendation data...")
        
        # Extract recommendations
        print("📝 Extracting restaurant recommendations from comments...")
        recommendations = self.extract_restaurant_recommendations()
        print(f"✅ Found {len(recommendations)} restaurant recommendations in Reddit data")
        
        # Calculate recommendation scores
        print("📊 Calculating recommendation scores...")
        recommendation_scores = self.calculate_recommendation_scores(recommendations)
        print(f"✅ Calculated scores for {len(recommendation_scores)} unique restaurants")
        
        # Match recommendations to DineSafe data
        matches = self.match_recommendations_to_dinesafe(recommendations)
        print(f"✅ Matched {len(matches)} recommendations to DineSafe establishments")
        
        # Calculate combined scores
        print("🏆 Calculating final hidden gem scores...")
        hidden_gems = []
        
        # Track unique establishments to avoid duplicates
        seen_establishments = set()
        
        for match in tqdm(matches, desc="Scoring hidden gems", unit="match"):
            reddit_name = match['reddit_name']
            rec_data = recommendation_scores.get(reddit_name.upper().strip(), {})
            dinesafe_data = match['dinesafe_data']
            
            # Create unique key for establishment (ID + Name + Address)
            establishment_key = f"{dinesafe_data['Establishment ID']}_{dinesafe_data['Establishment Name']}_{dinesafe_data['Establishment Address']}"
            
            # Skip if we've already processed this establishment
            if establishment_key in seen_establishments:
                continue
            
            seen_establishments.add(establishment_key)
            
            # Filter based on criteria
            mention_count = rec_data.get('mention_count', 0)
            dinesafe_score = dinesafe_data['quality_score']
            recommendation_score = rec_data.get('recommendation_score', 0)
            
            if (mention_count >= min_recommendation_mentions and 
                mention_count <= max_recommendation_mentions and
                dinesafe_score >= min_dinesafe_score):
                
                # Calculate uniqueness score
                uniqueness_score = self.calculate_uniqueness_score(
                    dinesafe_data['establishment_type'], mention_count, recommendation_score
                )
                
                # Analyze mood tags
                mood_tags, mood_scores = self.analyze_mood_tags(
                    dinesafe_data['establishment_type'],
                    rec_data.get('sources', []),
                    dinesafe_data['Establishment Name'],
                    dinesafe_data['Establishment Address']
                )
                
                # Calculate final hidden gem score with enhanced weights for recommendations
                final_score = (
                    recommendation_score * 0.35 +                    # Reddit recommendations (35%)
                    (rec_data.get('avg_sentiment', 0) + 1) * 50 * 0.20 +  # Sentiment (20%)
                    dinesafe_score * 0.25 +                         # DineSafe score (25%)
                    uniqueness_score * 0.20                         # Uniqueness (20%)
                )
                
                hidden_gem = {
                    'name': dinesafe_data['Establishment Name'],
                    'address': dinesafe_data['Establishment Address'],
                    'type': dinesafe_data['establishment_type'],
                    'latitude': dinesafe_data['Latitude'],
                    'longitude': dinesafe_data['Longitude'],
                    'hidden_gem_score': round(final_score, 2),
                    'dinesafe_score': round(dinesafe_score, 2),
                    'recommendation_score': round(recommendation_score, 2),
                    'uniqueness_score': round(uniqueness_score, 2),
                    'mention_count': mention_count,
                    'avg_sentiment': round(rec_data.get('avg_sentiment', 0), 3),
                    'avg_quality_score': round(rec_data.get('avg_quality_score', 0), 2),
                    'positive_indicators': rec_data.get('positive_indicators', 0),
                    'negative_indicators': rec_data.get('negative_indicators', 0),
                    'subreddit_diversity': rec_data.get('subreddit_diversity', 0),
                    'post_diversity': rec_data.get('post_diversity', 0),
                    'similarity_score': match['similarity_score'],
                    'establishment_id': dinesafe_data['Establishment ID'],
                    'is_recommendation_based': True,
                    'mood_tags': mood_tags,
                    'mood_scores': mood_scores
                }
                
                hidden_gems.append(hidden_gem)
        
        # Sort by hidden gem score
        hidden_gems.sort(key=lambda x: x['hidden_gem_score'], reverse=True)
        
        self.combined_results = hidden_gems
        return hidden_gems
    
    def filter_by_mood(self, mood_filter=None, top_n=10):
        """Filter hidden gems by mood tags"""
        if self.combined_results is None:
            print("No results available. Run find_hidden_gems() first.")
            return []
        
        if mood_filter is None:
            return self.combined_results[:top_n]
        
        mood_filter = mood_filter.title()  # Ensure proper capitalization
        filtered_gems = []
        
        for gem in self.combined_results:
            if mood_filter in gem.get('mood_tags', []):
                filtered_gems.append(gem)
        
        return filtered_gems[:top_n]
    
    def get_mood_statistics(self):
        """Get statistics about mood distribution"""
        if self.combined_results is None:
            print("No results available. Run find_hidden_gems() first.")
            return {}
        
        mood_counts = {
            'Romantic': 0, 'Adventure': 0, 'Relaxing': 0, 'Family': 0,
            'Cultural': 0, 'Foodie': 0, 'Nightlife': 0, 'Budget': 0
        }
        
        for gem in self.combined_results:
            for mood in gem.get('mood_tags', []):
                if mood in mood_counts:
                    mood_counts[mood] += 1
        
        return mood_counts
    
    def export_results(self, filename=None):
        """Export hidden gems results to CSV"""
        if self.combined_results is None:
            print("No results to export. Run find_hidden_gems() first.")
            return
        
        if filename is None:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            filename = f"data/toronto_hidden_gems_recommendations_{timestamp}.csv"
        
        # Prepare data for export (convert mood_tags list to string)
        export_data = []
        for gem in self.combined_results:
            gem_copy = gem.copy()
            gem_copy['mood_tags'] = ', '.join(gem.get('mood_tags', []))
            # Convert mood_scores dict to string for CSV
            mood_scores = gem.get('mood_scores', {})
            for mood, score in mood_scores.items():
                gem_copy[f'mood_score_{mood}'] = score
            del gem_copy['mood_scores']  # Remove the dict version
            export_data.append(gem_copy)
        
        df = pd.DataFrame(export_data)
        df.to_csv(filename, index=False)
        print(f"Exported {len(self.combined_results)} recommendation-based hidden gems to {filename}")
        
        return filename
    
    def get_gem_details(self, establishment_id):
        """Get detailed information about a specific hidden gem including recommendations"""
        # Get DineSafe details
        dinesafe_details = self.dinesafe_analyzer.get_establishment_details(establishment_id)
        
        # Find related recommendations
        related_recommendations = []
        if self.recommendation_data and not self.recommendation_data['comments'].empty:
            for _, comment in self.recommendation_data['comments'].iterrows():
                if any(gem['establishment_id'] == establishment_id for gem in self.combined_results or []):
                    related_recommendations.append({
                        'comment_body': comment['comment_body'],
                        'sentiment': comment['sentiment_score'],
                        'quality_score': comment['quality_score'],
                        'post_title': comment['post_title'],
                        'subreddit': comment['subreddit'],
                        'author': comment['author']
                    })
        
        return {
            'dinesafe_details': dinesafe_details,
            'recommendations': related_recommendations
        }

if __name__ == "__main__":
    # Example usage
    finder = HiddenGemsFinderRecommendations()
    
    # Load or collect recommendation data
    finder.load_or_collect_recommendation_data(use_existing=False)
    
    # Find hidden gems using recommendations
    hidden_gems = finder.find_hidden_gems(
        min_dinesafe_score=65,  # Slightly lower threshold for recommendations
        min_recommendation_mentions=1,
        max_recommendation_mentions=6  # Focus on moderately mentioned places
    )
    
    # Display top results
    print(f"\n🎉 Found {len(hidden_gems)} recommendation-based hidden gems!")
    if hidden_gems:
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
            print(f"    👍 Positive Indicators: {gem['positive_indicators']}")
            print(f"    🎭 Mood Tags: {', '.join(gem['mood_tags'])}")
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
        finder.export_results()
    else:
        print("No recommendation-based hidden gems found with current criteria.") 