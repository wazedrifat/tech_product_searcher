import 'package:html/parser.dart' as parser;
import 'package:tech_product_searcher/models/search_result.dart';
import 'package:tech_product_searcher/services/service_engine/search_engine.dart';

class TechLandSearch extends SearchEngine {
  TechLandSearch() : super();

  @override
  String get shopName => 'Tech Land';

  @override
  String getSearchUrl(String search, int page) => 'https://www.techlandbd.com/index.php?route=product/search&search=$search&page=$page';

  @override
  List<SearchResult> processResults(String html) {
    var document = parser.parse(html);
    var products = document.querySelectorAll('.product-thumb');

    List<SearchResult> results = [];
    for (var product in products) {
    var nameElement = product.querySelector('.name a');
    var priceElement = product.querySelector('.price .price-new');
    var imgElement = product.querySelector('.image img');
    var stockElement = product.querySelector('.caption .stats span span:last-child');

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
