import 'package:http/http.dart' as http;
import 'package:tech_product_searcher/models/search_request.dart';
import 'package:tech_product_searcher/models/search_result.dart';

abstract class SearchEngine {
  final int maxPages;

	SearchEngine({this.maxPages = 5});

  Future<List<SearchResult>> fetchData(SearchRequest search) async {
    List<SearchResult> allResults = [];
    for (int page = 1; page <= maxPages; page++) {
      String html = await searchObject(search.include, page);
      List<SearchResult> pageResults = processResults(html);
      if (pageResults.isEmpty) {
        break;
      }
      allResults.addAll(pageResults);
    }
    return filterOutNoise(allResults, search);
  }

  List<SearchResult> filterOutNoise(List<SearchResult> results, SearchRequest search) {
    List<String> includeWords = search.include.split(' ').where((w) => w.isNotEmpty).toList();
    String includePattern = includeWords.map((word) => RegExp.escape(word)).join(r'.*');
    RegExp includeRegex = RegExp(includePattern, caseSensitive: false);
    
    List<RegExp> excludeRegexes = [];
    for (String phrase in search.exclude) {
      if (phrase.trim().isEmpty) continue;
      
      List<String> phraseWords = phrase.split(' ').where((w) => w.isNotEmpty).toList();
      String phrasePattern = phraseWords.map((word) => RegExp.escape(word)).join(r'.*');
      excludeRegexes.add(RegExp(phrasePattern, caseSensitive: false));
    }

    List<SearchResult> res = results.where((result) {
      String name = result.name.toLowerCase();
      
      if (!includeRegex.hasMatch(name)) {
        return false;
      }
      
      for (RegExp excludeRegex in excludeRegexes) {
        if (excludeRegex.hasMatch(name)) {
          return false;
        }
      }
      return true;
    }).toList();

    // print('$shopName has ${res.length} results');
    return res;
  }

  Future<String> searchObject(String search, int page) async {
    String url = getSearchUrl(Uri.encodeComponent(search), page);
    final response = await http.get(Uri.parse(url));
    return response.body;
  }

  List<SearchResult> processResults(String html);

	String get shopName;

	String getSearchUrl(String search, int page);
}
