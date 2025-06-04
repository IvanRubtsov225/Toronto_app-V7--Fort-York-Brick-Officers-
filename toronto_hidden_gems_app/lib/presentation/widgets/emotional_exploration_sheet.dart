import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/gems_provider.dart';

class EmotionalExplorationSheet extends StatefulWidget {
  const EmotionalExplorationSheet({super.key});

  @override
  State<EmotionalExplorationSheet> createState() => _EmotionalExplorationSheetState();
}

class _EmotionalExplorationSheetState extends State<EmotionalExplorationSheet> {
  final List<MoodOption> moods = [
    MoodOption(
      name: 'Romantic',
      emoji: '💕',
      description: 'Perfect for date nights and intimate moments',
      color: Colors.pink,
      gradient: [Colors.pink.shade300, Colors.pink.shade500],
    ),
    MoodOption(
      name: 'Foodie',
      emoji: '🍽️',
      description: 'Discover culinary adventures and unique flavors',
      color: Colors.orange,
      gradient: [Colors.orange.shade300, Colors.orange.shade500],
    ),
    MoodOption(
      name: 'Adventure',
      emoji: '🌟',
      description: 'Exciting experiences and thrilling discoveries',
      color: Colors.purple,
      gradient: [Colors.purple.shade300, Colors.purple.shade500],
    ),
    MoodOption(
      name: 'Relaxing',
      emoji: '🌸',
      description: 'Peaceful spots to unwind and recharge',
      color: Colors.green,
      gradient: [Colors.green.shade300, Colors.green.shade500],
    ),
    MoodOption(
      name: 'Cultural',
      emoji: '🎭',
      description: 'Rich heritage and artistic experiences',
      color: Colors.indigo,
      gradient: [Colors.indigo.shade300, Colors.indigo.shade500],
    ),
    MoodOption(
      name: 'Nightlife',
      emoji: '🌙',
      description: 'Vibrant evening entertainment and socializing',
      color: Colors.deepPurple,
      gradient: [Colors.deepPurple.shade300, Colors.deepPurple.shade500],
    ),
    MoodOption(
      name: 'Budget',
      emoji: '💰',
      description: 'Great experiences that won\'t break the bank',
      color: Colors.teal,
      gradient: [Colors.teal.shade300, Colors.teal.shade500],
    ),
    MoodOption(
      name: 'Family',
      emoji: '👨‍👩‍👧‍👦',
      description: 'Fun activities perfect for families with kids',
      color: Colors.amber,
      gradient: [Colors.amber.shade300, Colors.amber.shade500],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
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
          
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  'How are you feeling? 💖',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.primaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose your mood and discover hidden gems that match your vibe',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          // Mood grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.85,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: moods.length,
              itemBuilder: (context, index) {
                final mood = moods[index];
                return _buildMoodCard(context, mood);
              },
            ),
          ),
          
          // Close button
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(color: Colors.grey[300]!),
                ),
                child: Text(
                  'Maybe Later',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodCard(BuildContext context, MoodOption mood) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: () => _selectMood(context, mood),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: mood.gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: mood.color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              mood.emoji,
              style: const TextStyle(fontSize: 40),
            ),
            const SizedBox(height: 12),
            Text(
              mood.name,
              style: theme.textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              mood.description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white.withOpacity(0.9),
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _selectMood(BuildContext context, MoodOption mood) async {
    // Close the bottom sheet
    Navigator.of(context).pop();
    
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: mood.color,
              ),
              const SizedBox(height: 16),
              Text(
                'Finding ${mood.name.toLowerCase()} gems...',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
    
    try {
      // Filter gems by mood
      final gemsProvider = context.read<GemsProvider>();
      await gemsProvider.filterByMood(mood.name);
      
      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
        
        // Navigate to gems list with filtered results
        context.go('/gems');
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Found ${gemsProvider.filteredGems.length} ${mood.name.toLowerCase()} gems! ${mood.emoji}',
            ),
            backgroundColor: mood.color,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
        
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Oops! Couldn\'t find ${mood.name.toLowerCase()} gems. Try again!'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }
}

class MoodOption {
  final String name;
  final String emoji;
  final String description;
  final Color color;
  final List<Color> gradient;

  MoodOption({
    required this.name,
    required this.emoji,
    required this.description,
    required this.color,
    required this.gradient,
  });
} 