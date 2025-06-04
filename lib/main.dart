import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MyApp extends StatefulWidget {
  // ... (existing code)
}

class _MyAppState extends State<MyApp> {
  // ... (existing code)

  @override
  Widget build(BuildContext context) {
    // ... (existing code)

    return GoRouter(
      routes: [
        GoRoute(
          path: '/gems',
          builder: (context, state) => const GemsListScreen(),
        ),
      ],
    );
  }
} 