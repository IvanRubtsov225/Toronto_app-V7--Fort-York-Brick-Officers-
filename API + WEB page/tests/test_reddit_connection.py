#!/usr/bin/env python3
"""
Test Reddit API connection and debug authentication issues
"""

import praw
import sys
import os
sys.path.append(os.path.join(os.path.dirname(__file__), '..'))
from config.config import *

def test_reddit_connection():
    """Test Reddit API connection"""
    print("🧪 Testing Reddit API Connection...")
    print(f"Client ID: {REDDIT_CLIENT_ID}")
    print(f"Username: {REDDIT_USERNAME}")
    print(f"User Agent: {REDDIT_USER_AGENT}")
    
    try:
        # Initialize Reddit instance
        reddit = praw.Reddit(
            client_id=REDDIT_CLIENT_ID,
            client_secret=REDDIT_CLIENT_SECRET,
            username=REDDIT_USERNAME,
            password=REDDIT_PASSWORD,
            user_agent=REDDIT_USER_AGENT
        )
        
        # Test authentication
        print("\n🔐 Testing authentication...")
        user = reddit.user.me()
        print(f"✅ Successfully authenticated as: {user.name}")
        
        # Test subreddit access
        print("\n📱 Testing subreddit access...")
        subreddit = reddit.subreddit('toronto')
        print(f"✅ Successfully accessed r/toronto")
        print(f"   Subscribers: {subreddit.subscribers:,}")
        print(f"   Description: {subreddit.public_description[:100]}...")
        
        # Test getting posts
        print("\n📄 Testing post retrieval...")
        posts = list(subreddit.hot(limit=5))
        print(f"✅ Successfully retrieved {len(posts)} posts")
        
        for i, post in enumerate(posts, 1):
            print(f"   {i}. {post.title[:60]}...")
            print(f"      Score: {post.score}, Comments: {post.num_comments}")
        
        # Test food-related posts
        print("\n🍽️ Testing food-related post filtering...")
        food_posts = []
        for post in subreddit.hot(limit=20):
            full_text = post.title + " " + (post.selftext or "")
            if any(keyword in full_text.lower() for keyword in FOOD_KEYWORDS):
                food_posts.append(post)
        
        print(f"✅ Found {len(food_posts)} food-related posts out of 20")
        
        for i, post in enumerate(food_posts[:3], 1):
            print(f"   {i}. {post.title}")
        
        return True
        
    except Exception as e:
        if "invalid_grant" in str(e):
            print(f"❌ Authentication Failed: {e}")
            print("💡 This usually means:")
            print("   1. Incorrect username/password")
            print("   2. Two-factor authentication is enabled")
            print("   3. Reddit app configuration mismatch")
            print("   4. Account doesn't have API access")
            return False
        elif "ResponseException" in str(type(e)):
            print(f"❌ Reddit API Response Error: {e}")
            print("💡 Check your credentials in config.py")
            return False
        else:
            print(f"❌ Unexpected error: {e}")
            print(f"   Error type: {type(e).__name__}")
            return False

def test_specific_subreddits():
    """Test access to specific Toronto subreddits"""
    print("\n🏙️ Testing Toronto subreddits...")
    
    reddit = praw.Reddit(
        client_id=REDDIT_CLIENT_ID,
        client_secret=REDDIT_CLIENT_SECRET,
        username=REDDIT_USERNAME,
        password=REDDIT_PASSWORD,
        user_agent=REDDIT_USER_AGENT
    )
    
    for subreddit_name in TORONTO_SUBREDDITS[:5]:  # Test first 5
        try:
            subreddit = reddit.subreddit(subreddit_name)
            posts = list(subreddit.hot(limit=3))
            print(f"✅ r/{subreddit_name}: {len(posts)} posts retrieved")
        except Exception as e:
            print(f"❌ r/{subreddit_name}: {e}")

if __name__ == "__main__":
    print("🍽️ Toronto Hidden Gems - Reddit Connection Test")
    print("=" * 50)
    
    success = test_reddit_connection()
    
    if success:
        test_specific_subreddits()
        print("\n🎉 Reddit connection test completed successfully!")
        print("💡 You can now run the main application.")
    else:
        print("\n⚠️ Reddit connection failed.")
        print("\n🔧 Troubleshooting steps:")
        print("1. Go to https://www.reddit.com/prefs/apps")
        print("2. Click 'edit' on your 'Toronto app V2' application")
        print("3. Ensure it's configured as 'script' type")
        print("4. Set redirect URI to: http://localhost:8080")
        print("5. Verify your username and password are correct")
        print("6. Make sure your account has API access enabled") 