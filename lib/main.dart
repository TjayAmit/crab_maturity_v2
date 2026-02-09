import 'package:crab_maturity_ml_app/home/controller/scan_controller.dart';
import 'package:crab_maturity_ml_app/home/home_page.dart';
import 'package:crab_maturity_ml_app/home/pages/about.dart';
import 'package:crab_maturity_ml_app/home/pages/explore.dart';
import 'package:crab_maturity_ml_app/home/pages/history.dart';
import 'package:crab_maturity_ml_app/home/pages/scan.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  runApp(
    ChangeNotifierProvider(
      create: (_) => ScanController(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    FlutterNativeSplash.remove();

    return GetMaterialApp(
      title: 'Crab Watch',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
      ),
      home: const HomePage(),
      getPages: [
        GetPage(name: '/', page: () => const HomePage()),
        GetPage(name: '/explore', page: () => const ExploreScreen()),
        GetPage(name: '/scan', page: () => const ScanScreen()),
        GetPage(name: '/history', page: () => const HistoryScreen()),
        GetPage(name: '/about', page: () => const AboutScreen()),
      ],
    );
  }
}
