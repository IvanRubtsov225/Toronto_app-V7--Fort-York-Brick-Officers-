import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/hidden_gem.dart';
import '../../core/providers/gems_provider.dart';
import '../../core/providers/location_provider.dart';
import '../widgets/toronto_app_bar.dart';
import '../widgets/map_filter_bar.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  
  // Toronto coordinates
  static const LatLng torontoCenter = LatLng(43.6532, -79.3832);
  
  // Filter state
  Set<GemCategory> _selectedCategories = {};
  bool _showHighQualityOnly = false;
  bool _showPopularOnly = false;
  double _minScore = 0.0;
  double _maxScore = 100.0;
  bool _showFilterBar = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Set navigation context for better back navigation
      context.read<GemsProvider>().setNavigationContext(NavigationContext.map);
      
      context.read<GemsProvider>().initialize();
      context.read<LocationProvider>().initializeLocation();
    });
  }

  List<HiddenGem> _getFilteredGems(List<HiddenGem> allGems) {
    List<HiddenGem> filtered = List.from(allGems);
    
    // Apply category filter
    if (_selectedCategories.isNotEmpty) {
      filtered = filtered.where((gem) => _selectedCategories.contains(gem.category)).toList();
    }
    
    // Apply quality filter
    if (_showHighQualityOnly) {
      filtered = filtered.where((gem) => gem.isHighQuality).toList();
    }
    
    // Apply popularity filter
    if (_showPopularOnly) {
      filtered = filtered.where((gem) => gem.isPopular).toList();
    }
    
    // Apply score range filter
    filtered = filtered.where((gem) => 
      gem.hiddenGemScore >= _minScore && gem.hiddenGemScore <= _maxScore
    ).toList();
    
    return filtered;
  }

  void _onCategoryFilterChanged(Set<GemCategory> categories) {
    setState(() {
      _selectedCategories = categories;
    });
    
    // Update navigation context if filters are active
    final gemsProvider = context.read<GemsProvider>();
    gemsProvider.setNavigationContext(
      categories.isNotEmpty || _showHighQualityOnly || _showPopularOnly || _minScore > 0 || _maxScore < 100
          ? NavigationContext.mapWithFilters
          : NavigationContext.map,
    );
  }

  void _onScoreRangeChanged(double minScore, double maxScore) {
    setState(() {
      _minScore = minScore;
      _maxScore = maxScore;
    });
  }

  void _onHighQualityToggled(bool enabled) {
    setState(() {
      _showHighQualityOnly = enabled;
    });
  }

  void _onPopularToggled(bool enabled) {
    setState(() {
      _showPopularOnly = enabled;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: const TorontoAppBar(
        title: 'Toronto Map',
      ),
      body: Consumer2<GemsProvider, LocationProvider>(
        builder: (context, gemsProvider, locationProvider, child) {
          final filteredGems = _getFilteredGems(gemsProvider.allGems);
          
          return Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: torontoCenter,
                  initialZoom: 13.0,
                  minZoom: 10.0,
                  maxZoom: 18.0,
                  backgroundColor: Colors.grey[100]!,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.toronto_hidden_gems_app',
                  ),
                  
                  // Gem markers (using filtered gems)
                  MarkerLayer(
                    markers: filteredGems.map((gem) {
                      return Marker(
                        point: LatLng(gem.latitude, gem.longitude),
                        width: 50,
                        height: 50,
                        child: GestureDetector(
                          onTap: () => _showGemDetails(context, gem),
                          child: Container(
                            decoration: BoxDecoration(
                              color: _getGemColor(gem),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              _getGemIcon(gem.category),
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  
                  // User location marker
                  if (locationProvider.currentPosition != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(
                            locationProvider.currentPosition!.latitude,
                            locationProvider.currentPosition!.longitude,
                          ),
                          width: 40,
                          height: 40,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.person_pin_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              
              // Loading overlay
              if (gemsProvider.isLoading && gemsProvider.allGems.isEmpty)
                Container(
                  color: Colors.black.withOpacity(0.3),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(height: 16),
                        Text(
                          'Loading gems...',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              
              // Map Filter Bar
              if (_showFilterBar)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: MapFilterBar(
                    onCategoryFilterChanged: _onCategoryFilterChanged,
                    onScoreRangeChanged: _onScoreRangeChanged,
                    onHighQualityToggled: _onHighQualityToggled,
                    onPopularToggled: _onPopularToggled,
                  ),
                ),
              
              // Map controls
              Positioned(
                top: _showFilterBar ? 180 : 16,
                right: 16,
                child: Column(
                  children: [
                    _buildMapButton(
                      icon: Icons.tune_rounded,
                      onPressed: () {
                        setState(() {
                          _showFilterBar = !_showFilterBar;
                        });
                      },
                      tooltip: _showFilterBar ? 'Hide Filters' : 'Show Filters',
                      isSelected: _showFilterBar,
                    ),
                    const SizedBox(height: 8),
                    _buildMapButton(
                      icon: Icons.my_location_rounded,
                      onPressed: () => _centerOnUserLocation(locationProvider),
                      tooltip: 'My Location',
                    ),
                    const SizedBox(height: 8),
                    _buildMapButton(
                      icon: Icons.location_city_rounded,
                      onPressed: _centerOnToronto,
                      tooltip: 'Toronto Center',
                    ),
                  ],
                ),
              ),
              
              // Legend
              Positioned(
                bottom: 100,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 16,
                            color: theme.primaryColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Legend',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildLegendItem(
                        color: const Color(0xFFE31837),
                        label: 'High Quality Gems',
                        count: filteredGems.where((g) => g.isHighQuality).length,
                      ),
                      _buildLegendItem(
                        color: Colors.orange,
                        label: 'Popular Gems',
                        count: filteredGems.where((g) => g.isPopular && !g.isHighQuality).length,
                      ),
                      _buildLegendItem(
                        color: Colors.blue,
                        label: 'Other Gems',
                        count: filteredGems.where((g) => !g.isHighQuality && !g.isPopular).length,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Total: ${filteredGems.length} gems',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMapButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
    bool isSelected = false,
  }) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? theme.primaryColor : Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: isSelected ? Colors.white : theme.primaryColor,
        ),
        tooltip: tooltip,
        iconSize: 24,
      ),
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
    required int count,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(width: 4),
          Text(
            '($count)',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getGemColor(HiddenGem gem) {
    if (gem.isHighQuality) {
      return const Color(0xFFE31837); // Toronto red
    } else if (gem.isPopular) {
      return Colors.orange;
    } else {
      return Colors.blue;
    }
  }

  IconData _getGemIcon(GemCategory category) {
    switch (category) {
      case GemCategory.restaurant:
        return Icons.restaurant_rounded;
      case GemCategory.cafe:
        return Icons.coffee_rounded;
      case GemCategory.park:
        return Icons.park_rounded;
      case GemCategory.museum:
        return Icons.museum_rounded;
      case GemCategory.shopping:
        return Icons.shopping_bag_rounded;
      case GemCategory.entertainment:
        return Icons.theater_comedy_rounded;
      case GemCategory.historical:
        return Icons.account_balance_rounded;
      case GemCategory.viewpoint:
        return Icons.visibility_rounded;
    }
  }

  void _centerOnUserLocation(LocationProvider locationProvider) {
    if (locationProvider.currentPosition != null) {
      _mapController.move(
        LatLng(
          locationProvider.currentPosition!.latitude,
          locationProvider.currentPosition!.longitude,
        ),
        15.0,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location not available'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _centerOnToronto() {
    _mapController.move(torontoCenter, 13.0);
  }

  void _showGemDetails(BuildContext context, HiddenGem gem) {
    final theme = Theme.of(context);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: _getGemColor(gem),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getGemIcon(gem.category),
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                gem.name,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                gem.address,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Score and category
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getGemColor(gem).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Score: ${gem.hiddenGemScore.toStringAsFixed(1)}',
                            style: TextStyle(
                              color: _getGemColor(gem),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            gem.category.displayName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Description
                    Text(
                      gem.description,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        height: 1.5,
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              // Set navigation context before navigating to gem detail
                              final gemsProvider = context.read<GemsProvider>();
                              gemsProvider.setNavigationContext(
                                _selectedCategories.isNotEmpty || _showHighQualityOnly || _showPopularOnly || _minScore > 0 || _maxScore < 100
                                    ? NavigationContext.mapWithFilters
                                    : NavigationContext.map,
                              );
                              context.go('/gem/${gem.id}');
                            },
                            icon: const Icon(Icons.info_rounded),
                            label: const Text('View Details'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: () {
                            _mapController.move(
                              LatLng(gem.latitude, gem.longitude),
                              17.0,
                            );
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.center_focus_strong_rounded),
                          label: const Text('Center'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: BorderSide(color: theme.primaryColor),
                            foregroundColor: theme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
