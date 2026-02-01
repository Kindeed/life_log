import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:life_log/modules/tabs/tabs_view.dart';
import 'package:life_log/modules/work_log/work_log_controller.dart';
import 'package:life_log/modules/photo/photo_controller.dart';
import 'package:life_log/common/db/db_service.dart'; // Import DbService

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('zh_CN', null);

  // 1. Initialize DB Service first (Async)
  await Get.putAsync(() => DbService().init());

  // 2. Initialize Controllers
  Get.put(WorkLogController());
  Get.put(PhotoController()); // Inject PhotoController

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812), // Standard iPhone X design size
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return GetMaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Life Log',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF1A73E8),
              primary: const Color(0xFF1A73E8),
              surface: Colors.white,
            ),
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xFFF7F9FC),
            appBarTheme: const AppBarTheme(
              centerTitle: true,
              backgroundColor: Colors.white,
              elevation: 0,
              scrolledUnderElevation: 0,
              titleTextStyle: TextStyle(
                color: Color(0xFF1C1B1F),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          home: const TabsView(),
        );
      },
    );
  }
}
