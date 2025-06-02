import requests
import pandas as pd
import json
from datetime import datetime, timedelta
from textblob import TextBlob
import time
import sys
import os
sys.path.append(os.path.join(os.path.dirname(__file__), '..', '..'))
from config.config import *

class TicketmasterCollector:
    def __init__(self):
        """Initialize Ticketmaster API collector"""
        self.api_key = TICKETMASTER_CONSUMER_KEY
        self.base_url = TICKETMASTER_API_URL
        self.session = requests.Session()
        
    def get_events(self, 
                   event_type='events', 
                   start_date=None, 
                   end_date=None, 
                   size=200,
                   classification_names=None,
                   keyword=None):
        """
        Get events from Ticketmaster API for Toronto area
        
        Args:
            event_type: Type of events (events, attractions, venues)
            start_date: Start date (YYYY-MM-DDTHH:mm:ssZ)
            end_date: End date (YYYY-MM-DDTHH:mm:ssZ)
            size: Number of events to retrieve (max 200)
            classification_names: Event categories (Music, Arts & Theatre, Sports, etc.)
            keyword: Search keyword
        """
        url = f"{self.base_url}{event_type}.json"
        
        # Default date range: next 30 days
        if not start_date:
            start_date = datetime.now().strftime("%Y-%m-%dT00:00:00Z")
        if not end_date:
            end_date = (datetime.now() + timedelta(days=30)).strftime("%Y-%m-%dT23:59:59Z")
        
        params = {
            'apikey': self.api_key,
            'latlong': f"{TORONTO_COORDINATES['latitude']},{TORONTO_COORDINATES['longitude']}",
            'radius': TORONTO_COORDINATES['radius'],
            'unit': 'km',
            'startDateTime': start_date,
            'endDateTime': end_date,
            'size': size,
            'sort': 'date,asc',
            'locale': 'en-ca'
        }
        
        if classification_names:
            params['classificationName'] = classification_names
        if keyword:
            params['keyword'] = keyword
            
        try:
            print(f"🎫 Fetching events from Ticketmaster API...")
            response = self.session.get(url, params=params)
            response.raise_for_status()
            
            data = response.json()
            events = data.get('_embedded', {}).get('events', [])
            
            print(f"📅 Found {len(events)} events")
            return events
            
        except requests.exceptions.RequestException as e:
            print(f"❌ Error fetching Ticketmaster data: {e}")
            return []
        except json.JSONDecodeError as e:
            print(f"❌ Error parsing Ticketmaster response: {e}")
            return []
    
    def extract_event_data(self, event):
        """Extract relevant data from a Ticketmaster event"""
        try:
            # Basic event information
            event_data = {
                'event_id': event.get('id', ''),
                'name': event.get('name', ''),
                'type': event.get('type', ''),
                'url': event.get('url', ''),
                'info': event.get('info', ''),
                'please_note': event.get('pleaseNote', ''),
                'price_ranges': self.extract_price_info(event.get('priceRanges', [])),
                'sales_public': event.get('sales', {}).get('public', {})
            }
            
            # Date and time information
            dates = event.get('dates', {})
            event_data['start_date'] = dates.get('start', {}).get('localDate', '')
            event_data['start_time'] = dates.get('start', {}).get('localTime', '')
            event_data['timezone'] = dates.get('timezone', '')
            event_data['status'] = dates.get('status', {}).get('code', '')
            
            # Venue information
            venues = event.get('_embedded', {}).get('venues', [])
            if venues:
                venue = venues[0]
                event_data['venue_name'] = venue.get('name', '')
                event_data['venue_address'] = self.format_address(venue.get('address', {}))
                event_data['venue_city'] = venue.get('city', {}).get('name', '')
                event_data['venue_postal_code'] = venue.get('postalCode', '')
                event_data['venue_location'] = venue.get('location', {})
                event_data['venue_accessibility'] = venue.get('accessibility', {})
                event_data['venue_parking'] = venue.get('parkingDetail', '')
            else:
                event_data.update({
                    'venue_name': '', 'venue_address': '', 'venue_city': '',
                    'venue_postal_code': '', 'venue_location': {},
                    'venue_accessibility': {}, 'venue_parking': ''
                })
            
            # Classifications (genre, segment, etc.)
            classifications = event.get('classifications', [])
            if classifications:
                classification = classifications[0]
                event_data['segment'] = classification.get('segment', {}).get('name', '')
                event_data['genre'] = classification.get('genre', {}).get('name', '')
                event_data['sub_genre'] = classification.get('subGenre', {}).get('name', '')
                event_data['family'] = classification.get('family', {}).get('name', '')
            else:
                event_data.update({
                    'segment': '', 'genre': '', 'sub_genre': '', 'family': ''
                })
            
            # Promoter information
            promoters = event.get('promoters', [])
            if promoters:
                event_data['promoter'] = promoters[0].get('name', '')
            else:
                event_data['promoter'] = ''
            
            # Images
            images = event.get('images', [])
            event_data['images'] = [img.get('url', '') for img in images]
            
            # Products (ticket info)
            products = event.get('products', [])
            event_data['products'] = len(products)
            
            # Calculate event mood/vibe
            event_data['mood_tags'] = self.analyze_event_mood(event_data)
            
            # Analyze accessibility and family-friendliness
            event_data['accessibility_score'] = self.calculate_accessibility_score(event_data)
            event_data['family_friendly_score'] = self.calculate_family_friendly_score(event_data)
            
            return event_data
            
        except Exception as e:
            print(f"⚠️  Error extracting event data: {e}")
            return None
    
    def extract_price_info(self, price_ranges):
        """Extract price information from price ranges"""
        if not price_ranges:
            return {'min': 0, 'max': 0, 'currency': 'CAD'}
        
        prices = []
        currency = 'CAD'
        
        for price_range in price_ranges:
            if 'min' in price_range:
                prices.append(price_range['min'])
            if 'max' in price_range:
                prices.append(price_range['max'])
            currency = price_range.get('currency', 'CAD')
        
        return {
            'min': min(prices) if prices else 0,
            'max': max(prices) if prices else 0,
            'currency': currency
        }
    
    def format_address(self, address):
        """Format venue address"""
        if not address:
            return ''
        
        parts = []
        if 'line1' in address:
            parts.append(address['line1'])
        if 'line2' in address:
            parts.append(address['line2'])
        
        return ', '.join(parts)
    
    def analyze_event_mood(self, event_data):
        """Analyze event mood based on type, genre, and description"""
        mood_tags = []
        
        # Combine text fields for analysis
        text_fields = [
            event_data.get('name', ''),
            event_data.get('info', ''),
            event_data.get('genre', ''),
            event_data.get('sub_genre', ''),
            event_data.get('segment', '')
        ]
        
        full_text = ' '.join(text_fields).lower()
        
        # Mood indicators
        mood_indicators = {
            'romantic': [
                'romantic', 'intimate', 'acoustic', 'jazz', 'classical', 'chamber',
                'date night', 'couples', 'wine', 'candlelight', 'valentine'
            ],
            'energetic': [
                'rock', 'electronic', 'dance', 'party', 'club', 'festival',
                'edm', 'hip hop', 'punk', 'metal', 'high energy', 'rave'
            ],
            'cultural': [
                'theatre', 'opera', 'ballet', 'symphony', 'museum', 'gallery',
                'cultural', 'heritage', 'traditional', 'folk', 'ethnic'
            ],
            'family': [
                'family', 'kids', 'children', 'disney', 'cartoon', 'puppet',
                'educational', 'matinee', 'all ages'
            ],
            'outdoor': [
                'outdoor', 'festival', 'park', 'beach', 'summer', 'patio',
                'garden', 'rooftop', 'open air', 'street'
            ],
            'nightlife': [
                'nightlife', 'club', 'late night', 'after hours', 'bar',
                'lounge', 'cocktail', 'dj', 'dancing'
            ],
            'foodie': [
                'food', 'wine', 'beer', 'tasting', 'culinary', 'chef',
                'restaurant', 'dining', 'gourmet', 'foodie'
            ],
            'artistic': [
                'art', 'gallery', 'exhibition', 'creative', 'design',
                'installation', 'performance art', 'avant-garde'
            ]
        }
        
        # Check for mood indicators
        for mood, keywords in mood_indicators.items():
            score = sum(1 for keyword in keywords if keyword in full_text)
            if score > 0:
                mood_tags.append(mood.title())
        
        # Price-based mood
        price_min = event_data.get('price_ranges', {}).get('min', 0)
        if price_min == 0:
            mood_tags.append('Free')
        elif price_min < 30:
            mood_tags.append('Budget')
        elif price_min > 100:
            mood_tags.append('Premium')
        
        # Time-based mood
        start_time = event_data.get('start_time', '')
        if start_time:
            try:
                hour = int(start_time.split(':')[0])
                if hour < 12:
                    mood_tags.append('Morning')
                elif hour < 17:
                    mood_tags.append('Afternoon')
                elif hour < 22:
                    mood_tags.append('Evening')
                else:
                    mood_tags.append('Late Night')
            except:
                pass
        
        return list(set(mood_tags)) if mood_tags else ['General']
    
    def calculate_accessibility_score(self, event_data):
        """Calculate accessibility score based on venue info"""
        score = 0
        accessibility = event_data.get('venue_accessibility', {})
        
        if accessibility.get('wheelchair', False):
            score += 30
        if accessibility.get('assistiveListening', False):
            score += 20
        if accessibility.get('visuallyImpaired', False):
            score += 20
        if accessibility.get('hearingImpaired', False):
            score += 20
        if event_data.get('venue_parking'):
            score += 10
        
        return min(score, 100)
    
    def calculate_family_friendly_score(self, event_data):
        """Calculate family-friendly score"""
        score = 0
        
        # Check for family-friendly indicators
        text_fields = [
            event_data.get('name', ''),
            event_data.get('info', ''),
            event_data.get('genre', '')
        ]
        
        full_text = ' '.join(text_fields).lower()
        
        family_indicators = [
            'family', 'kids', 'children', 'all ages', 'matinee',
            'educational', 'disney', 'cartoon', 'puppet'
        ]
        
        for indicator in family_indicators:
            if indicator in full_text:
                score += 20
        
        # Time factor (earlier = more family friendly)
        start_time = event_data.get('start_time', '')
        if start_time:
            try:
                hour = int(start_time.split(':')[0])
                if hour < 18:
                    score += 20
                elif hour > 22:
                    score -= 20
            except:
                pass
        
        # Price factor (lower price = more accessible to families)
        price_min = event_data.get('price_ranges', {}).get('min', 0)
        if price_min == 0:
            score += 30
        elif price_min < 50:
            score += 10
        
        return max(0, min(score, 100))
    
    def collect_toronto_events(self, 
                              days_ahead=30, 
                              include_categories=None,
                              keywords=None):
        """Collect comprehensive event data for Toronto"""
        
        all_events = []
        
        print(f"🎭 Collecting Toronto events for next {days_ahead} days...")
        
        try:
            # First batch: Get all events without filters for maximum coverage
            print(f"  🌟 Collecting all available events...")
            
            # Use pagination to get more than 200 events
            page = 0
            while True:
                events = self.get_events(
                    size=200,  # Maximum allowed per page
                    end_date=(datetime.now() + timedelta(days=days_ahead)).strftime("%Y-%m-%dT23:59:59Z")
                )
                
                if not events:
                    break
                    
                for event in events:
                    event_data = self.extract_event_data(event)
                    if event_data:
                        event_data['category'] = 'General'
                        all_events.append(event_data)
                
                page += 1
                if len(events) < 200:  # No more pages
                    break
                    
                time.sleep(1)  # Rate limiting
            
            # Second batch: Search with keywords for additional coverage
            if keywords:
                for keyword in keywords:
                    print(f"  🔍 Searching for '{keyword}' events...")
                    try:
                        events = self.get_events(
                            keyword=keyword,
                            size=100,
                            end_date=(datetime.now() + timedelta(days=days_ahead)).strftime("%Y-%m-%dT23:59:59Z")
                        )
                        
                        for event in events:
                            event_data = self.extract_event_data(event)
                            if event_data and not any(e['event_id'] == event_data['event_id'] for e in all_events):
                                event_data['category'] = f'Keyword: {keyword}'
                                all_events.append(event_data)
                    except Exception as e:
                        print(f"⚠️ Error collecting events for keyword '{keyword}': {e}")
                    
                    time.sleep(1)  # Rate limiting between keyword searches
            
            # Remove duplicates based on event_id
            unique_events = []
            seen_ids = set()
            for event in all_events:
                if event['event_id'] not in seen_ids:
                    unique_events.append(event)
                    seen_ids.add(event['event_id'])
            
            print(f"✅ Successfully collected {len(unique_events)} unique events from Ticketmaster")
            return unique_events
            
        except Exception as e:
            print(f"❌ Error in collect_toronto_events: {e}")
            # Return any events we managed to collect before the error
            if all_events:
                print(f"⚠️ Returning {len(all_events)} events collected before error")
                return all_events
            return []
    
    def save_events_data(self, events, timestamp=None):
        """Save collected events data to CSV"""
        if not events:
            print("No events to save")
            return None
        
        if timestamp is None:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        
        # Create DataFrame
        events_df = pd.DataFrame(events)
        
        # Save to CSV
        filename = f"data/ticketmaster_events_{timestamp}.csv"
        events_df.to_csv(filename, index=False)
        
        print(f"💾 Saved {len(events)} events to {filename}")
        return filename

if __name__ == "__main__":
    collector = TicketmasterCollector()
    
    # Collect events with food/culinary focus
    keywords = ['food', 'wine', 'beer', 'culinary', 'tasting', 'festival']
    events = collector.collect_toronto_events(
        days_ahead=30,
        keywords=keywords
    )
    
    if events:
        collector.save_events_data(events)
        
        # Show sample events
        print(f"\n🎉 Sample Events Found:")
        for i, event in enumerate(events[:5], 1):
            print(f"{i}. {event['name']}")
            print(f"   📅 {event['start_date']} at {event['start_time']}")
            print(f"   📍 {event['venue_name']}")
            print(f"   🎭 Moods: {', '.join(event['mood_tags'])}")
            print(f"   💰 Price: ${event['price_ranges']['min']}-${event['price_ranges']['max']} {event['price_ranges']['currency']}")
            print()
    else:
        print("No events collected from Ticketmaster") 