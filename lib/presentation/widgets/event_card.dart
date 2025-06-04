import 'package:flutter/material.dart';
import '../../core/models/toronto_event.dart';

class EventCard extends StatelessWidget {
  final TorontoEvent event;
  final VoidCallback? onTap;

  const EventCard({
    super.key,
    required this.event,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with event category and buzz indicators
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Event category icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(event.category).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getCategoryIcon(event.category),
                      color: _getCategoryColor(event.category),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Event details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Event name
                        Text(
                          event.title.isNotEmpty ? event.title : event.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        
                        // Venue
                        Text(
                          event.venue,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Buzz and quality indicators
                  Column(
                    children: [
                      if (event.isFree)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'FREE',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      const SizedBox(height: 4),
                      if (event.isHiddenGem)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE31837).withOpacity(0.1), // Toronto red
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '💎 GEM',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: const Color(0xFFE31837),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Event timing and date
              Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatEventTime(),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  
                  // Neighborhood
                  Icon(
                    Icons.location_on_rounded,
                    size: 16,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    event.neighborhood,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Price and buzz metrics
              Row(
                children: [
                  // Price range
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: theme.colorScheme.outline.withOpacity(0.2),
                      ),
                    ),
                    child: Text(
                      event.priceRange.isNotEmpty ? event.priceRange : 'Price TBA',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Buzz score
                  Row(
                    children: [
                      Icon(
                        Icons.trending_up_rounded,
                        size: 14,
                        color: _getBuzzColor(event.redditBuzzScore),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        event.buzzLevel,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: _getBuzzColor(event.redditBuzzScore),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  
                  const Spacer(),
                  
                  // More actions
                  if (onTap != null)
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: theme.colorScheme.onSurface.withOpacity(0.4),
                    ),
                ],
              ),
              
              // Mood tags (if available)
              if (event.moodTagsList.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: event.moodTagsList.take(3).map((mood) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF003F7F).withOpacity(0.1), // Toronto blue
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        mood,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: const Color(0xFF003F7F),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(EventCategory category) {
    switch (category) {
      case EventCategory.music:
        return Icons.music_note_rounded;
      case EventCategory.food:
        return Icons.restaurant_rounded;
      case EventCategory.art:
        return Icons.palette_rounded;
      case EventCategory.sports:
        return Icons.sports_rounded;
      case EventCategory.festival:
        return Icons.celebration_rounded;
      case EventCategory.nightlife:
        return Icons.nightlife_rounded;
      case EventCategory.community:
        return Icons.groups_rounded;
      case EventCategory.cultural:
        return Icons.account_balance_rounded;
    }
  }

  Color _getCategoryColor(EventCategory category) {
    switch (category) {
      case EventCategory.music:
        return Colors.purple;
      case EventCategory.food:
        return Colors.orange;
      case EventCategory.art:
        return Colors.pink;
      case EventCategory.sports:
        return Colors.green;
      case EventCategory.festival:
        return Colors.amber;
      case EventCategory.nightlife:
        return Colors.indigo;
      case EventCategory.community:
        return Colors.blue;
      case EventCategory.cultural:
        return const Color(0xFFE31837); // Toronto red
    }
  }

  Color _getBuzzColor(double buzzScore) {
    if (buzzScore >= 80) return Colors.red;
    if (buzzScore >= 60) return Colors.orange;
    if (buzzScore >= 40) return Colors.yellow[700]!;
    return Colors.grey;
  }

  String _formatEventTime() {
    if (event.isToday) {
      return 'Today • ${_formatTime(event.startTime)}';
    } else if (event.startTime.difference(DateTime.now()).inDays == 1) {
      return 'Tomorrow • ${_formatTime(event.startTime)}';
    } else {
      return '${_formatDate(event.startTime)} • ${_formatTime(event.startTime)}';
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  String _formatDate(DateTime dateTime) {
    final months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dateTime.month]} ${dateTime.day}';
  }
} 