#!/usr/bin/env python3
"""
Toronto Hidden Gems & Events Web Application
A beautiful, modern web interface inspired by Apple UI, Toronto flag colors, and IBM Design Language
"""

from flask import Flask, render_template, jsonify, request, send_from_directory
import json
import os
import sys
import csv
from datetime import datetime
import glob
import random
import subprocess

# Add project root to path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

app = Flask(__name__)

class TorontoHiddenGemsAPI:
    def __init__(self):
        self.data_dir = "data"
        self.gems_data = None
        self.events_data = None
        self.load_latest_data()
    
    def load_latest_data(self):
        """Load the most recent hidden gems and events data"""
        self.load_gems_data()
        self.load_events_data()
    
    def load_gems_data(self):
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
                
                print(f"Loaded gems data from: {latest_file}")
                print(f"Total gems: {len(self.gems_data)}")
            else:
                print("No hidden gems data found")
                self.gems_data = []
        except Exception as e:
            print(f"Error loading gems data: {e}")
            self.gems_data = []
    
    def load_events_data(self):
        """Load the most recent events data"""
        try:
            # Find the most recent events file
            pattern = os.path.join(self.data_dir, "hidden_gem_events_*.csv")
            files = glob.glob(pattern)
            
            if files:
                latest_file = max(files, key=os.path.getctime)
                self.events_data = []
                
                with open(latest_file, 'r', encoding='utf-8') as f:
                    reader = csv.DictReader(f)
                    for row in reader:
                        # Convert numeric fields
                        for field in ['hidden_gem_score', 'popularity_score', 'accessibility_score', 
                                    'family_friendly_score', 'price_min', 'price_max', 'reddit_buzz', 'reddit_sentiment']:
                            if field in row and row[field]:
                                try:
                                    row[field] = float(row[field])
                                except ValueError:
                                    row[field] = 0.0
                        
                        self.events_data.append(row)
                
                print(f"Loaded events data from: {latest_file}")
                print(f"Total events: {len(self.events_data)}")
            else:
                print("No events data found")
                self.events_data = []
        except Exception as e:
            print(f"Error loading events data: {e}")
            self.events_data = []
    
    def get_all_gems(self, limit=None):
        """Get all hidden gems"""
        if not self.gems_data:
            return []
        
        data = self.gems_data.copy()
        if limit:
            data = data[:limit]
        
        return data
    
    def get_all_events(self, limit=None):
        """Get all events"""
        if not self.events_data:
            return []
        
        data = self.events_data.copy()
        if limit:
            data = data[:limit]
        
        return data
    
    def get_events_by_mood(self, mood, limit=10):
        """Get events filtered by mood"""
        if not self.events_data:
            return []
        
        mood_filtered = []
        for event in self.events_data:
            mood_tags = str(event.get('mood_tags', '')).lower()
            if mood.lower() in mood_tags:
                mood_filtered.append(event)
        
        return mood_filtered[:limit]
    
    def get_events_by_type(self, event_type, limit=10):
        """Get events filtered by type"""
        if not self.events_data:
            return []
        
        type_filtered = []
        for event in self.events_data:
            event_genre = str(event.get('genre', '')).lower()
            event_segment = str(event.get('segment', '')).lower()
            if event_type.lower() in event_genre or event_type.lower() in event_segment:
                type_filtered.append(event)
        
        return type_filtered[:limit]
    
    def get_top_events(self, limit=10):
        """Get top-rated events"""
        if not self.events_data:
            return []
        
        # Sort by hidden_gem_score in descending order
        sorted_events = sorted(self.events_data, key=lambda x: x.get('hidden_gem_score', 0), reverse=True)
        return sorted_events[:limit]
    
    def get_free_events(self, limit=10):
        """Get free events"""
        if not self.events_data:
            return []
        
        free_events = [event for event in self.events_data if event.get('price_min', 0) == 0]
        # Sort by hidden gem score
        free_events.sort(key=lambda x: x.get('hidden_gem_score', 0), reverse=True)
        return free_events[:limit]
    
    def get_upcoming_events(self, days_ahead=7, limit=10):
        """Get upcoming events in the next few days"""
        if not self.events_data:
            return []
        
        # For now, return all events (would need date parsing for real filtering)
        # Sort by date would go here
        return self.get_top_events(limit)
    
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
    
    def get_event_statistics(self):
        """Get event statistics"""
        if not self.events_data:
            return {
                'total_events': 0,
                'average_score': 0,
                'free_events': 0,
                'average_price': 0,
                'mood_distribution': {},
                'type_distribution': {}
            }
        
        # Calculate statistics
        scores = [event.get('hidden_gem_score', 0) for event in self.events_data]
        prices = [event.get('price_min', 0) for event in self.events_data if event.get('price_min', 0) > 0]
        free_count = sum(1 for event in self.events_data if event.get('price_min', 0) == 0)
        
        # Count mood tags
        mood_counts = {}
        for event in self.events_data:
            mood_str = str(event.get('mood_tags', ''))
            if mood_str and mood_str != 'nan':
                for mood in mood_str.split(','):
                    mood = mood.strip()
                    if mood:
                        mood_counts[mood] = mood_counts.get(mood, 0) + 1
        
        # Count event types
        type_counts = {}
        for event in self.events_data:
            event_type = event.get('segment', '') or event.get('genre', '') or 'Unknown'
            if event_type:
                type_counts[event_type] = type_counts.get(event_type, 0) + 1
        
        return {
            'total_events': len(self.events_data),
            'average_score': sum(scores) / len(scores) if scores else 0,
            'free_events': free_count,
            'average_price': sum(prices) / len(prices) if prices else 0,
            'mood_distribution': dict(sorted(mood_counts.items(), key=lambda x: x[1], reverse=True)[:5]),
            'type_distribution': dict(sorted(type_counts.items(), key=lambda x: x[1], reverse=True)[:5])
        }

