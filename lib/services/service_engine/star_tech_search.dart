import 'package:html/parser.dart' as parser;
import 'package:tech_product_searcher/constants/constant.dart';
import 'package:tech_product_searcher/models/search_result.dart';
import 'package:tech_product_searcher/services/service_engine/search_engine.dart';

class StarTechSearch extends SearchEngine {
  StarTechSearch() : super();

  @override
  String get shopName => 'Star Tech';

  @override
  String getSearchUrl(String search, int page) => 'https://www.startech.com.bd/product/search?search=$search&page=$page';

  @override
  List<SearchResult> processResults(String html) {
    var document = parser.parse(html);
    var products = document.querySelectorAll('.p-item-inner');

    List<SearchResult> results = [];
    for (var product in products) {
      var nameElement = product.querySelector('.p-item-name a');
      var priceElement = product.querySelector('.p-item-price span');
      var imgElement = product.querySelector('.p-item-img img');
      var stockElement = product.querySelector('.stock-status');

      String name = nameElement?.text.trim() ?? 'No name found';
      String price = priceElement?.text.trim() ?? 'No price found';
      String link = nameElement?.attributes['href'] ?? '';
      String imageLink = imgElement?.attributes['src'] ?? '';
      String stockStatus = stockElement?.text.trim() ?? Constants.InStock;
      
      final numericString = price.replaceAll(RegExp(r'[^0-9]'), '');
      final priceValue = int.tryParse(numericString) ?? 0;

      results.add(SearchResult(name, priceValue, stockStatus, link, imageLink, shopName));
    }

    return results;
  }
}
