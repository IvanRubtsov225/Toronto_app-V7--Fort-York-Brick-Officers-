#!/usr/bin/env python3
"""
Toronto Hidden Gems Finder - Main Entry Point

This is the main entry point for the Toronto Hidden Gems Finder application.
It provides easy access to all functionality through a simple command-line interface.
"""

import sys
import os

# Add the project root to Python path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

# Import and run the main script
from scripts.run import main

if __name__ == "__main__":
    main() 