# Initialize API
api = TorontoHiddenGemsAPI()

@app.route('/')
def index():
    """Main page"""
    stats = api.get_statistics()
    event_stats = api.get_event_statistics()
    top_gems = api.get_top_gems(6)
    top_events = api.get_top_events(4)
    return render_template('index.html', 
                         stats=stats, 
                         event_stats=event_stats,
                         top_gems=top_gems,
                         top_events=top_events)

@app.route('/gems')
def gems_page():
    """Hidden gems explorer page"""
    all_gems = api.get_all_gems()
    return render_template('gems.html', gems=all_gems)

@app.route('/events')
def events_page():
    """Events explorer page"""
    all_events = api.get_all_events()
    event_stats = api.get_event_statistics()
    return render_template('events.html', events=all_events, stats=event_stats)

@app.route('/documentation')
def documentation():
    """API documentation page"""
    return render_template('documentation.html')

# GEMS API ENDPOINTS
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

# EVENTS API ENDPOINTS
@app.route('/api/events')
def api_events():
    """API endpoint: Get all events"""
    limit = request.args.get('limit', type=int)
    events = api.get_all_events(limit)
    return jsonify({
        'status': 'success',
        'count': len(events),
        'data': events
    })

@app.route('/api/events/top')
def api_top_events():
    """API endpoint: Get top events"""
    limit = request.args.get('limit', 10, type=int)
    events = api.get_top_events(limit)
    return jsonify({
        'status': 'success',
        'count': len(events),
        'data': events
    })

@app.route('/api/events/free')
def api_free_events():
    """API endpoint: Get free events"""
    limit = request.args.get('limit', 10, type=int)
    events = api.get_free_events(limit)
    return jsonify({
        'status': 'success',
        'count': len(events),
        'data': events
    })

