import 'package:crab_maturity_ml_app/home/controller/explore_controller.dart';
import 'package:get/get.dart';

class CrabListBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CrabListController>(() => CrabListController());
  }
}
