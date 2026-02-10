import 'package:crab_maturity_ml_app/core/bindings/crab_list_bindings.dart';
import 'package:crab_maturity_ml_app/home/home_page.dart';
import 'package:crab_maturity_ml_app/home/pages/about.dart';
import 'package:crab_maturity_ml_app/home/pages/explore.dart';
import 'package:crab_maturity_ml_app/home/pages/history.dart';
import 'package:crab_maturity_ml_app/home/pages/scan.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  runApp(const MyApp());
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
        GetPage(name: '/explore', page: () => const ExploreScreen(), binding: CrabListBinding()),
        GetPage(name: '/scan', page: () => ScanScreen()),
        GetPage(name: '/history', page: () => const HistoryScreen()),
        GetPage(name: '/about', page: () => const AboutScreen()),
      ],
    );
  }
}
