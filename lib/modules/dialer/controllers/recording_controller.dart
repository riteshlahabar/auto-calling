import 'package:flutter/services.dart';

class RecordingController {
  static const MethodChannel _channel = MethodChannel(
    'com.yourcompany.yourapp/recording',
  );

  static Future<void> requestPermissions() async {
    await _channel.invokeMethod('requestPermissions');
    print("🎙️ Requesting recording permissions...");
  }

  static Future<void> startRecording({int? rowIndex}) async {
  await _channel.invokeMethod('startRecording', {'rowIndex': rowIndex});
  print("🎙️ Starting recording with rowIndex: $rowIndex");
  print("✅ Recording started successfully");
}

  static Future<String?> getRecordedFilePath() async {
    final String? path = await _channel.invokeMethod('getRecordedFilePath');
    if (path == null || path.isEmpty) return null;
    return path;
  }

  static Future<void> stopRecording() async {
    await _channel.invokeMethod('stopRecording');
    print("🛑 Stopping recording...");
  }
}
