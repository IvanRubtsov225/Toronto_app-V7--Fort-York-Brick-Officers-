import os

# Reddit API Configuration
REDDIT_CLIENT_ID = "IZcXFFPrUwhhHkfxG6Ga6Q"
REDDIT_CLIENT_SECRET = "Gpr8FgVTED_Ld6jgx2hyrI6J4e3JOQ"
REDDIT_USERNAME = "xX_danker_Xx"
REDDIT_PASSWORD = "Jeffry420"
REDDIT_USER_AGENT = "Toronto app V2:IZcXFFPrUwhhHkfxG6Ga6Q:1.0 (by /u/xX_danker_Xx)"

# Toronto Subreddits to monitor
TORONTO_SUBREDDITS = [
    'toronto',
    'askTO',
    'TorontoEats',
    'TorontoEvents',
    'TorontoAnarchy',
    'GTAMarketPlace',
    'TorontoRealEstate',
    'TorontoJobs',
    'UofT',
    'ryerson',
    'yorku'
]

# Keywords for finding hidden gems
HIDDEN_GEM_KEYWORDS = [
    'hidden gem', 'secret spot', 'underrated', 'hole in the wall',
    'local favorite', 'best kept secret', 'off the beaten path',
    'locals only', 'authentic', 'family owned', 'mom and pop',
    'dive bar', 'hole-in-the-wall', 'tucked away', 'small business',
    'neighborhood', 'cozy', 'intimate', 'unique', 'special place'
]

# Food-related keywords
FOOD_KEYWORDS = [
    'restaurant', 'cafe', 'bar', 'pub', 'bistro', 'eatery',
    'food truck', 'bakery', 'deli', 'market', 'grocery',
    'takeout', 'delivery', 'dining', 'brunch', 'lunch',
    'dinner', 'breakfast', 'coffee', 'tea', 'dessert'
]

# DineSafe data configuration
DINESAFE_FILE = "data/Dine Safe Data .csv"

# Scoring weights for hidden gem algorithm
SCORING_WEIGHTS = {
    'reddit_mentions': 0.3,
    'sentiment_score': 0.25,
    'dinesafe_score': 0.25,
    'uniqueness_score': 0.2
} 