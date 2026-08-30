import 'package:get/get.dart';
import '../../core/models/crab_model.dart';
import '../../feature/crabs/services/crab_api_service.dart';

enum ExploreFilter { all, blue, mud, edible, poisonous }

enum ExploreSort { nameAsc, nameDesc, category }

enum ExploreViewMode { grid, list }

class CrabListController extends GetxController {
  final CrabApiService _api = CrabApiService();

  final crabs = <Crab>[].obs;
  final isLoading = false.obs;
  final errorMessage = RxnString();
  final searchQuery = ''.obs;

  final selectedFilter = ExploreFilter.all.obs;
  final selectedSort = ExploreSort.nameAsc.obs;
  final viewMode = ExploreViewMode.grid.obs;

  final selectedCrab = Rxn<Crab>();

  @override
  void onInit() {
    super.onInit();
    loadCrabs();
  }

  Future<void> loadCrabs() async {
    try {
      isLoading.value = true;
      errorMessage.value = null;

      final List<Crab> result = await _api.fetchCrabs();
      crabs.assignAll(result);
    } catch (e) {
      errorMessage.value = 'Unable to load species catalog. Check your connection.';
    } finally {
      isLoading.value = false;
    }
  }

  void updateSearch(String value) {
    searchQuery.value = value.trim().toLowerCase();
  }

  void setFilter(ExploreFilter filter) {
    selectedFilter.value = filter;
  }

  void setSort(ExploreSort sort) {
    selectedSort.value = sort;
  }

  void toggleViewMode() {
    viewMode.value =
        viewMode.value == ExploreViewMode.grid ? ExploreViewMode.list : ExploreViewMode.grid;
  }

  void selectCrab(Crab crab) {
    selectedCrab.value = crab;
  }

  void clearSelection() {
    selectedCrab.value = null;
  }

  List<Crab> get filteredCrabs {
    List<Crab> list = List.from(crabs);

    // 1. Text Search Filter
    if (searchQuery.value.isNotEmpty) {
      final query = searchQuery.value;
      list = list.where((crab) {
        final nameMatch = crab.commonName.toLowerCase().contains(query);
        final sciMatch = crab.scientificName.toLowerCase().contains(query);
        final typeMatch = crab.speciesType.toLowerCase().contains(query);
        final habitatMatch = crab.habitat.toLowerCase().contains(query);
        return nameMatch || sciMatch || typeMatch || habitatMatch;
      }).toList();
    }

    // 2. Category Filter
    switch (selectedFilter.value) {
      case ExploreFilter.blue:
        list = list
            .where((crab) =>
                crab.speciesType.toLowerCase().contains('blue') ||
                crab.commonName.toLowerCase().contains('blue') ||
                crab.commonName.toLowerCase().contains('alimasag'))
            .toList();
        break;
      case ExploreFilter.mud:
        list = list
            .where((crab) =>
                crab.speciesType.toLowerCase().contains('mud') ||
                crab.commonName.toLowerCase().contains('mud') ||
                crab.commonName.toLowerCase().contains('alimango'))
            .toList();
        break;
      case ExploreFilter.edible:
        list = list.where((crab) => !crab.isPoisonous).toList();
        break;
      case ExploreFilter.poisonous:
        list = list.where((crab) => crab.isPoisonous).toList();
        break;
      case ExploreFilter.all:
        break;
    }

    // 3. Sorting
    switch (selectedSort.value) {
      case ExploreSort.nameAsc:
        list.sort((a, b) =>
            a.commonName.toLowerCase().compareTo(b.commonName.toLowerCase()));
        break;
      case ExploreSort.nameDesc:
        list.sort((a, b) =>
            b.commonName.toLowerCase().compareTo(a.commonName.toLowerCase()));
        break;
      case ExploreSort.category:
        list.sort((a, b) =>
            a.speciesType.toLowerCase().compareTo(b.speciesType.toLowerCase()));
        break;
    }

    return list;
  }

  int get countBlue => crabs
      .where((crab) =>
          crab.speciesType.toLowerCase().contains('blue') ||
          crab.commonName.toLowerCase().contains('blue') ||
          crab.commonName.toLowerCase().contains('alimasag'))
      .length;

  int get countMud => crabs
      .where((crab) =>
          crab.speciesType.toLowerCase().contains('mud') ||
          crab.commonName.toLowerCase().contains('mud') ||
          crab.commonName.toLowerCase().contains('alimango'))
      .length;

  int get countEdible => crabs.where((crab) => !crab.isPoisonous).length;
  int get countPoisonous => crabs.where((crab) => crab.isPoisonous).length;
}
