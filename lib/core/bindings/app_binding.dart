import 'package:get/get.dart';
import '../../core/network/connectivity_service.dart';
import '../../data/services/outbox_service.dart';

class AppBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<ConnectivityService>(ConnectivityService(), permanent: true);
    final outbox = OutboxService();
    outbox.init(); // fire-and-forget; consider awaiting in splash
    Get.put<OutboxService>(outbox, permanent: true);
  }
}
