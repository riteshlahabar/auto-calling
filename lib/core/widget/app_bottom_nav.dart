// lib/core/widgets/app_bottom_nav.dart
import 'package:flutter/material.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const AppBottomNav({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      backgroundColor: Theme.of(context).colorScheme.surface,
      destinations: const [
        NavigationDestination(icon: Icon(Icons.dialpad), label: 'Dialer'),
        NavigationDestination(icon: Icon(Icons.history), label: 'History'),
        NavigationDestination(icon: Icon(Icons.chat_bubble_outline), label: 'WhatsApp'),
      ],
      indicatorColor: cs.primary.withOpacity(0.12),
    );
  }
}
