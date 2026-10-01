import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/painting.dart' show Color;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_map/flutter_map.dart' show LatLngBounds;
import 'package:latlong2/latlong.dart';

/// Polygon ber-style hasil parsing GeoJSON (FeatureCollection of Polygon).
///
/// Setiap feature bisa membawa gaya sendiri di `properties`
/// (`fill`, `fill-opacity`, `stroke`, `stroke-width`) dan `name`. Layer yang
/// GeoJSON-nya tidak membawa gaya (mis. `assets/maps/Sarijadi_Blocks.json`,
/// `assets/maps/Sarijadi_Area.json`, `assets/maps/Sarijadi_Blocks_Strips.json`)
/// memakai satu warna seragam dari [defaultColor] agar peta tidak terlihat
/// penuh warna-warni.
class StyledPolygon {
  final List<LatLng> points;
  final Color fillColor;
  final Color strokeColor;
  final double strokeWidth;
  final String? name;

  /// `properties.id` bila ada, dipakai sebagai kunci stabil untuk filter/label.
  final Object? id;

  /// `properties.group` bila ada (mis. `unit-A` pada block strip).
  final String? group;

  const StyledPolygon({
    required this.points,
    required this.fillColor,
    required this.strokeColor,
    required this.strokeWidth,
    this.name,
    this.id,
    this.group,
  });
}

/// Titik (Point) hasil parsing GeoJSON, dipakai untuk layer vertex/sudut.
///
/// Mirip [StyledPolygon] tetapi hanya punya satu koordinat. `group` dan
/// `parent` diambil dari `properties` sehingga titik bisa dikelompokkan
/// (mis. `pit` / `corner`) dan ditelusuri ke induknya (`unit-A`, `BLOCK-A`).
class StyledPoint {
  final LatLng point;
  final Color color;
  final String? name;

  /// `properties.id` bila ada, dipakai sebagai kunci stabil untuk filter.
  final Object? id;

  /// `properties.group` bila ada (mis. `pit` atau `corner`).
  final String? group;

  /// `properties.parent` bila ada (mis. `BLOCK-A` atau `unit-A`).
  final String? parent;

  const StyledPoint({
    required this.point,
    required this.color,
    this.name,
    this.id,
    this.group,
    this.parent,
  });
}

/// Helper untuk membaca GeoJSON sederhana (FeatureCollection / GeometryCollection
/// / geometry tunggal) dari asset maupun string JSON.
class GeoJsonService {
  /// Warna tunggal untuk semua polygon layer Sarijadi.
  ///
  /// Dipakai bila feature tidak membawa `fill`/`stroke` sendiri di
  /// `properties` (mis. `Sarijadi_Blocks.json`, `Sarijadi_Area.json`,
  /// `Sarijadi_Blocks_Strips.json`). Seluruh layer memakai satu warna yang
  /// sama agar peta tidak terlihat penuh warna-warni.
  static const Color defaultColor = Color(0xFF2196F3);

  /// Alpha default untuk fill saat `fill-opacity` tidak ada di properties.
  static const double defaultFillOpacity = 0.35;

  /// Lebar garis default saat `stroke-width` tidak ada di properties.
  static const double defaultStrokeWidth = 2.0;

  /// Baca dan parse polygon ber-style dari asset GeoJSON.
  ///
  /// Melempar exception jika asset tidak ada atau JSON-nya tidak valid
  /// (dibiarkan ke pemanggil agar bisa fallback / logging).
  static Future<List<StyledPolygon>> loadStyledPolygons(String assetPath) async {
    final jsonStr = await rootBundle.loadString(assetPath);
    return parseStyledPolygons(jsonStr);
  }

