import 'dart:io';

/// Alat sekali pakai untuk memindahkan koordinat asset & tracking dari
/// area Berau lama ke area Sarijadi.
///
/// Memakai transformasi affine seragam: center -> center, lalu skalakan
/// supaya sebaran data muat di dalam bounds Sarijadi. Relasi posisi antar
/// aset (mana yang di utara/timur dari mana) tetap terjaga.
///
/// Jalankan dari root project:  dart run tool/shift_coords.dart
void main(List<String> args) {
  final file = File('lib/services/data_service.dart');
  if (!file.existsSync()) {
    stderr.writeln('File tidak ditemukan: ${file.path}');
    exit(1);
  }

  // Sumber: area Berau lama.
  const srcLat = 2.0857;
  const srcLng = 117.44925;

  // Tujuan: pusat area Sarijadi (lihat assets/maps/Sarijadi_Bounds.json).
  const dstLat = -6.876;
  const dstLng = 107.574;
  const scale = 0.24;

  var source = file.readAsStringSync();
  final pattern = RegExp(r'LatLng\(\s*(-?[\d.]+)\s*,\s*(-?[\d.]+)');
  final matches = pattern.allMatches(source).toList();

  if (matches.isEmpty) {
    stderr.writeln('Tidak ada koordinat LatLng yang ditemukan.');
    exit(1);
  }

  // Tulis ulang dari belakang supaya index tetap valid.
  final buffer = StringBuffer();
  var cursor = source.length;
  for (final match in matches.reversed) {
    final lat = double.parse(match.group(1)!);
    final lng = double.parse(match.group(2)!);
    final newLat = _round8(dstLat + (lat - srcLat) * scale);
    final newLng = _round8(dstLng + (lng - srcLng) * scale);
    buffer
      ..write(source.substring(match.end, cursor))
      ..write('LatLng($newLat, $newLng)');
    cursor = match.start;
  }
  buffer.write(source.substring(0, cursor));

  file.writeAsStringSync(buffer.toString());
  stdout.writeln('Mengganti ${matches.length} koordinat.');
}

double _round8(double v) {
  final factor = 100000000;
  return (v * factor).roundToDouble() / factor;
}
