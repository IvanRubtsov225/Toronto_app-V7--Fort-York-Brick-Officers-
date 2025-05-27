"""
Data Collectors Package

Contains modules for collecting data from various sources:
- Reddit API for community insights
- Read-only Reddit collector for authentication-free access
- Recommendation-focused Reddit collector for targeted data collection
"""

from .reddit_collector_readonly import RedditCollectorReadOnly
from .reddit_collector_recommendations import RedditRecommendationCollector

try:
    from .reddit_collector import RedditCollector
except ImportError:
    # Fallback if authentication fails
    RedditCollector = RedditCollectorReadOnly

__all__ = ['RedditCollector', 'RedditCollectorReadOnly', 'RedditRecommendationCollector'] 