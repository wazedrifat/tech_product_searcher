class SettingsModel {
  bool saveLastSearch = false;
  bool showInStockOnly = false;
  Set<String> selectedEngines = {};
  double minPrice = 0;
  double maxPrice = 200000;
}