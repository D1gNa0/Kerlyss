import 'package:flutter/material.dart';

class DiscoveryEmptyState extends StatelessWidget {
  final bool hasQuery;

  const DiscoveryEmptyState({super.key, required this.hasQuery});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.explore_outlined, color: Colors.white10, size: 48),
          const SizedBox(height: 16),
          Text(
            hasQuery ? 'NO RESULTS FOUND' : 'START YOUR SEARCH',
            style: const TextStyle(color: Colors.white12, letterSpacing: 2, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