  /// Parse polygon dari string GeoJSON.
  ///
  /// Seluruh polygon memakai satu warna yang sama ([fallbackColor]) sehingga
  /// peta tidak terlihat penuh warna-warni. Warna ini hanya dipakai sebagai
  ///allback; feature yang punya `fill`/`stroke` sendiri di `properties`
  /// tetap dirender sesuai file aslinya.
  static List<StyledPolygon> parseStyledPolygons(
    String jsonStr, {
    Color fallbackColor = defaultColor,
  }) {
    final decoded = json.decode(jsonStr);
    if (decoded is! Map<String, dynamic>) return const [];

    final features = decoded['features'] as List<dynamic>?;
    if (features == null) return const [];

    final List<StyledPolygon> polygons = [];

    for (final f in features) {
      if (f is! Map<String, dynamic>) continue;
      final geometry = f['geometry'] as Map<String, dynamic>?;
      if (geometry == null) continue;
      // Hanya Polygon yang didukung (MultiPolygon bisa ditambah bila perlu).
      if (geometry['type'] != 'Polygon') continue;

      final rings = geometry['coordinates'] as List<dynamic>?;
      if (rings == null || rings.isEmpty) continue;

      final points = latLngsFromRing(rings.first);
      if (points.length < 3) continue;

      final props = f['properties'] as Map<String, dynamic>?;
      final fill = parseHexColor(props?['fill'] as String?) ?? fallbackColor;
      final fillOpacity =
          ((props?['fill-opacity'] ?? props?['fillOpacity']) as num?)
              ?.toDouble() ??
          defaultFillOpacity;
      final stroke = parseHexColor(props?['stroke'] as String?) ?? fallbackColor;
      final strokeWidth =
          (props?['stroke-width'] as num?)?.toDouble() ?? defaultStrokeWidth;

      polygons.add(
        StyledPolygon(
          points: points,
          fillColor: fill.withValues(alpha: fillOpacity.clamp(0.0, 1.0)),
          strokeColor: stroke,
          strokeWidth: strokeWidth,
          name: props?['name'] as String?,
          id: props?['id'],
          group: props?['group'] as String?,
        ),
      );
    }

    return polygons;
  }

  /// Ubah satu ring GeoJSON `[[lng, lat], ...]` menjadi `List<LatLng>`.
  static List<LatLng> latLngsFromRing(List<dynamic> ring) {
    final List<LatLng> points = [];
    for (final p in ring) {
      if (p is! List || p.length < 2) continue;
      final lng = p[0];
      final lat = p[1];
      if (lng is! num || lat is! num) continue;
      points.add(LatLng(lat.toDouble(), lng.toDouble()));
    }
    return points;
  }

  /// Baca dan parse geometry `Point` dari asset GeoJSON.
  ///
  /// Melempar exception bila asset tidak ada atau JSON tidak valid.
  static Future<List<StyledPoint>> loadPoints(String assetPath) async {
    final jsonStr = await rootBundle.loadString(assetPath);
    return parsePoints(jsonStr);
  }

  /// Parse geometry `Point` dari string GeoJSON.
  ///
  /// Feature bertipe selain `Point` diabaikan. Semua titik memakai satu
  /// warna yang sama ([fallbackColor]) agar konsisten dengan
  /// [parseStyledPolygons] dan tidak membuat peta penuh warna-warni.
  static List<StyledPoint> parsePoints(
    String jsonStr, {
    Color fallbackColor = defaultColor,
  }) {
    final decoded = json.decode(jsonStr);
    if (decoded is! Map<String, dynamic>) return const [];

    final features = decoded['features'] as List<dynamic>?;
    if (features == null) return const [];

    final List<StyledPoint> points = [];

    for (final f in features) {
      if (f is! Map<String, dynamic>) continue;
      final geometry = f['geometry'] as Map<String, dynamic>?;
      if (geometry == null) continue;
      if (geometry['type'] != 'Point') continue;

      final coords = geometry['coordinates'];
      if (coords is! List || coords.length < 2) continue;
      final lng = coords[0];
      final lat = coords[1];
      if (lng is! num || lat is! num) continue;

      final props = f['properties'] as Map<String, dynamic>?;
      points.add(
        StyledPoint(
          point: LatLng(lat.toDouble(), lng.toDouble()),
          color: parseHexColor(props?['fill'] as String?) ?? fallbackColor,
          name: props?['name'] as String?,
          id: props?['id'],
          group: props?['group'] as String?,
          parent: props?['parent'] as String?,
        ),
      );
    }

    return points;
  }

