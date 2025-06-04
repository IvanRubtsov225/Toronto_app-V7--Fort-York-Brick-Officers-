import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/providers/gems_provider.dart';
import '../../core/providers/location_provider.dart';
import '../../core/models/hidden_gem.dart';
import '../widgets/toronto_app_bar.dart';
import 'package:go_router/go_router.dart';

class GemDetailScreen extends StatefulWidget {
  final String gemId;

  const GemDetailScreen({
    super.key,
    required this.gemId,
  });

  @override
  State<GemDetailScreen> createState() => _GemDetailScreenState();
}

class _GemDetailScreenState extends State<GemDetailScreen> {
  HiddenGem? gem;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadGem();
  }

  Future<void> _loadGem() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      final gemsProvider = context.read<GemsProvider>();
      final loadedGem = await gemsProvider.getGemById(widget.gemId);
      
      if (mounted) {
        setState(() {
          gem = loadedGem;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e.toString();
          isLoading = false;
        });
      }
    }
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openDirections() async {
    if (gem != null) {
      final url = 'https://maps.apple.com/?daddr=${gem!.latitude},${gem!.longitude}';
      await _launchUrl(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (isLoading) {
      return Scaffold(
        appBar: const TorontoAppBar(title: 'Loading...'),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (error != null || gem == null) {
      return Scaffold(
        appBar: const TorontoAppBar(title: 'Error'),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Gem Not Found',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  error ?? 'The gem you\'re looking for could not be found.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => _navigateBack(context),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // App bar with image
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: theme.primaryColor,
            foregroundColor: Colors.white,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(25),
              ),
              child: IconButton(
                onPressed: () => _navigateBack(context),
                icon: const Icon(
                  Icons.arrow_back_ios_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                tooltip: 'Back to explore more gems',
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: IconButton(
                  onPressed: () {
                    // TODO: Implement favorites
                  },
                  icon: const Icon(
                    Icons.favorite_outline_rounded,
                    color: Colors.white,
                  ),
                  tooltip: 'Add to favorites',
                ),
              ),
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: IconButton(
                  onPressed: () {
                    // TODO: Implement share
                  },
                  icon: const Icon(
                    Icons.share_rounded,
                    color: Colors.white,
                  ),
                  tooltip: 'Share this gem',
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  gem!.imageUrl != null && gem!.imageUrl!.isNotEmpty
                      ? Image.network(
                          gem!.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildPlaceholderImage();
                          },
                        )
                      : _buildPlaceholderImage(),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.3),
                          Colors.black.withOpacity(0.5),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Content
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header info
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                gem!.name,
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.primaryColor,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: theme.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                gem!.category.displayName,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: theme.primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Rating and reviews
                        if (gem!.rating != null)
                          Row(
                            children: [
                              Row(
                                children: List.generate(5, (index) {
                                  return Icon(
                                    index < gem!.rating!.floor()
                                        ? Icons.star_rounded
                                        : Icons.star_outline_rounded,
                                    color: Colors.amber[600],
                                    size: 20,
                                  );
                                }),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${gem!.rating!.toStringAsFixed(1)} rating',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  
                  // Action buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _openDirections,
                            icon: const Icon(Icons.directions_rounded),
                            label: const Text('Directions'),
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
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: theme.primaryColor,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            onPressed: () {
                              // TODO: Implement favorites
                            },
                            icon: const Icon(Icons.favorite_outline_rounded),
                            color: theme.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: theme.primaryColor,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            onPressed: () {
                              // TODO: Implement share
                            },
                            icon: const Icon(Icons.share_rounded),
                            color: theme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Description
                  _buildSection(
                    context,
                    'About This Gem',
                    Text(
                      gem!.description,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        height: 1.6,
                      ),
                    ),
                  ),
                  
                  // Location info
                  _buildSection(
                    context,
                    'Location',
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.location_city_rounded,
                              size: 20,
                              color: theme.primaryColor,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              gem!.neighborhood,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.location_on_rounded,
                              size: 20,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                gem!.address,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Consumer<LocationProvider>(
                          builder: (context, locationProvider, child) {
                            if (locationProvider.currentPosition != null) {
                              final distance = gem!.calculateDistance(
                                locationProvider.currentPosition!.latitude,
                                locationProvider.currentPosition!.longitude,
                              );
                              final direction = gem!.getDirectionFrom(
                                locationProvider.currentPosition!.latitude,
                                locationProvider.currentPosition!.longitude,
                              );
                              
                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.near_me_rounded,
                                      size: 16,
                                      color: theme.primaryColor,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      distance < 1
                                          ? '${(distance * 1000).round()}m away'
                                          : '${distance.toStringAsFixed(1)}km away',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Icon(
                                      Icons.compass_calibration_rounded,
                                      size: 16,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      direction,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  // Features
                  if (gem!.features.isNotEmpty)
                    _buildSection(
                      context,
                      'Features',
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: gem!.features.map(
                          (feature) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              feature,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ).toList(),
                      ),
                    ),
                  
                  // Website link
                  if (gem!.websiteUrl != null && gem!.websiteUrl!.isNotEmpty)
                    _buildSection(
                      context,
                      'More Information',
                      GestureDetector(
                        onTap: () => _launchUrl(gem!.websiteUrl!),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: theme.primaryColor,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.language_rounded,
                                color: theme.primaryColor,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Visit Website',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: theme.primaryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 16,
                                color: theme.primaryColor,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 100), // Bottom padding
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Consumer<GemsProvider>(
        builder: (context, gemsProvider, child) {
          // Show different button based on context
          if (gemsProvider.currentMoodFilter != null) {
            return FloatingActionButton.extended(
              onPressed: () => context.go('/gems'),
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.filter_list_rounded),
              label: Text('${gemsProvider.currentMoodFilter} Gems'),
              tooltip: 'Back to filtered gems list',
            );
          } else {
            return FloatingActionButton.extended(
              onPressed: () => context.go('/gems'),
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.explore_rounded),
              label: const Text('Explore More'),
              tooltip: 'Discover more hidden gems',
            );
          }
        },
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Consumer<GemsProvider>(
            builder: (context, gemsProvider, child) {
              return Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _navigateBack(context),
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: Text(gemsProvider.currentMoodFilter != null 
                          ? '${gemsProvider.currentMoodFilter} List' 
                          : 'Back'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: theme.primaryColor),
                        foregroundColor: theme.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _openDirections,
                      icon: const Icon(Icons.directions_rounded),
                      label: const Text('Directions'),
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
                  const SizedBox(width: 8),
                  // Home button
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.primaryColor),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      onPressed: () => context.go('/home'),
                      icon: const Icon(Icons.home_rounded),
                      color: theme.primaryColor,
                      tooltip: 'Go to Home',
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, Widget content) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          content,
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    final theme = Theme.of(context);
    
    return Container(
      color: theme.primaryColor.withOpacity(0.1),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_city_rounded,
              size: 80,
              color: theme.primaryColor.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Toronto Hidden Gem',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.primaryColor.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateBack(BuildContext context) {
    // Try to go back to the previous screen, but if there's no history
    // or it would cause a black screen, go to a logical default screen
    if (context.canPop()) {
      // Check if we came from the gems list with filters
      final gemsProvider = context.read<GemsProvider>();
      if (gemsProvider.currentMoodFilter != null || gemsProvider.filteredGems.isNotEmpty) {
        context.go('/gems');
      } else {
        // Safe pop with fallback
        try {
          context.pop();
        } catch (e) {
          context.go('/home');
        }
      }
    } else {
      // No navigation stack, go to home
      context.go('/home');
    }
  }
} 