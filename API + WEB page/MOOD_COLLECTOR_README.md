# 🎭 Toronto Mood & Events Collector - Executable App

## Quick Start - Double-Click to Launch! 

You now have **two ways** to launch your comprehensive mood collection and event discovery process without typing terminal commands:

### 🍎 Option 1: macOS App Bundle (Recommended)
Double-click: **`Toronto Mood Collector.app`**
- Native macOS app with notifications
- Runs in background with progress updates
- Shows completion dialog when done
- Collects both restaurant data AND events

### 📜 Option 2: Command Script  
Double-click: **`launch_mood_collector.command`**
- Shows detailed terminal output
- Step-by-step progress visible
- More verbose feedback during execution
- Full process transparency

## 🎯 What These Scripts Do

Both executables run the **complete Toronto discovery process**:

### 🍽️ **Restaurant & Hidden Gems Discovery**
1. **🔧 Environment Setup**
   - Creates Python virtual environment (if needed)
   - Installs all required dependencies
   - Verifies Reddit API access

2. **📱 Reddit Data Collection** (`python3 scripts/run.py recommendations`)
   - Uses `RedditRecommendationCollector` (read-only, no authentication required)
   - Collects restaurant recommendations from Toronto subreddits
   - Extracts sentiment and quality indicators
   - Saves data to `data/reddit_recommendation_*.csv`

3. **💎 Hidden Gems Analysis** (`python3 scripts/run.py find-recs`)
   - Uses `HiddenGemsFinderRecommendations` with mood tagging
   - Analyzes mood patterns: Romantic, Foodie, Budget, Cultural, etc.
   - Combines Reddit data with DineSafe inspection scores
   - Finds underrated gems with high quality but low visibility
   - Saves results to `data/hidden_gems_*.csv`

### 🎭 **Events Discovery** (NEW!)
4. **🎪 Event Collection** (`python3 scripts/run.py events`)
   - **Reddit Events**: Collects event discussions from Toronto subreddits
   - **Ticketmaster API**: Fetches official events in Toronto area (30km radius)
   - Gathers concerts, festivals, art shows, food events, cultural events
   - Extracts venue info, dates, prices, and event types

5. **🎯 Hidden Gem Events** (`python3 scripts/run.py find-events`)
   - Uses `EventFinder` to combine Reddit buzz with Ticketmaster data
   - Finds underrated events with great potential
   - Analyzes accessibility, family-friendliness, and mood tags
   - Identifies free events, underground shows, and unique experiences
   - Saves results to `data/hidden_gem_events_*.csv`

## 🎭 Mood Tagging Features

The mood analysis assigns tags based on:

### 🍽️ **Restaurant Moods**
- **Keywords in Reddit comments**: "date night", "family-friendly", "cheap eats"
- **Restaurant type**: Fine dining → Romantic, Food trucks → Adventure
- **Location patterns**: King St → Foodie, Chinatown → Cultural
- **Sentiment analysis**: Positive language → Higher mood scores

### 🎪 **Event Moods**
- **Event type**: Concert → Energetic, Gallery → Artistic, Wine tasting → Foodie
- **Venue size**: Intimate venues → Underground, Large venues → Mainstream
- **Price point**: Free → Budget, $100+ → Premium
- **Time of day**: Morning → Family, Late night → Nightlife

**Available Mood Tags:**
- 💑 **Romantic**: Date spots, intimate venues, wine bars
- 🍽️ **Foodie**: Gourmet, artisan, chef-driven experiences
- 🌟 **Adventure**: Unique, ethnic, hole-in-the-wall discoveries
- 🌿 **Relaxing**: Cafes, peaceful spots, casual hangouts
- 👨‍👩‍👧‍👦 **Family**: Kid-friendly, family restaurants & events
- 🎭 **Cultural**: Authentic ethnic, heritage spots, art shows
- 🌙 **Nightlife**: Bars, late-night, drinks, clubs
- 💰 **Budget**: Affordable, student-friendly, value options
- 🎁 **Free**: No-cost events and experiences
- ⚡ **Energetic**: High-energy concerts, festivals, sports
- 🎨 **Artistic**: Creative, avant-garde, galleries, design
- 🌲 **Outdoor**: Parks, patios, summer events, markets