  /// Baca bounds (extent) dari asset GeoJSON.
  static Future<LatLngBounds?> loadBounds(String assetPath) async {
    final jsonStr = await rootBundle.loadString(assetPath);
    final decoded = json.decode(jsonStr);
    if (decoded is! Map<String, dynamic>) return null;
    return boundsFromGeoJson(decoded);
  }

  /// Hitung [LatLngBounds] dari GeoJSON apapun bentuknya
  /// (FeatureCollection, GeometryCollection, Feature, atau geometry tunggal).
  static LatLngBounds? boundsFromGeoJson(Map<String, dynamic> data) {
    double? minLat, minLng, maxLat, maxLng;

    void visit(dynamic node) {
      if (node is! List) return;
      // [longitude, latitude] => titik koordinat
      if (node.length >= 2 && node[0] is num && node[1] is num) {
        final lng = (node[0] as num).toDouble();
        final lat = (node[1] as num).toDouble();
        minLat = minLat == null ? lat : math.min(minLat!, lat);
        maxLat = maxLat == null ? lat : math.max(maxLat!, lat);
        minLng = minLng == null ? lng : math.min(minLng!, lng);
        maxLng = maxLng == null ? lng : math.max(maxLng!, lng);
        return;
      }
      for (final child in node) {
        visit(child);
      }
    }

    final features = data['features'] as List<dynamic>?;
    if (features != null) {
      for (final f in features) {
        if (f is! Map<String, dynamic>) continue;
        final geometry = f['geometry'] as Map<String, dynamic>?;
        visit(geometry?['coordinates']);
      }
    } else if (data['geometries'] is List) {
      for (final g in data['geometries'] as List<dynamic>) {
        if (g is! Map<String, dynamic>) continue;
        visit(g['coordinates']);
      }
    } else {
      visit(data['coordinates']);
    }

    if (minLat == null || minLng == null || maxLat == null || maxLng == null) {
      return null;
    }
    return LatLngBounds(LatLng(minLat!, minLng!), LatLng(maxLat!, maxLng!));
  }

  /// Konversi warna hex dari GeoJSON (`#rrggbb` atau `#aarrggbb`) ke [Color].
  static Color? parseHexColor(String? value) {
    if (value == null) return null;
    var hex = value.trim().replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    if (hex.length != 8) return null;
    final parsed = int.tryParse(hex, radix: 16);
    return parsed == null ? null : Color(parsed);
  }

  /// Ambang luminansi (WCAG) di mana kontras teks hitam dan teks putih setara.
  static const double _luminancePivot = 0.179;

  /// Warna teks yang kontras untuk label di dalam kotak berwarna [fillColor].
  ///
  /// Kotak digambar semi-transparan di atas citra peta, jadi warna tampak
  /// kotak diperkirakan dengan mem-blend [fillColor] ke atas [backdrop]
  /// (abu-abu netral). Lalu dipilih teks gelap untuk kotak terang dan teks
  /// terang untuk kotak gelap sehingga kontrasnya tetap terjaga.
  static Color labelColorFor(
    Color fillColor, {
    Color backdrop = const Color(0xFF808080),
    Color darkText = const Color(0xFF000000),
    Color lightText = const Color(0xFFFFFFFF),
  }) {
    final blended = Color.alphaBlend(fillColor, backdrop);
    return blended.computeLuminance() > _luminancePivot
        ? darkText
        : lightText;
  }

  /// Warna "halo" (bayangan teks) kebalikan dari [labelColor], supaya label
  /// tetap terbaca walau warna dasar di bawahnya berubah-ubah.
  static Color haloColorFor(Color labelColor) {
    return labelColor.computeLuminance() > 0.5
        ? const Color(0xCC000000)
        : const Color(0xCCFFFFFF);
  }
}
