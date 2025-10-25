
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/adapters.dart';
import 'core/routes/app_pages.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async{ 
  
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter(); // required before opening boxes   
  runApp(const AutoDialerApp());
}

// Moved from app.dart into this file.
class AutoDialerApp extends StatelessWidget {
  const AutoDialerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Auto Dialer',
      debugShowCheckedModeBanner: false,
      // Material 3 is the default; custom themes still use ColorScheme for consistency.
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      // GetX navigation with per-route Bindings.
      getPages: AppPages.pages,
      initialRoute: '/login',
    );
  }
}
