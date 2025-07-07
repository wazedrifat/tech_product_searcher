import 'package:html/parser.dart' as parser;
import 'package:tech_product_searcher/models/search_result.dart';
import 'package:tech_product_searcher/services/service_engine/tech_land_search.dart';

class TechLandSearchV2 extends TechLandSearch {
  TechLandSearchV2() : super();

  @override
  String getSearchUrl(String search, int page) => 'https://www.techlandbd.com/search/advance/product/result/$search?page=$page';

  @override
  List<SearchResult> processResults(String html) {
    var document = parser.parse(html);
    var products = document.querySelectorAll('.grid > div');

    List<SearchResult> results = [];

    for (var product in products) {
      var container = product.querySelector('div.bg-white');
      if (container == null) continue;

      var nameElement = container.querySelector('a.text-gray-800');
      var priceElement = container.querySelector('.text-red-600.text-lg');
      var imgElement = container.querySelector('img');
      var stockElement = container.querySelector('.pt-2 span');

      String name = nameElement?.text.trim() ?? 'No name found';
      String price = priceElement?.text.trim() ?? 'No price found';
      String link = nameElement?.attributes['href'] ?? '';
      String imageLink = imgElement?.attributes['src'] ?? '';
      String stockStatus = stockElement?.text.trim() ?? 'Unknown';

      final numericString = price.replaceAll(RegExp(r'[^0-9]'), '');
      final priceValue = int.tryParse(numericString) ?? 0;

      results.add(SearchResult(name, priceValue, stockStatus, link, imageLink, shopName));
    }

    return results;
  }
}