@app.route('/api/events/upcoming')
def api_upcoming_events():
    """API endpoint: Get upcoming events"""
    days = request.args.get('days', 7, type=int)
    limit = request.args.get('limit', 10, type=int)
    events = api.get_upcoming_events(days, limit)
    return jsonify({
        'status': 'success',
        'count': len(events),
        'data': events
    })

@app.route('/api/events/mood/<mood>')
def api_events_by_mood(mood):
    """API endpoint: Get events by mood"""
    limit = request.args.get('limit', 10, type=int)
    events = api.get_events_by_mood(mood, limit)
    return jsonify({
        'status': 'success',
        'mood': mood,
        'count': len(events),
        'data': events
    })

@app.route('/api/events/type/<event_type>')
def api_events_by_type(event_type):
    """API endpoint: Get events by type"""
    limit = request.args.get('limit', 10, type=int)
    events = api.get_events_by_type(event_type, limit)
    return jsonify({
        'status': 'success',
        'type': event_type,
        'count': len(events),
        'data': events
    })

@app.route('/api/stats')
def api_stats():
    """API endpoint: Get statistics"""
    stats = api.get_statistics()
    return jsonify({
        'status': 'success',
        'data': stats
    })

@app.route('/api/events/stats')
def api_event_stats():
    """API endpoint: Get event statistics"""
    stats = api.get_event_statistics()
    return jsonify({
        'status': 'success',
        'data': stats
    })

@app.route('/analytics')
def analytics():
    """Analytics and statistics dashboard page"""
    stats = api.get_statistics()
    event_stats = api.get_event_statistics()
    all_gems = api.get_all_gems()
    all_events = api.get_all_events()
    
    # Calculate additional analytics
    analytics_data = {
        'stats': stats,
        'event_stats': event_stats,
        'gems_by_score_range': {
            'excellent': [gem for gem in all_gems if gem.get('hidden_gem_score', 0) >= 80],
            'good': [gem for gem in all_gems if 70 <= gem.get('hidden_gem_score', 0) < 80],
            'fair': [gem for gem in all_gems if gem.get('hidden_gem_score', 0) < 70]
        },
        'events_by_score_range': {
            'excellent': [event for event in all_events if event.get('hidden_gem_score', 0) >= 80],
            'good': [event for event in all_events if 70 <= event.get('hidden_gem_score', 0) < 80],
            'fair': [event for event in all_events if event.get('hidden_gem_score', 0) < 70]
        },
        'top_establishments': sorted(all_gems, key=lambda x: x.get('hidden_gem_score', 0), reverse=True)[:10],
        'top_events': sorted(all_events, key=lambda x: x.get('hidden_gem_score', 0), reverse=True)[:10],
        'most_mentioned': sorted(all_gems, key=lambda x: x.get('mention_count', 0), reverse=True)[:10],
        'best_sentiment': sorted(all_gems, key=lambda x: x.get('avg_sentiment', 0), reverse=True)[:10],
        'free_events': api.get_free_events(10)
    }
    
    return render_template('analytics.html', data=analytics_data)

def get_mood_gradient(mood):
    """Get gradient style for a mood"""
    gradients = {
        'romantic': 'linear-gradient(135deg, #FF6B6B 0%, #FFB8B8 100%)',
        'foodie': 'linear-gradient(135deg, #FF9F1C 0%, #FFBF69 100%)',
        'adventure': 'linear-gradient(135deg, #2EC4B6 0%, #7DDCD3 100%)',
        'relaxing': 'linear-gradient(135deg, #9381FF 0%, #B8B8FF 100%)',
        'cultural': 'linear-gradient(135deg, #F72585 0%, #FF99D7 100%)',
        'budget': 'linear-gradient(135deg, #4CAF50 0%, #8BC34A 100%)',
        'free': 'linear-gradient(135deg, #28a745 0%, #20c997 100%)',
        'energetic': 'linear-gradient(135deg, #ff6b35 0%, #f7931e 100%)',
        'artistic': 'linear-gradient(135deg, #6f42c1 0%, #e83e8c 100%)',
        'nightlife': 'linear-gradient(135deg, #343a40 0%, #6c757d 100%)'
    }
    return gradients.get(mood.lower(), 'linear-gradient(135deg, #6c757d 0%, #495057 100%)')

