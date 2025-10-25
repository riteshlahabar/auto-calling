// lib/modules/auth/controllers/login_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/login_request.dart';
import '../../../data/services/auth_service.dart';
import '../../../core/routes/app_routes.dart';

class LoginController extends GetxController {
  LoginController(this._auth);
  final AuthService _auth;

  // Form + inputs
  final formKey = GlobalKey<FormState>();
  final usernameCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();

  // Reactive state that UI should READ inside Obx
  final isLoading = false.obs;        // controls button/loading
  final errorText = ''.obs;           // shows validation/server error
  final canSubmit = false.obs;        // enables/disables submit button

  // Local mirrors for quick checks (optional)
  final _username = ''.obs;
  final _password = ''.obs;

  // Validators (used by Form)
  String? validateUser(String? v) {
    if (v == null || v.trim().isEmpty) return 'Please enter username or email';
    return null;
  }

  String? validatePass(String? v) {
    if (v == null || v.isEmpty) return 'Please enter password';
    if (v.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  // Compute canSubmit when inputs change
  void _recomputeCanSubmit() {
    final u = _username.value.trim();
    final p = _password.value;
    canSubmit.value = u.isNotEmpty && p.length >= 6 && !isLoading.value;
  }

  @override
  void onInit() {
    super.onInit();

    // Keep Rx copies in sync with TextControllers
    usernameCtrl.addListener(() {
      _username.value = usernameCtrl.text;
      errorText.value = '';           // clear any server error on change
      _recomputeCanSubmit();
    });
    passwordCtrl.addListener(() {
      _password.value = passwordCtrl.text;
      errorText.value = '';           // clear any server error on change
      _recomputeCanSubmit();
    });

    // Also recompute when loading flips
    ever<bool>(isLoading, (_) => _recomputeCanSubmit());
  }

  Future<void> submit() async {
    // Guard: form validation
    final form = formKey.currentState;
    if (form == null) return;
    if (!form.validate()) {
      errorText.value = '';
      return;
    }

    // Execute auth
    isLoading.value = true;
    errorText.value = '';
    try {
      final ok = await _auth.login(
        LoginRequest(
          name: usernameCtrl.text,
          password: passwordCtrl.text,
        ),
      );

      if (ok) {
        Get.offAllNamed(Routes.dialer);
      } else {
        errorText.value = 'Invalid credentials';
        Get.snackbar(
          'Login failed',
          'Invalid credentials',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      errorText.value = 'Something went wrong. Please try again.';
      Get.snackbar(
        'Login failed',
        'Something went wrong. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    usernameCtrl.dispose();
    passwordCtrl.dispose();
    super.onClose();
  }
}
