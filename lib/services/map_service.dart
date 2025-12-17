import 'dart:convert';

import 'package:http/http.dart' as http;

/// Service untuk mengambil data peta (blok, pit, dll) dari API backend.
class MapService {
  static const String _baseUrl = 'http://192.168.18.36:8000';

  /// Ambil GeoJSON block dari endpoint `/get-block`.
  ///
  /// Response diharapkan berbentuk:
  /// {
  ///   "type": "GeometryCollection",
  ///   "geometries": [ ... ]
  /// }
  static Future<Map<String, dynamic>> fetchBlocksGeoJson() async {
    final uri = Uri.parse('$_baseUrl/get-block');

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception(
        'Gagal mengambil data block (status: ${response.statusCode})',
      );
    }

    final dynamic decoded = json.decode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception('Format response /get-block tidak sesuai (bukan object)');
    }

    // Optional: validasi minimal field yang diperlukan
    if (!decoded.containsKey('type') || !decoded.containsKey('geometries')) {
      throw Exception('Response /get-block tidak memiliki field wajib');
    }

    return decoded;
  }

  /// Ambil GeoJSON pit dari endpoint `/get-pit`.
  ///
  /// Response diharapkan berbentuk:
  /// {
  ///   "type": "FeatureCollection",
  ///   "features": [ ... ]
  /// }
  static Future<Map<String, dynamic>> fetchPitsGeoJson() async {
    final uri = Uri.parse('$_baseUrl/get-pit');

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception(
        'Gagal mengambil data pit (status: ${response.statusCode})',
      );
    }

    final dynamic decoded = json.decode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception('Format response /get-pit tidak sesuai (bukan object)');
    }

    // Minimal validasi field
    if (!decoded.containsKey('type') || !decoded.containsKey('features')) {
      throw Exception('Response /get-pit tidak memiliki field wajib');
    }

    return decoded;
  }
}


