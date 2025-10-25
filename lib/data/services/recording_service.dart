// lib/modules/recording/recording_service.dart
import 'dart:io';
import 'package:dio/dio.dart';

class RecordingService {
  final Dio _http;
  RecordingService(this._http);

  Future<void> uploadRecording({
    required String filePath,
    required String spreadsheetId,
    required String tabTitle,
    required int rowIndex,
    required String status,
    required int durationSec,
    required DateTime endedAt,
  }) async {
    // Extract file name and extension
    final name = filePath.split('/').last;
    final ext = name.split('.').last.toLowerCase();

    // Ensure file exists and is not empty
    final f = File(filePath);
    if (!await f.exists()) throw Exception('Recording file not found');

    var size = await f.length();
    if (size == 0) {
      await Future.delayed(const Duration(milliseconds: 200));
      size = await f.length();
      if (size == 0) throw Exception('Recording file is empty');
    }

    // Detect MIME subtype for supported formats
    String mimeSubtype;
    if (ext == 'amr') {
      mimeSubtype = 'amr';
    } else if (ext == 'pcm') {
      mimeSubtype =
          'wav'; // or 'x-pcm', though client's backend might treat this as 'wav'
    } else if (ext == 'm4a') {
      mimeSubtype = 'x-m4a';
    } else if (ext == 'mp3') {
      mimeSubtype = 'mpeg';
    } else if (ext == 'aac') {
      mimeSubtype = 'aac';
    } else if (ext == 'wav') {
      mimeSubtype = 'wav';
    } else {
      mimeSubtype = 'mpeg'; // fallback
    }

    // Read file bytes and create multipart part with correct MIME type
    final bytes = await File(filePath).readAsBytes();
    final part = MultipartFile.fromBytes(
      bytes,
      filename: name,
      contentType: DioMediaType('audio', mimeSubtype),
    );

    // Form data with all required fields
    final form = FormData.fromMap({
      'audio': part,
      'spreadsheet_id': spreadsheetId,
      'tab_title': tabTitle,
      'row_index': rowIndex,
      'status': status,
      'duration_sec': durationSec,
      'ended_at': endedAt.toUtc().toIso8601String(),
    });

    // Perform the upload request
    final res = await _http.post(
      '/v1/recordings',
      data: form,
      options: Options(
        headers: const {'Accept': 'application/json'},
        contentType: 'multipart/form-data',
      ),
    );

    // Handle unsuccessful response
    if (res.statusCode != 201) {
      throw DioException(
        requestOptions: res.requestOptions,
        response: res,
        message: 'Recording upload failed',
        type: DioExceptionType.badResponse,
      );
    }    
  }
}
