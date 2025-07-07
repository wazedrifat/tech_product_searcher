
import 'package:flutter/material.dart';
import 'package:tech_product_searcher/constants/constant.dart';
import 'package:tech_product_searcher/models/product.dart';
import 'package:tech_product_searcher/models/search_request.dart';
import 'package:tech_product_searcher/models/search_result.dart';
import 'package:tech_product_searcher/models/settings.dart';
import 'package:tech_product_searcher/services/service_engine/monarch_it_search.dart';
import 'package:tech_product_searcher/services/service_engine/potaka_it_search.dart';
import 'package:tech_product_searcher/services/service_engine/ryans_search.dart';
import 'package:tech_product_searcher/services/service_engine/search_engine.dart';
import 'package:tech_product_searcher/services/service_engine/sky_land_search.dart';
import 'package:tech_product_searcher/services/service_engine/star_tech_search.dart';
import 'package:tech_product_searcher/services/service_engine/tech_land_search_v2.dart';
import 'package:tech_product_searcher/services/service_engine/ucc_search.dart';
import 'package:tech_product_searcher/widgets/settings_modal.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:core';
import 'package:intl/intl.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _searchController = TextEditingController();
  final _tagController = TextEditingController();
	final takaFormat = NumberFormat.currency(locale: 'en_US', symbol: '৳', decimalDigits: 2);
  final List<String> _tags = [];
  final List<SearchEngine> searchEngines = [
    StarTechSearch(),
    PotakaItSearch(),
    SkyLandSearch(),
    TechLandSearchV2(),
    UccSearch(),
    RyansSearch(),
    MonarchItSearch()
  ];
  SettingsModel settings = SettingsModel();
  List<Product> _products = [];
  List<Product> _allProducts = [];
  bool _showResults = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _searchController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _addTag() {
    if (_tagController.text.trim().isNotEmpty) {
      setState(() {
        _tags.add(_tagController.text.trim());
        _tagController.clear();
      });
    }
  }

  void _removeTag(int index) {
    setState(() {
      _tags.removeAt(index);
    });
  }

  void _clearForm() {
    _formKey.currentState?.reset();
    setState(() {
      _tags.clear();
      _showResults = false;
      _products.clear();
      _allProducts.clear();
    });
  }

  void _applySettings() {
    _products = _allProducts.where((product) {
      if (settings.showInStockOnly && product.stockStatus.toLowerCase() != Constants.InStock.toLowerCase()) {
        return false;
      }
      if (product.price < settings.minPrice || product.price > settings.maxPrice) {
        return false;
      }

      if (settings.selectedEngines.isNotEmpty) {
        bool ret = settings.selectedEngines.contains(product.shopName);
        return ret;
      }
      return true;
    }).toList();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _showResults = false;
        _products.clear();
        _allProducts.clear();
      });

      SearchRequest request = SearchRequest(
        _searchController.text,
        exclude: _tags,
      );

      try {
        List<Future<List<SearchResult>>> futures = [];
        for (var engine in searchEngines) {
          futures.add(engine.fetchData(request));
        }
        List<List<SearchResult>> results = await Future.wait(futures);
        List<Product> allProducts = [];
        for (var engineResults in results) {
          for (var result in engineResults) {
            allProducts.add(Product(
              name: result.name,
              price: result.price.toDouble(),
              stockStatus: result.status,
              link: result.link,
              imageUrl: result.imageLink,
              shopName: result.shopName,
            ));
          }
        }

        allProducts.sort((a, b) {
					bool aInStock = a.stockStatus.toLowerCase() == Constants.InStock.toLowerCase();
					bool bInStock = b.stockStatus.toLowerCase() == Constants.InStock.toLowerCase();

					if (aInStock != bInStock) {
						return aInStock ? -1 : 1; 
					}

					bool aHasPrice = a.price > 0;
					bool bHasPrice = b.price > 0;
					if (aHasPrice != bHasPrice) {
						return aHasPrice ? -1 : 1;
					}

					return a.price.compareTo(b.price);
				});

        _allProducts = allProducts;
        setState(() {
          _applySettings();
          _showResults = true;
          _isLoading = false;
        });

      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error occurred: $e')),
        );
      }
    }
  }

  Future<void> _launchUrl(String url) async {
    if (!await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch $url')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
		Map<String, List<Product>> groupedProducts = {};
		for (var product in _products) {
			groupedProducts.putIfAbsent(product.name, () => []).add(product);
		}

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Finder'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              showSettingsModal(context, settings, searchEngines, () {
                setState(() {
                  _applySettings();
                });
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _clearForm,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Search Products',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          labelText: 'Search term',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a search term';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Exclude Tags:',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      
                      if (_tags.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Wrap(
                            spacing: 8.0,
                            runSpacing: 8.0,
                            children: _tags.asMap().entries.map((entry) {
                              return Chip(
                                label: Text(entry.value),
                                deleteIcon: const Icon(Icons.close, size: 18),
                                onDeleted: () => _removeTag(entry.key),
                                backgroundColor: Colors.blue[50],
                                labelStyle: const TextStyle(color: Colors.blue),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _tagController,
                              decoration: const InputDecoration(
                                labelText: 'Enter a tag to exclude',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                              ),
                              onFieldSubmitted: (value) => _addTag(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.add, size: 20),
                            label: const Text('Add'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                            onPressed: _addTag,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _submitForm,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Search Products',
                                      style: TextStyle(fontSize: 16),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_showResults) ...[
              const SizedBox(height: 24),
              const Text(
                'Search Results',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ...groupedProducts.entries.map((entry) {
                String productName = entry.key;
                List<Product> productVariants = entry.value;

                final prices = productVariants.map((e) => e.price).where((p) => p > 0).toList();
                final minPrice = prices.isNotEmpty ? prices.reduce((a, b) => a < b ? a : b) : 0;
                final maxPrice = prices.isNotEmpty ? prices.reduce((a, b) => a > b ? a : b) : 0;
                final stockCount = productVariants.where((p) => p.stockStatus.toLowerCase() == Constants.InStock.toLowerCase()).length;
                final groupImage = productVariants.firstWhere((p) => p.imageUrl.isNotEmpty, orElse: () => productVariants.first).imageUrl;
								String priceDisplay = (minPrice == maxPrice)
                    ? '৳${minPrice.toStringAsFixed(0)}'
                    : '৳${minPrice.toStringAsFixed(0)} - ৳${maxPrice.toStringAsFixed(0)}';

                return ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 8),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      groupImage,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  ),
                  title: Text(
                    productName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Row(
                    children: [
                      Text(
                        priceDisplay,
                        style: const TextStyle(fontSize: 12, color: Colors.teal),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '$stockCount/${productVariants.length} ${Constants.InStock.toLowerCase()}',
                        style: const TextStyle(fontSize: 12, color: Colors.lightGreen),
                      ),
                    ],
                  ),
                  children: productVariants.map((product) {
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    product.imageUrl,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            product.shopName,
                                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                          ),
                                          Text(
                                            takaFormat.format(product.price),
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blue,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.inventory,
                                            color: product.stockStatus == Constants.InStock ? Colors.green : Colors.red,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            product.stockStatus,
                                            style: TextStyle(
                                              color: product.stockStatus == Constants.InStock ? Colors.green : Colors.red,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      ElevatedButton(
                                        onPressed: () => _launchUrl(product.link),
                                        child: const Text('Go to Store'),
                                        style: ElevatedButton.styleFrom(
                                          foregroundColor: Colors.white,
                                          backgroundColor: Colors.deepPurple,
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              }).toList(),
            ],
          ],
        ),
      ),
    );
  }
}