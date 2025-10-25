// lib/data/services/dialer_service.dart
import 'package:dialer_app/data/models/daily_summary.dart';
import 'package:dio/dio.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';

import '../models/contact.dart';

class DialerService {
  DialerService(
    this._http, {
    this.defaultRegion = IsoCode.IN,
    this.defaultRowsLimit = 600,
  });

  final Dio _http;
  final IsoCode defaultRegion;
  final int defaultRowsLimit;

  // Optional normalization to keep consistent phone format
  String normalize(String input) {
    try {
      final p = PhoneNumber.parse(input, callerCountry: defaultRegion);
      return p.international; // or p.e164 if desired
    } catch (_) {
      return input.trim();
    }
  }

  // Fetch assigned spreadsheet tab rows for the authenticated user (contacts only)
  // Server returns only blank-status rows when only_blank=true, in deterministic row order.
  Future<List<Contact>> fetchAssignedRowsAsContacts({
    int? rowsLimit,
    bool onlyBlank = true,
  }) async {
    final res = await _http.get(
      '/v1/sheets/rows/assigned',
      queryParameters: {
        'only_blank': onlyBlank,
        'rows_limit': rowsLimit ?? defaultRowsLimit,
      },
      options: Options(headers: const {'Accept': 'application/json'}),
    );
    if (res.statusCode == 200 &&
        res.data is Map &&
        (res.data['data'] is List)) {
      final List list = res.data['data'] as List;
      return list.map((e) {
        final m = Map<String, dynamic>.from(e as Map);
        final name = (m['name'] ?? '') as String;
        final number = (m['number'] ?? '') as String;
        return Contact(name: name, phone: number);
      }).toList();
    }
    return <Contact>[];
  }

  // Fetch assigned rows with all raw fields (rowIndex, name, number, status)
  Future<List<Map<String, dynamic>>> fetchAssignedRowsRaw({
    int? rowsLimit,
    bool onlyBlank = true,
  }) async {
    final res = await _http.get(
      '/v1/sheets/rows/assigned',
      queryParameters: {
        'only_blank': onlyBlank,
        'rows_limit': rowsLimit ?? defaultRowsLimit,
      },
      options: Options(headers: const {'Accept': 'application/json'}),
    );
    if (res.statusCode == 200 &&
        res.data is Map &&
        (res.data['data'] is List)) {
      return List<Map<String, dynamic>>.from(
        (res.data['data'] as List).map(
          (e) => Map<String, dynamic>.from(e as Map),
        ),
      );
    }
    return <Map<String, dynamic>>[];
  }

  // Fetch assigned rows with meta included (spreadsheet_id, tab_title, etc.)
  Future<Map<String, dynamic>> fetchAssignedRowsBundle({
    int? rowsLimit,
    bool onlyBlank = true,
  }) async {
    final res = await _http.get(
      '/v1/sheets/rows/assigned',
      queryParameters: {
        'only_blank': onlyBlank,
        'rows_limit': rowsLimit ?? defaultRowsLimit,
      },
      options: Options(headers: const {'Accept': 'application/json'}),
    );

    if (res.statusCode == 200 && res.data is Map) {
      final map = Map<String, dynamic>.from(res.data as Map);
      final dataList = List<Map<String, dynamic>>.from(
        (map['data'] as List? ?? const []),
      );
      final metaMap = Map<String, dynamic>.from(
        (map['meta'] as Map? ?? const {}),
      );
      return {'data': dataList, 'meta': metaMap};
    }

    return {'data': <Map<String, dynamic>>[], 'meta': <String, dynamic>{}};
  }

  // Report call result so backend updates status and daily counters
  // Endpoint expects spreadsheet_id, tab_title, row_index, status, optional duration_sec and ended_at.
  // data/services/dialer_service.dart (update reportResult to return the summary)
Future<DailySummary?> reportResult({
  required String spreadsheetId,
  required String tabTitle,
  required int rowIndex,
  required String status,
  int? durationSec,
  DateTime? endedAt,
}) async {
  final payload = <String, dynamic>{
    'spreadsheet_id': spreadsheetId,
    'tab_title': tabTitle,
    'row_index': rowIndex,
    'status': status,
    if (durationSec != null) 'duration_sec': durationSec,
    if (endedAt != null) 'ended_at': endedAt.toIso8601String(),
  };

  final res = await _http.post(
    '/v1/dial/result',
    data: payload,
    options: Options(headers: const {'Accept': 'application/json'}),
  );

  // Dio decodes JSON for you; res.data is already a Map or List as appropriate.
  // Parse daily_summary directly if present.
  if (res.statusCode == 200 || res.statusCode == 201) {
    final body = res.data as Map; // already decoded JSON
    final ds = body['daily_summary'];
    if (ds is Map) {
      return DailySummary.fromMap(Map<String, dynamic>.from(ds));
    }
    return null;
  }

  throw DioException(
    requestOptions: res.requestOptions,
    response: res,
    message: 'Failed to report result',
    type: DioExceptionType.badResponse,
  );
}


  // Optional: fetch daily stats (total/dialed/pending/connected, midnight boundary)
  // In DialerService
// DialerService
Future<Map<String, dynamic>> fetchDailyStats() async {
  final res = await _http.get('/v1/dialer/daily-stats',
    options: Options(headers: const {'Accept': 'application/json'}));
  if (res.statusCode == 200) {
    return Map<String, dynamic>.from(res.data as Map);
  }
  throw DioException(
    requestOptions: res.requestOptions,
    response: res,
    message: 'Failed to fetch daily stats',
    type: DioExceptionType.badResponse,
  );
}



// Example: POST to /v1/calls/status (relative to baseUrl)
Future<void> postCallStatus({
  required String callId,        // or rowIndex, etc., per backend spec
  required String status,        // e.g., 'connected', 'no_answer', etc.
  int? durationSec,
  DateTime? endedAt,
  Map<String, dynamic>? extra,   // optional extra payload
}) async {
  final payload = <String, dynamic>{
    'call_id': callId,
    'status': status,
    if (durationSec != null) 'duration_sec': durationSec,
    if (endedAt != null) 'ended_at': endedAt.toIso8601String(),
    if (extra != null) ...extra,
  };

  final res = await _http.post(
    '/v1/calls/status', 
    data: payload,
    options: Options(headers: const {'Accept': 'application/json'}),
  );

  if (res.statusCode != 200 && res.statusCode != 201) {
    throw DioException(
      requestOptions: res.requestOptions,
      response: res,
      message: 'Failed to post call status',
      type: DioExceptionType.badResponse,
    );
  }
}

  // Optional: dynamic status options (kept for compatibility)
  Future<List<String>> fetchStatusTemplates() async {
    final res = await _http.get(
      '/v1/templates',
      options: Options(headers: const {'Accept': 'application/json'}),
    );
    if (res.statusCode == 200 && res.data is Map) {
      final list = (res.data['data'] as List?) ?? const [];
      return list
          .map<String>((e) {
            if (e is String) return e;
            if (e is Map) {
              final m = Map<String, dynamic>.from(e);
              return (m['name'] ?? m['label'] ?? '').toString();
            }
            return '';
          })
          .where((s) => s.isNotEmpty)
          .toList();
    }
    return <String>[];
  }
}
