class SearchRequest {
  final String include;
  final List<String> exclude;

  SearchRequest(this.include, {this.exclude = const []});
}