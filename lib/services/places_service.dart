import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/google_config.dart';

class PlaceSuggestion {
  final String placeId;
  final String description;

  PlaceSuggestion({required this.placeId, required this.description});
}

class PlaceDetails {
  final String name;
  final String formattedAddress;
  final double lat;
  final double lng;

  PlaceDetails({
    required this.name,
    required this.formattedAddress,
    required this.lat,
    required this.lng,
  });
}

class PlacesService {
  static const _base = 'https://maps.googleapis.com/maps/api/place';

  Future<List<PlaceSuggestion>> autocomplete(String input) async {
    if (input.trim().length < 2) return [];

    final uri = Uri.parse('$_base/autocomplete/json').replace(queryParameters: {
      'input': input.trim(),
      'components': 'country:pk',
      'key': GoogleConfig.placesApiKey,
    });

    final response = await http.get(uri).timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) return [];

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['status'] != 'OK' && data['status'] != 'ZERO_RESULTS') {
      return [];
    }

    final predictions = data['predictions'] as List<dynamic>? ?? [];
    return predictions
        .map((p) => PlaceSuggestion(
              placeId: p['place_id'] as String,
              description: p['description'] as String,
            ))
        .toList();
  }

  Future<PlaceDetails?> placeDetails(String placeId) async {
    final uri = Uri.parse('$_base/details/json').replace(queryParameters: {
      'place_id': placeId,
      'fields': 'name,formatted_address,geometry',
      'key': GoogleConfig.placesApiKey,
    });

    final response = await http.get(uri).timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) return null;

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['status'] != 'OK') return null;

    final result = data['result'] as Map<String, dynamic>?;
    if (result == null) return null;

    final geometry = result['geometry'] as Map<String, dynamic>?;
    final location = geometry?['location'] as Map<String, dynamic>?;
    if (location == null) return null;

    return PlaceDetails(
      name: result['name'] as String? ?? '',
      formattedAddress: result['formatted_address'] as String? ?? '',
      lat: (location['lat'] as num).toDouble(),
      lng: (location['lng'] as num).toDouble(),
    );
  }
}
