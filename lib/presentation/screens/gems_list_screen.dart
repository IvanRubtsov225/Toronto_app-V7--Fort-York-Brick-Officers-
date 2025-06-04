import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/hidden_gem.dart';
import '../../core/providers/gems_provider.dart';
import '../widgets/gem_card.dart';
import '../widgets/toronto_app_bar.dart';

class GemsListScreen extends StatefulWidget {
  const GemsListScreen({super.key});

  @override
  State<GemsListScreen> createState() => _GemsListScreenState();
}

class _GemsListScreenState extends State<GemsListScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TorontoAppBar(
        title: 'Hidden Gems',
        subtitle: 'Discover Toronto\'s best kept secrets',
      ),
      body: Consumer<GemsProvider>(
        builder: (context, gemsProvider, child) {
          if (gemsProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (gemsProvider.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Error loading gems',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => gemsProvider.refresh(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: gemsProvider.allGems.length,
            itemBuilder: (context, index) {
              final gem = gemsProvider.allGems[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: GemCard(gem: gem),
              );
            },
          );
        },
      ),
    );
  }
} 