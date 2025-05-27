import dash
from dash import dcc, html, Input, Output, callback_context, dash_table
import plotly.express as px
import plotly.graph_objects as go
import pandas as pd
import numpy as np
from datetime import datetime
import dash_bootstrap_components as dbc

import sys
import os
sys.path.append(os.path.join(os.path.dirname(__file__), '..', '..'))

from src.finders.hidden_gems_finder_readonly import HiddenGemsFinderReadOnly as HiddenGemsFinder

class HiddenGemsDashboard:
    def __init__(self):
        """Initialize the dashboard"""
        self.app = dash.Dash(__name__, external_stylesheets=[dbc.themes.BOOTSTRAP])
        self.finder = HiddenGemsFinder()
        self.gems_data = None
        self.setup_layout()
        self.setup_callbacks()
    
    def load_data(self):
        """Load or generate hidden gems data"""
        try:
            # Try to load existing data first
            self.gems_data = pd.read_csv('toronto_hidden_gems_latest.csv')
            print("Loaded existing hidden gems data")
        except:
            print("Generating new hidden gems data...")
            # Load Reddit data if available
            self.finder.load_or_collect_reddit_data(use_existing=False)
            
            # Find hidden gems
            gems = self.finder.find_hidden_gems(
                min_dinesafe_score=60,
                min_reddit_mentions=1,
                max_reddit_mentions=15
            )
            
            if gems:
                self.gems_data = pd.DataFrame(gems)
                self.gems_data.to_csv('toronto_hidden_gems_latest.csv', index=False)
                print(f"Generated {len(gems)} hidden gems")
            else:
                # Create sample data for demonstration
                self.create_sample_data()
    
    def create_sample_data(self):
        """Create sample data for demonstration purposes"""
        sample_data = [
            {
                'name': 'SAMPLE HIDDEN CAFE',
                'address': '123 Queen St W, Toronto',
                'type': 'Restaurant',
                'latitude': 43.6532,
                'longitude': -79.3832,
                'hidden_gem_score': 85.5,
                'dinesafe_score': 92.0,
                'reddit_score': 78.0,
                'uniqueness_score': 65.0,
                'mention_count': 3,
                'avg_sentiment': 0.7,
                'hidden_gem_mentions': 2,
                'subreddit_diversity': 2,
                'similarity_score': 95,
                'establishment_id': 'SAMPLE001'
            },
            {
                'name': 'SAMPLE BAKERY',
                'address': '456 College St, Toronto',
                'type': 'Bakery',
                'latitude': 43.6577,
                'longitude': -79.4103,
                'hidden_gem_score': 82.3,
                'dinesafe_score': 88.5,
                'reddit_score': 72.0,
                'uniqueness_score': 70.0,
                'mention_count': 2,
                'avg_sentiment': 0.8,
                'hidden_gem_mentions': 1,
                'subreddit_diversity': 1,
                'similarity_score': 90,
                'establishment_id': 'SAMPLE002'
            }
        ]
        self.gems_data = pd.DataFrame(sample_data)
        print("Created sample data for demonstration")
    
    def setup_layout(self):
        """Setup the dashboard layout"""
        self.app.layout = dbc.Container([
            dbc.Row([
                dbc.Col([
                    html.H1("🍽️ Toronto Hidden Gems Finder", 
                           className="text-center mb-4",
                           style={'color': '#2c3e50', 'font-weight': 'bold'}),
                    html.P("Discover amazing local restaurants using Reddit insights and DineSafe data",
                           className="text-center text-muted mb-4")
                ])
            ]),
            
            # Control Panel
            dbc.Row([
                dbc.Col([
                    dbc.Card([
                        dbc.CardBody([
                            html.H5("Filters", className="card-title"),
                            
                            html.Label("Minimum Hidden Gem Score:"),
                            dcc.Slider(
                                id='score-slider',
                                min=0, max=100, step=5, value=70,
                                marks={i: str(i) for i in range(0, 101, 20)},
                                tooltip={"placement": "bottom", "always_visible": True}
                            ),
                            
                            html.Label("Establishment Type:", className="mt-3"),
                            dcc.Dropdown(
                                id='type-dropdown',
                                options=[
                                    {'label': 'All Types', 'value': 'all'},
                                    {'label': 'Restaurant', 'value': 'restaurant'},
                                    {'label': 'Cafe', 'value': 'cafe'},
                                    {'label': 'Bakery', 'value': 'bakery'},
                                    {'label': 'Bar/Pub', 'value': 'bar'},
                                    {'label': 'Take Out', 'value': 'take out'}
                                ],
                                value='all'
                            ),
                            
                            html.Label("Maximum Reddit Mentions:", className="mt-3"),
                            dcc.Slider(
                                id='mentions-slider',
                                min=1, max=20, step=1, value=10,
                                marks={i: str(i) for i in range(1, 21, 5)},
                                tooltip={"placement": "bottom", "always_visible": True}
                            ),
                            
                            dbc.Button("Refresh Data", id="refresh-btn", 
                                     color="primary", className="mt-3 w-100")
                        ])
                    ])
                ], width=3),
                
                # Map
                dbc.Col([
                    dbc.Card([
                        dbc.CardBody([
                            html.H5("Hidden Gems Map", className="card-title"),
                            dcc.Graph(id='gems-map', style={'height': '500px'})
                        ])
                    ])
                ], width=9)
            ], className="mb-4"),
            
            # Statistics Row
            dbc.Row([
                dbc.Col([
                    dbc.Card([
                        dbc.CardBody([
                            html.H4(id="total-gems", className="text-primary"),
                            html.P("Total Hidden Gems", className="text-muted")
                        ])
                    ])
                ], width=3),
                dbc.Col([
                    dbc.Card([
                        dbc.CardBody([
                            html.H4(id="avg-score", className="text-success"),
                            html.P("Average Score", className="text-muted")
                        ])
                    ])
                ], width=3),
                dbc.Col([
                    dbc.Card([
                        dbc.CardBody([
                            html.H4(id="top-type", className="text-info"),
                            html.P("Most Common Type", className="text-muted")
                        ])
                    ])
                ], width=3),
                dbc.Col([
                    dbc.Card([
                        dbc.CardBody([
                            html.H4(id="avg-sentiment", className="text-warning"),
                            html.P("Average Sentiment", className="text-muted")
                        ])
                    ])
                ], width=3)
            ], className="mb-4"),
            
            # Charts Row
            dbc.Row([
                dbc.Col([
                    dbc.Card([
                        dbc.CardBody([
                            html.H5("Score Distribution", className="card-title"),
                            dcc.Graph(id='score-histogram')
                        ])
                    ])
                ], width=6),
                dbc.Col([
                    dbc.Card([
                        dbc.CardBody([
                            html.H5("Types Distribution", className="card-title"),
                            dcc.Graph(id='type-pie-chart')
                        ])
                    ])
                ], width=6)
            ], className="mb-4"),
            
            # Data Table
            dbc.Row([
                dbc.Col([
                    dbc.Card([
                        dbc.CardBody([
                            html.H5("Hidden Gems Details", className="card-title"),
                            dash_table.DataTable(
                                id='gems-table',
                                columns=[
                                    {'name': 'Name', 'id': 'name'},
                                    {'name': 'Address', 'id': 'address'},
                                    {'name': 'Type', 'id': 'type'},
                                    {'name': 'Hidden Gem Score', 'id': 'hidden_gem_score', 'type': 'numeric', 'format': {'specifier': '.1f'}},
                                    {'name': 'DineSafe Score', 'id': 'dinesafe_score', 'type': 'numeric', 'format': {'specifier': '.1f'}},
                                    {'name': 'Reddit Mentions', 'id': 'mention_count'},
                                    {'name': 'Sentiment', 'id': 'avg_sentiment', 'type': 'numeric', 'format': {'specifier': '.2f'}}
                                ],
                                sort_action="native",
                                page_size=10,
                                style_cell={'textAlign': 'left'},
                                style_data_conditional=[
                                    {
                                        'if': {'row_index': 'odd'},
                                        'backgroundColor': 'rgb(248, 248, 248)'
                                    }
                                ],
                                style_header={
                                    'backgroundColor': 'rgb(230, 230, 230)',
                                    'fontWeight': 'bold'
                                }
                            )
                        ])
                    ])
                ])
            ])
        ], fluid=True)
    
    def setup_callbacks(self):
        """Setup dashboard callbacks"""
        
        @self.app.callback(
            [Output('gems-map', 'figure'),
             Output('gems-table', 'data'),
             Output('total-gems', 'children'),
             Output('avg-score', 'children'),
             Output('top-type', 'children'),
             Output('avg-sentiment', 'children'),
             Output('score-histogram', 'figure'),
             Output('type-pie-chart', 'figure')],
            [Input('score-slider', 'value'),
             Input('type-dropdown', 'value'),
             Input('mentions-slider', 'value'),
             Input('refresh-btn', 'n_clicks')]
        )
        def update_dashboard(min_score, establishment_type, max_mentions, refresh_clicks):
            # Load data if not already loaded
            if self.gems_data is None:
                self.load_data()
            
            # Filter data
            filtered_data = self.gems_data.copy()
            
            # Apply filters
            filtered_data = filtered_data[filtered_data['hidden_gem_score'] >= min_score]
            filtered_data = filtered_data[filtered_data['mention_count'] <= max_mentions]
            
            if establishment_type != 'all':
                filtered_data = filtered_data[
                    filtered_data['type'].str.lower().str.contains(establishment_type.lower(), na=False)
                ]
            
            # Create map
            if len(filtered_data) > 0:
                map_fig = px.scatter_mapbox(
                    filtered_data,
                    lat='latitude',
                    lon='longitude',
                    hover_name='name',
                    hover_data={
                        'address': True,
                        'type': True,
                        'hidden_gem_score': ':.1f',
                        'mention_count': True,
                        'latitude': False,
                        'longitude': False
                    },
                    color='hidden_gem_score',
                    size='mention_count',
                    color_continuous_scale='Viridis',
                    size_max=20,
                    zoom=11,
                    center={'lat': 43.6532, 'lon': -79.3832}
                )
                map_fig.update_layout(
                    mapbox_style="open-street-map",
                    margin={"r": 0, "t": 0, "l": 0, "b": 0}
                )
            else:
                map_fig = go.Figure()
                map_fig.add_annotation(
                    text="No data matches the current filters",
                    xref="paper", yref="paper",
                    x=0.5, y=0.5, showarrow=False
                )
            
            # Calculate statistics
            total_gems = len(filtered_data)
            avg_score = f"{filtered_data['hidden_gem_score'].mean():.1f}" if total_gems > 0 else "N/A"
            top_type = filtered_data['type'].mode().iloc[0] if total_gems > 0 else "N/A"
            avg_sentiment = f"{filtered_data['avg_sentiment'].mean():.2f}" if total_gems > 0 else "N/A"
            
            # Create histogram
            if len(filtered_data) > 0:
                hist_fig = px.histogram(
                    filtered_data,
                    x='hidden_gem_score',
                    nbins=20,
                    title="Distribution of Hidden Gem Scores"
                )
                hist_fig.update_layout(
                    xaxis_title="Hidden Gem Score",
                    yaxis_title="Count"
                )
            else:
                hist_fig = go.Figure()
                hist_fig.add_annotation(
                    text="No data to display",
                    xref="paper", yref="paper",
                    x=0.5, y=0.5, showarrow=False
                )
            
            # Create pie chart
            if len(filtered_data) > 0:
                type_counts = filtered_data['type'].value_counts()
                pie_fig = px.pie(
                    values=type_counts.values,
                    names=type_counts.index,
                    title="Distribution by Establishment Type"
                )
            else:
                pie_fig = go.Figure()
                pie_fig.add_annotation(
                    text="No data to display",
                    xref="paper", yref="paper",
                    x=0.5, y=0.5, showarrow=False
                )
            
            # Prepare table data
            table_data = filtered_data.to_dict('records') if len(filtered_data) > 0 else []
            
            return (map_fig, table_data, str(total_gems), avg_score, 
                   top_type, avg_sentiment, hist_fig, pie_fig)
    
    def run(self, debug=True, port=8050):
        """Run the dashboard"""
        self.load_data()
        print(f"Starting dashboard on http://localhost:{port}")
        self.app.run_server(debug=debug, port=port)

if __name__ == "__main__":
    dashboard = HiddenGemsDashboard()
    dashboard.run() 