## 📊 Results & Output

After completion, check these folders:
- **`data/`**: CSV files with raw Reddit data, restaurant analysis, and event discoveries
- **`mood_events_collection.log`**: Detailed execution log
- **Web Interface**: Run `python3 web_app.py` to explore results

### 🌐 **Web App Features**
- **📍 Homepage**: Quick stats and top discoveries
- **💎 Hidden Gems**: Browse mood-tagged restaurants
- **🎭 Events**: Discover upcoming events by mood and type
- **📊 Analytics**: Data insights and trends
- **🎨 Mood Explorer**: Filter by romantic, foodie, budget, etc.

## 🔧 Troubleshooting

### App Won't Launch?
1. **Security Warning**: Right-click app → "Open" → "Open" again
2. **Python Missing**: Install Python 3.8+ from python.org
3. **Permissions**: Run `chmod +x "Toronto Mood Collector.app/Contents/MacOS/Toronto Mood Collector"`

### No Data Collected?
- Check internet connection
- Verify Reddit is accessible
- Check Ticketmaster API status
- Look at `mood_events_collection.log` for detailed errors

### Reddit API Issues?
- The app uses **read-only** access (no API keys required)
- If Reddit blocks requests, try again later
- Reddit has rate limits - the app includes delays

### Ticketmaster API Issues?
- API keys are included in config
- Limited to 1000 requests per day
- Geographic search focused on Toronto (43.6532, -79.3832, 50km radius)

## 🚀 Next Steps

1. **Run the executable** - Double-click either app option
2. **Wait for completion** - Process takes 10-25 minutes (now includes events!)
3. **View results** - Run `python3 web_app.py` for web interface
4. **Explore discoveries** - Filter by mood, type, price, and date
5. **Plan your adventures** - Use mood tags to find perfect spots and events

## 📱 Web App URLs (after running `python3 web_app.py`)

- **🏠 Homepage**: http://localhost:8000
- **💎 Hidden Gems**: http://localhost:8000/gems
- **🎭 Events**: http://localhost:8000/events
- **📊 Analytics**: http://localhost:8000/analytics
- **🎨 Mood Explorer**: http://localhost:8000/moods
- **📖 API Docs**: http://localhost:8000/documentation

## 📝 Technical Details

The executable replaces this manual command sequence:
```bash
cd "/path/to/your/app" && \
python3 -m venv venv && \
source venv/bin/activate && \
python3 -m pip install -r config/requirements.txt && \
python3 scripts/run.py recommendations && \
python3 scripts/run.py find-recs && \
python3 scripts/run.py events && \
python3 scripts/run.py find-events
```

**Key Scripts Used:**
- `scripts/run.py recommendations` → Collects Reddit recommendation data
- `scripts/run.py find-recs` → Finds hidden gems with mood analysis
- `scripts/run.py events` → Collects events from Reddit + Ticketmaster
- `scripts/run.py find-events` → Finds hidden gem events with mood tags

**Key Components:**
- `src/collectors/reddit_collector_recommendations.py` → Read-only Reddit collector
- `src/collectors/reddit_events_collector.py` → Event-focused Reddit collector
- `src/collectors/ticketmaster_collector.py` → Ticketmaster API integration
- `src/finders/hidden_gems_finder_recommendations.py` → Restaurant mood tagging
- `src/finders/event_finder.py` → Event discovery and mood analysis

## 🎉 What You'll Discover

### 🍽️ **Hidden Gem Restaurants**
- Underrated spots with high quality scores
- Mood-tagged for easy discovery
- DineSafe inspection data included
- Reddit community recommendations

### 🎭 **Hidden Gem Events**
- Underground concerts and art shows
- Free community events
- Food festivals and tastings
- Cultural celebrations
- Intimate venues and unique experiences

---

🎉 **Enjoy discovering Toronto's hidden gems AND events with comprehensive mood insights!** 🎭🍽️ 