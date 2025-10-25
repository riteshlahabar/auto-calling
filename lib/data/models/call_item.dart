// lib/data/models/call_item.dart
class CallItem {
  final String displayNumber;
  final String? displayName;
  final Duration duration;
  const CallItem({required this.displayNumber, this.displayName, this.duration = Duration.zero});
}



