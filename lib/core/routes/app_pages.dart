// lib/core/routes/app_pages.dart

import 'package:get/get.dart';
import '../../modules/auth/bindings/login_binding.dart';
import '../../modules/auth/views/login_view.dart';
import '../../modules/dialer/views/dialer_view.dart';
import '../../modules/dialer/bindings/dialer_binding.dart';

class AppPages {
  static final pages = <GetPage>[
    GetPage(
      name: '/login',
      page: () => const LoginView(),
      binding: LoginBinding(),
    ),
    GetPage(
      name: '/',
      page: () => const DialerView(),
      binding: DialerBinding(),
    ),
   
  ];
}
