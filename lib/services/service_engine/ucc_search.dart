import 'package:html/parser.dart' as parser;
import 'package:tech_product_searcher/models/search_result.dart';
import 'package:tech_product_searcher/services/service_engine/search_engine.dart';

class UccSearch extends SearchEngine {
  UccSearch() : super();

  @override
  String get shopName => 'UCC';

  @override
  String getSearchUrl(String search, int page) => 'https://www.ucc.com.bd/index.php?route=product/search&search=$search&page=$page';

  @override
  List<SearchResult> processResults(String html) {
    var document = parser.parse(html);
    var products = document.querySelectorAll('.product-thumb');

    List<SearchResult> results = [];
    for (var product in products) {
      var nameElement = product.querySelector('.name a');
      var priceElement = product.querySelector('.price .price-normal');
      var imgElement = product.querySelector('.image img');
      var stockElement = product.querySelector('.stats .stat-1 span:last-child');

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
