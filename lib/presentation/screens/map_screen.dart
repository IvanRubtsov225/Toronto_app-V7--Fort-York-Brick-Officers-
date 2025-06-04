import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../core/models/hidden_gem.dart';
import '../../core/providers/gems_provider.dart';
import '../../core/providers/location_provider.dart';
import '../widgets/toronto_app_bar.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  
  // Toronto coordinates
  static const LatLng torontoCenter = LatLng(43.6532, -79.3832);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GemsProvider>().loadAllGems();
      context.read<LocationProvider>().initializeLocation();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Toronto Map'),
      ),
      body: const Center(
        child: Text('Map View Coming Soon!'),
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
        return Icons.restaurant;
      case GemCategory.cafe:
        return Icons.coffee;
      case GemCategory.park:
        return Icons.park;
      case GemCategory.museum:
        return Icons.museum;
      case GemCategory.shopping:
        return Icons.shopping_bag;
      case GemCategory.entertainment:
        return Icons.theater_comedy;
      case GemCategory.historical:
        return Icons.account_balance;
      case GemCategory.viewpoint:
        return Icons.visibility;
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
    }
  }

  void _centerOnToronto() {
    _mapController.move(torontoCenter, 13.0);
  }

  void _showGemDetails(BuildContext context, HiddenGem gem) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              gem.name,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              gem.address,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Chip(
                  label: Text('Score: ${gem.hiddenGemScore.toStringAsFixed(1)}'),
                  backgroundColor: _getGemColor(gem).withOpacity(0.1),
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text(gem.category.displayName),
                  backgroundColor: Colors.grey[200],
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Navigate to gem details
                },
                child: const Text('View Details'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;

  const _LegendItem({
    required this.color,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 10,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
} 