import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/foundation.dart' show compute, kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/asset.dart';
import '../services/data_service.dart';
import '../services/geojson_service.dart';
// removed unused import: map_service
import '../widgets/asset_sidebar.dart';

import '../widgets/map_controls.dart';
import '../widgets/legend_control.dart';
import '../widgets/layer_control.dart';
import '../widgets/asset_popup.dart';
import '../widgets/task_history_table.dart';
import '../widgets/asset_tracking_table.dart';

class MapsScreen extends StatefulWidget {
  final VoidCallback? onToggleTheme;
  const MapsScreen({super.key, this.onToggleTheme});

  @override
  State<MapsScreen> createState() => _MapsScreenState();
}

class _MapsScreenState extends State<MapsScreen> {
  final MapController _mapController = MapController();
  late List<Asset> _filteredAssets;
  final Set<AssetStatus> _visibleStatuses = {
    AssetStatus.active,
    AssetStatus.operating,
    AssetStatus.hold,
    AssetStatus.inactive,
  };
  String _currentMapLayer = 'geotiff-base';
  Asset? _selectedAsset;
  bool _showTaskHistory = false;
  bool _showTracking = false;
  double _detailPanelHeightFactor =
      0.4; // proportion of available height for detail panel
  List<AssetTrackingPoint> _trackingData = const [];
  Offset? _popupPosition;
  DateTime _currentTime = DateTime.now();
  DateTime _nasaDate = DateTime.now().subtract(const Duration(days: 1));
  Timer? _timer;
  bool _isTiffLoading = false;

  // TIFF overlay state
  Uint8List? _tiffPngBytes;
  LatLngBounds? _tiffBounds;
  double _tiffOpacity = 0.0; // for fade-in animation
  // Sementara: jika tidak ada GeoTIFF worldfile/prj dibaca otomatis, pakai bbox manual
  // TODO: update ke nilai akurat sesuai georeferensi Berau_3.tif
  // Update ke bounding box yang lebih ketat agar sesuai area Berau
  static final LatLngBounds _fallbackBounds = LatLngBounds(
    LatLng(2.02, 117.22), // south-west (adjusted)
    LatLng(2.14, 117.38), // north-east (adjusted)
  );

  // Sarijadi_Blocks_Strips overlay polygons (loaded from GeoJSON).
  // Dipakai bersama [StyledPolygon] supaya label "A-01" / "B-01" bisa digambar.
  List<StyledPolygon> _blockStripPolygons = [];
  bool _showBlockStripPolygons = true; // default on

  // Berau_3_Track overlay polylines (loaded from GeoJSON)
  List<List<LatLng>> _trackPolylines = [];
  bool _showTrackPolylines = true; // default off

  // Berau_3_Point overlay markers (loaded from GeoJSON)
  List<Marker> _letterPointMarkers = [];
  List<Marker> _pitPointMarkers = [];
  bool _showLetterPoints = true;
  bool _showPitPoints = true;
  bool _showPointMarkers = true; // default off
  Set<String> _visiblePointNames = {};
  List<String> _allPointNames = [];

  // Sarijadi_Area overlay polygons (BLOCK A/B, SOIL, ODP, ISP, PORT).
  List<StyledPolygon> _sarijadiAreaPolygons = [];
  bool _showSarijadiAreaPolygons = true;

  // Sarijadi_Blocks overlay polygons (grid box-1 .. box-4).
  List<StyledPolygon> _sarijadiBlockPolygons = [];
  bool _showSarijadiBlockPolygons = true;

  // Label untuk ketiga layer Sarijadi di atas.
  bool _showSarijadiLabels = true;

  // Sarijadi_Points overlay — titik sudut (corner) tiap area dan titik PIT.
  // Satu warna seragam, sama seperti layer polygon di atas.
  List<StyledPoint> _sarijadiPoints = [];
  bool _showSarijadiPoints = true;
  bool _showCornerPoints = true; // titik corner tiap area

  // Filter states
  String? _selectedSite;
  EquipmentType? _selectedEquipmentType;
  String? _selectedUnit;
  AssetStatus? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _filteredAssets = DataService.assets;
    _startTimer();

