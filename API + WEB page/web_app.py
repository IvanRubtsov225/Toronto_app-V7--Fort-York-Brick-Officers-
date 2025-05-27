#!/usr/bin/env python3
"""
Toronto Hidden Gems Web Application
A beautiful, modern web interface inspired by Apple UI, Toronto flag colors, and IBM Design Language
"""

from flask import Flask, render_template, jsonify, request, send_from_directory
import json
import os
import sys
import csv
from datetime import datetime
import glob

# Add project root to path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

app = Flask(__name__)

class TorontoHiddenGemsAPI:
    def __init__(self):
        self.data_dir = "data"
        self.gems_data = None
        self.load_latest_data()
    
    def load_latest_data(self):
        """Load the most recent hidden gems data"""
        try:
            # Find the most recent recommendations file
            pattern = os.path.join(self.data_dir, "toronto_hidden_gems_recommendations_*.csv")
            files = glob.glob(pattern)
            
            if files:
                latest_file = max(files, key=os.path.getctime)
                self.gems_data = []
                
                with open(latest_file, 'r', encoding='utf-8') as f:
                    reader = csv.DictReader(f)
                    for row in reader:
                        # Convert numeric fields
                        for field in ['hidden_gem_score', 'dinesafe_score', 'recommendation_score', 
                                    'uniqueness_score', 'mention_count', 'avg_sentiment', 'latitude', 'longitude']:
                            if field in row and row[field]:
                                try:
                                    row[field] = float(row[field])
                                except ValueError:
                                    row[field] = 0.0
                        
                        # Convert integer fields
                        for field in ['positive_indicators', 'negative_indicators']:
                            if field in row and row[field]:
                                try:
                                    row[field] = int(row[field])
                                except ValueError:
                                    row[field] = 0
                        
                        self.gems_data.append(row)
                
                print(f"Loaded data from: {latest_file}")
                print(f"Total gems: {len(self.gems_data)}")
            else:
                print("No hidden gems data found")
                self.gems_data = []
        except Exception as e:
            print(f"Error loading data: {e}")
            self.gems_data = []
    
    def get_all_gems(self, limit=None):
        """Get all hidden gems"""
        if not self.gems_data:
            return []
        
        data = self.gems_data.copy()
        if limit:
            data = data[:limit]
        
        return data
    
    def get_gems_by_mood(self, mood, limit=10):
        """Get gems filtered by mood"""
        if not self.gems_data:
            return []
        
        # Filter by mood tags
        mood_filtered = []
        for gem in self.gems_data:
            mood_tags = gem.get('mood_tags', '').lower()
            if mood.lower() in mood_tags:
                mood_filtered.append(gem)
        
        return mood_filtered[:limit]
    
    def get_gems_by_type(self, establishment_type, limit=10):
        """Get gems filtered by establishment type"""
        if not self.gems_data:
            return []
        
        type_filtered = []
        for gem in self.gems_data:
            gem_type = gem.get('type', '').lower()
            if establishment_type.lower() in gem_type:
                type_filtered.append(gem)
        
        return type_filtered[:limit]
    
    def get_top_gems(self, limit=10):
        """Get top-rated hidden gems"""
        if not self.gems_data:
            return []
        
        # Sort by hidden_gem_score in descending order
        sorted_gems = sorted(self.gems_data, key=lambda x: x.get('hidden_gem_score', 0), reverse=True)
        return sorted_gems[:limit]
    
    def get_statistics(self):
        """Get overall statistics"""
        if not self.gems_data:
            return {
                'total_gems': 0,
                'average_score': 0,
                'average_sentiment': 0,
                'top_establishment_type': 'N/A',
                'mood_distribution': {},
                'score_ranges': {'excellent': 0, 'good': 0, 'fair': 0}
            }
        
        # Calculate statistics from list of dictionaries
        scores = [gem.get('hidden_gem_score', 0) for gem in self.gems_data]
        sentiments = [gem.get('avg_sentiment', 0) for gem in self.gems_data]
        types = [gem.get('type', '') for gem in self.gems_data]
        moods = [gem.get('mood_tags', '') for gem in self.gems_data]
        
        # Count establishment types
        type_counts = {}
        for t in types:
            if t:
                type_counts[t] = type_counts.get(t, 0) + 1
        top_type = max(type_counts.items(), key=lambda x: x[1])[0] if type_counts else 'N/A'
        
        # Count mood tags
        mood_counts = {}
        for mood_str in moods:
            if mood_str:
                for mood in mood_str.split(','):
                    mood = mood.strip()
                    if mood:
                        mood_counts[mood] = mood_counts.get(mood, 0) + 1
        
        # Score ranges
        excellent = sum(1 for score in scores if score >= 80)
        good = sum(1 for score in scores if 70 <= score < 80)
        fair = sum(1 for score in scores if score < 70)
        
        stats = {
            'total_gems': len(self.gems_data),
            'average_score': sum(scores) / len(scores) if scores else 0,
            'average_sentiment': sum(sentiments) / len(sentiments) if sentiments else 0,
            'top_establishment_type': top_type,
            'mood_distribution': dict(sorted(mood_counts.items(), key=lambda x: x[1], reverse=True)[:5]),
            'score_ranges': {
                'excellent': excellent,
                'good': good,
                'fair': fair
            }
        }
        
        return stats

