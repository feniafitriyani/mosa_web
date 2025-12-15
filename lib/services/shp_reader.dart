import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:latlong2/latlong.dart';

/// Minimal Shapefile (.shp) reader for Polygon/MultiPolygon geometries.
/// - Supports shape types: Polygon (5), PolygonM (25), PolygonZ (15)
/// - Reads only geometry from .shp (ignores attributes in .dbf)
/// - Assumes coordinates are already in EPSG:4326 (lat/lng). If not, you must reproject offline.
class ShpReader {
  /// Load polygon rings (outer rings only) from a .shp located in Flutter assets.
  /// Returns a list of polygons, each polygon is a list of LatLng (outer ring).
  static Future<List<List<LatLng>>> loadPolygonRingsFromAsset(String assetPath) async {
    final byteData = await rootBundle.load(assetPath);
    final bytes = byteData.buffer.asUint8List();

    if (bytes.length < 100) {
      throw Exception('SHP file too small: < 100 bytes');
    }

    int _readInt32BE(int offset) => (bytes[offset] << 24) |
        (bytes[offset + 1] << 16) |
        (bytes[offset + 2] << 8) |
        (bytes[offset + 3]);

    int _readInt32LE(int offset) => (bytes[offset]) |
        (bytes[offset + 1] << 8) |
        (bytes[offset + 2] << 16) |
        (bytes[offset + 3] << 24);

    double _readFloat64LE(int offset) {
      final b = bytes.buffer.asByteData();
      return b.getFloat64(offset, Endian.little);
    }

    // Validate file code (big endian 9994)
    final fileCode = _readInt32BE(0);
    if (fileCode != 9994) {
      throw Exception('Invalid SHP file code: $fileCode');
    }

    // Header fields we might check (not strictly needed):
    // version (LE) at 28, shape type (LE) at 32
    final version = _readInt32LE(28);
    if (version != 1000) {
      // Not fatal, but warn
    }

    final headerShapeType = _readInt32LE(32);
    // We'll still iterate records to handle mixed types or null shapes.

    final List<List<LatLng>> polygons = [];

    int pos = 100; // records start after 100-byte header
    while (pos + 8 <= bytes.length) {
      // Record header (big endian)
      final recNumber = _readInt32BE(pos);
      final contentLengthWords = _readInt32BE(pos + 4); // in 16-bit words
      final contentLengthBytes = contentLengthWords * 2;
      pos += 8;

      if (pos + contentLengthBytes > bytes.length) {
        // Corrupt length; stop parsing safely
        break;
      }

      final recStart = pos;
      final shapeType = _readInt32LE(recStart);

      // 0 = NullShape
      if (shapeType == 0) {
        pos += contentLengthBytes;
        continue;
      }

      // Accept Polygon types
      if (shapeType == 5 || shapeType == 15 || shapeType == 25) {
        // Polygon record content (LE):
        // int32 shapeType
        // bbox: 4 x float64 (xMin, yMin, xMax, yMax)
        // int32 numParts, int32 numPoints
        // parts: numParts x int32
        // points: numPoints x (float64 x, float64 y)
        int o = recStart + 4; // after shapeType
        // skip bbox (32 bytes)
        o += 32;
        final numParts = _readInt32LE(o); o += 4;
        final numPoints = _readInt32LE(o); o += 4;

        // Safety checks
        if (numParts <= 0 || numPoints <= 0) {
          pos += contentLengthBytes;
          continue;
        }

        final parts = <int>[];
        for (int i = 0; i < numParts; i++) {
          parts.add(_readInt32LE(o));
          o += 4;
        }

        // Points
        final pointsOffset = o;
        final expectedPointsBytes = numPoints * 16; // 16 bytes per point (x,y)
        if (pointsOffset + expectedPointsBytes > recStart + contentLengthBytes) {
          // Corrupt
          pos += contentLengthBytes;
          continue;
        }

        // Use only outer ring (first part)
        final startIndex = parts[0];
        final endIndex = (numParts > 1) ? parts[1] : numPoints;
        if (startIndex < 0 || endIndex > numPoints || endIndex <= startIndex) {
          pos += contentLengthBytes;
          continue;
        }

        final ring = <LatLng>[];
        for (int i = startIndex; i < endIndex; i++) {
          final pOff = pointsOffset + (i * 16);
          final x = _readFloat64LE(pOff + 0); // lon
          final y = _readFloat64LE(pOff + 8); // lat
          ring.add(LatLng(y, x));
        }

        if (ring.isNotEmpty) {
          polygons.add(ring);
        }
      }

      // Move to next record
      pos += contentLengthBytes;
    }

    // If header says not polygon but we parsed some, it's fine.
    if (polygons.isEmpty && (headerShapeType != 5 && headerShapeType != 15 && headerShapeType != 25)) {
      // No polygons found
    }

    return polygons;
  }
}