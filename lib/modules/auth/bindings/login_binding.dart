// lib/modules/auth/bindings/login_binding.dart
import 'package:get/get.dart';
import '../../../data/services/api_service.dart';
import '../../../data/services/auth_service.dart';
import '../controllers/login_controller.dart';

class LoginBinding extends Bindings {
  @override
  void dependencies() {
    // 1) Provide the shared ApiService (single Dio, baseUrl, interceptors)
    Get.lazyPut<ApiService>(
      () => ApiService(),
      fenix: true, // re-create if disposed
    );

    // 2) Provide AuthService with ApiService injected
    Get.lazyPut<AuthService>(
      () => AuthService(Get.find<ApiService>()),
      fenix: true,
    );

    // 3) Provide LoginController with AuthService injected
    Get.lazyPut<LoginController>(
      () => LoginController(Get.find<AuthService>()),
      fenix: true,
    );
  }
}