# Initialize API
api = TorontoHiddenGemsAPI()

@app.route('/')
def index():
    """Main page"""
    stats = api.get_statistics()
    top_gems = api.get_top_gems(6)
    return render_template('index.html', stats=stats, top_gems=top_gems)

@app.route('/gems')
def gems_page():
    """Hidden gems explorer page"""
    all_gems = api.get_all_gems(50)  # Limit for performance
    return render_template('gems.html', gems=all_gems)

@app.route('/documentation')
def documentation():
    """API documentation page"""
    return render_template('documentation.html')

@app.route('/api/gems')
def api_gems():
    """API endpoint: Get all gems"""
    limit = request.args.get('limit', type=int)
    gems = api.get_all_gems(limit)
    return jsonify({
        'status': 'success',
        'count': len(gems),
        'data': gems
    })

@app.route('/api/gems/top')
def api_top_gems():
    """API endpoint: Get top gems"""
    limit = request.args.get('limit', 10, type=int)
    gems = api.get_top_gems(limit)
    return jsonify({
        'status': 'success',
        'count': len(gems),
        'data': gems
    })

@app.route('/api/gems/mood/<mood>')
def api_gems_by_mood(mood):
    """API endpoint: Get gems by mood"""
    limit = request.args.get('limit', 10, type=int)
    gems = api.get_gems_by_mood(mood, limit)
    return jsonify({
        'status': 'success',
        'mood': mood,
        'count': len(gems),
        'data': gems
    })

@app.route('/api/gems/type/<establishment_type>')
def api_gems_by_type(establishment_type):
    """API endpoint: Get gems by type"""
    limit = request.args.get('limit', 10, type=int)
    gems = api.get_gems_by_type(establishment_type, limit)
    return jsonify({
        'status': 'success',
        'type': establishment_type,
        'count': len(gems),
        'data': gems
    })

@app.route('/api/stats')
def api_stats():
    """API endpoint: Get statistics"""
    stats = api.get_statistics()
    return jsonify({
        'status': 'success',
        'data': stats
    })

@app.route('/analytics')
def analytics():
    """Analytics and statistics dashboard page"""
    stats = api.get_statistics()
    all_gems = api.get_all_gems()
    
    # Calculate additional analytics
    analytics_data = {
        'stats': stats,
        'gems_by_score_range': {
            'excellent': [gem for gem in all_gems if gem.get('hidden_gem_score', 0) >= 80],
            'good': [gem for gem in all_gems if 70 <= gem.get('hidden_gem_score', 0) < 80],
            'fair': [gem for gem in all_gems if gem.get('hidden_gem_score', 0) < 70]
        },
        'top_establishments': sorted(all_gems, key=lambda x: x.get('hidden_gem_score', 0), reverse=True)[:10],
        'most_mentioned': sorted(all_gems, key=lambda x: x.get('mention_count', 0), reverse=True)[:10],
        'best_sentiment': sorted(all_gems, key=lambda x: x.get('avg_sentiment', 0), reverse=True)[:10]
    }
    
    return render_template('analytics.html', data=analytics_data)

@app.route('/moods')
def moods_page():
    """Mood-based gem browsing page"""
    stats = api.get_statistics()
    
    # Get gems for each mood category
    mood_categories = ['romantic', 'foodie', 'budget', 'nightlife', 'family', 'cultural', 'relaxing', 'adventure']
    mood_gems = {}
    
    for mood in mood_categories:
        gems = api.get_gems_by_mood(mood, limit=8)
        mood_gems[mood] = gems
    
    return render_template('moods.html', mood_gems=mood_gems, mood_stats=stats.get('mood_distribution', {}))

@app.route('/about')
def about():
    """About page explaining the project and methodology"""
    return render_template('about.html')

@app.route('/static/<path:filename>')
def static_files(filename):
    """Serve static files"""
    return send_from_directory('static', filename)

if __name__ == '__main__':
    print("🍽️ Toronto Hidden Gems Web Application")
    print("=" * 50)
    print("🚀 Starting server...")
    print("📍 Available at: http://localhost:8000")
    print("📊 API Documentation: http://localhost:8000/documentation")
    print("💎 Hidden Gems Explorer: http://localhost:8000/gems")
    
    app.run(debug=True, host='0.0.0.0', port=8000) 