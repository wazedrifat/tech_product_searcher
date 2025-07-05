import 'dart:collection';
import 'dart:convert';

import 'package:html/parser.dart' as parser;
import 'package:http/http.dart' as http;
import 'package:tech_product_searcher/constants/constant.dart';
import 'package:tech_product_searcher/models/search_request.dart';
import 'package:tech_product_searcher/models/search_result.dart';
import 'package:tech_product_searcher/services/service_engine/search_engine.dart';

class MonarchItSearch extends SearchEngine {
  MonarchItSearch() : super();

  @override
  String get shopName => 'Monarch IT';

  @override
  String getSearchUrl(String search, int page) => 'https://www.monarchit.com.bd/index.php?route=product/search&search=$search&description=true&page=$page';

	@override
	Future<List<SearchResult>> fetchData(SearchRequest search) async {
    List<SearchResult> allResults = [];
		Map<String, String> productIndexMap = {};
    for (int page = 1; page <= maxPages; page++) {
      String html = await super.searchObject(search.include, page);
      List<SearchResult> pageResults = processResults(html);
      if (pageResults.isEmpty) {
        break;
      }

			insertToProductIndexMap(html, productIndexMap);
      allResults.addAll(pageResults);
    }
		await updateStatusForResults(allResults, productIndexMap);
    return filterOutNoise(allResults, search);
  }

  @override
  List<SearchResult> processResults(String html) {
		var document = parser.parse(html);
		var products = document.querySelectorAll('.product-layout');

		List<SearchResult> results = [];

		for (var product in products) {
			var nameElement = product.querySelector('.name a');
			var priceElement = product.querySelector('.price-normal');
			var price2Element = product.querySelector('.price-new');
			var imgElement = product.querySelector('.image img');
			var otherStockStatusElement = product.querySelector('.button-group h3');

			String name = nameElement?.text.trim() ?? 'No name found';
			String price = priceElement?.text.trim() ?? price2Element?.text.trim() ?? 'No price found';
			String link = nameElement?.attributes['href'] ?? '';
			String imageLink = imgElement?.attributes['src'] ?? '';
			String stockStatus = otherStockStatusElement?.text.trim() ?? Constants.InStock;

			
			final numericString = price.contains(RegExp(r'[0-9]'))
					? price.replaceAll(RegExp(r'[^0-9]'), '')
					: '0';
			final priceValue = int.tryParse(numericString) ?? 0;
			final result = SearchResult(name, priceValue, stockStatus, link, imageLink, shopName);
			results.add(result);
		}

		return results;
	}

	void insertToProductIndexMap(String html, Map<String, String> productIndexMap) {
		var document = parser.parse(html);
		var products = document.querySelectorAll('.product-layout');

		for (var product in products) {
			var nameElement = product.querySelector('.name a');
			var productIdElement = product.querySelector('input[name="product_id"]');

			if (productIdElement == null) continue;

			String name = nameElement?.text.trim() ?? '';
			String productId = productIdElement.attributes['value'] ?? '';

			if (name.isNotEmpty && productId.isNotEmpty) {
				productIndexMap[name] = productId;
			}
		}
	}

	Future<void> updateStatusForResults(List<SearchResult> products, Map<String, String> productIndexMap) async {
		var preOrderStatus = await fetchPreOrderStatus(productIndexMap.values.toList());

		for (var product in products) {
			var id = productIndexMap[product.name];

			if (id == null || id == '') continue;

			if (preOrderStatus.contains(id)) {
				product.status = "Pre Order";
			}
		}
	}

	Future<HashSet<String>> fetchPreOrderStatus(List<String> productIds) async {
		final uri = Uri.parse('https://www.monarchit.com.bd/index.php?route=extension/module/preorder/checkQuantityPO');
		final body = jsonEncode({'product_id': productIds});
		final response = await http.post(uri, body: body);

		if (response.statusCode == 200) {
			final data = jsonDecode(response.body);
			var productList = data['PO'] as List<dynamic>;
			return HashSet<String>.from(productList.map((item) => item.toString()));
		} else {
			return HashSet<String>();
		}
	}
}
