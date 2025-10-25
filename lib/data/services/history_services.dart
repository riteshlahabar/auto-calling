import 'package:dio/dio.dart';

class HistoryService {
  HistoryService(this._dio);

  final Dio _dio;

  // Adjust to match your backend route if different.
  // Alternative examples you might use:
  // static const String path = '/v1/sheets/rows/history';
  static const String path = '/v1/sheets/rows/status-report';

  Future<List<Map<String, dynamic>>> fetchStatusReport({
    required String spreadsheetId,
    required String tabTitle,
    String? status, // null -> All
    String? query,  // optional search term
    int page = 1,
    int perPage = 50,
    DateTime? from,
    DateTime? to,
  }) async {
    final qp = <String, dynamic>{
      'spreadsheet_id': spreadsheetId,
      'tab_title': tabTitle,
      'page': page,
      'per_page': perPage,
      if (status != null && status.isNotEmpty) 'status': status,
      if (query != null && query.isNotEmpty) 'q': query,
      if (from != null) 'from': from.toIso8601String(),
      if (to != null) 'to': to.toIso8601String(),
    };

    final res = await _dio.get(path, queryParameters: qp);

    // Expected response formats:
    // 1) { data: [ ... ] }
    // 2) [ ... ]
    final data = res.data;
    final List list = (data is Map && data['data'] is List)
        ? (data['data'] as List)
        : (data is List ? data : const []);

    return list.map<Map<String, dynamic>>(
      (e) => Map<String, dynamic>.from(e as Map),
    ).toList();
  }
}
