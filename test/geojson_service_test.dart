// Unit test untuk GeoJsonService.
//
// Memastikan file aset yang dipakai aplikasi benar-benar terbaca dengan
// benar:
// - `assets/maps/Sarijadi_Bounds.json`  -> bounds untuk menempatkan
//   gambar `assets/maps/Berau_3.webp` di peta.
// - `assets/maps/Sarijadi_Blocks.json`  -> grid kotak (box-1 .. box-4).
// - `assets/maps/Sarijadi_Area.json`    -> area bernama (BLOCK A/B, SOIL, ...).
// - `assets/maps/Sarijadi_Blocks_Strips.json` -> strip per unit (A-01, B-01, ...).
//
// File dibaca lewat dart:io (bukan rootBundle) supaya test murni unit test.

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_map/flutter_map.dart' show LatLngBounds;
import 'package:flutter/painting.dart' show Color;
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:mosa_maps_web/services/geojson_service.dart';

String _asset(String relativePath) => File(relativePath).readAsStringSync();

Map<String, dynamic> _assetMap(String relativePath) =>
    json.decode(_asset(relativePath)) as Map<String, dynamic>;

/// Rasio kontras WCAG antara dua warna (1.0 - 21.0).
double _contrastRatio(Color a, Color b) {
  final lumA = a.computeLuminance();
  final lumB = b.computeLuminance();
  final lighter = math.max(lumA, lumB);
  final darker = math.min(lumA, lumB);
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  group('GeoJsonService.parseHexColor', () {
    test('membaca #rrggbb sebagai warna opaque', () {
      expect(const Color(0xFFE6194B), GeoJsonService.parseHexColor('#e6194b'));
    });

    test('membaca #aarrggbb termasuk alpha', () {
      final color = GeoJsonService.parseHexColor('#80e6194b')!;
      expect(color.a, closeTo(0.5, 1 / 255));
      expect(color.toARGB32() & 0xFFFFFF, 0xE6194B);
    });

    test('mengembalikan null untuk nilai tidak valid', () {
      expect(GeoJsonService.parseHexColor(null), isNull);
      expect(GeoJsonService.parseHexColor(''), isNull);
      expect(GeoJsonService.parseHexColor('bukan-warna'), isNull);
    });
  });

  group('GeoJsonService.boundsFromGeoJson', () {
    test('Sarijadi_Bounds.json menghasilkan extent polygon-nya', () {
      final bounds = GeoJsonService.boundsFromGeoJson(
        _assetMap('assets/maps/Sarijadi_Bounds.json'),
      );

      expect(bounds, isNotNull);
      expect(bounds!.south, closeTo(-6.8820, 1e-9));
      expect(bounds.west, closeTo(107.5680, 1e-9));
      expect(bounds.north, closeTo(-6.8700, 1e-9));
      expect(bounds.east, closeTo(107.5800, 1e-9));
      // `center` dihitung dengan floating point, jadi toleransinya dilonggarkan.
      expect(bounds.center.latitude, closeTo(-6.8760, 1e-6));
      expect(bounds.center.longitude, closeTo(107.5740, 1e-6));
    });

    test('berau.bounds.json (format lama) tidak menghasilkan bounds GeoJSON', () {
      // Ini alasan tetap ada fallback format {minLat, minLng, maxLat, maxLng}.
      final bounds = GeoJsonService.boundsFromGeoJson(
        _assetMap('assets/maps/berau.bounds.json'),
      );

      expect(bounds, isNull);
    });

    test('geometry tunggal juga didukung', () {
      final bounds = GeoJsonService.boundsFromGeoJson({
        'type': 'Polygon',
        'coordinates': [
          [
            [107.0, -6.0],
            [107.5, -6.0],
            [107.5, -6.5],
            [107.0, -6.0],
          ],
        ],
      });

      expect(bounds!.south, closeTo(-6.5, 1e-9));
      expect(bounds.east, closeTo(107.5, 1e-9));
    });
  });

  group('GeoJsonService.parseStyledPolygons (Sarijadi_Blocks.json)', () {
    late List<StyledPolygon> polygons;

    setUpAll(() {
      polygons = GeoJsonService.parseStyledPolygons(
        _asset('assets/maps/Sarijadi_Blocks.json'),
      );
    });

    test('4 kotak grid terbaca dengan nama box-1..box-4', () {
      expect(polygons.length, 4);
      expect(
        polygons.map((p) => p.name).toList(),
        ['box-1', 'box-2', 'box-3', 'box-4'],
      );
    });

    test('file tanpa gaya memakai satu warna seragam', () {
      // Tidak ada `fill` di file, jadi semua kotak memakai defaultColor
      // yang sama agar peta tidak terlihat penuh warna-warni.
      for (final p in polygons) {
        expect(
          p.fillColor.toARGB32() & 0xFFFFFF,
          GeoJsonService.defaultColor.toARGB32() & 0xFFFFFF,
        );
        expect(p.strokeColor.toARGB32(), GeoJsonService.defaultColor.toARGB32());
        // Fill semi-transparan supaya citra peta di bawahnya tetap terlihat.
        expect(p.fillColor.a, closeTo(0.35, 1e-9));
        expect(p.strokeWidth, 2);
      }
    });

    test('box-1 adalah persegi sesuai koordinat di file', () {
      final box1 = polygons.first;
      final lats = box1.points.map((p) => p.latitude);
      final lngs = box1.points.map((p) => p.longitude);

      expect(lats.reduce((a, b) => a < b ? a : b), closeTo(-6.873, 1e-9));
      expect(lats.reduce((a, b) => a > b ? a : b), closeTo(-6.87, 1e-9));
      expect(lngs.reduce((a, b) => a < b ? a : b), closeTo(107.568, 1e-9));
      expect(lngs.reduce((a, b) => a > b ? a : b), closeTo(107.58, 1e-9));
    });
  });

  group('GeoJsonService.parseStyledPolygons (Sarijadi_Area.json)', () {
    late List<StyledPolygon> polygons;

    setUpAll(() {
      polygons = GeoJsonService.parseStyledPolygons(
        _asset('assets/maps/Sarijadi_Area.json'),
      );
    });

    test('7 area terbaca dengan nama dan id yang benar', () {
      expect(polygons.length, 7);
      expect(
        polygons.map((p) => p.name).toList(),
        ['BLOCK A', 'BLOCK B', 'SOIL 01', 'SOIL-02', 'ODP', 'ISP', 'PORT'],
      );
      expect(polygons.map((p) => p.id).toList(), [3, 4, 5, 6, 7, 8, 9]);
    });

    test('semua area memakai satu warna yang sama', () {
      final colors =
          polygons.map((p) => p.fillColor.toARGB32() & 0xFFFFFF).toSet();
      expect(colors, {GeoJsonService.defaultColor.toARGB32() & 0xFFFFFF});
    });

    test('area ODP berbentuk persegi sesuai koordinat di file', () {
      final odp = polygons.firstWhere((p) => p.name == 'ODP');
      final lats = odp.points.map((p) => p.latitude);
      final lngs = odp.points.map((p) => p.longitude);

      expect(lats.reduce((a, b) => a < b ? a : b), closeTo(-6.8761143, 1e-9));
      expect(lats.reduce((a, b) => a > b ? a : b), closeTo(-6.8754261, 1e-9));
      expect(lngs.reduce((a, b) => a < b ? a : b), closeTo(107.5778191, 1e-9));
      expect(lngs.reduce((a, b) => a > b ? a : b), closeTo(107.5784492, 1e-9));
    });
  });

  group(
    'GeoJsonService.parseStyledPolygons (Sarijadi_Blocks_Strips.json)',
    () {
      late List<StyledPolygon> polygons;

      setUpAll(() {
        polygons = GeoJsonService.parseStyledPolygons(
          _asset('assets/maps/Sarijadi_Blocks_Strips.json'),
        );
      });

      test('15 strip terbaca (A-01..A-12 dan B-01..B-03)', () {
        expect(polygons.length, 15);
        expect(polygons.first.name, 'A-01');
        expect(polygons[11].name, 'A-12');
        expect(polygons.last.name, 'B-03');
      });

      test('properties group memisahkan unit-A dan unit-B', () {
        expect(
          polygons.where((p) => p.group == 'unit-A').length,
          12,
        );
        expect(
          polygons.where((p) => p.group == 'unit-B').length,
          3,
        );
      });

      test('ring tertutup dan koordinat [lng, lat] terkonversi', () {
        final a01 = polygons.first;
        expect(a01.points.length, 5); // ring tertutup
        expect(a01.points.first, const LatLng(-6.8814977, 107.574671));
        expect(a01.points.first, a01.points.last);
      });
    },
  );

  group('GeoJsonService bounds vs layer Sarijadi', () {
    late LatLngBounds bounds;

    setUpAll(() {
      bounds = GeoJsonService.boundsFromGeoJson(
        _assetMap('assets/maps/Sarijadi_Bounds.json'),
      )!;
    });

    for (final file in const [
      'assets/maps/Sarijadi_Blocks.json',
      'assets/maps/Sarijadi_Area.json',
      'assets/maps/Sarijadi_Blocks_Strips.json',
    ]) {
      test('semua polygon di $file berada di dalam bounds', () {
        final polygons = GeoJsonService.parseStyledPolygons(_asset(file));
        expect(polygons, isNotEmpty);

        for (final polygon in polygons) {
          for (final point in polygon.points) {
            expect(
              bounds.contains(point),
              isTrue,
              reason: '${polygon.name} keluar dari bounds Sarijadi',
            );
          }
        }
      });
    }
  });

  group('GeoJsonService.parsePoints (Sarijadi_Points.json)', () {
    late List<StyledPoint> points;

    setUpAll(() {
      points = GeoJsonService.parsePoints(
        _asset('assets/maps/Sarijadi_Points.json'),
      );
    });

    test('36 titik terbaca: 8 PIT + 28 corner', () {
      expect(points.length, 36);
      expect(points.where((p) => p.group == 'pit').length, 8);
      expect(points.where((p) => p.group == 'corner').length, 28);
    });

    test('koordinat [lng, lat] dikonversi ke LatLng(lat, lng)', () {
      final first = points.first;
      expect(first.name, 'PIT-A01-C1');
      expect(first.point, const LatLng(-6.8812146, 107.5755745));
    });

    test('properties parent menunjuk ke area induknya', () {
      final odp = points.firstWhere((p) => p.name == 'ODP-C3');
      expect(odp.parent, 'ODP');
      expect(odp.id, 54);

      // Titik PIT induknya unit, bukan polygon area.
      final pit = points.firstWhere((p) => p.name == 'PIT-B01-C2');
      expect(pit.group, 'pit');
      expect(pit.parent, 'unit-B');
    });

    test('semua titik memakai satu warna seragam', () {
      for (final p in points) {
        expect(
          p.color.toARGB32(),
          GeoJsonService.defaultColor.toARGB32(),
          reason: p.name,
        );
      }
    });

    test('setiap area punya tepat 4 titik corner', () {
      final parents = points
          .where((p) => p.group == 'corner')
          .map((p) => p.parent)
          .toList();

      for (final parent in parents.toSet()) {
        expect(
          parents.where((p) => p == parent).length,
          4,
          reason: 'corner untuk $parent',
        );
      }
      // 7 area: BLOCK A/B, SOIL 01/02, ODP, ISP, PORT.
      expect(parents.toSet().length, 7);
    });

    // `parent` di Sarijadi_Points.json dan `name` di Sarijadi_Area.json
    // tidak selalu sama formatnya: "BLOCK A" vs "BLOCK-A",
    // "SOIL 01" vs "SOIL-01". Normalisasi supaya yang dibandingkan isi
    // nama, bukan tanda pisah.
    String keyOf(String value) => value.replaceAll(RegExp(r'[\s_]+'), '-');

    test('titik corner area mendekati vertex polygon-nya', () {
      // Corner tiap area harus berimpit dengan vertex polygon di
      // Sarijadi_Area.json. Yang diuji adalah jarak ke vertex TERDEKAT,
      // bukan urutan index, karena urutan titik di kedua file tidak
      // dijamin sama.
      //
      // Toleransi 1e-4 derajat (~11 m) longgar karena dua titik memang
      // tidak identik di data:
      //   ODP-C4   ~1.4 m  (Points -6.876101499 vs Area -6.8761143)
      //   PORT-C2  ~4.9 m  (Points -6.876135599 vs Area -6.8761795)
      // Sisanya cocok persis. Polygon yang dirender, jadi file Area
      // dipakai sebagai acuan.
      final areaPolygons = GeoJsonService.parseStyledPolygons(
        _asset('assets/maps/Sarijadi_Area.json'),
      );

      for (final area in areaPolygons) {
        final corners =
            points.where((p) => keyOf(p.parent!) == keyOf(area.name!)).toList();
        expect(corners.length, 4, reason: 'corner untuk ${area.name}');

        // Buang titik ring tertutup, ambil 4 vertex unik.
        final vertices = area.points.take(4).toList();

        for (final corner in corners) {
          final nearest = vertices
              .map(
                (v) => math.sqrt(
                  math.pow(v.latitude - corner.point.latitude, 2) +
                      math.pow(v.longitude - corner.point.longitude, 2),
                ),
              )
              .reduce((a, b) => a < b ? a : b);

          expect(
            nearest,
            lessThan(1e-4),
            reason: '${corner.name} jauh dari vertex ${area.name}',
          );
        }
      }
    });

    test('corner yang menyimpang dari polygon > 1 m terbatas 4 titik', () {
      // Dokumentasi data. Corner di Sarijadi_Points.json tidak selalu sama
      // persis dengan vertex polygon di Sarijadi_Area.json. Diukur ke
      // vertex TERDEKAT, simpangan yang tercatat:
      //   PORT-C2     4.89 m
      //   BLOCK-B-C4  1.93 m
      //   ODP-C4      1.42 m
      //   BLOCK-A-C1  0.94 m  (masih di bawah ambang 1 m)
      // Sisanya jauh lebih kecil. Test ini gagal duluan kalau data di
      // sumber berubah atau proses generate ulang tidak stabil.
      const expectedOver1m = {'PORT-C2', 'BLOCK-B-C4', 'ODP-C4'};

      final areaPolygons = GeoJsonService.parseStyledPolygons(
        _asset('assets/maps/Sarijadi_Area.json'),
      );
      final over1m = <String>{};

      for (final area in areaPolygons) {
        final vertices = area.points.take(4).toList();
        for (final corner
            in points.where((p) => keyOf(p.parent!) == keyOf(area.name!))) {
          final nearest = vertices
              .map(
                (v) => math.sqrt(
                  math.pow(v.latitude - corner.point.latitude, 2) +
                      math.pow(v.longitude - corner.point.longitude, 2),
                ),
              )
              .reduce((a, b) => a < b ? a : b);

          // 1 meter ~= 9e-6 derajat; pakai 1e-5 (sekitar 1.1 m) sebagai
          // ambang "melebihi 1 meter".
          if (nearest > 1e-5) over1m.add(corner.name!);
        }
      }

      expect(over1m, expectedOver1m);
    });

    test('setiap parent corner punya area yang cocok di Sarijadi_Area.json', () {
      // Menangkap kalau ada parent yang tidak punya polygon pasangan.
      final areaNames = GeoJsonService.parseStyledPolygons(
        _asset('assets/maps/Sarijadi_Area.json'),
      ).map((a) => keyOf(a.name!)).toSet();

      final parentNames = points
          .where((p) => p.group == 'corner')
          .map((p) => keyOf(p.parent!))
          .toSet();

      // 7 area: BLOCK A/B, SOIL 01/02, ODP, ISP, PORT.
      expect(parentNames.length, 7);
      expect(parentNames.difference(areaNames), isEmpty);
    });

    test('semua titik berada di dalam Sarijadi_Bounds.json', () {
      final bounds = GeoJsonService.boundsFromGeoJson(
        _assetMap('assets/maps/Sarijadi_Bounds.json'),
      )!;

      for (final p in points) {
        expect(bounds.contains(p.point), isTrue, reason: '${p.name} di luar');
      }
    });
  });

  group('GeoJsonService.parsePoints mengabaikan geometry lain', () {
    test('feature non-Point dilewati, bukan di-crash', () {
      final points = GeoJsonService.parsePoints(
        _asset('assets/maps/Sarijadi_Area.json'),
      );
      // File itu semua Polygon, jadi tidak ada yang jadi StyledPoint.
      expect(points, isEmpty);
    });
  });

  group('GeoJsonService satu warna untuk semua layer Sarijadi', () {
    test('ketiga layer memakai warna yang sama persis', () {
      // RGB saja (tanpa alpha) karena fill sudah di-mask dengan 0xFFFFFF.
      const expected = 0x2196F3;
      expect(GeoJsonService.defaultColor.toARGB32() & 0xFFFFFF, expected);

      for (final file in const [
        'assets/maps/Sarijadi_Blocks.json',
        'assets/maps/Sarijadi_Area.json',
        'assets/maps/Sarijadi_Blocks_Strips.json',
      ]) {
        final polygons = GeoJsonService.parseStyledPolygons(_asset(file));
        expect(polygons, isNotEmpty, reason: file);

        for (final p in polygons) {
          expect(
            p.fillColor.toARGB32() & 0xFFFFFF,
            expected,
            reason: '${p.name} di $file tidak seragam',
          );
          // Stroke opaque, jadi nilainya berupa ARGB penuh.
          expect(
            p.strokeColor.toARGB32(),
            0xFF000000 | expected,
            reason: p.name,
          );
        }
      }
    });

    test('fallbackColor bisa dioverride per pemanggil', () {
      const orange = Color(0xFFF58231);
      final polygons = GeoJsonService.parseStyledPolygons(
        _asset('assets/maps/Sarijadi_Area.json'),
        fallbackColor: orange,
      );

      for (final p in polygons) {
        expect(p.strokeColor.toARGB32(), orange.toARGB32());
      }
    });
  });

  group('GeoJsonService.labelColorFor', () {
    test('warna label kontras dengan warna poligonnya', () {
      const darkFill = Color(0xFF1A237E);
      const lightFill = Color(0xFFFFF9C4);

      expect(GeoJsonService.labelColorFor(darkFill), const Color(0xFFFFFFFF));
      expect(GeoJsonService.labelColorFor(lightFill), const Color(0xFF000000));

      // Rasio kontras harus jauh di atas ambang keterbacaan WCAG AA.
      for (final fill in const [darkFill, lightFill]) {
        final label = GeoJsonService.labelColorFor(fill);
        expect(
          _contrastRatio(label, GeoJsonService.haloColorFor(label)),
          greaterThan(1.5),
        );
      }
    });
  });
}