def get_mood_emoji(mood):
    """Get emoji for a mood"""
    emojis = {
        'romantic': '💑',
        'foodie': '🍽️',
        'adventure': '🌟',
        'relaxing': '🌿',
        'cultural': '🎭',
        'budget': '💰',
        'free': '🎁',
        'energetic': '⚡',
        'artistic': '🎨',
        'nightlife': '🌙',
        'family': '👨‍👩‍👧‍👦',
        'outdoor': '🌲',
        'music': '🎵',
        'premium': '💎'
    }
    return emojis.get(mood.lower(), '🏷️')

# Register template filters
app.jinja_env.filters['mood_gradient'] = get_mood_gradient
app.jinja_env.filters['mood_emoji'] = get_mood_emoji

@app.route('/moods')
def moods_page():
    """Mood-based exploration page with interactive map"""
    stats = api.get_statistics()
    event_stats = api.get_event_statistics()
    return render_template('moods.html', stats=stats, event_stats=event_stats)

@app.route('/api/gems/moods', methods=['GET'])
def api_gems_by_moods():
    """API endpoint: Get gems filtered by multiple moods"""
    moods = request.args.get('moods', '').split(',')
    moods = [mood.strip().lower() for mood in moods if mood.strip()]
    
    if not moods:
        gems = api.get_all_gems()
    else:
        gems = [gem for gem in api.get_all_gems() if any(
            mood in (gem.get('mood_tags', '').lower()) for mood in moods
        )]
    
    return jsonify({
        'status': 'success',
        'count': len(gems),
        'data': gems
    })

@app.route('/api/events/moods', methods=['GET'])
def api_events_by_moods():
    """API endpoint: Get events filtered by multiple moods"""
    moods = request.args.get('moods', '').split(',')
    moods = [mood.strip().lower() for mood in moods if mood.strip()]
    
    if not moods:
        events = api.get_all_events()
    else:
        events = [event for event in api.get_all_events() if any(
            mood in str(event.get('mood_tags', '')).lower() for mood in moods
        )]
    
    return jsonify({
        'status': 'success',
        'count': len(events),
        'data': events
    })

@app.route('/about')
def about():
    """About page explaining the project and methodology"""
    return render_template('about.html')

@app.route('/api/gems/all')
def api_gems_all():
    """API endpoint: Get all gems (no limit, for client-side filtering)"""
    gems = api.get_all_gems()
    return jsonify({
        'status': 'success',
        'count': len(gems),
        'data': gems
    })

@app.route('/api/events/all')
def api_events_all():
    """API endpoint: Get all events (no limit, for client-side filtering)"""
    events = api.get_all_events()
    return jsonify({
        'status': 'success',
        'count': len(events),
        'data': events
    })

@app.route('/static/<path:filename>')
def static_files(filename):
    """Serve static files"""
    return send_from_directory('static', filename)

@app.route('/api/flutter/random-gem')
def api_flutter_random_gem():
    """Flutter endpoint: Get a random hidden gem (Toronto style!)"""
    gems = api.get_all_gems()
    if not gems:
        return jsonify({
            'status': 'oh no!',
            'message': 'No gems found in the 6ix! 🍁',
            'data': None
        })
    gem = random.choice(gems)
    return jsonify({
        'status': 'success',
        'message': 'Here\'s a random Toronto hidden gem for your Flutter app! 🏙️',
        'data': gem
    })

@app.route('/api/flutter/random-event')
def api_flutter_random_event():
    """Flutter endpoint: Get a random event (Toronto style!)"""
    events = api.get_all_events()
    if not events:
        return jsonify({
            'status': 'oh no!',
            'message': 'No events found in the 6ix! 🍁',
            'data': None
        })
    event = random.choice(events)
    return jsonify({
        'status': 'success',
        'message': 'Here\'s a random Toronto event for your Flutter app! 🎭',
        'data': event
    })

