import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/hidden_gem.dart';
import '../../core/models/gem_filters.dart';
import '../../core/providers/gems_provider.dart';
import '../../core/providers/location_provider.dart';
import '../widgets/gem_card.dart';
import '../widgets/toronto_app_bar.dart';
import '../widgets/modern_search_bar.dart';
import '../widgets/comprehensive_filter_panel.dart';
import '../widgets/filter_status_bar.dart';

class GemsListScreen extends StatefulWidget {
  const GemsListScreen({super.key});

  @override
  State<GemsListScreen> createState() => _GemsListScreenState();
}

class _GemsListScreenState extends State<GemsListScreen> {
  final ScrollController _scrollController = ScrollController();
  GemFilters _currentFilters = const GemFilters();
  List<HiddenGem> _filteredGems = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Set navigation context for better back navigation
      final gemsProvider = context.read<GemsProvider>();
      gemsProvider.setNavigationContext(
        gemsProvider.hasFilters 
            ? NavigationContext.gemsListWithFilters 
            : NavigationContext.gemsList,
      );
      
      gemsProvider.initialize();
      _applyFilters();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    final gemsProvider = context.read<GemsProvider>();
    final allGems = gemsProvider.allGems;
    
    setState(() {
      _filteredGems = allGems.where((gem) => _currentFilters.matches(gem)).toList();
    });
    
    // Apply sorting
    _sortGems();
    
    // Update navigation context
    _updateNavigationContext();
  }

  void _sortGems() {
    final locationProvider = context.read<LocationProvider>();
    
    switch (_currentFilters.sortOption) {
      case GemSortOption.distance:
        if (locationProvider.currentPosition != null) {
          _filteredGems.sort((a, b) {
            final distanceA = a.calculateDistance(
              locationProvider.currentPosition!.latitude,
              locationProvider.currentPosition!.longitude,
            );
            final distanceB = b.calculateDistance(
              locationProvider.currentPosition!.latitude,
              locationProvider.currentPosition!.longitude,
            );
            return distanceA.compareTo(distanceB);
          });
        }
        break;
      case GemSortOption.rating:
        _filteredGems.sort((a, b) {
          final ratingA = a.rating ?? 0;
          final ratingB = b.rating ?? 0;
          return ratingB.compareTo(ratingA);
        });
        break;
      case GemSortOption.popularity:
        _filteredGems.sort((a, b) => b.mentionCount.compareTo(a.mentionCount));
        break;
      case GemSortOption.newest:
        _filteredGems.sort((a, b) => b.hiddenGemScore.compareTo(a.hiddenGemScore));
        break;
    }
  }

  void _updateNavigationContext() {
    final gemsProvider = context.read<GemsProvider>();
    gemsProvider.setNavigationContext(
      _currentFilters.hasActiveFilters
          ? NavigationContext.gemsListWithFilters
          : NavigationContext.gemsList,
    );
  }

  void _onFiltersChanged(GemFilters newFilters) {
    setState(() {
      _currentFilters = newFilters;
    });
    _applyFilters();
  }

  void _onSearchChanged(String query) {
    _onFiltersChanged(_currentFilters.copyWith(searchQuery: query));
  }

  void _showFilterPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ComprehensiveFilterPanel(
        initialFilters: _currentFilters,
        onFiltersChanged: _onFiltersChanged,
        onClose: () => Navigator.of(context).pop(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: const TorontoAppBar(
        title: 'Hidden Gems',
      ),
      body: Consumer<GemsProvider>(
        builder: (context, gemsProvider, child) {
          if (gemsProvider.isLoading && gemsProvider.allGems.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        CircularProgressIndicator(
                          color: theme.primaryColor,
                          strokeWidth: 3,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Loading Toronto\'s hidden gems...',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Discovering amazing places for you',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          if (gemsProvider.hasError) {
            return Center(
              child: Container(
                margin: const EdgeInsets.all(32),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 64,
                      color: Colors.red[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Oops! Something went wrong',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Unable to load gems right now',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => gemsProvider.refresh(),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Try Again'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: [
              // Modern Search Bar
              ModernSearchBar(
                initialQuery: _currentFilters.searchQuery,
                onSearchChanged: _onSearchChanged,
                onFilterPressed: _showFilterPanel,
                hasActiveFilters: _currentFilters.hasActiveFilters,
              ),
              
              // Filter Status Bar
              FilterStatusBar(
                filters: _currentFilters,
                onFiltersChanged: _onFiltersChanged,
                totalResults: _filteredGems.length,
              ),
              
              // Gems List
              Expanded(
                child: _buildGemsList(context),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGemsList(BuildContext context) {
    final theme = Theme.of(context);
    
    if (_filteredGems.isEmpty) {
      return Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.search_off_rounded,
                  size: 48,
                  color: theme.primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No gems found',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Try adjusting your search or filters\nto discover more hidden gems',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              if (_currentFilters.hasActiveFilters) ...[
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => _onFiltersChanged(_currentFilters.clear()),
                  icon: const Icon(Icons.clear_all_rounded),
                  label: const Text('Clear all filters'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ] else ...[
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: _showFilterPanel,
                  icon: const Icon(Icons.tune_rounded),
                  label: const Text('Explore filters'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.primaryColor,
                    side: BorderSide(color: theme.primaryColor),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await context.read<GemsProvider>().refresh();
        _applyFilters();
      },
      color: theme.primaryColor,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _filteredGems.length + 1, // +1 for results summary
        itemBuilder: (context, index) {
          if (index == 0) {
            // Results summary card
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.primaryColor.withOpacity(0.1),
                    theme.primaryColor.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.primaryColor.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.primaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.diamond_rounded,
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
                          '${_filteredGems.length} Hidden Gems Found',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.primaryColor,
                          ),
                        ),
                        Text(
                          'Sorted by ${_currentFilters.sortOption.displayName.toLowerCase()}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_currentFilters.hasActiveFilters)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.primaryColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${_currentFilters.activeFilterCount} filters',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            );
          }
          
          final gem = _filteredGems[index - 1];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: GemCard(
              gem: gem,
              onTap: () {
                // Set navigation context before navigating to gem detail
                _updateNavigationContext();
                context.go('/gem/${gem.id}');
              },
            ),
          );
        },
      ),
    );
  }
}
