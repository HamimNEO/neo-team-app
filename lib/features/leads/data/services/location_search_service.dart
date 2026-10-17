import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/config/app_config.dart';

class LocationSearchResult {
  final String title;
  final String subtitle;
  final String displayName;
  final String? placeId;
  final double latitude;
  final double longitude;

  const LocationSearchResult({
    required this.title,
    required this.subtitle,
    required this.displayName,
    this.placeId,
    required this.latitude,
    required this.longitude,
  });
}

class LocationSearchService {
  LocationSearchService._();
  static final LocationSearchService instance = LocationSearchService._();

  static const List<LocationSearchResult> popularHubs = [
    LocationSearchResult(
      title: 'Dhaka',
      subtitle: 'Dhaka Division, Bangladesh',
      displayName: 'Dhaka, Bangladesh',
      latitude: 23.8103,
      longitude: 90.4125,
    ),
    LocationSearchResult(
      title: "Cox's Bazar",
      subtitle: 'Chittagong Division, Bangladesh',
      displayName: "Cox's Bazar, Bangladesh",
      latitude: 21.4272,
      longitude: 92.0058,
    ),
    LocationSearchResult(
      title: 'Chattogram',
      subtitle: 'Chittagong Division, Bangladesh',
      displayName: 'Chattogram, Bangladesh',
      latitude: 22.3569,
      longitude: 91.7832,
    ),
    LocationSearchResult(
      title: 'Sylhet',
      subtitle: 'Sylhet Division, Bangladesh',
      displayName: 'Sylhet, Bangladesh',
      latitude: 24.8949,
      longitude: 91.8687,
    ),
    LocationSearchResult(
      title: 'Gulshan 2',
      subtitle: 'Dhaka, Bangladesh',
      displayName: 'Gulshan 2, Dhaka, Bangladesh',
      latitude: 23.7925,
      longitude: 90.4078,
    ),
    LocationSearchResult(
      title: 'Banani',
      subtitle: 'Dhaka, Bangladesh',
      displayName: 'Banani, Dhaka, Bangladesh',
      latitude: 23.7937,
      longitude: 90.4066,
    ),
    LocationSearchResult(
      title: 'Dhanmondi',
      subtitle: 'Dhaka, Bangladesh',
      displayName: 'Dhanmondi, Dhaka, Bangladesh',
      latitude: 23.7461,
      longitude: 90.3742,
    ),
    LocationSearchResult(
      title: 'Inani Beach',
      subtitle: 'Cox\'s Bazar, Bangladesh',
      displayName: "Inani Beach, Marine Drive, Cox's Bazar, Bangladesh",
      latitude: 21.2156,
      longitude: 92.0489,
    ),
  ];

  String get _apiKey => AppConfig.googleMapsApiKey;

  Future<List<LocationSearchResult>> search(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return const [];

    final key = _apiKey;
    if (key.isNotEmpty) {
      try {
        final uri = Uri.parse(
          'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=${Uri.encodeComponent(cleanQuery)}&key=$key',
        );
        final response = await http.get(uri, headers: {
          'Accept': 'application/json'
        }).timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data is Map && data['status'] == 'OK') {
            final predictions = data['predictions'] as List? ?? [];
            final results = <LocationSearchResult>[];

            for (final p in predictions.take(5)) {
              if (p is Map) {
                final placeId = p['place_id']?.toString();
                final formatting = p['structured_formatting'] as Map?;
                final title = formatting?['main_text']?.toString() ??
                    p['description']?.toString() ??
                    '';
                final subtitle =
                    formatting?['secondary_text']?.toString() ?? '';
                final displayName = p['description']?.toString() ?? title;

                if (placeId != null) {
                  // Resolve coordinate for the prediction
                  final coords = await getPlaceCoordinates(placeId);
                  results.add(
                    LocationSearchResult(
                      title: title,
                      subtitle: subtitle,
                      displayName: displayName,
                      placeId: placeId,
                      latitude: coords?['lat'] ?? 23.8103,
                      longitude: coords?['lng'] ?? 90.4125,
                    ),
                  );
                }
              }
            }
            if (results.isNotEmpty) return results;
          }
        }
      } catch (_) {}

      // Fallback to Google Geocoding API if places autocomplete didn't return
      try {
        final geoUri = Uri.parse(
          'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(cleanQuery)}&key=$key',
        );
        final geoResp =
            await http.get(geoUri).timeout(const Duration(seconds: 5));
        if (geoResp.statusCode == 200) {
          final data = jsonDecode(geoResp.body);
          if (data is Map && data['status'] == 'OK') {
            final geoResults = data['results'] as List? ?? [];
            final results = <LocationSearchResult>[];
            for (final r in geoResults.take(4)) {
              if (r is Map) {
                final formatted = r['formatted_address']?.toString() ?? '';
                final loc = r['geometry']?['location'] as Map?;
                final lat = (loc?['lat'] as num?)?.toDouble();
                final lng = (loc?['lng'] as num?)?.toDouble();
                if (lat != null && lng != null) {
                  final parts =
                      formatted.split(',').map((s) => s.trim()).toList();
                  results.add(
                    LocationSearchResult(
                      title: parts.first,
                      subtitle: parts.skip(1).take(2).join(', '),
                      displayName: formatted,
                      latitude: lat,
                      longitude: lng,
                    ),
                  );
                }
              }
            }
            if (results.isNotEmpty) return results;
          }
        }
      } catch (_) {}
    }

    // Local matching from popular hubs
    final lower = cleanQuery.toLowerCase();
    return popularHubs
        .where((h) =>
            h.title.toLowerCase().contains(lower) ||
            h.subtitle.toLowerCase().contains(lower))
        .toList();
  }

  Future<Map<String, double>?> getPlaceCoordinates(String placeId) async {
    final key = _apiKey;
    if (key.isEmpty) return null;
    try {
      final uri = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&fields=geometry&key=$key',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map && data['status'] == 'OK') {
          final loc = data['result']?['geometry']?['location'] as Map?;
          final lat = (loc?['lat'] as num?)?.toDouble();
          final lng = (loc?['lng'] as num?)?.toDouble();
          if (lat != null && lng != null) {
            return {'lat': lat, 'lng': lng};
          }
        }
      }
    } catch (_) {}
    return null;
  }

  Future<String?> reverseGeocode(double lat, double lng) async {
    final key = _apiKey;
    if (key.isNotEmpty) {
      try {
        final uri = Uri.parse(
          'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$key',
        );
        final response =
            await http.get(uri).timeout(const Duration(seconds: 4));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data is Map && data['status'] == 'OK') {
            final results = data['results'] as List?;
            if (results != null && results.isNotEmpty) {
              final formatted = results[0]['formatted_address']?.toString();
              if (formatted != null && formatted.isNotEmpty) {
                // Shorten slightly if too verbose
                final parts =
                    formatted.split(',').map((p) => p.trim()).toList();
                if (parts.length > 4) {
                  return parts.take(3).join(', ');
                }
                return formatted;
              }
            }
          }
        }
      } catch (_) {}
    }
    return null;
  }
}
