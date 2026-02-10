import 'package:get/get.dart';
import '../../core/models/crab_model.dart';
import '../../feature/crabs/services/crab_api_service.dart';

class CrabListController extends GetxController {
  final CrabApiService _api = CrabApiService();

  final crabs = <Crab>[].obs;
  final filteredCrabs = <Crab>[].obs;
  final isLoading = false.obs;
  final errorMessage = RxnString();
  final searchQuery = ''.obs;
  
  final selectedCrab = Rxn<Crab>();

  @override
  void onInit() {
    super.onInit();
    loadCrabs();
    ever(searchQuery, (_) => _applyFilter());
  }

  Future<void> loadCrabs() async {
    try {
      isLoading.value = true;
      errorMessage.value = null;

      final List<Crab> result = await _api.fetchCrabs();
      crabs.assignAll(result);
      filteredCrabs.assignAll(crabs);
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  void updateSearch(String value) {
    searchQuery.value = value.trim().toLowerCase();
  }

  void selectCrab(Crab crab) {
    selectedCrab.value = crab;
  }

  void clearSelection() {
    selectedCrab.value = null;
  }

  void _applyFilter() {
    if (searchQuery.value.isEmpty) {
      filteredCrabs.assignAll(crabs);
      return;
    }

    filteredCrabs.assignAll(
      crabs.where((crab) =>
        crab.commonName.toLowerCase().contains(searchQuery.value) ||
        crab.scientificName.toLowerCase().contains(searchQuery.value),
      ),
    );
  }
}
