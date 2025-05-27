# 🍽️ Toronto Hidden Gems Finder

A sophisticated data-driven application that discovers hidden culinary gems in Toronto by combining hyperlocal Reddit insights with official DineSafe inspection data.

## 🎯 Overview

This application intelligently identifies underrated restaurants and food establishments in Toronto by:

- **Reddit Analysis**: Scraping Toronto-related subreddits for restaurant mentions and sentiment analysis
- **DineSafe Integration**: Analyzing official Toronto health inspection data for safety scores
- **Smart Matching**: Using fuzzy string matching to connect Reddit mentions with official establishments
- **Scoring Algorithm**: Combining multiple factors to identify true "hidden gems"

## 🚀 Features

### Data Collection
- **Reddit API Integration**: Collects posts and comments from 11 Toronto subreddits
- **Sentiment Analysis**: Uses TextBlob for sentiment scoring of mentions
- **Location Extraction**: Advanced regex patterns to identify restaurant names
- **DineSafe Processing**: Analyzes 27MB+ of Toronto health inspection data

### Smart Scoring System
- **Reddit Score** (30%): Based on mention frequency, sentiment, and hidden gem keywords
- **Sentiment Score** (25%): Positive/negative sentiment from Reddit discussions
- **DineSafe Score** (25%): Health inspection performance and safety record
- **Uniqueness Score** (20%): Rarity and establishment type factors

### Interactive Dashboard
- **Interactive Map**: Plotly-powered map showing hidden gems across Toronto
- **Real-time Filtering**: Filter by score, establishment type, and mention count
- **Data Visualization**: Charts showing score distributions and type breakdowns
- **Detailed Tables**: Sortable tables with comprehensive establishment data

## 📊 Data Sources

### Reddit Data
- **Subreddits Monitored**:
  - r/toronto, r/askTO, r/TorontoEats
  - r/TorontoEvents, r/TorontoAnarchy
  - r/GTAMarketPlace, r/UofT, r/ryerson, r/yorku

### DineSafe Data
- Official Toronto Public Health inspection records
- Establishment details, inspection dates, violations
- Geographic coordinates for mapping
- Safety scores and compliance history

## 🛠️ Installation

### Prerequisites
- Python 3.8+
- Reddit API credentials (see setup below)

### Setup

1. **Clone the repository**
```bash
git clone <repository-url>
cd toronto-hidden-gems
```

2. **Install dependencies**
```bash
pip install -r requirements.txt
```

3. **Reddit API Setup**
   - Go to https://www.reddit.com/prefs/apps
   - Create a new application (script type)
   - Update `config.py` with your credentials:
   ```python
   REDDIT_CLIENT_ID = "your_client_id"
   REDDIT_CLIENT_SECRET = "your_client_secret"
   REDDIT_USERNAME = "your_username"
   REDDIT_PASSWORD = "your_password"
   ```

4. **Ensure DineSafe data is present**
   - The `Dine Safe Data .csv` file should be in the project directory
   - This contains Toronto's official restaurant inspection data

## 🎮 Usage

### Quick Start - Dashboard
```bash
python dashboard.py
```
Then open http://localhost:8050 in your browser.

### Command Line Usage

#### Analyze DineSafe Data Only
```bash
python dinesafe_analyzer.py
```

#### Collect Reddit Data
```bash
python reddit_collector.py
```

#### Find Hidden Gems
```bash
python hidden_gems_finder.py
```

### Programmatic Usage

```python
from hidden_gems_finder import HiddenGemsFinder

# Initialize the finder
finder = HiddenGemsFinder()

# Collect Reddit data
finder.load_or_collect_reddit_data(use_existing=False)

# Find hidden gems with custom parameters
hidden_gems = finder.find_hidden_gems(
    min_dinesafe_score=75,    # Minimum health inspection score
    min_reddit_mentions=2,    # Minimum Reddit mentions
    max_reddit_mentions=8     # Maximum mentions (too many = not hidden)
)

# Get top results
top_gems = finder.get_top_hidden_gems(limit=20)

# Export results
finder.export_results("my_hidden_gems.csv")
```

## 📈 Scoring Algorithm

