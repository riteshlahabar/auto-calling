import 'package:meta/meta.dart';

@immutable
class CallHistoryItem {
  final String number;   // e.g., "+1 (555) 123-4567"
  final String time;     // preformatted: "10:30 AM" or controller-formatted datetime
  final String status;   // normalized status string from your backend
  final String duration; // preformatted "mm:ss"

  const CallHistoryItem({
    required this.number,
    required this.time,
    required this.status,
    required this.duration,
  });

  factory CallHistoryItem.fromJson(Map<String, dynamic> json) {
    return CallHistoryItem(
      number: (json['number'] ?? '').toString(),
      time: (json['ended_at'] ?? json['time'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      duration: _formatSeconds((json['duration_sec'] as num?)?.toInt() ?? 0),
    );
  }

  static String _formatSeconds(int seconds) {
    final mm = (seconds ~/ 60).toString().padLeft(2, '0');
    final ss = (seconds % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }
}
