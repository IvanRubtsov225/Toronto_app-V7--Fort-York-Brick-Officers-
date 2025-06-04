import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;
import '../../core/providers/location_provider.dart';
import '../../core/providers/gems_provider.dart';
import '../../core/models/hidden_gem.dart';
import '../widgets/gem_card.dart';
import '../widgets/toronto_app_bar.dart';
import '../widgets/location_status_card.dart';

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
      _loadNearbyGems();
    });
  }

  Future<void> _loadNearbyGems() async {
    final gemsProvider = context.read<GemsProvider>();
    final locationProvider = context.read<LocationProvider>();
    
    print('🏠 HomeScreen: Starting to load gems...');
    print('🏠 Current gems count: ${gemsProvider.allGems.length}');
    print('🏠 Loading state: ${gemsProvider.loadingState}');
    
    // First ensure we have all gems loaded
    if (gemsProvider.allGems.isEmpty) {
      print('🏠 No gems loaded, initializing from API...');
      await gemsProvider.initialize();
      print('🏠 After initialization, gems count: ${gemsProvider.allGems.length}');
      print('🏠 Loading state after init: ${gemsProvider.loadingState}');
      print('🏠 Has error: ${gemsProvider.hasError}');
      if (gemsProvider.hasError) {
        print('🏠 Error details: ${gemsProvider.error}');
      }
    }
    
    // Debug: print first few gem names
    if (gemsProvider.allGems.isNotEmpty) {
      print('🏠 First 3 gems loaded:');
      for (int i = 0; i < math.min(3, gemsProvider.allGems.length); i++) {
        final gem = gemsProvider.allGems[i];
        print('🏠   ${i + 1}. ${gem.name} (Score: ${gem.hiddenGemScore}) - ${gem.address}');
      }
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
    // ... (existing code)
  }
} 