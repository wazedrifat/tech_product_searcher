import 'package:html/parser.dart' as parser;
import 'package:tech_product_searcher/models/search_result.dart';
import 'package:tech_product_searcher/services/service_engine/search_engine.dart';

class RyansSearch extends SearchEngine {
  RyansSearch() : super();

  @override
  String get shopName => 'Ryans';

  @override
  String getSearchUrl(String search, int page) => 'https://www.ryans.com/search?q=$search&page=$page';

  @override
  List<SearchResult> processResults(String html) {
    var document = parser.parse(html);
    var products = document.querySelectorAll('.category-single-product');

    List<SearchResult> results = [];
    for (var product in products) {
      var nameElement = product.querySelector('.card-body a');
      var priceElement = product.querySelector('.pr-text');
      var imgElement = product.querySelector('.image-box img');
      var stockElement = product.querySelector('.container__ribbon4');

      String name = nameElement?.text.trim() ?? 'No name found';
      String price = priceElement?.text.trim() ?? 'No price found';
      String link = nameElement?.attributes['href'] ?? '';
      String imageLink = imgElement?.attributes['src'] ?? '';
      String stockStatus = stockElement?.text.trim() ?? 'In Stock';

      final numericString = price.replaceAll(RegExp(r'[^0-9]'), '');
      final priceValue = int.tryParse(numericString) ?? 0;

      results.add(SearchResult(
        name,
        priceValue,
        stockStatus,
        link,
        imageLink,
        shopName
      ));
    }

    return results;
  }
}