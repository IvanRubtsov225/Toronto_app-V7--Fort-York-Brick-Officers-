import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/location_provider.dart';
import '../widgets/toronto_app_bar.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const TorontoAppBar(
        title: 'Settings',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Info Card
            _buildInfoCard(
              context,
              title: 'Toronto Hidden Gems 🍁',
              subtitle: 'Discover the best of Toronto',
              icon: Icons.location_city_rounded,
              color: theme.primaryColor,
            ),
            
            const SizedBox(height: 24),
            
            // Location Section
            _buildSectionHeader(context, 'Location Services'),
            _buildLocationSettings(context),
            
            const SizedBox(height: 24),
            
            // App Section
            _buildSectionHeader(context, 'App Settings'),
            _buildAppSettings(context),
            
            const SizedBox(height: 24),
            
            // Support Section
            _buildSectionHeader(context, 'Support'),
            _buildSupportSettings(context),
            
            const SizedBox(height: 24),
            
            // About Section
            _buildSectionHeader(context, 'About'),
            _buildAboutSettings(context),
            
            const SizedBox(height: 100), // Bottom padding
          ],
        ),
      ),
      
      // Back to Home button
      bottomNavigationBar: SafeArea(
        child: Container(
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
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.go('/home'),
                  icon: const Icon(Icons.home_rounded),
                  label: const Text('Back to Home'),
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
              ElevatedButton.icon(
                onPressed: () => context.go('/gems'),
                icon: const Icon(Icons.location_city_rounded),
                label: const Text('View Gems'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color,
            color.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.primaryColor,
        ),
      ),
    );
  }

  Widget _buildLocationSettings(BuildContext context) {
    return Column(
      children: [
        Consumer<LocationProvider>(
          builder: (context, locationProvider, child) {
            return _buildSettingsTile(
              context,
              icon: Icons.location_on_rounded,
              title: 'Location Services',
              subtitle: locationProvider.isLocationEnabled
                  ? 'Enabled - Finding nearby gems'
                  : 'Disabled - Enable to find gems',
              trailing: Switch(
                value: locationProvider.isLocationEnabled,
                onChanged: (value) {
                  if (value) {
                    locationProvider.initializeLocation();
                  } else {
                    locationProvider.disableLocation();
                  }
                },
              ),
            );
          },
        ),
        
        _buildSettingsTile(
          context,
          icon: Icons.notifications_rounded,
          title: 'Proximity Notifications',
          subtitle: 'Get notified when near hidden gems',
          trailing: Switch(
            value: false, // TODO: Implement notifications
            onChanged: (value) {
              // TODO: Handle notification settings
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAppSettings(BuildContext context) {
    return Column(
      children: [
        _buildSettingsTile(
          context,
          icon: Icons.map_rounded,
          title: 'Default Map Style',
          subtitle: 'OpenStreetMap',
          onTap: () {
            // TODO: Implement map style selection
          },
        ),
        
        _buildSettingsTile(
          context,
          icon: Icons.filter_list_rounded,
          title: 'Default Filters',
          subtitle: 'Configure your gem preferences',
          onTap: () {
            // TODO: Implement default filters
          },
        ),
        
        _buildSettingsTile(
          context,
          icon: Icons.cached_rounded,
          title: 'Clear Cache',
          subtitle: 'Free up storage space',
          onTap: () {
            _showClearCacheDialog(context);
          },
        ),
      ],
    );
  }

  Widget _buildSupportSettings(BuildContext context) {
    return Column(
      children: [
        _buildSettingsTile(
          context,
          icon: Icons.help_outline_rounded,
          title: 'Help & FAQ',
          subtitle: 'Get answers to common questions',
          onTap: () {
            // TODO: Navigate to help screen
          },
        ),
        
        _buildSettingsTile(
          context,
          icon: Icons.feedback_rounded,
          title: 'Send Feedback',
          subtitle: 'Help us improve the app',
          onTap: () {
            _launchEmail();
          },
        ),
        
        _buildSettingsTile(
          context,
          icon: Icons.bug_report_rounded,
          title: 'Report a Bug',
          subtitle: 'Let us know about any issues',
          onTap: () {
            _launchEmail(isBugReport: true);
          },
        ),
      ],
    );
  }

  Widget _buildAboutSettings(BuildContext context) {
    return Column(
      children: [
        _buildSettingsTile(
          context,
          icon: Icons.info_outline_rounded,
          title: 'App Version',
          subtitle: '1.0.0 (Build 1)',
          onTap: null,
        ),
        
        _buildSettingsTile(
          context,
          icon: Icons.article_rounded,
          title: 'Terms of Service',
          subtitle: 'Read our terms and conditions',
          onTap: () {
            // TODO: Show terms of service
          },
        ),
        
        _buildSettingsTile(
          context,
          icon: Icons.privacy_tip_rounded,
          title: 'Privacy Policy',
          subtitle: 'Learn how we protect your data',
          onTap: () {
            // TODO: Show privacy policy
          },
        ),
        
        _buildSettingsTile(
          context,
          icon: Icons.code_rounded,
          title: 'Open Source Licenses',
          subtitle: 'View third-party licenses',
          onTap: () {
            _showLicensePage(context);
          },
        ),
      ],
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: theme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            icon,
            color: theme.primaryColor,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        trailing: trailing ?? (onTap != null 
            ? Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Colors.grey[400],
              )
            : null),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 4,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _showClearCacheDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text(
          'This will remove all cached data including images and map tiles. '
          'The app may need to download this data again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implement cache clearing
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cache cleared successfully'),
                ),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _launchEmail({bool isBugReport = false}) async {
    final subject = isBugReport ? 'Bug Report' : 'App Feedback';
    final body = isBugReport 
        ? 'Please describe the bug you encountered:\n\n'
        : 'Please share your feedback:\n\n';
    
    final uri = Uri(
      scheme: 'mailto',
      path: 'support@torontohiddengems.app',
      query: 'subject=$subject&body=$body',
    );
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _showLicensePage(BuildContext context) {
    showLicensePage(
      context: context,
      applicationName: 'Toronto Hidden Gems',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.location_city_rounded,
          color: Colors.white,
          size: 32,
        ),
      ),
    );
  }
} 