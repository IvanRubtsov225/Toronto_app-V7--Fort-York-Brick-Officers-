import os

# Reddit API Configuration
REDDIT_CLIENT_ID = "IZcXFFPrUwhhHkfxG6Ga6Q"
REDDIT_CLIENT_SECRET = "Gpr8FgVTED_Ld6jgx2hyrI6J4e3JOQ"
REDDIT_USERNAME = "xX_danker_Xx"
REDDIT_PASSWORD = "Jeffry420"
REDDIT_USER_AGENT = "Toronto app V2:IZcXFFPrUwhhHkfxG6Ga6Q:1.0 (by /u/xX_danker_Xx)"

# Ticketmaster API Configuration
TICKETMASTER_CONSUMER_KEY = "ymnY9IJGuOeQGnMNiGwwFAdu5jYEmuNf"
TICKETMASTER_CONSUMER_SECRET = "dIB4oxxz42OfxZ6W"
TICKETMASTER_API_URL = "https://app.ticketmaster.com/discovery/v2/"

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

# Event-specific subreddits
EVENT_SUBREDDITS = [
    'TorontoEvents',
    'toronto',
    'askTO',
    'TorontoMusic',
    'TorontoNightlife',
    'TorontoFestivals'
]

# Keywords for finding hidden gems
HIDDEN_GEM_KEYWORDS = [
    'hidden gem', 'secret spot', 'underrated', 'hole in the wall',
    'local favorite', 'best kept secret', 'off the beaten path',
    'locals only', 'authentic', 'family owned', 'mom and pop',
    'dive bar', 'hole-in-the-wall', 'tucked away', 'small business',
    'neighborhood', 'cozy', 'intimate', 'unique', 'special place'
]

# Event-related keywords
EVENT_KEYWORDS = [
    'event', 'concert', 'festival', 'show', 'performance', 'exhibition',
    'market', 'fair', 'party', 'nightlife', 'club', 'live music',
    'theater', 'comedy', 'art show', 'gallery', 'museum', 'workshop',
    'meetup', 'gathering', 'celebration', 'happening', 'popup', 'outdoor',
    'food festival', 'wine tasting', 'beer garden', 'rooftop', 'patio'
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

# Toronto geographic boundaries (for Ticketmaster API)
TORONTO_COORDINATES = {
    'latitude': 43.6532,
    'longitude': -79.3832,
    'radius': '50'  # Include GTA (radius in km)
}

# Scoring weights for hidden gem algorithm
SCORING_WEIGHTS = {
    'reddit_mentions': 0.3,
    'sentiment_score': 0.25,
    'dinesafe_score': 0.25,
    'uniqueness_score': 0.2
}

# Event scoring weights
EVENT_SCORING_WEIGHTS = {
    'reddit_buzz': 0.3,
    'sentiment_score': 0.25,
    'ticketmaster_popularity': 0.2,
    'uniqueness_score': 0.25
} 