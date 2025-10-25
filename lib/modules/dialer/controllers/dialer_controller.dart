// lib/modules/dialer/controllers/dialer_controller.dart
import 'dart:async';
import 'dart:io';
import 'package:dialer_app/data/models/call_stats.dart';
import 'package:dialer_app/modules/dialer/controllers/recording_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart'; // AppLifecycleListener, WidgetsBinding [endOfFrame]
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:phone_state/phone_state.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';

import '../../../data/models/call_item.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/dialer_service.dart';
import '../../../data/services/recording_service.dart';
import '../views/status_popup_view.dart';

class DialerController extends GetxController {
  DialerController(this._auth, this.dialer, this.recService);
  final AuthService _auth;
  final DialerService dialer;
   // <-- add
  final RecordingService recService; // <-- add

  // UI state
  final isFinished = false.obs;
  final stats = const CallStats(total: 0, connected: 0).obs;
  final current = const CallItem(
    displayNumber: '',
    displayName: null,
    duration: Duration.zero,
  ).obs;
  final next = const CallItem(
    displayNumber: '',
    displayName: null,
    duration: Duration.zero,
  ).obs;
  final isRunning = false.obs;
  final navIndex = 0.obs;
  final isPaused = false.obs;
  final isLoading = false.obs;
  final statusText = ''.obs;

  // Internal state
  final _queue = <CallItem>[].obs;
  final _connectedCount = 0.obs;
  final _index = (-1).obs;
  StreamSubscription<PhoneState>? _phoneSub;
  DateTime? _callStartAt;

  // Assignment meta
  String? _assignedSpreadsheetId;
  String? _assignedTabTitle;
  final Map<String, int> _rowIndexByNumber = {};
  final List<int> _queueRowIndexes = <int>[]; // rowIndex per queue entry

  // Popup lifecycle and re-entrancy guards
  late final AppLifecycleListener _life;
  bool _pendingPopup = false;
  String? _pendingNumber;
  bool _statusDialogShowing = false; // prevents stacked dialogs

  final dailyDialed = 0.obs; // RxInt [web:728]
  final dailyConnected = 0.obs; // RxInt [web:728]

  // use .value [web:742]

  // Fixed options for popup (no network fetch)
  static const List<String> kStatusOptions = <String>[
    'SELECT OUTCOME',
    'NO ANSWER',
    'BUSY',
    'SWITCHED OFF',
    'CALL BACK',
    'WRONG NUMBER',
    'NOT INTERESTED',
    'INTRO CALL',
    'DEMO',
    'INTERESTED',
    'SEND INFO',
    'BUSINESS CLOSED',
    'OUT OF SERVICE',
  ];

  @override
  void onInit() {
    super.onInit();
    _life = AppLifecycleListener(onResume: _onAppResume);
    _bootstrap();
  }

  @override
  void onClose() {
    // Release suppression on controller dispose.
    _auth.resumeLogout();
    _life.dispose();
    _phoneSub?.cancel();
    super.onClose();
  }