@app.route('/api/flutter/moods')
def api_flutter_moods():
    """Flutter endpoint: Get all unique moods (Toronto style!)"""
    gems = api.get_all_gems()
    events = api.get_all_events()
    mood_set = set()
    
    # Collect moods from gems
    for gem in gems:
        moods = gem.get('mood_tags', '')
        for mood in str(moods).split(','):
            mood = mood.strip()
            if mood and mood != 'nan':
                mood_set.add(mood)
    
    # Collect moods from events
    for event in events:
        moods = event.get('mood_tags', '')
        for mood in str(moods).split(','):
            mood = mood.strip()
            if mood and mood != 'nan':
                mood_set.add(mood)
    
    return jsonify({
        'status': 'success',
        'message': 'All the moods you\'ll find in Toronto! 🎉',
        'count': len(mood_set),
        'data': sorted(list(mood_set))
    })

@app.route('/api/refresh-data', methods=['POST'])
def api_refresh_data():
    """Endpoint to refresh the hidden gems and events data"""
    try:
        api.load_latest_data()
        return jsonify({
            'status': 'success',
            'message': 'Data refreshed! The 6ix is up to date! 🏙️🍁',
        })
    except Exception as e:
        return jsonify({
            'status': 'error',
            'message': f'Uh oh! Something went wrong in the 6ix: {str(e)}',
        }), 500

@app.route('/api/collect-data', methods=['POST'])
def api_collect_data():
    """Comprehensive data collection endpoint - collects both gems and events like the Toronto Mood Collector app"""
    try:
        print("🏙️ Starting comprehensive Toronto data collection (Mood Collector style)...")
        
        # Get the absolute path to the project directory
        project_dir = os.path.dirname(os.path.abspath(__file__))
        venv_python = os.path.join(project_dir, 'venv', 'bin', 'python3')
        script_path = os.path.join(project_dir, 'scripts', 'run.py')
        
        print(f"📍 Project directory: {project_dir}")
        print(f"📍 Using Python from: {venv_python}")
        print(f"📜 Running script: {script_path}")
        
        # Create and activate virtual environment if it doesn't exist
        if not os.path.exists(os.path.join(project_dir, 'venv')):
            print("🔧 Creating virtual environment...")
            subprocess.run(
                [sys.executable, '-m', 'venv', 'venv'],
                check=True,
                cwd=project_dir
            )
        
        # Install dependencies
        print("📦 Installing dependencies...")
        subprocess.run(
            [venv_python, '-m', 'pip', 'install', '-r', 'config/requirements.txt'],
            check=True,
            cwd=project_dir
        )
        
        results = {
            'gems_collection': None,
            'events_collection': None,
            'gems_found': 0,
            'events_found': 0
        }
        
        # Step 1: Collect Hidden Gems Data
        print("🍁 Phase 1: Collecting Hidden Gems Data...")
        print("🎯 Running recommendations collector...")
        subprocess.run(
            [venv_python, script_path, 'recommendations'],
            check=True,
            cwd=project_dir
        )
        
        print("💎 Running recommendation-based finder with mood analysis...")
        gems_result = subprocess.run(
            [venv_python, script_path, 'find-recs'],
            capture_output=True,
            text=True,
            cwd=project_dir
        )
        
        results['gems_collection'] = gems_result.stdout
        if gems_result.returncode == 0:
            print("✅ Hidden gems collection completed successfully!")
            # Count gems found from output
            if 'gems found' in gems_result.stdout.lower():
                import re
                match = re.search(r'(\d+)\s+gems?\s+found', gems_result.stdout, re.IGNORECASE)
                if match:
                    results['gems_found'] = int(match.group(1))
        else:
            print(f"⚠️ Gems collection had issues: {gems_result.stderr}")
        
        # Step 2: Collect Events Data
        print("🎭 Phase 2: Collecting Events Data...")
        print("🎫 Running event finder with Ticketmaster integration...")
        events_result = subprocess.run(
            [venv_python, script_path, 'find-events'],
            capture_output=True,
            text=True,
            cwd=project_dir
        )
        
        results['events_collection'] = events_result.stdout
        if events_result.returncode == 0:
            print("✅ Events collection completed successfully!")
            # Count events found from output
            if 'events found' in events_result.stdout.lower():
                import re
                match = re.search(r'(\d+)\s+events?\s+found', events_result.stdout, re.IGNORECASE)
                if match:
                    results['events_found'] = int(match.group(1))
        else:
            print(f"⚠️ Events collection had issues: {events_result.stderr}")
        
        # Step 3: Refresh Data in Memory
        print("🔄 Phase 3: Refreshing data in memory...")
        api.load_latest_data()
        
        # Determine overall success
        gems_success = gems_result.returncode == 0
        events_success = events_result.returncode == 0
        
        if gems_success and events_success:
            status = 'success'
            message = f'🎉 Complete data collection successful! Found {results["gems_found"]} gems and {results["events_found"]} events in Toronto!'
        elif gems_success or events_success:
            status = 'partial_success'
            success_part = 'gems' if gems_success else 'events'
            message = f'⚠️ Partial success: {success_part} collection completed. Check logs for details.'
        else:
            status = 'error'
            message = '❌ Both collections failed. Please check the logs for details.'
        
        print(f"📊 Final Results: {message}")
        
        return jsonify({
            'status': status,
            'message': message,
            'details': {
                'gems_found': results['gems_found'],
                'events_found': results['events_found'],
                'gems_success': gems_success,
                'events_success': events_success
            },
            'output': {
                'gems': results['gems_collection'],
                'events': results['events_collection']
            }
        })
            
    except Exception as e:
        print(f"❌ Exception occurred during comprehensive data collection: {str(e)}")
        return jsonify({
            'status': 'error',
            'message': f'Comprehensive data collection failed: {str(e)}'
        }), 500

