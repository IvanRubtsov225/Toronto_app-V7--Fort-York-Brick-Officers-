import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/location_provider.dart';
import 'core/providers/gems_provider.dart';
import 'core/providers/events_provider.dart';
import 'core/services/location_service.dart';
import 'core/services/api_service.dart';
import 'presentation/screens/splash_screen.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/gems_list_screen.dart';
import 'presentation/screens/gem_detail_screen.dart';
import 'presentation/screens/events_screen.dart';
import 'presentation/screens/map_screen.dart';
import 'presentation/screens/settings_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Set Toronto-themed status bar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
      ),
  );

  runApp(TorontoApp());
}

class TorontoApp extends StatelessWidget {
  TorontoApp({super.key});

  final GoRouter _router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/gems',
        builder: (context, state) => const GemsListScreen(),
      ),
      GoRoute(
        path: '/gem/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return GemDetailScreen(gemId: id);
        },
      ),
      GoRoute(
        path: '/events',
        builder: (context, state) => const EventsScreen(),
      ),
      GoRoute(
        path: '/map',
        builder: (context, state) => const MapScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<LocationService>(
          create: (_) => LocationService(),
        ),
        Provider<ApiService>(
          create: (_) => ApiService(),
        ),
        ChangeNotifierProvider<LocationProvider>(
          create: (context) => LocationProvider(
            locationService: context.read<LocationService>(),
          ),
        ),
        ChangeNotifierProvider<GemsProvider>(
          create: (context) => GemsProvider(
            apiService: context.read<ApiService>(),
      ),
        ),
        ChangeNotifierProvider<EventsProvider>(
          create: (context) => EventsProvider(
            apiService: context.read<ApiService>(),
          ),
        ),
      ],
      child: MaterialApp.router(
        title: 'The Toronto App 🍁',
        debugShowCheckedModeBanner: false,
        theme: TorontoAppTheme.lightTheme,
        routerConfig: _router,
      ),
    );
  }
}
