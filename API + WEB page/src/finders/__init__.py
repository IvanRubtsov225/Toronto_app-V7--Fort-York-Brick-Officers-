"""
Hidden Gems Finders Package

Contains modules for finding hidden gems by combining multiple data sources:
- Main hidden gems finder with full Reddit access
- Read-only hidden gems finder for authentication-free operation
- Recommendation-focused hidden gems finder for targeted analysis
"""

from .hidden_gems_finder_readonly import HiddenGemsFinderReadOnly
from .hidden_gems_finder_recommendations import HiddenGemsFinderRecommendations

try:
    from .hidden_gems_finder import HiddenGemsFinder
except ImportError:
    # Fallback if authentication fails
    HiddenGemsFinder = HiddenGemsFinderReadOnly

__all__ = ['HiddenGemsFinder', 'HiddenGemsFinderReadOnly', 'HiddenGemsFinderRecommendations'] 