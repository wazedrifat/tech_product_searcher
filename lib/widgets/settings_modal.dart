import 'package:flutter/material.dart';
import 'package:tech_product_searcher/models/settings.dart';
import 'package:tech_product_searcher/services/service_engine/search_engine.dart';

void showSettingsModal(BuildContext context, SettingsModel settings, List<SearchEngine> engines, void Function() onChanged) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: StatefulBuilder(
          builder: (context, setModalState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Settings',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(),
                SwitchListTile(
                  title: const Text('Save Last Search'),
                  value: settings.saveLastSearch,
                  onChanged: (val) {
                    setModalState(() => settings.saveLastSearch = val);
                    onChanged();
                  },
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Show In-Stock Only'),
                  value: settings.showInStockOnly,
                  onChanged: (val) {
                    setModalState(() => settings.showInStockOnly = val);
                    onChanged();
                  },
                ),
                const SizedBox(height: 12),
                const Text(
                  'Search Engines',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                ...engines.map((engine) {
                  return CheckboxListTile(
                    title: Text(engine.shopName.toString()),
                    value: settings.selectedEngines.contains(engine.shopName.toString()),
                    onChanged: (checked) {
                      setModalState(() {
                        if (checked == true) {
                          settings.selectedEngines.add(engine.shopName.toString());
                        } else {
                          settings.selectedEngines.remove(engine.shopName.toString());
                        }
                      });
                      onChanged();
                    },
                  );
                }).toList(),
                const SizedBox(height: 12),
                const Text(
                  'Price Range',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                RangeSlider(
                  values: RangeValues(settings.minPrice, settings.maxPrice),
                  min: 0,
                  max: 200000,
                  divisions: 100,
                  labels: RangeLabels(
                    '৳${settings.minPrice.toInt()}',
                    '৳${settings.maxPrice.toInt()}',
                  ),
                  onChanged: (range) {
                    setModalState(() {
                      settings.minPrice = range.start;
                      settings.maxPrice = range.end;
                    });
                    onChanged();
                  },
                ),
                const SizedBox(height: 12),
                Center(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Done'),
                  ),
                )
              ],
            );
          },
        ),
      );
    },
  );
}