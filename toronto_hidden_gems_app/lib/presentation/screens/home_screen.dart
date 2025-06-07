import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/location_provider.dart';
import '../../core/providers/gems_provider.dart';
import '../../core/models/hidden_gem.dart';
import '../widgets/gem_card.dart';
import '../widgets/toronto_app_bar.dart';
import '../widgets/location_status_card.dart';
import '../widgets/emotional_exploration_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Set navigation context for home screen
      context.read<GemsProvider>().setNavigationContext(NavigationContext.home);
      
      _loadNearbyGems();
    });
  }

  Future<void> _loadNearbyGems() async {
    final gemsProvider = context.read<GemsProvider>();
    final locationProvider = context.read<LocationProvider>();
    
    print('🏠 HomeScreen: Starting to load gems...');
    print('🏠 Current gems count: ${gemsProvider.allGems.length}');
    
    // First ensure we have all gems loaded
    if (gemsProvider.allGems.isEmpty) {
      print('🏠 No gems loaded, initializing from API...');
      await gemsProvider.initialize();
      print('🏠 After initialization, gems count: ${gemsProvider.allGems.length}');
    }
    
    // Then try to load nearby gems if location is available
    if (locationProvider.currentPosition != null) {
      print('🏠 Location available, loading nearby gems...');
      await gemsProvider.loadNearbyGems(
        latitude: locationProvider.currentPosition!.latitude,
        longitude: locationProvider.currentPosition!.longitude,
        radiusKm: 5.0,
      );
      print('🏠 Nearby gems count: ${gemsProvider.nearbyGems.length}');
    } else {
      // If no location, just show the first few gems
      print('🏠 No location available, showing first gems from API');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const TorontoAppBar(
        title: 'The Toronto App 🍁',
        showBackButton: false,
      ),
      body: RefreshIndicator(
        onRefresh: _loadNearbyGems,
        color: theme.primaryColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Location Status Card
              const LocationStatusCard(),
              
              const SizedBox(height: 24),
              
              // Quick Actions
              _buildQuickActions(context),
              
              const SizedBox(height: 24),
              
              // Nearby Gems Section
              _buildNearbyGemsSection(context),
              
              const SizedBox(height: 24),
              
              // Discover More Button
              _buildDiscoverMoreButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.primaryColor,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                context,
                icon: Icons.map_rounded,
                title: 'Explore Map',
                subtitle: 'View all gems',
                onTap: () {
                  context.read<GemsProvider>().setNavigationContext(NavigationContext.map);
                  context.go('/map');
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                context,
                icon: Icons.event_rounded,
                title: 'Events',
                subtitle: 'What\'s happening',
                onTap: () => context.go('/events'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Emotional Exploration button - full width
        _buildEmotionalExplorationCard(context),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: theme.primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNearbyGemsSection(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'The Toronto App',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.primaryColor,
              ),
            ),
            TextButton(
              onPressed: () {
                context.read<GemsProvider>().setNavigationContext(NavigationContext.gemsList);
                context.go('/gems');
              },
              child: Text(
                'View All',
                style: TextStyle(
                  color: theme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Consumer<GemsProvider>(
          builder: (context, gemsProvider, child) {
            print('🏠 UI Update - Gems count: ${gemsProvider.allGems.length}, Loading: ${gemsProvider.isLoading}, Error: ${gemsProvider.error}');
            
            if (gemsProvider.isLoading && gemsProvider.allGems.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (gemsProvider.error != null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading gems',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        gemsProvider.error!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[500],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadNearbyGems,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Show nearby gems if available, otherwise show first few all gems
            final gemsToShow = gemsProvider.nearbyGems.isNotEmpty 
                ? gemsProvider.nearbyGems 
                : gemsProvider.allGems;

            if (gemsToShow.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.location_off_rounded,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No gems found',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Check your internet connection and try again',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadNearbyGems,
                        child: const Text('Refresh'),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Column(
              children: [
                // Stats card showing total gems
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.primaryColor.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.diamond_rounded,
                        color: theme.primaryColor,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${gemsProvider.allGems.length} Hidden Gems Discovered',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.primaryColor,
                              ),
                            ),
                            Text(
                              '${gemsProvider.featuredGems.length} featured • ${gemsProvider.topGems.length} top-rated',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Gem cards
                ...gemsToShow
                    .take(5)
                    .map((gem) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GemCard(gem: gem),
                        ))
                    .toList(),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildDiscoverMoreButton(BuildContext context) {
    final theme = Theme.of(context);
    
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          context.read<GemsProvider>().setNavigationContext(NavigationContext.gemsList);
          context.go('/gems');
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.explore_rounded),
            const SizedBox(width: 8),
            Text(
              'Discover All Gems',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmotionalExplorationCard(BuildContext context) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: () => _showEmotionalExploration(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.primaryColor,
              theme.primaryColor.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: theme.primaryColor.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.favorite_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Emotional Exploration 💖',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Find gems that match your current mood',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white.withOpacity(0.8),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _showEmotionalExploration(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EmotionalExplorationSheet(),
    );
  }
} 