  Future<void> _bootstrap() async {
    isLoading.value = true;
    try {
      await _auth.loadSession();
      await _loadDailySummary();
      await _loadAssignedFromBackend(); // server returns blank-only rows in order
      _wirePhoneState();
      _updateHeader();
    } catch (e) {
      Get.snackbar(
        'Dialer',
        'Init failed: $e',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadDailySummary() async {
    try {
      // Expecting a Map with keys: service_day, dialed_calls, connected_calls
      final s = await dialer.fetchDailyStats();
      dailyDialed.value = int.tryParse('${s['dialed_calls']}') ?? 0;
      dailyConnected.value = int.tryParse('${s['connected_calls']}') ?? 0;
    } catch (_) {
      // Optional: keep defaults on failure; no UI block
    }
  }

  Future<void> _loadAssignedFromBackend() async {
    try {
      // { data: [{rowIndex,name,number,status},...], meta: {spreadsheet_id, tab_title} }
      final bundle = await dialer
          .fetchAssignedRowsBundle(); // only_blank + rows_limit handled in service
      final List<dynamic> rows = List<dynamic>.from(
        bundle['data'] as List? ?? const [],
      );
      final meta = Map<String, dynamic>.from(
        bundle['meta'] as Map? ?? const {},
      );

      _assignedSpreadsheetId = meta['spreadsheet_id'] as String?;
      _assignedTabTitle = meta['tab_title'] as String?;

      _rowIndexByNumber.clear();
      _queueRowIndexes.clear();
      final items = <CallItem>[];

      for (final r in rows) {
        final m = Map<String, dynamic>.from(r as Map);
        final name = (m['name'] ?? '') as String;
        final number = (m['number'] ?? '') as String;
        if (number.trim().isEmpty) continue;
        final rowIndex = (m['rowIndex'] as num).toInt();

        final normalized = _normalize(number);
        if (normalized.isEmpty) continue;

        _rowIndexByNumber[normalized] = rowIndex;
        _queueRowIndexes.add(rowIndex);
        items.add(
          CallItem(
            displayNumber: number,
            displayName: name.isEmpty ? null : name,
            duration: Duration.zero,
          ),
        );
      }

      _queue
        ..clear()
        ..assignAll(items);
      _connectedCount.value = 0;
      _index.value =
          -1; // no client progress restore; start() advances to first blank

      _recomputeStats();
      _peekNeighbors();
    } catch (e) {
      Get.snackbar(
        'Dialer',
        'Load failed: $e',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    }
  }

  String _normalize(String input) {
    try {
      final p = PhoneNumber.parse(input, callerCountry: IsoCode.IN);
      return p.international; // or p.e164
    } catch (_) {
      return input.trim();
    }
  }

  void _recomputeStats() {
    final total = _queue.length; // total blanks fetched [web:682]
    final connected = _index.value + 1; // progressed count [web:682]
    stats.value = CallStats(
      total: total,
      connected: connected,
    ); // keep for progress bar [web:682]
  }

  void _peekNeighbors() {
    final i = _index.value;
    current.value = (i >= 0 && i < _queue.length)
        ? _queue[i]
        : const CallItem(displayNumber: '', displayName: null);
    next.value = (i + 1 >= 0 && i + 1 < _queue.length)
        ? _queue[i + 1]
        : const CallItem(displayNumber: '', displayName: null);
  }

  void _updateHeader() {
    if (_queue.isEmpty) {
      statusText.value = 'No contacts to dial'; // nothing to do [web:682]
    } else if (_index.value < 0) {
      statusText.value =
          'Ready (${_queue.length} contacts)'; // before first call [web:682]
    } else {
      statusText.value =
          'Dialing ${_index.value + 1}/${_queue.length}'; // in progress [web:682]
    }
  }

  int get pending {
    final total = _queue.length; // all fetched blanks in serial order [web:728]
    final progressed = (_index.value + 1).clamp(
      0,
      total,
    ); // completed/current position [web:728]
    return (total - progressed).clamp(
      0,
      total,
    ); // remaining to last blank [web:728]
  }

  Future<bool> _ensurePermissions() async {
    final phone = await Permission.phone.request();
    return phone.isGranted;
  }

  void setNav(int idx) => navIndex.value = idx;

  Future<void> start() async {
    if (_queue.isEmpty) {
      statusText.value = 'No contacts to dial';
      return;
    }
    if (isFinished.value || _index.value >= _queue.length - 1) {
      isRunning.value = false;
      isPaused.value = false;
      statusText.value = 'Call list finished';
      current.value = const CallItem(displayNumber: '', displayName: null);
      next.value = const CallItem(displayNumber: '', displayName: null);
      return;
    }
    if (!await _ensurePermissions()) {
      statusText.value = 'Phone permission denied';
      return;
    }
    isRunning.value = true;
    isPaused.value = false;

    var i = _index.value;
    if (i < 0) {
      i = 0; // first blank row
    } else if (i < _queue.length - 1) {
      i = i + 1;
    } else {
      statusText.value = 'Completed ${_queue.length} calls';
      isRunning.value = false;
      return;
    }
    _index.value = i;
    _recomputeStats(); //added here to update stats on start
    _peekNeighbors();
    _updateHeader();
    await _dialCurrent();
  }

  void stop() {
    isRunning.value = false;
    isPaused.value = false;
    _peekNeighbors();
    _updateHeader();
  }

  void pause() {
    isPaused.value = true;
    statusText.value = 'Paused';
  }

  Future<void> nextNumber() async {
    if (_queue.isEmpty) return;
    final n = _index.value + 1;
    if (n >= _queue.length) {
      isRunning.value = false;
      isPaused.value = false;
      isFinished.value = true;
      statusText.value = 'Call list finished';
      current.value = const CallItem(displayNumber: '', displayName: null);
      next.value = const CallItem(displayNumber: '', displayName: null);
      statusText.value = 'Completed ${_queue.length} calls';
      Get.snackbar(
        'Dialer',
        statusText.value,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
      return;
    }
    _recomputeStats(); //added here to update stats on next
    _index.value = n;
    _recomputeStats();
    _peekNeighbors();
    _updateHeader();
    if (isRunning.value && !isPaused.value) {
      await _dialCurrent();
    }
  }

  Future<void> prevNumber() async {
    if (_queue.isEmpty) return;
    final p = _index.value - 1;
    if (p < 0) {
      statusText.value = 'At beginning';
      return;
    }
    _index.value = p;
    _recomputeStats();
    _peekNeighbors();
    _updateHeader();
    if (isRunning.value && !isPaused.value) {
      await _dialCurrent();
    }
  }

  Future<void> _dialCurrent() async {
    if (!isRunning.value || isPaused.value) return;
    final i = _index.value;
    if (i < 0 || i >= _queue.length) return;

    final item = _queue[i];
    statusText.value = 'Dialing ${item.displayName ?? item.displayNumber}';

    // Let the frame paint updated UI before launching native dialer
    await WidgetsBinding.instance.endOfFrame;

    _callStartAt = DateTime.now();
    try {
      await FlutterPhoneDirectCaller.callNumber(item.displayNumber);
      // CALL_ENDED will be received by phone_state
    } catch (e) {
      Get.snackbar(
        'Dialer',
        'Call failed: $e',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    }
  }

  void _wirePhoneState() {
    _phoneSub?.cancel();
    _phoneSub = PhoneState.stream.listen((PhoneState event) async {
      final st = event.status;
      final dur = event.duration;

      if (st == PhoneStateStatus.CALL_STARTED) {
        // Prevent auto-logout while system Phone UI takes focus.
        _auth.suppressLogout(); // engage guard
        _callStartAt = DateTime.now();
        // Determine rowIndex for filename context
        final i = _index.value;
        final rowIndex = (i >= 0 && i < _queueRowIndexes.length)
            ? _queueRowIndexes[i]
            : 0;

        // Start mic recording with foreground service
        await RecordingController.startRecording(rowIndex: rowIndex);
      }

      if (st == PhoneStateStatus.CALL_ENDED) {
        final d =
            dur ??
            (_callStartAt != null
                ? DateTime.now().difference(_callStartAt!)
                : Duration.zero);

        if (_index.value >= 0 && _index.value < _queue.length) {
          final cur = _queue[_index.value];
          current.value = CallItem(
            displayNumber: cur.displayNumber,
            displayName: cur.displayName,
            duration: d,
          );
          if (d.inSeconds >= 3) {
            _connectedCount.value++;
            _recomputeStats();
          }

          await RecordingController.stopRecording();

          _pendingNumber = cur.displayNumber;
          _pendingPopup = true;
          await _tryShowStatusPopup(); // show outcomes UI
        }

        _callStartAt = null;

        // Keep suppression for a short grace so any resume-time requests
        // or late 401s don't log the user out mid-popup.
        _auth.suppressLogout(grace: const Duration(seconds: 8));
      }
    });
  }

  void _onAppResume() {
    // Do not logout on resume; just ensure popup is shown if pending.
    if (_pendingPopup) {
      _tryShowStatusPopup();
    }
  }

  Future<void> _tryShowStatusPopup() async {
    if (!_pendingPopup || _pendingNumber == null) return;

    // Prevent stacked dialogs from CALL_ENDED and onResume racing
    if (_statusDialogShowing) return;
    _statusDialogShowing = true;

    // Prefer a navigator-capable context
    BuildContext? ctx = Get.context ?? Get.overlayContext;
    if (ctx == null) {
      _statusDialogShowing = false;
      return;
    }

    final number = _pendingNumber!;
    final normalized = _normalize(number);
    final rowIndex =
        _rowIndexByNumber[normalized] ?? _rowIndexByNumber[number.trim()];
    if (rowIndex == null) {
      _pendingPopup = false;
      _pendingNumber = null;
      _statusDialogShowing = false;
      return;
    }

    final spreadsheetId = _assignedSpreadsheetId;
    final tabTitle = _assignedTabTitle;
    if (spreadsheetId == null || tabTitle == null) {
      _pendingPopup = false;
      _pendingNumber = null;
      _statusDialogShowing = false;
      return;
    }

    try {
      // Show blocking popup; barrierDismissible=false avoids accidental duplicates
      await StatusPopupView.show(
        context: ctx,
        loadStatuses: () async => kStatusOptions,
        onSubmit: (status) async {
          final s = await dialer.reportResult(
            spreadsheetId: spreadsheetId,
            tabTitle: tabTitle,
            rowIndex: rowIndex,
            status: status,
            durationSec: current.value.duration.inSeconds,
            endedAt: DateTime.now(),
          );
          if (s != null) {
            dailyDialed.value = s.dialedCalls; // triggers Obx rebuilds
            dailyConnected.value = s.connectedCalls;
          }

          final path = await RecordingController.getRecordedFilePath();
          if (path != null) {
            try {
              await recService.uploadRecording(
                filePath: path,
                spreadsheetId: spreadsheetId,
                tabTitle: tabTitle,
                rowIndex: rowIndex,
                status: status,
                durationSec: current.value.duration.inSeconds,
                endedAt: DateTime.now(),
              );
              // Clean local temp file
              try {
                await File(path).delete();
              } catch (_) {}
            } catch (e) {
              Get.snackbar(
                'Recording',
                'Upload failed: $e\nPath: $path',
                snackPosition: SnackPosition.BOTTOM,
                duration: const Duration(seconds: 3),
              );
              // Keep file if you want a manual retry flow (skip delete)
            }
          }
          // Do NOT call nextNumber here; dialog will pop and return to dialer screen
        },
        // Do NOT call nextNumber here; dialog will pop and return to dialer screen
        title: 'Select Call Outcome',
        barrierDismissible: false,
      );

      // After the dialog is closed, ensure dialer screen shows, then wait 10s before next call
      await WidgetsBinding.instance.endOfFrame;

      statusText.value = 'Next call in 10s';
      await Future.delayed(
        const Duration(seconds: 10),
      ); // small hold before proceeding
      if (isRunning.value && !isPaused.value) {
        await nextNumber(); // proceed to next call after the hold
      }
    } catch (e) {
      Get.snackbar(
        'Dialer',
        'Popup failed: $e',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 10),
      );
    } finally {
      _pendingPopup = false;
      _pendingNumber = null;
      _statusDialogShowing = false;
    }
  }

  Future<void> logout() async {
    try {
      isRunning.value = false; // stop any ongoing dial cycle
      isPaused.value = false;
      await _auth.signOut(); // clear token and user_id
      Get.offAllNamed('/login');
    } catch (e) {
      Get.snackbar(
        'Logout',
        'Failed to logout: $e',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    }
  }
}
