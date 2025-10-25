import 'dart:async';
import 'package:dialer_app/data/services/history_services.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../models/call_history_item.dart';


class HistoryController extends GetxController {
  HistoryController({
    required this.service,
    required this.spreadsheetId,
    required this.tabTitle,
    this.initialFilter = 'All',
  });

  final HistoryService service;
  final String spreadsheetId;
  final String tabTitle;
  final String initialFilter;

  // UI state
  final isLoading = false.obs;
  final selected = 'All'.obs;
  final items = <CallHistoryItem>[].obs;

  // Search management
  final TextEditingController searchController = TextEditingController();
  Timer? _debounce;

  // Paging (optional; safe defaults)
  int _page = 1;
  final int _perPage = 50;
  bool _hasMore = true;

  @override
  void onInit() {
    selected.value = initialFilter;
    load(reset: true);
    super.onInit();
  }

  void setFilter(String f) {
    if (selected.value == f) return;
    selected.value = f;
    load(reset: true);
  }

  void setQuery(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      load(reset: true);
    });
  }

  Future<void> refreshList() async {
    await load(reset: true);
  }

  Future<void> load({bool reset = false}) async {
    if (reset) {
      _page = 1;
      _hasMore = true;
      items.clear();
    }
    if (!_hasMore || isLoading.value) return;

    isLoading.value = true;
    try {
      final status = (selected.value == 'All') ? null : selected.value;
      final query = searchController.text.trim().isEmpty
          ? null
          : searchController.text.trim();

      final list = await service.fetchStatusReport(
        spreadsheetId: spreadsheetId,
        tabTitle: tabTitle,
        status: status,
        query: query,
        page: _page,
        perPage: _perPage,
      );

      final mapped = list.map((m) => CallHistoryItem.fromJson(m)).toList();

      if (mapped.length < _perPage) _hasMore = false;
      items.addAll(mapped);
      _page++;
    } catch (e) {
      Get.snackbar(
        'History',
        'Load failed: $e',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    _debounce?.cancel();
    searchController.dispose();
    super.onClose();
  }
}