The hidden gem score combines four key factors:

### 1. Reddit Mentions (30% weight)
- Mention frequency across subreddits
- Presence of "hidden gem" keywords
- Subreddit diversity

### 2. Sentiment Score (25% weight)
- Average sentiment of Reddit mentions
- Positive sentiment indicates quality
- Range: -1 (negative) to +1 (positive)

### 3. DineSafe Score (25% weight)
- Based on inspection history
- Penalizes violations and infractions
- Rewards consistent passing grades
- Considers inspection recency

### 4. Uniqueness Score (20% weight)
- Lower mention count = higher uniqueness
- Establishment type rarity
- "Hidden" nature preservation

## 🗂️ File Structure

```
toronto-hidden-gems/
├── config.py                 # Configuration and API credentials
├── reddit_collector.py       # Reddit data collection
├── dinesafe_analyzer.py      # DineSafe data analysis
├── hidden_gems_finder.py     # Main hidden gems algorithm
├── dashboard.py              # Interactive web dashboard
├── requirements.txt          # Python dependencies
├── README.md                 # This file
└── Dine Safe Data .csv       # Toronto inspection data (27MB)
```

## 🎛️ Configuration

### Scoring Weights (config.py)
```python
SCORING_WEIGHTS = {
    'reddit_mentions': 0.3,    # 30%
    'sentiment_score': 0.25,   # 25%
    'dinesafe_score': 0.25,    # 25%
    'uniqueness_score': 0.2    # 20%
}
```

### Subreddits Monitored
```python
TORONTO_SUBREDDITS = [
    'toronto', 'askTO', 'TorontoEats', 'TorontoEvents',
    'TorontoAnarchy', 'GTAMarketPlace', 'TorontoRealEstate',
    'TorontoJobs', 'UofT', 'ryerson', 'yorku'
]
```

### Hidden Gem Keywords
```python
HIDDEN_GEM_KEYWORDS = [
    'hidden gem', 'secret spot', 'underrated', 'hole in the wall',
    'local favorite', 'best kept secret', 'off the beaten path',
    'locals only', 'authentic', 'family owned', 'mom and pop'
]
```

## 📊 Output Data

### Hidden Gems CSV Columns
- `name`: Establishment name
- `address`: Full address
- `type`: Establishment type (Restaurant, Cafe, etc.)
- `latitude/longitude`: Geographic coordinates
- `hidden_gem_score`: Final calculated score (0-100)
- `dinesafe_score`: Health inspection score
- `reddit_score`: Reddit-based score
- `uniqueness_score`: Rarity score
- `mention_count`: Number of Reddit mentions
- `avg_sentiment`: Average sentiment (-1 to +1)
- `hidden_gem_mentions`: Explicit "hidden gem" mentions

## 🔧 Advanced Features

### Custom Filtering
```python
# Find only bakeries with high scores
bakery_gems = finder.get_top_hidden_gems(
    limit=10, 
    establishment_type="bakery"
)

# Custom scoring parameters
gems = finder.find_hidden_gems(
    min_dinesafe_score=80,     # Higher safety standard
    min_reddit_mentions=1,     # Allow single mentions
    max_reddit_mentions=5      # Stricter "hidden" criteria
)
```

### Geographic Analysis
```python
# Find gems near specific location
analyzer = DineSafeAnalyzer()
nearby = analyzer.find_establishments_near_location(
    lat=43.6532, 
    lon=-79.3832, 
    radius_km=2.0
)
```

## 🚨 Rate Limiting & Ethics

- Reddit API calls are rate-limited (1 second between subreddits)
- Respects Reddit's API terms of service
- No personal data collection
- Public data only

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📝 License

This project is for educational and research purposes. Please respect Reddit's API terms and Toronto's open data policies.

## 🙏 Acknowledgments

- **Toronto Public Health** for DineSafe open data
- **Reddit API** for community insights
- **Toronto food community** for sharing hidden gems

## 📞 Support

For issues or questions:
1. Check existing GitHub issues
2. Create a new issue with detailed description
3. Include error logs and system information

---

**Happy gem hunting! 🍽️✨** 