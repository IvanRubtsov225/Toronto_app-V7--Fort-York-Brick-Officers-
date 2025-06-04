import 'package:flutter/material.dart';

class GemsListScreen extends StatefulWidget {
  const GemsListScreen({super.key});

  @override
  State<GemsListScreen> createState() => _GemsListScreenState();
}

class _GemsListScreenState extends State<GemsListScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hidden Gems')),
      body: const Center(child: Text('Gems List Coming Soon!')),
    );
  }
}