    // Tunda pekerjaan berat sampai frame pertama dirender agar tidak blok UI awal
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadGeoTiffOverlay(); // Prioritaskan overlay dasar terlebih dahulu
      // Tiga layer geospasial Sarijadi (grid block, area, dan block strip).
      _loadSarijadiBlockGeoJson(); // assets/maps/Sarijadi_Blocks.json
      _loadSarijadiAreaGeoJson(); // assets/maps/Sarijadi_Area.json
      _loadBerauBlockStripGeoJson(); // assets/maps/Sarijadi_Blocks_Strips.json
      _loadSarijadiPointsGeoJson(); // assets/maps/Sarijadi_Points.json
    });
  }

  // Build units list filtered by equipment type selection
  List<String> _unitsForType(EquipmentType? type) {
    final assets = DataService.assets;
    final filtered =
        type == null ? assets : assets.where((a) => a.type == type);
    return filtered.map((a) => a.name).toList();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _currentTime = DateTime.now();
      });
    });
  }

  // Helper untuk proses berat di isolate: decode TIFF, resize keras, encode cepat
  static Uint8List _decodeResizeEncodePng(Uint8List tiffBytes) {
    final img.Image? raster = img.decodeTiff(tiffBytes);
    if (raster == null) {
      throw Exception('Gagal decode TIFF (null result)');
    }
    // Turunkan resolusi agar proses resize/encode jauh lebih cepat
    // 1536 cukup tajam untuk view umum; set ke 1024 jika ingin lebih cepat lagi.
    final int targetWidth = 1536;
    final img.Image resized = img.copyResize(
      raster,
      width: raster.width > targetWidth ? targetWidth : raster.width,
      interpolation: img.Interpolation.linear,
    );
    // Gunakan level kompresi rendah agar encode cepat dan ukuran file kecil cukup
    return Uint8List.fromList(img.encodePng(resized, level: 1));
  }

  /// Baca bounds peta dari file JSON.
  ///
  /// Bounds inilah yang dipakai untuk meletakkan gambar
  /// `assets/maps/Berau_3.webp` di atas peta (gambar tetap Berau_3.webp,
  /// tetapi koordinat/extent-nya mengikuti file Sarijadi).
  ///
  /// Urutan sumber:
  /// 1. `assets/maps/Sarijadi_Bounds.json` — GeoJSON FeatureCollection,
  ///    bounds dihitung otomatis dari koordinat polygon.
  /// 2. `assets/maps/berau.bounds.json` — format lama
  ///    `{ minLat, minLng, maxLat, maxLng }` sebagai fallback.
  Future<LatLngBounds?> _tryLoadBoundsFromJson() async {
    // 1) Prioritaskan Sarijadi_Bounds.json (GeoJSON FeatureCollection)
    try {
      final bounds = await GeoJsonService.loadBounds(
        'assets/maps/Sarijadi_Bounds.json',
      );
      if (bounds != null) return bounds;
    } catch (_) {
      // Abaikan, lanjut ke format fallback
    }

    // 2) Fallback: format sederhana berau.bounds.json
    try {
      final jsonStr = await rootBundle.loadString(
        'assets/maps/berau.bounds.json',
      );
      final Map<String, dynamic> data = json.decode(jsonStr);
      final minLat = (data['minLat'] as num).toDouble();
      final minLng = (data['minLng'] as num).toDouble();
      final maxLat = (data['maxLat'] as num).toDouble();
      final maxLng = (data['maxLng'] as num).toDouble();
      return LatLngBounds(LatLng(minLat, minLng), LatLng(maxLat, maxLng));
    } catch (_) {
      return null;
    }
  }

  Future<File?> _getCacheFile() async {
    if (kIsWeb) return null;
    final dir = await getTemporaryDirectory();
    // Tambahkan versi agar bisa invalidasi jika algoritma/ukuran berubah
    final path =
        '${dir.path}${Platform.pathSeparator}berau_3_cache_v1_1536.png';
    return File(path);
  }

  Future<bool> _tryLoadFromCache() async {
    if (kIsWeb) return false;
    try {
      final file = await _getCacheFile();
      if (file == null) return false;
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        if (bytes.isNotEmpty) {
          _tiffPngBytes = bytes;
          return true;
        }
      }
    } catch (_) {}
    return false;
  }

  Future<void> _saveToCache(Uint8List bytes) async {
    if (kIsWeb) return;
    try {
      final file = await _getCacheFile();
      if (file == null) return;
      await file.writeAsBytes(bytes, flush: true);
    } catch (_) {}
  }

  Future<void> _loadGeoTiffOverlay() async {
    try {
      setState(() {
        _isTiffLoading = true;
        _tiffOpacity = 0.0; // reset opacity for fade-in
      });

      // 1) Coba baca bounds dari JSON jika tersedia
      _tiffBounds = await _tryLoadBoundsFromJson() ?? _fallbackBounds;

      // 1.5) Coba dari cache lokal agar startup berikutnya instan
      if (await _tryLoadFromCache()) {
        setState(() {
          _isTiffLoading = false;
          _tiffOpacity = 1.0;
        });
        if (mounted && _tiffBounds != null) {
          _mapController.fitCamera(CameraFit.bounds(bounds: _tiffBounds!));
        }
        return;
      }

      // 2) Coba muat raster prarender (WEBP/JPG/PNG) dengan beberapa opsi ukuran
      try {
        // Prioritaskan WEBP (paling kecil), lalu JPG, kemudian PNG
        final List<String> candidates = [
          'assets/maps/Berau_3.webp',
          'assets/maps/Berau_3_1536.webp',
          'assets/maps/Berau_3_1024.webp',
          'assets/maps/Berau_3_1536.jpg',
          'assets/maps/Berau_3_2048.jpg',
          'assets/maps/Berau_3_1536.png',
          'assets/maps/Berau_3_2048.png',
        ];
        ByteData? best;
        for (final path in candidates) {
          try {
            best = await rootBundle.load(path);
            if (best.lengthInBytes > 0) {
              break;
            }
          } catch (_) {
            // ignore and try next candidate
          }
        }
        if (best != null && best.lengthInBytes > 0) {
          _tiffPngBytes = best.buffer.asUint8List();
          // Simpan ke cache untuk startup berikutnya
          await _saveToCache(_tiffPngBytes!);

          setState(() {
            _isTiffLoading = false;
            _tiffOpacity = 1.0; // trigger fade-in
          });

          // Auto fit ke bounds
          if (mounted && _tiffBounds != null) {
            _mapController.fitCamera(CameraFit.bounds(bounds: _tiffBounds!));
          }
          return; // sukses prarender raster, tidak perlu proses TIFF
        }
      } catch (_) {
        // Tidak ada raster prarender, lanjut ke TIFF
      }

      // 3) Fallback: Load GeoTIFF bytes dari assets (akan lebih lambat)
      final byteData = await rootBundle.load('assets/maps/Berau_3.tif');
      final bytes = byteData.buffer.asUint8List();

      // 4) Pindahkan decode + resize + encode ke isolate agar UI tidak freeze
      final pngBytes = await compute(_decodeResizeEncodePng, bytes);
      _tiffPngBytes = pngBytes;
      // Simpan ke cache untuk startup berikutnya
      await _saveToCache(_tiffPngBytes!);

      setState(() {
        _isTiffLoading = false;
        _tiffOpacity = 1.0; // trigger fade-in
      });

      // 5) Auto fit camera ke bounds GeoTIFF
      if (mounted && _tiffBounds != null) {
        _mapController.fitCamera(CameraFit.bounds(bounds: _tiffBounds!));
      }
    } catch (e) {
      setState(() => _isTiffLoading = false);
      debugPrint('Failed to load GeoTIFF overlay: $e');
    }
  }

  /// Load polygon grid blok dari `assets/maps/Sarijadi_Blocks.json`.
  ///
  /// Berisi 4 kotak persegi (`box-1` .. `box-4`) yang membagi area peta
  /// menjadi grid. File ini tidak membawa gaya, jadi semua kotak memakai
  /// satu warna seragam dari [GeoJsonService.defaultColor].
  Future<void> _loadSarijadiBlockGeoJson() async {
    try {
      final polygons = await GeoJsonService.loadStyledPolygons(
        'assets/maps/Sarijadi_Blocks.json',
      );
      if (!mounted) return;
      setState(() {
        _sarijadiBlockPolygons = polygons;
      });
    } catch (e) {
      debugPrint('Failed to load Sarijadi_Blocks: $e');
    }
  }

  /// Load area Sarijadi dari `assets/maps/Sarijadi_Area.json`
  /// (BLOCK A, BLOCK B, SOIL 01, SOIL-02, ODP, ISP, PORT).
  Future<void> _loadSarijadiAreaGeoJson() async {
    try {
      final polygons = await GeoJsonService.loadStyledPolygons(
        'assets/maps/Sarijadi_Area.json',
      );
      if (!mounted) return;
      setState(() {
        _sarijadiAreaPolygons = polygons;
      });
    } catch (e) {
      debugPrint('Failed to load Sarijadi_Area: $e');
    }
  }

  /// Load strip blok dari `assets/maps/Sarijadi_Blocks_Strips.json`.
  ///
  /// Setiap strip punya `name` (A-01 .. A-12, B-01 .. B-03) dan `group`
  /// (`unit-A` / `unit-B`) sehingga labelnya bisa ditampilkan.
  Future<void> _loadBerauBlockStripGeoJson() async {
    try {
      final polygons = await GeoJsonService.loadStyledPolygons(
        'assets/maps/Sarijadi_Blocks_Strips.json',
      );
      if (!mounted) return;
      setState(() {
        _blockStripPolygons = polygons;
      });
    } catch (e) {
      debugPrint('Failed to load Sarijadi_Blocks_Strips: $e');
    }
  }

  /// Load titik sudut dari `assets/maps/Sarijadi_Points.json`.
  ///
  /// Berisi 36 titik: 8 titik PIT (`group: pit`) dan 28 titik corner
  /// (`group: corner`) dari BLOCK A/B, SOIL 01/02, ODP, ISP, dan PORT.
  /// `properties.parent` menyimpan induk tiap titik, mis. `ODP-C1` -> `ODP`.
  Future<void> _loadSarijadiPointsGeoJson() async {
    try {
      final points = await GeoJsonService.loadPoints(
        'assets/maps/Sarijadi_Points.json',
      );
      if (!mounted) return;
      setState(() {
        _sarijadiPoints = points;
      });
    } catch (e) {
      debugPrint('Failed to load Sarijadi_Points: $e');
    }
  }

  /// Bangun marker untuk satu [StyledPoint].
  ///
  /// Titik digambar sebagai lingkaran kecil dengan outline putih agar
  /// tetap terlihat di atas citra peta. Label nama hanya ditampilkan
  /// ketika [_showSarijadiLabels] aktif supaya tidak memenuhi peta.
  Marker _buildSarijadiPointMarker(StyledPoint p) {
    final isPit = p.group == 'pit';

    return Marker(
      point: p.point,
      width: 96,
      height: 40,
      key: ValueKey('sarijadi_point_${p.id ?? p.name}'),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_showSarijadiLabels && p.name != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: p.color, width: 0.5),
              ),
              child: Text(
                p.name!,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: isPit ? FontWeight.bold : FontWeight.normal,
                  color: const Color(0xFF000000),
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          // Ukuran sedikit dibedakan agar PIT mudah dibedakan dari corner,
          // tanpa memakai warna berbeda.
          Container(
            width: isPit ? 12 : 8,
            height: isPit ? 12 : 8,
            decoration: BoxDecoration(
              color: p.color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  // Load Berau_3_Track polylines
  // Future<void> _loadBerauTrackGeoJson() async {
  //   try {
  //     final jsonStr = await rootBundle.loadString(
  //       'assets/maps/Berau_3_Track.json',
  //     );
  //     final data = json.decode(jsonStr) as Map<String, dynamic>;
  //     final features = data['features'] as List<dynamic>?;
  //     if (features == null) return;

  //     final List<List<LatLng>> polylines = [];

  //     for (final f in features) {
  //       final feature = f as Map<String, dynamic>;
  //       final geometry = feature['geometry'] as Map<String, dynamic>?;
  //       if (geometry == null) continue;
  //       final type = geometry['type'] as String?;
  //       final coords = geometry['coordinates'];

  //       if (type == 'LineString') {
  //         final points = coords as List<dynamic>;
  //         final List<LatLng> latlngs =
  //             points
  //                 .map(
  //                   (p) => LatLng(
  //                     (p[1] as num).toDouble(),
  //                     (p[0] as num).toDouble(),
  //                   ),
  //                 )
  //                 .toList();
  //         polylines.add(latlngs);
  //       }
  //     }

  //     if (mounted) {
  //       setState(() {
  //         _trackPolylines = polylines;
  //       });
  //     }
  //   } catch (e) {
  //     debugPrint('Failed to load Berau_3_Track: $e');
  //   }
  // }

  // Load Berau_3_Point markers
  // Future<void> _loadBerauPointGeoJson() async {
  //   try {
  //     final jsonStr = await rootBundle.loadString(
  //       'assets/maps/Berau_3_Point.json',
  //     );
  //     final data = json.decode(jsonStr) as Map<String, dynamic>;
  //     final features = data['features'] as List<dynamic>?;
  //     if (features == null) return;

  //     final List<Marker> letters = [];
  //     final List<Marker> pits = [];
  //     final List<String> allNames = [];

  //     for (final f in features) {
  //       final feature = f as Map<String, dynamic>;
  //       final geometry = feature['geometry'] as Map<String, dynamic>?;
  //       final properties = feature['properties'] as Map<String, dynamic>?;
  //       if (geometry == null) continue;
  //       final type = geometry['type'] as String?;
  //       final coords = geometry['coordinates'];
  //       final name = properties?['name'] as String? ?? '';

  //       if (type == 'Point') {
  //         if (name.isNotEmpty && !allNames.contains(name)) {
  //           allNames.add(name);
  //         }
  //         final point = coords as List<dynamic>;
  //         final latLng = LatLng(
  //           (point[1] as num).toDouble(),
  //           (point[0] as num).toDouble(),
  //         );
  //         final marker = Marker(
  //           point: latLng,
  //           width: 80,
  //           height: 60,
  //           key: ValueKey('marker_$name'),
  //           child: Column(
  //             mainAxisSize: MainAxisSize.min,
  //             children: [
  //               Flexible(
  //                 child: Container(
  //                   padding: const EdgeInsets.symmetric(
  //                     horizontal: 4,
  //                     vertical: 1,
  //                   ),
  //                   decoration: BoxDecoration(
  //                     color: Colors.white,
  //                     borderRadius: BorderRadius.circular(3),
  //                     border: Border.all(color: Colors.black, width: 0.5),
  //                   ),
  //                   child: Text(
  //                     name,
  //                     style: const TextStyle(
  //                       fontSize: 10,
  //                       fontWeight: FontWeight.bold,
  //                       color: Colors.black,
  //                     ),
  //                     overflow: TextOverflow.ellipsis,
  //                     maxLines: 1,
  //                   ),
  //                 ),
  //               ),
  //               const Icon(Icons.location_on, color: Colors.red, size: 18),
  //             ],
  //           ),
  //         );

  //         if (name.toUpperCase().startsWith('PIT')) {
  //           pits.add(marker);
  //         } else {
  //           letters.add(marker);
  //         }
  //       }
  //     }

  //     if (mounted) {
  //       setState(() {
  //         _letterPointMarkers = letters;
  //         _pitPointMarkers = pits;
  //         _allPointNames = allNames;
  //         _visiblePointNames = Set.from(allNames);
  //       });
  //     }
  //   } catch (e) {
  //     debugPrint('Failed to load Berau_3_Point: $e');
  //   }
  // }

  /// Bangun [Polygon] untuk satu area Sarijadi.
  ///
  /// Warna teks label dipilih otomatis (terang/gelap) agar kontras dengan
  /// warna poligonnya, lalu diberi "halo" warna kebalikannya supaya tetap
  /// terbaca meski citra peta di bawahnya terang/gelap.
  Polygon<Object> _buildSarijadiPolygon(StyledPolygon p) {
    final labelColor = GeoJsonService.labelColorFor(p.fillColor);
    final haloColor = GeoJsonService.haloColorFor(labelColor);

    return Polygon<Object>(
      points: p.points,
      color: p.fillColor,
      borderColor: p.strokeColor,
      borderStrokeWidth: p.strokeWidth,
      label: _showSarijadiLabels ? p.name : null,
      labelStyle: TextStyle(
        fontSize: 9,
        fontWeight: FontWeight.bold,
        color: labelColor,
        shadows: [
          Shadow(color: haloColor, blurRadius: 2, offset: Offset.zero),
        ],
      ),
    );
  }

  void _applyFilters() {
    setState(() {
      _filteredAssets = DataService.getFilteredAssets(
        site: _selectedSite,
        equipmentType: _selectedEquipmentType,
        unit: _selectedUnit,
        status: _selectedStatus,
      );
    });
  }

  void _onAssetTap(Asset asset) {
    setState(() {
      _selectedAsset = asset;
      _showTaskHistory = false;
      _showTracking = false;
      _trackingData = const [];
      _popupPosition = _calculatePopupPosition(asset.position);
    });

    _mapController.move(asset.position, 16.0);
  }

  Offset _calculatePopupPosition(LatLng assetPosition) {
    // Get the map center and zoom level
    final mapCenter = _mapController.camera.center;
    final zoom = _mapController.camera.zoom;

    // Calculate screen position based on lat/lng differences
    // This is a simplified calculation - in production you'd want more precise conversion
    const double tileSize = 256.0;
    final scale = tileSize * (1 << zoom.toInt()) / 360.0;

    final centerX = (mapCenter.longitude + 180.0) * scale;
    final centerY = (90.0 - mapCenter.latitude) * scale * (3.14159 / 180.0);

    final assetX = (assetPosition.longitude + 180.0) * scale;
    final assetY = (90.0 - assetPosition.latitude) * scale * (3.14159 / 180.0);

    // Approximate screen offset from center
    double offsetX =
        (assetX - centerX) + 400; // 400 is approximate map center X
    double offsetY =
        (assetY - centerY) + 300; // 300 is approximate map center Y

    // Ensure popup doesn't go off screen
    offsetX = offsetX.clamp(20.0, 800.0);
    offsetY = offsetY.clamp(50.0, 500.0);

    return Offset(offsetX, offsetY);
  }

  void _onViewDetail() {
    setState(() {
      _showTracking = false;
      _showTaskHistory = true;
    });
  }

  void _onTrackAsset() {
    if (_selectedAsset == null) return;
    final tracking = DataService.getTrackingData(_selectedAsset!.id);
    setState(() {
      _showTaskHistory = false;
      _showTracking = true;
      _trackingData = tracking;
    });

    _fitMapToTrackingPoints(tracking);
  }

  void _handleFilteredTrackingPoints(List<AssetTrackingPoint> points) {
    if (!mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _trackingData = points;
      });
      _fitMapToTrackingPoints(points);
    });
  }

  void _fitMapToTrackingPoints(List<AssetTrackingPoint> points) {
    if (points.isEmpty) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (points.length == 1) {
        _mapController.move(points.first.position, 17.0);
      } else {
        final bounds = LatLngBounds.fromPoints(
          points.map((point) => point.position).toList(),
        );
        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: bounds,
            padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 80),
          ),
        );
      }
    });
  }

  void _closeAssetPopup() {
    setState(() {
      _selectedAsset = null;
      _showTaskHistory = false;
      _showTracking = false;
      _popupPosition = null;
    });
  }

  void _resetMapView() {
    if (_tiffBounds != null) {
      _mapController.fitCamera(CameraFit.bounds(bounds: _tiffBounds!));
    } else {
      _mapController.fitCamera(CameraFit.bounds(bounds: _fallbackBounds));
    }
  }

  void _recenterMap() {
    if (_filteredAssets.isNotEmpty) {
      final center = _calculateCenter(_filteredAssets);
      _mapController.move(center, 13.0);
    }
  }

  LatLng _calculateCenter(List<Asset> assets) {
    if (assets.isEmpty) return const LatLng(2.0875, 117.2833);

    double totalLat = 0;
    double totalLng = 0;

    for (final asset in assets) {
      totalLat += asset.position.latitude;
      totalLng += asset.position.longitude;
    }

    return LatLng(totalLat / assets.length, totalLng / assets.length);
  }

  Color _getStatusColor(AssetStatus status) {
    switch (status) {
      case AssetStatus.active:
        return Colors.green;
      case AssetStatus.operating:
        return Colors.teal;
      case AssetStatus.hold:
        return Colors.orange;
      case AssetStatus.inactive:
        return Theme.of(context).colorScheme.outline;
    }
  }

  List<Marker> _buildTrackingMarkers({List<AssetTrackingPoint>? points}) {
    final data = points ?? _trackingData;
    if (data.isEmpty) return [];

    return List.generate(data.length, (index) {
      final point = data[index];
      final bool isStart = index == 0;
      final bool isEnd = index == data.length - 1;
      final Color color =
          isStart
              ? Colors.green
              : isEnd
              ? Colors.red
              : Colors.blueAccent;
      final double size = isStart || isEnd ? 26 : 18;

      return Marker(
        point: point.position,
        width: size,
        height: size,
        alignment: Alignment.center,
        child: Tooltip(
          message: DateFormat('yyyy-MM-dd HH:mm').format(point.timestamp),
          child: Container(
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child:
                isStart || isEnd
                    ? Center(
                      child: Icon(
                        isStart ? Icons.play_arrow_rounded : Icons.flag_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                    )
                    : null,
          ),
        ),
      );
    });
  }

  List<Polyline> _buildTrackingPolylines({List<AssetTrackingPoint>? points}) {
    final data = points ?? _trackingData;
    if (data.length < 2) return [];

    final latLngs = data.map((point) => point.position).toList();
    return [
      Polyline(
        points: latLngs,
        color: Colors.blueAccent.withOpacity(0.65),
        strokeWidth: 4,
        borderColor: Colors.white.withOpacity(0.6),
        borderStrokeWidth: 1,
      ),
    ];
  }

  // Build asset icon widget from local SVGs in assets/icons
  Widget _buildAssetIcon(Asset asset) {
    final String svgPath = _svgPathForAsset(asset);
    final Color iconColor = _getStatusColor(asset.status);
    return SvgPicture.asset(
      svgPath,
      width: 28,
      height: 28,
      // Color follows status; no background container, so it's transparent
      colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
      package: null,
      placeholderBuilder:
          (_) => Icon(Icons.construction, size: 28, color: iconColor),
    );
  }

  // Map equipment types/names to local SVG asset paths
  String _svgPathForAsset(Asset asset) {
    final name = asset.name.toLowerCase();
    if (name.contains('fuel')) {
      return 'icons/fuel_truck.svg';
    }
    if (name.contains('ripper')) {
      return 'icons/ripper.svg';
    }
    switch (asset.type) {
      case EquipmentType.excavator:
        return 'icons/excavator.svg';
      case EquipmentType.dozer:
        return 'icons/bulldozer.svg';
      case EquipmentType.hauler:
        return 'icons/dump_truck.svg';
      case EquipmentType.grader:
        // No grader.svg provided, fallback to excavator or a generic one
        return 'icons/excavator.svg';
      case EquipmentType.fuel:
        // No grader.svg provided, fallback to excavator or a generic one
        return 'icons/excavator.svg';
    }
  }

  String _getTileUrl() {
    final dateStr = _formatDateForNasa(_nasaDate);

    switch (_currentMapLayer) {
      case 'osm':
        // OpenStreetMap (OpenMap) standar - Open Data (ODbL), gratis.
        return 'https://tiles.openfreemap.org/styles/liberty';
      case 'carto-light':
        // CartoDB Light - 100% gratis & legal untuk komersial
        return 'https://cartodb-basemaps-a.global.ssl.fastly.net/light_all/{z}/{x}/{y}.png';
      case 'wikimedia':
        // Wikimedia Maps - 100% gratis & legal untuk komersial
        return 'https://maps.wikimedia.org/osm-intl/{z}/{x}/{y}.png';
      case 'usgs-satellite':
        // USGS Satellite - US Government, Public Domain
        return 'https://basemap.nationalmap.gov/arcgis/rest/services/USGSImageryOnly/MapServer/tile/{z}/{y}/{x}';
      case 'usgs-glovis-landsat':
        // USGS GloVis Landsat - Public Domain, high resolution
        return 'https://basemap.nationalmap.gov/arcgis/rest/services/USGSImageryOnly/MapServer/tile/{z}/{y}/{x}';
      case 'usgs-imagery-topo':
        // USGS Imagery Topo - Combines satellite imagery with topographic data
        return 'https://basemap.nationalmap.gov/arcgis/rest/services/USGSImageryTopo/MapServer/tile/{z}/{y}/{x}';

      // NASA GIBS Layers with dynamic dates
      case 'nasa-modis-terra':
        return 'https://gibs.earthdata.nasa.gov/wmts/epsg3857/best/MODIS_Terra_CorrectedReflectance_TrueColor/default/$dateStr/GoogleMapsCompatible_Level9/{z}/{x}/{y}.jpg';
      case 'nasa-modis-aqua':
        return 'https://gibs.earthdata.nasa.gov/wmts/epsg3857/best/MODIS_Aqua_CorrectedReflectance_TrueColor/default/$dateStr/GoogleMapsCompatible_Level9/{z}/{x}/{y}.jpg';
      case 'nasa-viirs':
        return 'https://gibs.earthdata.nasa.gov/wmts/epsg3857/best/VIIRS_SNPP_CorrectedReflectance_TrueColor/default/$dateStr/GoogleMapsCompatible_Level9/{z}/{x}/{y}.jpg';
      case 'nasa-modis-terra-false':
        return 'https://gibs.earthdata.nasa.gov/wmts/epsg3857/best/MODIS_Terra_CorrectedReflectance_Bands721/default/$dateStr/GoogleMapsCompatible_Level9/{z}/{x}/{y}.jpg';
      case 'nasa-landsat':
        return 'https://gibs.earthdata.nasa.gov/wmts/epsg3857/best/Landsat_WELD_CorrectedReflectance_TrueColor_Global_Annual/default/$dateStr/GoogleMapsCompatible_Level12/{z}/{x}/{y}.jpg';

      // NASA LP DAAC Layers - Land Processes Data
      case 'nasa-lp-daac-lst':
        return 'https://gibs.earthdata.nasa.gov/wmts/epsg3857/best/MODIS_Terra_Land_Surface_Temp_Day/default/$dateStr/GoogleMapsCompatible_Level7/{z}/{x}/{y}.png';
      case 'nasa-lp-daac-ndvi':
        return 'https://gibs.earthdata.nasa.gov/wmts/epsg3857/best/MODIS_Terra_NDVI_8Day/default/$dateStr/GoogleMapsCompatible_Level9/{z}/{x}/{y}.png';
      case 'nasa-lp-daac-evi':
        return 'https://gibs.earthdata.nasa.gov/wmts/epsg3857/best/MODIS_Terra_EVI_8Day/default/$dateStr/GoogleMapsCompatible_Level9/{z}/{x}/{y}.png';

      // ESA Sentinel (Copernicus) Layers
      case 'esa-sentinel-2-cloudless':
        // ESA Sentinel-2 Cloudless by EOX - Free for commercial use with attribution
        return 'https://tiles.maps.eox.at/wmts/1.0.0/s2cloudless-2020_3857/default/g/{z}/{y}/{x}.jpg';
      case 'esa-sentinel-2-true-color':
        // ESA Sentinel-2 True Color - Using EOX alternative service
        return 'https://tiles.maps.eox.at/wmts/1.0.0/s2cloudless_3857/default/g/{z}/{y}/{x}.jpg';
      case 'esa-sentinel-1-sar':
        // ESA Sentinel-1 SAR - Using terrain visualization as alternative
        return 'https://tiles.maps.eox.at/wmts/1.0.0/terrain_3857/default/g/{z}/{y}/{x}.jpg';

      // JAXA Satellite Data - Open Data (using compatible tile services)
      case 'jaxa-alos-palsar':
        // JAXA ALOS PALSAR - Using OpenTopoMap as alternative (similar terrain data)
        return 'https://tile.opentopomap.org/{z}/{x}/{y}.png';
      case 'jaxa-gcom-amsr2':
        // JAXA GCOM AMSR2 - Using ESRI World Imagery as alternative
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';

      case 'sentinel-hub':
        // OpenTopoMap - Free for commercial use, topographic style
        return 'https://tile.opentopomap.org/{z}/{x}/{y}.png';
      case 'stamen-terrain':
        // Stamen Terrain - Free for commercial use
        return 'https://stamen-tiles.a.ssl.fastly.net/terrain/{z}/{x}/{y}.png';
      case 'google-satellite':
        // OpenAerialMap - Community satellite imagery, Free for commercial
        return 'https://tiles.openaerialmap.org/5ac626e091b5310010e0d482/0/5ac626e091b5310010e0d483/{z}/{x}/{y}';
      case 'bing-satellite':
        // USGS Topo - Free satellite-like imagery, Public Domain
        return 'https://basemap.nationalmap.gov/arcgis/rest/services/USGSTopo/MapServer/tile/{z}/{y}/{x}';
      case 'mapbox-satellite':
        // OpenStreetMap France HOT Style - Free for commercial
        return 'https://tile.openstreetmap.fr/hot/{z}/{x}/{y}.png';
      case 'geotiff-base':
        // Tidak ada tile URL karena GeoTIFF digunakan sebagai base tanpa layer lain
        return '';
      default:
        // Default ke CartoDB Light
        return 'https://cartodb-basemaps-a.global.ssl.fastly.net/light_all/{z}/{x}/{y}.png';
    }
  }

  String _formatDateForNasa(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _getTileAttribution() {
    switch (_currentMapLayer) {
      case 'osm':
        return '© OpenStreetMap contributors (ODbL)';
      case 'carto-light':
        return '© CARTO, © OpenStreetMap contributors';
      case 'wikimedia':
        return '© Wikimedia maps, © OpenStreetMap contributors';
      case 'usgs-satellite':
        return '© U.S. Geological Survey (USGS) - Public Domain';
      case 'usgs-glovis-landsat':
        return '© USGS GloVis - Landsat Collection (Public Domain)';
      case 'usgs-imagery-topo':
        return '© USGS Imagery Topo - Public Domain';

      // NASA GIBS Attributions
      case 'nasa-modis-terra':
      case 'nasa-modis-aqua':
      case 'nasa-viirs':
      case 'nasa-modis-terra-false':
      case 'nasa-landsat':
        return '© NASA EOSDIS GIBS - Public Domain';

      // NASA LP DAAC Attributions
      case 'nasa-lp-daac-lst':
      case 'nasa-lp-daac-ndvi':
      case 'nasa-lp-daac-evi':
        return '© NASA LP DAAC via GIBS - Public Domain';

      // ESA Sentinel (Copernicus) Attributions
      case 'esa-sentinel-2-cloudless':
        return '© Sentinel-2 cloudless by EOX IT Services GmbH (Contains modified Copernicus Sentinel data)';
      case 'esa-sentinel-2-true-color':
        return '© ESA Sentinel-2 via EOX (Contains Copernicus Sentinel data)';
      case 'esa-sentinel-1-sar':
        return '© ESA Sentinel-1 SAR via EOX (Contains Copernicus Sentinel data)';

      // JAXA Attributions (using alternative services)
      case 'jaxa-alos-palsar':
        return '© OpenTopoMap (CC-BY-SA), © OpenStreetMap contributors';
      case 'jaxa-gcom-amsr2':
        return '© Esri World Imagery, © OpenStreetMap contributors';

      case 'sentinel-hub':
        return '© OpenTopoMap (CC-BY-SA), © OpenStreetMap contributors';
      case 'stamen-terrain':
        return '© Stamen Design, © OpenStreetMap contributors';
      case 'google-satellite':
        return '© OpenAerialMap contributors - Community Driven';
      case 'bing-satellite':
        return '© U.S. Geological Survey (USGS) - Public Domain';
      case 'mapbox-satellite':
        return '© OpenStreetMap France, © OpenStreetMap contributors';
      case 'geotiff-base':
        return '© GeoTIFF Berau (local overlay)';
      default:
        return '© CARTO, © OpenStreetMap contributors';
    }
  }

  double _getMaxZoom() {
    switch (_currentMapLayer) {
      case 'geotiff-base':
        return 18.0;
      case 'osm':
        return 19.0; // OpenStreetMap standar maksimal z19
      case 'carto-light':
        return 20.0; // CartoDB Light maksimal z20
      case 'wikimedia':
        return 19.0; // Wikimedia osm-intl maksimal z19
      // NASA GIBS layers with enhanced zoom levels
      case 'nasa-modis-terra':
      case 'nasa-modis-aqua':
      case 'nasa-viirs':
      case 'nasa-modis-terra-false':
        return 9.0; // NASA GIBS MODIS/VIIRS max zoom
      case 'nasa-landsat':
        return 12.0; // NASA GIBS Landsat max zoom

      // NASA LP DAAC layers zoom levels
      case 'nasa-lp-daac-lst':
        return 7.0; // NASA LP DAAC Land Surface Temperature max zoom
      case 'nasa-lp-daac-ndvi':
      case 'nasa-lp-daac-evi':
        return 9.0; // NASA LP DAAC Vegetation indices max zoom

      // ESA Sentinel layers zoom levels
      case 'esa-sentinel-2-cloudless':
      case 'esa-sentinel-2-true-color':
        return 18.0; // ESA Sentinel-2 very high resolution
      case 'esa-sentinel-1-sar':
        return 12.0; // ESA Sentinel-1 SAR moderate zoom

      case 'usgs-satellite':
        return 16.0; // USGS has good resolution but limited zoom
      case 'usgs-glovis-landsat':
        return 18.0; // USGS GloVis Landsat high resolution
      case 'usgs-imagery-topo':
        return 16.0; // USGS Imagery Topo standard zoom

      // JAXA layers zoom levels
      case 'jaxa-alos-palsar':
        return 15.0; // JAXA ALOS PALSAR moderate zoom
      case 'jaxa-gcom-amsr2':
        return 12.0; // JAXA GCOM AMSR2 moderate zoom
      case 'sentinel-hub':
        return 17.0; // OpenTopoMap maximum zoom level
      case 'stamen-terrain':
        return 18.0; // Stamen Terrain standard zoom
      case 'google-satellite':
        return 18.0; // OpenAerialMap standard zoom
      case 'bing-satellite':
        return 19.0; // Bing Satellite high zoom
      case 'mapbox-satellite':
        return 18.0; // OSM France standard zoom
      default:
        return 18.0; // Standard zoom for map layers
    }
  }

  int _getMaxNativeZoom() {
    switch (_currentMapLayer) {
      case 'geotiff-base':
        // Tidak relevan untuk GeoTIFF overlay statis
        return 18;
      case 'osm':
        return 19; // OpenStreetMap standar maksimal z19
      case 'carto-light':
        return 20; // CartoDB Light maksimal z20
      case 'wikimedia':
        return 19; // Wikimedia osm-intl maksimal z19
      // NASA GIBS layers with enhanced zoom levels
      case 'nasa-modis-terra':
      case 'nasa-modis-aqua':
      case 'nasa-viirs':
      case 'nasa-modis-terra-false':
        return 9; // NASA GIBS MODIS/VIIRS max zoom
      case 'nasa-landsat':
        return 12; // NASA GIBS Landsat max zoom

      // NASA LP DAAC layers native zoom levels
      case 'nasa-lp-daac-lst':
        return 7; // NASA LP DAAC Land Surface Temperature max zoom
      case 'nasa-lp-daac-ndvi':
      case 'nasa-lp-daac-evi':
        return 9; // NASA LP DAAC Vegetation indices max zoom

      // ESA Sentinel layers native zoom levels
      case 'esa-sentinel-2-cloudless':
      case 'esa-sentinel-2-true-color':
        return 14; // ESA Sentinel-2 high resolution
      case 'esa-sentinel-1-sar':
        return 12; // ESA Sentinel-1 SAR moderate zoom

      case 'usgs-satellite':
        return 16; // USGS has good resolution but limited zoom
      case 'usgs-glovis-landsat':
        return 18; // USGS GloVis Landsat high resolution
      case 'usgs-imagery-topo':
        return 16; // USGS Imagery Topo standard zoom

      // JAXA layers native zoom levels
      case 'jaxa-alos-palsar':
        return 15; // JAXA ALOS PALSAR moderate zoom
      case 'jaxa-gcom-amsr2':
        return 12; // JAXA GCOM AMSR2 moderate zoom
      case 'sentinel-hub':
        return 17; // OpenTopoMap maximum zoom level
      case 'stamen-terrain':
        return 18; // Stamen Terrain standard zoom
      case 'google-satellite':
        return 18; // OpenAerialMap standard zoom
      case 'bing-satellite':
        return 19; // Bing Satellite high zoom
      case 'mapbox-satellite':
        return 18; // OSM France standard zoom
      default:
        return 18; // Standard zoom for map layers
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Left Sidebar
          Container(
            width: 300,
            color: Theme.of(context).colorScheme.surface,
            child: Column(
              children: [
                // Asset List with Search
                Expanded(
                  child: AssetSidebarWithSearch(
                    assets: _filteredAssets,
                    onAssetTap: _onAssetTap,
                    selectedAsset: _selectedAsset,
                    sites: DataService.sites,
                    units: _unitsForType(_selectedEquipmentType),
                    selectedSite: _selectedSite,
                    selectedEquipmentType: _selectedEquipmentType,
                    selectedUnit: _selectedUnit,
                    selectedStatus: _selectedStatus,
                    onSiteChanged: (value) {
                      setState(() => _selectedSite = value);
                      _applyFilters();
                    },
                    onEquipmentTypeChanged: (value) {
                      setState(() {
                        _selectedEquipmentType = value;
                        // Reset unit if it no longer belongs to the selected type
                        final units = _unitsForType(value);
                        if (_selectedUnit != null &&
                            !units.contains(_selectedUnit)) {
                          _selectedUnit = null;
                        }
                      });
                      _applyFilters();
                    },
                    onUnitChanged: (value) {
                      setState(() => _selectedUnit = value);
                      _applyFilters();
                    },
                    onStatusChanged: (value) {
                      setState(() => _selectedStatus = value);
                      _applyFilters();
                    },
                  ),
                ),
              ],
            ),
          ),
          // Main Map Area
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final availableHeight = constraints.maxHeight;
                final rawDetailHeight =
                    (_selectedAsset != null &&
                            (_showTaskHistory || _showTracking))
                        ? availableHeight * _detailPanelHeightFactor
                        : 0;
                final clampedDetailHeight =
                    rawDetailHeight.clamp(240.0, 420.0).toDouble();
                final showDetailPanel =
                    _selectedAsset != null &&
                    (_showTaskHistory || _showTracking);

                return Column(
                  children: [
                    // Map
                    Expanded(
                      child: SizedBox(
                        height:
                            showDetailPanel
                                ? math.max<double>(
                                  0,
                                  availableHeight - clampedDetailHeight,
                                )
                                : availableHeight,
                        child: Stack(
                          children: [
                            FlutterMap(
                              mapController: _mapController,
                              options: MapOptions(
                                initialCameraFit: CameraFit.bounds(
                                  bounds: _tiffBounds ?? _fallbackBounds,
                                ),
                                minZoom: 5.0,
                                maxZoom: 18.0,
                                onMapReady: () {
                                  if (_tiffBounds != null) {
                                    _mapController.fitCamera(
                                      CameraFit.bounds(bounds: _tiffBounds!),
                                    );
                                  }
                                },
                              ),
                              children: [
                                // Hilangkan semua tile base layer saat GeoTIFF menjadi dasar peta
                                if (_currentMapLayer != 'geotiff-base' &&
                                    _getTileUrl().isNotEmpty)
                                  TileLayer(
                                    urlTemplate: _getTileUrl(),
                                    userAgentPackageName:
                                        'com.example.mosa_maps_web',
                                    errorTileCallback: (
                                      tile,
                                      error,
                                      stackTrace,
                                    ) {
                                      debugPrint('Tile loading error: $error');
                                      debugPrint(
                                        'Failed to load tile for layer: $_currentMapLayer',
                                      );
                                    },
                                    maxNativeZoom: _getMaxNativeZoom(),
                                    maxZoom: _getMaxZoom(),
                                  ),
                                if (_tiffPngBytes != null &&
                                    _tiffBounds != null)
                                  AnimatedOpacity(
                                    duration: const Duration(milliseconds: 500),
                                    curve: Curves.easeInOut,
                                    opacity: _tiffOpacity,
                                    child: OverlayImageLayer(
                                      overlayImages: [
                                        OverlayImage(
                                          bounds: _tiffBounds!,
                                          opacity:
                                              _currentMapLayer == 'geotiff-base'
                                                  ? 1.0
                                                  : 0.9,
                                          imageProvider: MemoryImage(
                                            _tiffPngBytes!,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                // Layer Sarijadi digambar dari bawah ke atas:
                                // grid box (terluas) -> area -> block strip (terkecil).
                                // Grid box memakai fill transparan supaya citra
                                // peta di bawahnya tetap terlihat.
                                if (_showSarijadiBlockPolygons &&
                                    _sarijadiBlockPolygons.isNotEmpty)
                                  PolygonLayer(
                                    polygonLabels: _showSarijadiLabels,
                                    drawLabelsLast: false,
                                    polygons: _sarijadiBlockPolygons
                                        .map(
                                          (p) => Polygon<Object>(
                                            points: p.points,
                                            color: Colors.transparent,
                                            borderColor: p.strokeColor,
                                            borderStrokeWidth:
                                                p.strokeWidth + 1,
                                            label: _showSarijadiLabels
                                                ? p.name
                                                : null,
                                            labelStyle: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                              shadows: [
                                                Shadow(
                                                  color: Color(
                                                    0xCC000000,
                                                  ),
                                                  blurRadius: 3,
                                                  offset: Offset.zero,
                                                ),
                                              ],
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  ),
                                // Sarijadi_Area polygons layer
                                if (_showSarijadiAreaPolygons &&
                                    _sarijadiAreaPolygons.isNotEmpty)
                                  PolygonLayer(
                                    polygonLabels: _showSarijadiLabels,
                                    drawLabelsLast: false,
                                    polygons: _sarijadiAreaPolygons
                                        .map(_buildSarijadiPolygon)
                                        .toList(),
                                  ),
                                // Sarijadi_Blocks_Strips polygons layer
                                if (_showBlockStripPolygons &&
                                    _blockStripPolygons.isNotEmpty)
                                  PolygonLayer(
                                    polygonLabels: _showSarijadiLabels,
                                    drawLabelsLast: true,
                                    polygons: _blockStripPolygons
                                        .map(_buildSarijadiPolygon)
                                        .toList(),
                                  ),
                                // Berau_3_Track polylines layer
                                if (_showTrackPolylines &&
                                    _trackPolylines.isNotEmpty)
                                  PolylineLayer(
                                    polylines:
                                        _trackPolylines
                                            .map(
                                              (points) => Polyline(
                                                points: points,
                                                color: Colors.red,
                                                strokeWidth: 4,
                                              ),
                                            )
                                            .toList(),
                                  ),
                                // Sarijadi_Points: titik sudut tiap area + titik PIT.
                                if (_showSarijadiPoints &&
                                    _sarijadiPoints.isNotEmpty)
                                  MarkerLayer(
                                    markers:
                                        _sarijadiPoints
                                            .where(
                                              (p) =>
                                                  _showCornerPoints ||
                                                  p.group != 'corner',
                                            )
                                            .map(_buildSarijadiPointMarker)
                                            .toList(),
                                  ),
                                // Berau_3_Point markers layer
                                if (_showPointMarkers) ...[
                                  if (_showLetterPoints &&
                                      _letterPointMarkers.isNotEmpty)
                                    MarkerLayer(
                                      markers:
                                          _letterPointMarkers.where((m) {
                                            final name =
                                                ((m.child as Column).children[0]
                                                                as Flexible)
                                                            .child
                                                        is Container
                                                    ? (((m.child as Column).children[0]
                                                                            as Flexible)
                                                                        .child
                                                                    as Container)
                                                                .child
                                                            is Text
                                                        ? (((m.child as Column).children[0]
                                                                            as Flexible)
                                                                        .child
                                                                    as Container)
                                                                .child
                                                            as Text
                                                        : null
                                                    : null;
                                            return _visiblePointNames.contains(
                                              name?.data ?? '',
                                            );
                                          }).toList(),
                                    ),
                                  if (_showPitPoints &&
                                      _pitPointMarkers.isNotEmpty)
                                    MarkerLayer(
                                      markers:
                                          _pitPointMarkers.where((m) {
                                            final name =
                                                ((m.child as Column).children[0]
                                                                as Flexible)
                                                            .child
                                                        is Container
                                                    ? (((m.child as Column).children[0]
                                                                            as Flexible)
                                                                        .child
                                                                    as Container)
                                                                .child
                                                            is Text
                                                        ? (((m.child as Column).children[0]
                                                                            as Flexible)
                                                                        .child
                                                                    as Container)
                                                                .child
                                                            as Text
                                                        : null
                                                    : null;
                                            return _visiblePointNames.contains(
                                              name?.data ?? '',
                                            );
                                          }).toList(),
                                    ),
                                ],
                                if (_showTracking)
                                  PolylineLayer(
                                    polylines: _buildTrackingPolylines(
                                      points: _trackingData,
                                    ),
                                  ),
                                MarkerLayer(
                                  markers:
                                      (_showTracking && _selectedAsset != null
                                              ? [_selectedAsset!]
                                              : _filteredAssets)
                                          .where(
                                            (asset) => _visibleStatuses
                                                .contains(asset.status),
                                          )
                                          .map(
                                            (asset) => Marker(
                                              point: asset.position,
                                              child: GestureDetector(
                                                onTap: () => _onAssetTap(asset),
                                                child: Container(
                                                  width: 34,
                                                  height: 34,
                                                  padding: const EdgeInsets.all(
                                                    3,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        Theme.of(
                                                          context,
                                                        ).colorScheme.surface,
                                                    shape: BoxShape.circle,
                                                    border: Border.all(
                                                      color: _getStatusColor(
                                                        asset.status,
                                                      ),
                                                      width: 2,
                                                    ),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.black
                                                            .withOpacity(0.15),
                                                        blurRadius: 3,
                                                        offset: const Offset(
                                                          0,
                                                          1,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  child: _buildAssetIcon(asset),
                                                ),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                ),
                                if (_showTracking)
                                  MarkerLayer(markers: _buildTrackingMarkers()),
                              ],
                            ),
                            if (_currentMapLayer == 'geotiff-base' &&
                                _isTiffLoading)
                              // Overlay loading indicator saat GeoTIFF jadi base
                              Positioned.fill(
                                child: Container(
                                  color: Colors.black.withOpacity(0.2),
                                  child: const Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        CircularProgressIndicator(),
                                        SizedBox(height: 8),
                                        Text(
                                          'Memuat GeoTIFF…',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            // DateTime + Theme Toggle
                            Positioned(
                              top: 16,
                              right: 16,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                constraints: const BoxConstraints(
                                  maxWidth: 380,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surface,
                                  borderRadius: BorderRadius.circular(6),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.12),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                  border: Border.all(
                                    color:
                                        Theme.of(
                                          context,
                                        ).colorScheme.outlineVariant,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      size: 14,
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      DateFormat(
                                        'EEEE, dd MMMM yyyy • HH:mm:ss',
                                      ).format(_currentTime),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.onSurface,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // Theme toggle button
                                    Tooltip(
                                      message: 'Toggle Theme',
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(4),
                                        onTap: widget.onToggleTheme,
                                        child: Padding(
                                          padding: const EdgeInsets.all(4.0),
                                          child: Icon(
                                            Theme.of(context).brightness ==
                                                    Brightness.dark
                                                ? Icons.wb_sunny_outlined
                                                : Icons.nightlight_round,
                                            size: 16,
                                            color:
                                                Theme.of(
                                                  context,
                                                ).colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Right Side Controls Container
                            Positioned(
                              top: 70,
                              right: 16,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxHeight:
                                      MediaQuery.of(context).size.height -
                                      120, // Increased space
                                  maxWidth: 300,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Legend Control
                                    LegendControl(
                                      visibleStatuses: _visibleStatuses,
                                      onStatusToggle: (status, visible) {
                                        setState(() {
                                          if (visible) {
                                            _visibleStatuses.add(status);
                                          } else {
                                            _visibleStatuses.remove(status);
                                          }
                                        });
                                      },
                                      getStatusColor: _getStatusColor,
                                    ),
                                    const SizedBox(height: 8),
                                    // Layer Control
                                    LayerControl(
                                      currentLayer: _currentMapLayer,
                                      onLayerChanged: (layer) {
                                        setState(
                                          () => _currentMapLayer = layer,
                                        );
                                      },
                                      nasaDate: _nasaDate,
                                      onNasaDateChanged: (date) {
                                        setState(() => _nasaDate = date);
                                      },
                                      showBlockStrip: _showBlockStripPolygons,
                                      onShowBlockStripChanged:
                                          (v) => setState(
                                            () => _showBlockStripPolygons = v,
                                          ),
                                      showTrack: _showTrackPolylines,
                                      onShowTrackChanged:
                                          (v) => setState(
                                            () => _showTrackPolylines = v,
                                          ),
                                      showPoint: _showPointMarkers,
                                      onShowPointChanged:
                                          (v) => setState(
                                            () => _showPointMarkers = v,
                                          ),
                                      showLetterPoints: _showLetterPoints,
                                      onShowLetterPointsChanged:
                                          (v) => setState(
                                            () => _showLetterPoints = v,
                                          ),
                                      showPitPoints: _showPitPoints,
                                      onShowPitPointsChanged:
                                          (v) => setState(
                                            () => _showPitPoints = v,
                                          ),
                                      showSarijadiBlocks: _showSarijadiBlockPolygons,
                                      onShowSarijadiBlocksChanged:
                                          (v) => setState(
                                            () =>
                                                _showSarijadiBlockPolygons = v,
                                          ),
                                      showSarijadiArea: _showSarijadiAreaPolygons,
                                      onShowSarijadiAreaChanged:
                                          (v) => setState(
                                            () =>
                                                _showSarijadiAreaPolygons = v,
                                          ),
                                      showSarijadiPoints: _showSarijadiPoints,
                                      onShowSarijadiPointsChanged:
                                          (v) => setState(
                                            () => _showSarijadiPoints = v,
                                          ),
                                      showCornerPoints: _showCornerPoints,
                                      onShowCornerPointsChanged:
                                          (v) => setState(
                                            () => _showCornerPoints = v,
                                          ),
                                      showSarijadiLabels: _showSarijadiLabels,
                                      onShowSarijadiLabelsChanged:
                                          (v) => setState(
                                            () => _showSarijadiLabels = v,
                                          ),
                                      allPointNames: _allPointNames,
                                      visiblePointNames: _visiblePointNames,
                                      onPointVisibilityChanged: (
                                        name,
                                        visible,
                                      ) {
                                        setState(() {
                                          if (visible) {
                                            _visiblePointNames.add(name);
                                          } else {
                                            _visiblePointNames.remove(name);
                                          }
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Bottom Controls Container
                            Positioned(
                              bottom: 8,
                              left: 8,
                              right: 16,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  // Map Attribution
                                  Flexible(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .surface
                                            .withValues(alpha: 0.9),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                      child: Text(
                                        _getTileAttribution(),
                                        style: TextStyle(
                                          fontSize: 10,
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.onSurfaceVariant,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 2,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  // Map Controls
                                  MapControls(
                                    mapController: _mapController,
                                    onResetView: _resetMapView,
                                    onRecenter: _recenterMap,
                                  ),
                                ],
                              ),
                            ),
                            // Asset Popup
                            if (_selectedAsset != null &&
                                _popupPosition != null)
                              Positioned(
                                top: _popupPosition!.dy,
                                left: _popupPosition!.dx,
                                child: AssetPopup(
                                  asset: _selectedAsset!,
                                  onViewDetail: _onViewDetail,
                                  onTrack: _onTrackAsset,
                                  onClose: _closeAssetPopup,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    // Detail Panels (Task History / Tracking)
                    if (showDetailPanel) ...[
                      GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onVerticalDragUpdate: (details) {
                          setState(() {
                            // Adjust the height factor based on drag delta
                            _detailPanelHeightFactor =
                                (_detailPanelHeightFactor -
                                        details.delta.dy / availableHeight)
                                    .clamp(0.2, 0.8);
                          });
                        },
                        child: Container(
                          height: 8,
                          color: Colors.grey[300],
                          child: Center(
                            child: Container(
                              width: 40,
                              height: 4,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: clampedDetailHeight,
                        child:
                            _showTracking
                                ? AssetTrackingTable(
                                  asset: _selectedAsset!,
                                  onClose:
                                      () =>
                                          setState(() => _showTracking = false),
                                  onFilteredPointsChanged:
                                      _handleFilteredTrackingPoints,
                                )
                                : TaskHistoryTable(
                                  asset: _selectedAsset!,
                                  onClose:
                                      () => setState(
                                        () => _showTaskHistory = false,
                                      ),
                                ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
