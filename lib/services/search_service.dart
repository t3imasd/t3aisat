// lib/services/search_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logging/logging.dart';
import '../model/search_result.dart';

class MapboxSearchService {
  final _logger = Logger('MapboxSearchService');
  final String _accessToken = dotenv.env['MAPBOX_ACCESS_TOKEN'] ?? '';
  
  Future<List<SearchResult>> searchAddress(String query) async {
    if (query.length < 3) return [];
    
    final url = Uri.parse(
      'https://api.mapbox.com/geocoding/v5/mapbox.places/$query.json'
      '?access_token=$_accessToken'
      '&country=es'
      '&types=address,place'
      '&language=es'
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return SearchResult.fromFeatureCollection(json.decode(response.body));
      }
      _logger.warning('Search failed: ${response.statusCode}');
      return [];
    } catch (e) {
      _logger.severe('Search error: $e');
      return [];
    }
  }
}