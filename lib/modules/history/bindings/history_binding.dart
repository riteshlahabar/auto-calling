// lib/modules/dialer/bindings/history_binding.dart (adjust path if different)
import 'package:get/get.dart';

import '../../../data/services/api_service.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/history_services.dart';
import '../controllers/history_controller.dart';

class HistoryBinding extends Bindings {
  @override
  void dependencies() {
    // 1) Ensure ApiService (shared Dio) is available
    if (!Get.isRegistered<ApiService>()) {
      Get.put<ApiService>(ApiService(), permanent: true);
    }

    // 2) Ensure AuthService is available and injected with ApiService
    if (!Get.isRegistered<AuthService>()) {
      Get.put<AuthService>(AuthService(Get.find<ApiService>()), permanent: true);
    }

    // 3) HistoryService uses the shared Dio (either via ApiService or AuthService.http)
    if (!Get.isRegistered<HistoryService>()) {
      final api = Get.find<ApiService>();
      Get.lazyPut<HistoryService>(() => HistoryService(api.http), fenix: true);
      // Or: Get.lazyPut<HistoryService>(() => HistoryService(Get.find<AuthService>().http), fenix: true);
    }

    // 4) Read route params/arguments for spreadsheet context
    final params = Get.parameters;
    final args = Get.arguments is Map ? (Get.arguments as Map) : const {};

    final spreadsheetId =
        (params['spreadsheet_id'] ?? args['spreadsheetId'] ?? '').toString();
    final tabTitle = (params['tab_title'] ?? args['tabTitle'] ?? '').toString();
    final initialFilter =
        (params['filter'] ?? args['filter'] ?? 'All').toString();

    // 5) Provide the controller
    Get.put<HistoryController>(
      HistoryController(
        service: Get.find<HistoryService>(),
        spreadsheetId: spreadsheetId,
        tabTitle: tabTitle,
        initialFilter: initialFilter,
      ),
    );
  }
}
