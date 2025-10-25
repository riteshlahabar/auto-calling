// lib/modules/dialer/bindings/dialer_binding.dart
import 'package:dialer_app/data/services/recording_service.dart';
import 'package:dialer_app/modules/dialer/controllers/recording_controller.dart';
import 'package:get/get.dart';
import '../../../data/services/api_service.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/dialer_service.dart';
import '../controllers/dialer_controller.dart';

class DialerBinding extends Bindings {
  @override
  void dependencies() {
    // 1) Ensure ApiService (shared Dio) is available
    if (!Get.isRegistered<ApiService>()) {
      Get.put<ApiService>(ApiService(), permanent: true);
    }

    // 2) Ensure AuthService is available and injected with ApiService
    if (!Get.isRegistered<AuthService>()) {
      Get.put<AuthService>(
        AuthService(Get.find<ApiService>()),
        permanent: true,
      );
    }

    // 3) Build DialerService using the same shared Dio
    if (!Get.isRegistered<DialerService>()) {
      final api = Get.find<ApiService>();
      Get.put<DialerService>(DialerService(api.http), permanent: true);
      // Or lazy:
      // Get.lazyPut<DialerService>(() => DialerService(api.http), fenix: true);
    }

    // 3b) RecordingService (shares ApiService.http)  <-- ADD
    if (!Get.isRegistered<RecordingService>()) {
      final api = Get.find<ApiService>();
      Get.put<RecordingService>(RecordingService(api.http), permanent: true);
    }

    // 3c) RecordingController  <-- ADD
    if (!Get.isRegistered<RecordingController>()) {
      Get.lazyPut<RecordingController>(() => RecordingController(), fenix: true);
    }

    // 4) Inject controller with AuthService and DialerService
    Get.lazyPut<DialerController>(
      () => DialerController(
        Get.find<AuthService>(),
        Get.find<DialerService>(),        
        Get.find<RecordingService>(),
      ),
      fenix: true,
    );
  }
}
