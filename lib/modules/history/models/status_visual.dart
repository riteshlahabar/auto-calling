import 'package:flutter/material.dart';

class StatusVisual {
  final Color badgeBg;
  final Color badgeFg;
  final IconData icon;
  const StatusVisual({required this.badgeBg, required this.badgeFg, required this.icon});
}

StatusVisual statusVisualFor(String status) {
  switch (status) {
    case 'Connected':
    case 'Interested':
    case 'Demo':
    case 'Send Info':
    case 'Intro Call':
      return StatusVisual(
        badgeBg: Colors.green.withOpacity(0.1),
        badgeFg: Colors.green,
        icon: Icons.call_made,
      );
    case 'Disconnected':
      return StatusVisual(
        badgeBg: Colors.red.withOpacity(0.1),
        badgeFg: Colors.red,
        icon: Icons.call_missed,
      );
    case 'Busy':
    case 'Call Back':
    default:
      return StatusVisual(
        badgeBg: Colors.amber.withOpacity(0.1),
        badgeFg: Colors.amber[700]!,
        icon: Icons.phone_paused,
      );
  }
}
