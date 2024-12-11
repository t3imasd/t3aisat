// lib/models/search_result.dart
class SearchResult {
  final String name;
  final String address;
  final double latitude;
  final double longitude;

  SearchResult({
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  static List<SearchResult> fromFeatureCollection(Map<String, dynamic> json) {
    final features = json['features'] as List;
    return features.map((feature) {
      final coordinates = feature['geometry']['coordinates'] as List;
      return SearchResult(
        name: feature['text'] ?? '',
        address: feature['place_name'] ?? '',
        longitude: coordinates[0],
        latitude: coordinates[1],
      );
    }).toList();
  }
}
