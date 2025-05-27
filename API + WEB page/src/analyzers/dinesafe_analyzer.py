import pandas as pd
import numpy as np
from datetime import datetime, timedelta
from geopy.distance import geodesic
import re
from tqdm import tqdm
import sys
import os
sys.path.append(os.path.join(os.path.dirname(__file__), '..', '..'))
from config.config import DINESAFE_FILE

class DineSafeAnalyzer:
    def __init__(self):
        """Initialize DineSafe analyzer"""
        self.df = None
        self.load_data()
    
    def load_data(self):
        """Load DineSafe data from CSV"""
        try:
            print("Loading DineSafe data...")
            self.df = pd.read_csv(DINESAFE_FILE)
            print(f"Loaded {len(self.df)} inspection records")
            self.clean_data()
        except Exception as e:
            print(f"Error loading DineSafe data: {e}")
    
    def clean_data(self):
        """Clean and preprocess the DineSafe data"""
        # Convert date column
        self.df['Inspection Date'] = pd.to_datetime(self.df['Inspection Date'])
        
        # Clean establishment names
        self.df['Establishment Name'] = self.df['Establishment Name'].str.strip().str.upper()
        
        # Fill missing values
        self.df['Infraction Details'] = self.df['Infraction Details'].fillna('')
        self.df['Severity'] = self.df['Severity'].fillna('No Violation')
        self.df['Action'] = self.df['Action'].fillna('No Action')
        
        # Create severity score mapping
        severity_scores = {
            'C - Crucial': 3,
            'S - Significant': 2,
            'M - Minor': 1,
            'No Violation': 0,
            '': 0
        }
        self.df['severity_score'] = self.df['Severity'].map(severity_scores).fillna(0)
        
        print("Data cleaning completed")
    
    def calculate_establishment_scores(self):
        """Calculate quality scores for each establishment"""
        print("🏥 Calculating establishment scores...")
        
        # Group by establishment with progress bar
        print("📊 Grouping establishments by ID...")
        establishment_stats = self.df.groupby(['Establishment ID', 'Establishment Name', 
                                             'Establishment Address', 'Latitude', 'Longitude']).agg({
            'Inspection Date': ['count', 'max'],
            'severity_score': ['sum', 'mean'],
            'Establishment Status': lambda x: (x == 'Pass').sum() / len(x),
            'Infraction Details': lambda x: sum(1 for detail in x if detail.strip() != '')
        }).round(3)
        
        # Flatten column names
        establishment_stats.columns = [
            'total_inspections', 'last_inspection', 'total_severity', 
            'avg_severity', 'pass_rate', 'total_infractions'
        ]
        
        establishment_stats = establishment_stats.reset_index()
        
        # Calculate days since last inspection
        establishment_stats['days_since_inspection'] = (
            datetime.now() - establishment_stats['last_inspection']
        ).dt.days
        
        # Calculate quality score (0-100, higher is better) with progress bar
        print("⭐ Calculating quality scores...")
        tqdm.pandas(desc="Quality Scores")
        establishment_stats['quality_score'] = establishment_stats.progress_apply(
            lambda row: self.calculate_quality_score_single(row), axis=1
        )
        
        # Add establishment type
        type_mapping = self.df.groupby('Establishment ID')['Establishment Type'].first()
        establishment_stats['establishment_type'] = establishment_stats['Establishment ID'].map(type_mapping)
        
        return establishment_stats
    
    def calculate_quality_score_single(self, row):
        """Calculate a quality score for a single establishment"""
        score = 100  # Start with perfect score
        
        # Penalize for infractions (more infractions = lower score)
        if row['total_infractions'] > 0:
            infraction_penalty = min(row['total_infractions'] * 2, 30)
            score -= infraction_penalty
        
        # Penalize for severity (higher severity = lower score)
        if row['avg_severity'] > 0:
            severity_penalty = row['avg_severity'] * 15
            score -= severity_penalty
        
        # Reward high pass rate
        pass_bonus = row['pass_rate'] * 10
        score += pass_bonus
        
        # Penalize for old inspections (data freshness)
        if row['days_since_inspection'] > 365:
            age_penalty = min((row['days_since_inspection'] - 365) / 30, 20)
            score -= age_penalty
        
        # Ensure score is between 0 and 100
        return max(0, min(100, score))
    
    def calculate_quality_score(self, stats_df):
        """Calculate a quality score based on multiple factors (legacy method)"""
        scores = []
        
        for _, row in stats_df.iterrows():
            score = self.calculate_quality_score_single(row)
            scores.append(score)
        
        return scores
    
    def find_establishments_by_name(self, name, fuzzy_match=True):
        """Find establishments by name with fuzzy matching"""
        if self.df is None:
            return pd.DataFrame()
        
        name = name.upper().strip()
        
        if fuzzy_match:
            # Use partial matching
            mask = self.df['Establishment Name'].str.contains(name, na=False, regex=False)
        else:
            # Exact match
            mask = self.df['Establishment Name'] == name
        
        return self.df[mask]
    
    def find_establishments_near_location(self, lat, lon, radius_km=1.0):
        """Find establishments within a radius of given coordinates"""
        if self.df is None:
            return pd.DataFrame()
        
        # Filter out rows with missing coordinates
        valid_coords = self.df.dropna(subset=['Latitude', 'Longitude'])
        
        distances = []
        for _, row in valid_coords.iterrows():
            try:
                distance = geodesic((lat, lon), (row['Latitude'], row['Longitude'])).kilometers
                distances.append(distance)
            except:
                distances.append(float('inf'))
        
        valid_coords = valid_coords.copy()
        valid_coords['distance_km'] = distances
        
        return valid_coords[valid_coords['distance_km'] <= radius_km].sort_values('distance_km')
    
    def get_establishment_details(self, establishment_id):
        """Get detailed information about a specific establishment"""
        establishment_data = self.df[self.df['Establishment ID'] == establishment_id]
        
        if establishment_data.empty:
            return None
        
        # Get basic info
        basic_info = establishment_data.iloc[0]
        
        # Get inspection history
        inspections = establishment_data.sort_values('Inspection Date', ascending=False)
        
        # Calculate statistics
        stats = {
            'establishment_id': establishment_id,
            'name': basic_info['Establishment Name'],
            'address': basic_info['Establishment Address'],
            'type': basic_info['Establishment Type'],
            'latitude': basic_info['Latitude'],
            'longitude': basic_info['Longitude'],
            'total_inspections': len(inspections),
            'last_inspection': inspections['Inspection Date'].max(),
            'pass_rate': (inspections['Establishment Status'] == 'Pass').mean(),
            'recent_infractions': len(inspections[
                (inspections['Inspection Date'] >= datetime.now() - timedelta(days=365)) &
                (inspections['Infraction Details'].str.strip() != '')
            ]),
            'inspection_history': inspections.to_dict('records')
        }
        
        return stats
    
    def get_top_rated_establishments(self, establishment_type=None, limit=50):
        """Get top-rated establishments by quality score"""
        scores_df = self.calculate_establishment_scores()
        
        if establishment_type:
            scores_df = scores_df[scores_df['establishment_type'].str.contains(
                establishment_type, case=False, na=False
            )]
        
        return scores_df.nlargest(limit, 'quality_score')
    
    def analyze_establishment_trends(self):
        """Analyze trends in establishment quality over time"""
        # Group by year and calculate metrics
        self.df['year'] = self.df['Inspection Date'].dt.year
        
        yearly_stats = self.df.groupby('year').agg({
            'Establishment ID': 'nunique',
            'severity_score': 'mean',
            'Establishment Status': lambda x: (x == 'Pass').mean()
        }).round(3)
        
        yearly_stats.columns = ['unique_establishments', 'avg_severity', 'pass_rate']
        
        return yearly_stats
    
    def export_analysis(self, filename=None):
        """Export analysis results to CSV"""
        if filename is None:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            filename = f"dinesafe_analysis_{timestamp}.csv"
        
        scores_df = self.calculate_establishment_scores()
        scores_df.to_csv(filename, index=False)
        print(f"Analysis exported to {filename}")
        
        return filename

if __name__ == "__main__":
    analyzer = DineSafeAnalyzer()
    
    # Calculate and display top establishments
    top_establishments = analyzer.get_top_rated_establishments(limit=20)
    print("\nTop 20 Establishments by Quality Score:")
    print(top_establishments[['Establishment Name', 'establishment_type', 'quality_score', 'pass_rate']])
    
    # Export analysis
    analyzer.export_analysis() 