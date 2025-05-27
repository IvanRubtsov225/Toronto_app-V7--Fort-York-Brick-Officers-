# 📁 Toronto Hidden Gems Finder - Project Structure

This document describes the organized folder structure of the Toronto Hidden Gems Finder project.

## 🗂️ Directory Structure

```
toronto-hidden-gems/
├── main.py                          # Main entry point
├── config/                          # Configuration files
│   ├── config.py                   # Application configuration
│   └── requirements.txt            # Python dependencies
├── src/                            # Source code
│   ├── __init__.py
│   ├── collectors/                 # Data collection modules
│   │   ├── __init__.py
│   │   ├── reddit_collector.py     # Full Reddit API collector
│   │   └── reddit_collector_readonly.py  # Read-only Reddit collector
│   ├── analyzers/                  # Data analysis modules
│   │   ├── __init__.py
│   │   └── dinesafe_analyzer.py    # DineSafe data analyzer
│   ├── finders/                    # Hidden gems finding algorithms
│   │   ├── __init__.py
│   │   ├── hidden_gems_finder.py   # Main finder (full Reddit access)
│   │   └── hidden_gems_finder_readonly.py  # Read-only finder
│   └── dashboard/                  # Web dashboard
│       ├── __init__.py
│       └── dashboard.py            # Interactive Dash/Plotly dashboard
├── scripts/                        # Utility scripts
│   └── run.py                      # Main runner script
├── tests/                          # Test files
│   └── test_reddit_connection.py   # Reddit API connection tests
├── data/                           # Data files
│   ├── Dine Safe Data .csv         # Toronto health inspection data
│   └── *.csv                       # Generated data files
└── docs/                           # Documentation
    ├── README.md                   # Main documentation
    └── PROJECT_STRUCTURE.md        # This file
```

## 📦 Package Organization

### `src/` - Source Code
The main source code is organized into logical packages:

#### `collectors/` - Data Collection
- **`reddit_collector.py`**: Full Reddit API access with authentication
- **`reddit_collector_readonly.py`**: Read-only Reddit access (no auth required)

#### `analyzers/` - Data Analysis
- **`dinesafe_analyzer.py`**: Analyzes Toronto DineSafe inspection data

#### `finders/` - Hidden Gems Algorithms
- **`hidden_gems_finder.py`**: Main algorithm with full Reddit access
- **`hidden_gems_finder_readonly.py`**: Algorithm using read-only Reddit access

#### `dashboard/` - Web Interface
- **`dashboard.py`**: Interactive web dashboard using Dash/Plotly

### `config/` - Configuration
- **`config.py`**: All application configuration (API keys, settings, etc.)
- **`requirements.txt`**: Python package dependencies

### `scripts/` - Utility Scripts
- **`run.py`**: Main runner with multiple modes (dashboard, collect, analyze, find, demo)

### `tests/` - Testing
- **`test_reddit_connection.py`**: Tests Reddit API connectivity and authentication

### `data/` - Data Storage
- **`Dine Safe Data .csv`**: Official Toronto health inspection data (27MB+)
- Generated CSV files from Reddit collection and analysis

### `docs/` - Documentation
- **`README.md`**: Complete project documentation
- **`PROJECT_STRUCTURE.md`**: This structure documentation

## 🚀 Usage

### Quick Start
```bash
# Run the dashboard
python main.py dashboard

# Or use the script directly
python scripts/run.py dashboard
```

### Available Commands
```bash
python main.py dashboard    # Start interactive dashboard
python main.py collect     # Collect Reddit data
python main.py analyze     # Analyze DineSafe data
python main.py find        # Find hidden gems
python main.py demo        # Quick demo with sample data
```

## 🔧 Import Structure

The organized structure uses proper Python imports:

```python
# From root directory
from src.collectors import RedditCollectorReadOnly
from src.analyzers import DineSafeAnalyzer
from src.finders import HiddenGemsFinderReadOnly
from src.dashboard import HiddenGemsDashboard
```

## 📈 Benefits of This Structure

1. **🎯 Clear Separation of Concerns**: Each package has a specific responsibility
2. **🔄 Easy Maintenance**: Related code is grouped together
3. **📦 Proper Python Packaging**: Uses `__init__.py` files for clean imports
4. **🧪 Testable**: Tests are separated from source code
5. **📚 Well Documented**: Clear documentation structure
6. **🚀 Easy Deployment**: Simple entry point with `main.py`
7. **⚙️ Configurable**: All configuration centralized in `config/`

## 🔄 Migration Notes

- All import statements have been updated to work with the new structure
- The main entry point (`main.py`) provides backward compatibility
- Configuration paths have been updated to reflect the new data location
- Package imports use fallbacks for authentication issues

This structure makes the project more professional, maintainable, and easier to understand for new contributors. 