@app.route('/api/collect-events', methods=['POST'])
def api_collect_events():
    """Endpoint to run event collection and finding"""
    try:
        print("🎭 Starting event collection and finding...")
        
        # Get the absolute path to the project directory
        project_dir = os.path.dirname(os.path.abspath(__file__))
        venv_python = os.path.join(project_dir, 'venv', 'bin', 'python3')
        script_path = os.path.join(project_dir, 'scripts', 'run.py')
        
        # Run event finder
        print("💎 Running event finder...")
        result = subprocess.run(
            [venv_python, script_path, 'find-events'],
            capture_output=True,
            text=True,
            cwd=project_dir
        )
        
        print("📤 Command output:")
        print(result.stdout)
        
        if result.stderr:
            print("❌ Error output:")
            print(result.stderr)
        
        if result.returncode == 0:
            print("✅ Event finder completed successfully!")
            return jsonify({
                'status': 'success',
                'message': 'Hidden gem events found!',
                'output': result.stdout
            })
        else:
            print(f"❌ Event finder failed with return code: {result.returncode}")
            return jsonify({
                'status': 'error',
                'message': 'Event finder failed.',
                'output': result.stderr
            }), 500
            
    except Exception as e:
        print(f"❌ Exception occurred: {str(e)}")
        return jsonify({
            'status': 'error',
            'message': f'Error: {str(e)}'
        }), 500

if __name__ == '__main__':
    print("🎭 Toronto Hidden Gems & Events Web Application")
    print("=" * 50)
    print("🚀 Starting server...")
    print("📍 Available at: http://localhost:8000")
    print("📊 API Documentation: http://localhost:8000/documentation")
    print("💎 Hidden Gems Explorer: http://localhost:8000/gems")
    print("🎭 Events Explorer: http://localhost:8000/events")
    
    app.run(debug=True, host='0.0.0.0', port=8000) 