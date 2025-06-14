import 'package:html/parser.dart' as parser;
import 'package:tech_product_searcher/models/search_result.dart';
import 'package:tech_product_searcher/services/service_engine/search_engine.dart';

class PotakaItSearch extends SearchEngine {
  PotakaItSearch() : super();

  @override
  String get shopName => 'Potaka IT';

  @override
  String getSearchUrl(String search, int page) => 'https://potakait.com/product/search?search=$search&page=$page';

  @override
  List<SearchResult> processResults(String html) {
    var document = parser.parse(html);
    var products = document.querySelectorAll('.product-item');

    List<SearchResult> results = [];
    for (var product in products) {
      var nameElement = product.querySelector('.title a');
      var priceElement = product.querySelector('.price-info .price');
      var imgElement = product.querySelector('.product-img img');
      var buttonElement = product.querySelector('.cart-button-wrap button');
      var linkElement = product.querySelector('.cart-button-wrap a'); // NEW: also check for <a>

      String name = nameElement?.text.trim() ?? 'No name found';
      String price = priceElement?.text.trim() ?? '0';
      String link = nameElement?.attributes['href'] ?? '';
      String imageLink = imgElement?.attributes['src'] ?? '';

      // Detect stock status
      String stockStatus = buttonElement?.text.trim() ?? linkElement?.text.trim() ?? 'Unknown';
      if (stockStatus.toLowerCase().contains('buy now') || stockStatus.toLowerCase().contains('add to cart')) {
        stockStatus = 'In Stock';
      }

      final numericString = price.replaceAll(RegExp(r'[^0-9]'), '');
      final priceValue = int.tryParse(numericString) ?? 0;

      results.add(SearchResult(name, priceValue, stockStatus, link, imageLink, shopName));
    }

    return results;
  }
}
