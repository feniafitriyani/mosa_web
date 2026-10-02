import 'dart:io';

/// Geser seluruh koordinat `LatLng(...)` di
/// `lib/services/data_service.dart` ke dalam area Sarijadi
/// (`assets/maps/Sarijadi_Bounds.json`).
///
/// Memakai transformasi affine seragam: center -> center, lalu skalakan
/// agar sebaran data muat di dalam bounds Sarijadi dengan margin.
/// Karena skalanya seragam untuk lat maupun lng, relasi posisi antar aset
/// (mana yang di utara/timur dari mana) tetap terjaga.
///
/// Idempoten: koordinat yang sudah berada di area Sarijadi dilewati,
/// jadi tool aman dijalankan berulang kali dan tidak akan menggeser
/// koordinat dua kali.
///
/// Sebelum menulis, file divalidasi (jumlah `import`, deklarasi `class`
/// dan `_assets`); bila gagal, file tidak disentuh sama sekali.
///
/// Pemakaian:  dart run tool/fix_coords.dart
void main(List<String> args) {
  const path = 'lib/services/data_service.dart';
  final file = File(path);
  if (!file.existsSync()) {
    stderr.writeln('File tidak ditemukan: $path');
    exit(1);
  }
  var source = file.readAsStringSync().replaceAll('\r\n', '\n');
  stdout.writeln('Membaca ${source.length} karakter dari $path.');

  // --- Validasi file sumber -------------------------------------------
  // `^` dengan multiLine di Dart hanya mengenali \n, jadi pastikan baris
  // baru sudah dinormalisasi lebih dulu (lihat baris di atas).
  final srcImports = RegExp(
    r'^import ',
    multiLine: true,
  ).allMatches(source).length;
  final srcClass = 'class DataService'.allMatches(source).length;
  final srcAssets = 'static final List<Asset> _assets'.allMatches(source).length;
  if (srcImports != 2 || srcClass != 1 || srcAssets != 1) {
    stderr.writeln(
      'File sumber tidak utuh: import=$srcImports (2), '
      'class=$srcClass (1), _assets=$srcAssets (1). Dilewati.',
    );
    exit(1);
  }

  // --- Langkah 2: geser koordinat ke area Sarijadi --------------------
  // Batas Sarijadi_Bounds.json: lat -6.8820..-6.8700, lng 107.568..107.580.
  const boundSouth = -6.882;
  const boundNorth = -6.870;
  const boundWest = 107.568;
  const boundEast = 107.580;
  const margin = 0.0012; // jangan menempel tepi bounds

  // Sumber: area Berau lama.
  const srcLat = 2.0857;
  const srcLng = 117.44925;

  // Tujuan: pusat area Sarijadi.
  const dstLat = -6.876;
  const dstLng = 107.574;

  // Izinkan pemformatan multi-baris (`LatLng(\n  lat,\n  lng,\n)`).
  // Whitescaping dibatasi supaya regex tidak ikut menelan baris kode lain.
  final pattern = RegExp(r'LatLng\(\s*(-?[\d.]+)[\s,]+(-?[\d.]+)\s*\)');
  final matches = pattern.allMatches(source).toList();
  if (matches.isEmpty) {
    stderr.writeln('Tidak ada koordinat LatLng.');
    exit(1);
  }

  final pending = <_Coord>[];
  final insideCoords = <_Coord>[];
  var inside = 0;
  for (final m in matches) {
    final lat = double.parse(m.group(1)!);
    final lng = double.parse(m.group(2)!);
    final isInside =
        lat >= boundSouth &&
        lat <= boundNorth &&
        lng >= boundWest &&
        lng <= boundEast;
    if (isInside) {
      inside++;
      insideCoords.add(_Coord(m.start, m.end, lat, lng));
    } else {
      pending.add(_Coord(m.start, m.end, lat, lng));
    }
  }
  stdout.writeln(
    '${matches.length} koordinat: $inside sudah di Sarijadi, '
    '${pending.length} digeser.',
  );

  if (pending.isNotEmpty) {
    var minLat = double.infinity, maxLat = -double.infinity;
    var minLng = double.infinity, maxLng = -double.infinity;
    for (final c in pending) {
      if (c.lat < minLat) minLat = c.lat;
      if (c.lat > maxLat) maxLat = c.lat;
      if (c.lng < minLng) minLng = c.lng;
      if (c.lng > maxLng) maxLng = c.lng;
    }

    final usableLat = boundNorth - boundSouth - margin * 2;
    final usableLng = boundEast - boundWest - margin * 2;
    final spanLat = (maxLat - minLat).abs();
    final spanLng = (maxLng - minLng).abs();
    final scale = <double>[
      if (spanLat > 0) usableLat / spanLat,
      if (spanLng > 0) usableLng / spanLng,
    ].reduce((a, b) => a < b ? a : b);
    stdout.writeln('Skala: ${scale.toStringAsFixed(6)}');

    // Semua koordinat ikut ditulis ulang; yang sudah di Sarijadi ditulis
    // apa adanya supaya baris kodenya tetap utuh.
    final replacements = <_Replacement>[];
    for (final c in pending) {
      final newLat = _round8(dstLat + (c.lat - srcLat) * scale);
      final newLng = _round8(dstLng + (c.lng - srcLng) * scale);
      replacements.add(
        _Replacement(c.start, c.end, 'LatLng($newLat, $newLng)'),
      );
    }
    for (final c in insideCoords) {
      replacements.add(
        _Replacement(c.start, c.end, 'LatLng(${c.lat}, ${c.lng})'),
      );
    }
    replacements.sort((a, b) => a.start.compareTo(b.start));

    // Tulis ulang dari depan ke belakang memakai offset geser, karena
    // [StringBuffer] menempel dalam urutan pemanggilan `write` (menulis
    // dari belakang akan menghasilkan teks yang terbalik).
    //
    // Dengan forward scan, `cursor` selalu maju, jadi tidak ada potongan
    // teks yang tertinggal maupun terbalik.
    final buffer = StringBuffer();
    var cursor = 0;
    for (final c in replacements) {
      buffer
        ..write(source.substring(cursor, c.start))
        ..write(c.text);
      cursor = c.end;
    }
    buffer.write(source.substring(cursor));
    source = buffer.toString();
  }

  // --- Validasi sebelum menulis ----------------------------------------
  // Kegagalan di titik ini berarti jangan sentuh file sama sekali.
  final importCount = RegExp(r'^import ', multiLine: true).allMatches(source).length;
  final classCount = 'class DataService'.allMatches(source).length;
  final assetsCount = 'static final List<Asset> _assets'.allMatches(source).length;
  if (importCount != 2 || classCount != 1 || assetsCount != 1) {
    stderr.writeln(
      'VALIDASI GAGAL: import=$importCount (2), class=$classCount (1), '
      '_assets=$assetsCount (1). File tidak ditulis.',
    );
    exit(1);
  }

  File('lib/services/data_service.dart').writeAsStringSync(source);
  stdout.writeln('Selesai. Validasi import/class lolos.');
}

class _Coord {
  final int start;
  final int end;
  final double lat;
  final double lng;
  _Coord(this.start, this.end, this.lat, this.lng);
}

/// Koordinat yang sudah punya nilai pengganti siap ditulis.
class _Replacement {
  final int start;
  final int end;
  final String text;
  _Replacement(this.start, this.end, this.text);
}

double _round8(double v) => (v * 100000000).roundToDouble() / 100000000;
