#!/bin/bash

# Toronto Mood & Events Collector - Simple Launcher
# Double-click this file to run mood collection and event discovery

clear
echo "🎭 =================================="
echo "🎭 Toronto Mood & Events Collector"
echo "💎 Hidden Gems Finder with Mood Tagging"
echo "🎪 Event Discovery (Reddit + Ticketmaster)"
echo "🎭 =================================="
echo ""

# Get the directory where this script is located
cd "$(dirname "$0")"

echo "📍 Current directory: $(pwd)"
echo ""

# Check if Python 3 is available
if ! command -v python3 &> /dev/null; then
    echo "❌ Error: Python 3 is not installed"
    echo "Please install Python 3 and try again."
    echo ""
    echo "Press any key to exit..."
    read -n 1
    exit 1
fi

echo "✅ Python 3 found: $(python3 --version)"
echo ""

# Create virtual environment if it doesn't exist
if [ ! -d "venv" ]; then
    echo "🔧 Creating Python virtual environment..."
    python3 -m venv venv
    echo "✅ Virtual environment created"
else
    echo "✅ Virtual environment found"
fi
echo ""

# Activate virtual environment
echo "⚡ Activating virtual environment..."
source venv/bin/activate
echo "✅ Virtual environment activated"
echo ""

# Install/update requirements
echo "📦 Installing/updating dependencies..."
if [ -f "config/requirements.txt" ]; then
    echo "Installing from config/requirements.txt..."
    python3 -m pip install -r config/requirements.txt
else
    echo "Installing from requirements.txt..."
    python3 -m pip install -r requirements.txt
fi
echo "✅ Dependencies installed"
echo ""

echo "🎯 Starting comprehensive data collection..."
echo "This will collect restaurant recommendations, analyze mood patterns, and discover events."
echo ""

# Run the mood tagging collection
echo "📱 Step 1: Collecting recommendation data with mood analysis..."
python3 scripts/run.py recommendations

echo ""
echo "💎 Step 2: Finding hidden gems with mood analysis..."
python3 scripts/run.py find-recs

echo ""
echo "🎭 Step 3: Collecting events from Reddit and Ticketmaster..."
python3 scripts/run.py events

echo ""
echo "🎪 Step 4: Finding hidden gem events..."
python3 scripts/run.py find-events

echo ""
echo "🎉 ====================================="
echo "✅ Mood & Events collection complete!"
echo "📄 Results saved to data folder"
echo "🎭 Mood tags analyzed and applied"
echo "💎 Hidden gems identified"
echo "🎪 Events discovered and categorized"
echo "🎉 ====================================="
echo ""
echo "📊 To view results in web browser:"
echo "   python3 web_app.py"
echo ""
echo "📍 Web app will be available at:"
echo "   http://localhost:8000"
echo ""
echo "🔗 Quick links:"
echo "   • Hidden Gems: http://localhost:8000/gems"
echo "   • Events: http://localhost:8000/events"
echo "   • Analytics: http://localhost:8000/analytics"
echo "   • Mood Explorer: http://localhost:8000/moods"
echo ""
echo "Press any key to close..."
read -n 1 