// Icon generator for WhatIsThisNote.
//
// Everything lives under design/icon/ (vector sources + this generator).
// It renders PNGs straight from vector paths with dart:ui (so no external
// tools are needed) and writes the platform assets plus the vector sources.
//
// Regenerate after editing the geometry below:
//
//   cd whatisthisnote
//   flutter test ../design/icon/generate_icons_test.dart
//
// Outputs:
//   design/icon/icon.svg                     master (square, opaque)
//   design/icon/icon-rounded.svg             rounded corners (favicon/legacy)
//   design/icon/icon-maskable.svg            safe-zone version for PWA maskable
//   design/icon/icon-foreground.svg          adaptive-foreground reference
//   design/icon/icon-monochrome.svg          monochrome reference
//   design/icon/preview.png                  256px preview
//   whatisthisnote/ios/Runner/Assets.xcassets/AppIcon.appiconset/*.png
//   whatisthisnote/android/app/src/main/res/mipmap-*/ic_launcher[_round].png
//   whatisthisnote/android/app/src/main/res/drawable/ic_launcher_*.xml
//   whatisthisnote/android/app/src/main/res/mipmap-anydpi-v26/ic_launcher*.xml
//   whatisthisnote/android/app/src/main/res/values/ic_launcher_background.xml
//   whatisthisnote/web/favicon.png
//   whatisthisnote/web/icons/*.png
//   whatisthisnote/windows/runner/resources/app_icon.ico
//   whatisthisnote/macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_*.png
//   whatisthisnote/linux/runner/resources/app_icon.png
library;

import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Design tokens
// ---------------------------------------------------------------------------

const ui.Color _background = ui.Color(0xFFFFFFFF); // white tile
const ui.Color _staff = ui.Color(0xFFD0D5DD); // faint grey lines
const ui.Color _note = ui.Color(0xFF242428); // soft near-black note
const String _backgroundHex = '#FFFFFF';
const String _staffHex = '#D0D5DD';
const String _noteHex = '#242428';

// Artwork geometry in a local 100 x 100 box: a faint five-line staff with a
// single soft-black quarter note centred on the middle line.
const double _staffX0 = 6;
const double _staffX1 = 94;
const double _staffWidth = 2.4;
const List<double> _staffYs = [36, 45, 54, 63, 72];
const double _noteCX = 50;
const double _noteCY = 54; // middle line
const double _rx = 8.6;
const double _ry = 6.3;
const double _rot = -20;
const double _stemX = 57.3;
const double _stemTop = 23;
const double _stemWidth = 2.8;

const double _safeScale = 0.66; // adaptive / maskable safe zone
const double _plainScale = 0.80; // iOS / web / legacy

void main() {
  test('generate app icons', () async {
    final appDir = Directory.current;
    _expectAppDir(appDir);
    final repoRoot = appDir.parent;
    final designDir = Directory(
        '${repoRoot.path}${Platform.pathSeparator}design'
        '${Platform.pathSeparator}icon');
    designDir.createSync(recursive: true);

    await _writeVectors(designDir);
    await _writeIos(appDir);
    await _writeAndroid(appDir);
    await _writeWeb(appDir);
    await _writeWindows(appDir);
    await _writeMacos(appDir);
    await _writeLinux(appDir);

    await _writePng(
      '${designDir.path}${Platform.pathSeparator}preview.png',
      256,
      scale: _safeScale,
      radius: 0,
    );

    await _printPreview();
    // ignore: avoid_print
    print('Icons generated from ${appDir.path}');
  });
}

void _expectAppDir(Directory dir) {
  final hasPubspec =
      File('${dir.path}${Platform.pathSeparator}pubspec.yaml').existsSync();
  if (!hasPubspec || !Directory('${dir.path}${Platform.pathSeparator}android')
      .existsSync()) {
    throw StateError('Run from the whatisthisnote/ app directory '
        '(current: ${dir.path}).');
  }
}

// ---------------------------------------------------------------------------
// Rendering
// ---------------------------------------------------------------------------

Future<ui.Image> _render(
  int size, {
  required double scale,
  required double radius,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  final s = size.toDouble();

  final rect = ui.Rect.fromLTWH(0, 0, s, s);
  final paint = ui.Paint()..color = _background;
  if (radius > 0) {
    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(rect, ui.Radius.circular(s * radius)),
      paint,
    );
  } else {
    canvas.drawRect(rect, paint);
  }

  final unit = s * scale / 100.0;
  final offset = (s - 100.0 * unit) / 2.0;
  canvas.save();
  canvas.translate(offset, offset);
  canvas.scale(unit);
  _paintArt(canvas);
  canvas.restore();

  return recorder.endRecording().toImage(size, size);
}

void _paintArt(ui.Canvas canvas) {
  final staffPaint = ui.Paint()
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = _staffWidth
    ..strokeCap = ui.StrokeCap.round
    ..color = _staff;
  for (final y in _staffYs) {
    canvas.drawLine(ui.Offset(_staffX0, y), ui.Offset(_staffX1, y), staffPaint);
  }

  canvas.drawLine(
    ui.Offset(_stemX, _noteCY),
    ui.Offset(_stemX, _stemTop),
    ui.Paint()
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = _stemWidth
      ..strokeCap = ui.StrokeCap.round
      ..color = _note,
  );

  canvas.drawPath(_notePath(), ui.Paint()..color = _note);
}

ui.Path _notePath() {
  final p = _ellipsePoints(_noteCX, _noteCY, _rx, _ry, _rot);
  return ui.Path()
    ..moveTo(p[0].dx, p[0].dy)
    ..cubicTo(p[1].dx, p[1].dy, p[2].dx, p[2].dy, p[3].dx, p[3].dy)
    ..cubicTo(p[4].dx, p[4].dy, p[5].dx, p[5].dy, p[6].dx, p[6].dy)
    ..cubicTo(p[7].dx, p[7].dy, p[8].dx, p[8].dy, p[9].dx, p[9].dy)
    ..cubicTo(p[10].dx, p[10].dy, p[11].dx, p[11].dy, p[0].dx, p[0].dy)
    ..close();
}

/// Cubic-bezier approximation of a rotated ellipse.
/// Order: P0 C1 C2 P1 C3 C4 P2 C5 C6 P3 C7 C8.
List<ui.Offset> _ellipsePoints(
    double cx, double cy, double rx, double ry, double deg) {
  const k = 0.5522847498307936;
  final rad = deg * math.pi / 180.0;
  final ca = math.cos(rad);
  final sa = math.sin(rad);
  ui.Offset at(double dx, double dy) => ui.Offset(
        cx + dx * ca - dy * sa,
        cy + dx * sa + dy * ca,
      );
  return [
    at(rx, 0),
    at(rx, -k * ry),
    at(k * rx, -ry),
    at(0, -ry),
    at(-k * rx, -ry),
    at(-rx, -k * ry),
    at(-rx, 0),
    at(-rx, k * ry),
    at(-k * rx, ry),
    at(0, ry),
    at(k * rx, ry),
    at(rx, k * ry),
  ];
}

// ---------------------------------------------------------------------------
// File output
// ---------------------------------------------------------------------------

Future<void> _writePng(
  String path,
  int size, {
  required double scale,
  required double radius,
}) async {
  final image = await _render(
    size,
    scale: scale,
    radius: radius,
  );
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  final file = File(path);
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(data!.buffer.asUint8List());
}

Future<void> _writeIos(Directory appDir) async {
  final dir = Directory('${appDir.path}${Platform.pathSeparator}ios'
      '${Platform.pathSeparator}Runner${Platform.pathSeparator}Assets.xcassets'
      '${Platform.pathSeparator}AppIcon.appiconset');
  const icons = {
    'Icon-App-20x20@1x.png': 20,
    'Icon-App-20x20@2x.png': 40,
    'Icon-App-20x20@3x.png': 60,
    'Icon-App-29x29@1x.png': 29,
    'Icon-App-29x29@2x.png': 58,
    'Icon-App-29x29@3x.png': 87,
    'Icon-App-40x40@1x.png': 40,
    'Icon-App-40x40@2x.png': 80,
    'Icon-App-40x40@3x.png': 120,
    'Icon-App-60x60@2x.png': 120,
    'Icon-App-60x60@3x.png': 180,
    'Icon-App-76x76@1x.png': 76,
    'Icon-App-76x76@2x.png': 152,
    'Icon-App-83.5x83.5@2x.png': 167,
    'Icon-App-1024x1024@1x.png': 1024,
  };
  for (final entry in icons.entries) {
    await _writePng(
      '${dir.path}${Platform.pathSeparator}${entry.key}',
      entry.value,
      scale: _plainScale,
      radius: 0,
    );
  }
}

Future<void> _writeAndroid(Directory appDir) async {
  final res = '${appDir.path}${Platform.pathSeparator}android'
      '${Platform.pathSeparator}app${Platform.pathSeparator}src'
      '${Platform.pathSeparator}main${Platform.pathSeparator}res';

  const legacy = {
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192,
  };
  for (final entry in legacy.entries) {
    final base = '$res${Platform.pathSeparator}${entry.key}';
    await _writePng('$base${Platform.pathSeparator}ic_launcher.png', entry.value,
        scale: _plainScale, radius: 0.223);
    await _writePng(
        '$base${Platform.pathSeparator}ic_launcher_round.png',
        entry.value,
        scale: _plainScale,
        radius: 0.5);
  }

  File('$res${Platform.pathSeparator}drawable'
          '${Platform.pathSeparator}ic_launcher_foreground.xml')
      .writeAsStringSync(_inkVector(monochrome: false));
  File('$res${Platform.pathSeparator}drawable'
          '${Platform.pathSeparator}ic_launcher_monochrome.xml')
      .writeAsStringSync(_inkVector(monochrome: true));
  File('$res${Platform.pathSeparator}values'
          '${Platform.pathSeparator}ic_launcher_background.xml')
      .writeAsStringSync(
          '<resources>\n'
          '    <color name="ic_launcher_background">$_backgroundHex</color>\n'
          '</resources>\n');

  final anydpi =
      Directory('$res${Platform.pathSeparator}mipmap-anydpi-v26');
  anydpi.createSync(recursive: true);
  final adaptive = '<?xml version="1.0" encoding="utf-8"?>\n'
      '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
      '    <background android:drawable="@color/ic_launcher_background"/>\n'
      '    <foreground android:drawable="@drawable/ic_launcher_foreground"/>\n'
      '    <monochrome android:drawable="@drawable/ic_launcher_monochrome"/>\n'
      '</adaptive-icon>\n';
  File('${anydpi.path}${Platform.pathSeparator}ic_launcher.xml')
      .writeAsStringSync(adaptive);
  File('${anydpi.path}${Platform.pathSeparator}ic_launcher_round.xml')
      .writeAsStringSync(adaptive);
}

Future<void> _writeWeb(Directory appDir) async {
  final web = appDir.path + Platform.pathSeparator + 'web';
  final icons = web + Platform.pathSeparator + 'icons';

  await _writePng('$web${Platform.pathSeparator}favicon.png', 48,
      scale: _plainScale, radius: 0.223);
  await _writePng('$icons${Platform.pathSeparator}Icon-192.png', 192,
      scale: _plainScale, radius: 0.223);
  await _writePng('$icons${Platform.pathSeparator}Icon-512.png', 512,
      scale: _plainScale, radius: 0.223);
  await _writePng('$icons${Platform.pathSeparator}apple-touch-icon.png', 180,
      scale: _plainScale, radius: 0);
  await _writePng('$icons${Platform.pathSeparator}Icon-maskable-192.png', 192,
      scale: _safeScale, radius: 0);
  await _writePng('$icons${Platform.pathSeparator}Icon-maskable-512.png', 512,
      scale: _safeScale, radius: 0);
}

Future<void> _writeWindows(Directory appDir) async {
  const sizes = [16, 32, 48, 64, 128, 256];
  final pngs = <int, List<int>>{};
  for (final size in sizes) {
    final image = await _render(
      size,
      scale: _plainScale,
      radius: 0.223,
    );
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    pngs[size] = data!.buffer.asUint8List();
  }

  final bytes = <int>[
    ..._u16(0), // reserved
    ..._u16(1), // type: icon
    ..._u16(pngs.length),
  ];
  var offset = 6 + pngs.length * 16;
  final imageData = <int>[];
  for (final entry in pngs.entries) {
    final size = entry.key;
    bytes.addAll([
      size >= 256 ? 0 : size, // width
      size >= 256 ? 0 : size, // height
      0, // color count
      0, // reserved
      ..._u16(1), // color planes
      ..._u16(32), // bits per pixel
      ..._u32(entry.value.length),
      ..._u32(offset),
    ]);
    imageData.addAll(entry.value);
    offset += entry.value.length;
  }
  bytes.addAll(imageData);

  final file = File('${appDir.path}${Platform.pathSeparator}windows'
      '${Platform.pathSeparator}runner${Platform.pathSeparator}resources'
      '${Platform.pathSeparator}app_icon.ico');
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(bytes);
}

List<int> _u16(int value) => [value & 0xFF, (value >> 8) & 0xFF];

List<int> _u32(int value) => [
      value & 0xFF,
      (value >> 8) & 0xFF,
      (value >> 16) & 0xFF,
      (value >> 24) & 0xFF,
    ];

Future<void> _writeMacos(Directory appDir) async {
  final dir = '${appDir.path}${Platform.pathSeparator}macos'
      '${Platform.pathSeparator}Runner${Platform.pathSeparator}Assets.xcassets'
      '${Platform.pathSeparator}AppIcon.appiconset';
  const icons = {
    'app_icon_16.png': 16,
    'app_icon_32.png': 32,
    'app_icon_64.png': 64,
    'app_icon_128.png': 128,
    'app_icon_256.png': 256,
    'app_icon_512.png': 512,
    'app_icon_1024.png': 1024,
  };
  for (final entry in icons.entries) {
    await _writePng(
      '${dir}${Platform.pathSeparator}${entry.key}',
      entry.value,
      scale: _plainScale,
      radius: 0.223,
    );
  }
}

Future<void> _writeLinux(Directory appDir) async {
  final dir = '${appDir.path}${Platform.pathSeparator}linux'
      '${Platform.pathSeparator}runner${Platform.pathSeparator}resources';
  await _writePng(
    '${dir}${Platform.pathSeparator}app_icon.png',
    256,
    scale: _plainScale,
    radius: 0.223,
  );
}

Future<void> _writeVectors(Directory dir) async {
  final sep = Platform.pathSeparator;
  const size = 1024.0;
  const rad = 0.223;

  File('${dir.path}${sep}icon.svg').writeAsStringSync(
      _svg(size, scale: _plainScale, radius: 0));
  File('${dir.path}${sep}icon-rounded.svg').writeAsStringSync(
      _svg(size, scale: _plainScale, radius: rad));
  File('${dir.path}${sep}icon-maskable.svg').writeAsStringSync(
      _svg(size, scale: _safeScale, radius: 0));
  File('${dir.path}${sep}icon-foreground.svg').writeAsStringSync(
      _svg(108, scale: _safeScale, radius: 0, transparent: true));
  File('${dir.path}${sep}icon-monochrome.svg').writeAsStringSync(
      _svg(108, scale: _safeScale, radius: 0, transparent: true));
}

// ---------------------------------------------------------------------------
// Vector text
// ---------------------------------------------------------------------------

String _svg(
  double size, {
  required double scale,
  required double radius,
  bool transparent = false,
}) {
  final unit = size * scale / 100.0;
  final offset = (size - 100.0 * unit) / 2.0;
  final b = StringBuffer()
    ..writeln('<svg xmlns="http://www.w3.org/2000/svg" '
        'width="${_n(size)}" height="${_n(size)}" '
        'viewBox="0 0 ${_n(size)} ${_n(size)}">');
  if (!transparent) {
    final r = radius > 0 ? ' rx="${_n(size * radius)}"' : '';
    b.writeln('  <rect width="${_n(size)}" height="${_n(size)}"$r '
        'fill="$_backgroundHex"/>');
  }
  b.writeln('  <g transform="translate(${_n(offset)},${_n(offset)}) '
      'scale(${_n(unit)})">');
  b.write(_svgArt());
  b.writeln('  </g>');
  b.writeln('</svg>');
  return b.toString();
}

String _svgArt() {
  final b = StringBuffer();
  b.writeln('    <path d="${_staffPathData()}" fill="none" '
      'stroke="$_staffHex" stroke-width="${_n(_staffWidth)}" '
      'stroke-linecap="round"/>');
  b.writeln('    <path d="M${_n(_stemX)} ${_n(_noteCY)}V${_n(_stemTop)}" '
      'fill="none" stroke="$_noteHex" stroke-width="${_n(_stemWidth)}" '
      'stroke-linecap="round"/>');
  b.writeln('    <path d="${_ellipsePathData(_noteCX, _noteCY)}" '
      'fill="$_noteHex"/>');
  return b.toString();
}

String _inkVector({required bool monochrome}) {
  final staffD = _staffPathData();
  // A monochrome (themed) drawable must use one tint color; Android keeps the
  // alpha channel and recolors it to the user's Material You palette. The
  // staff keeps its lighter look through alpha instead of a second color.
  final staff = monochrome ? '#66000000' : '#FFD0D5DD';
  final note = monochrome ? '#FF000000' : _noteHex;
  return '<?xml version="1.0" encoding="utf-8"?>\n'
      '<vector xmlns:android="http://schemas.android.com/apk/res/android"\n'
      '    android:width="108dp" android:height="108dp"\n'
      '    android:viewportWidth="108" android:viewportHeight="108">\n'
      '    <group android:scaleX="$_safeScale" android:scaleY="$_safeScale"\n'
      '        android:translateX="${_n((108 - 100 * _safeScale) / 2)}" '
      'android:translateY="${_n((108 - 100 * _safeScale) / 2)}">\n'
      '        <path android:strokeColor="$staff" '
      'android:strokeWidth="${_n(_staffWidth)}" '
      'android:strokeLineCap="round" android:pathData="$staffD"/>\n'
      '        <path android:strokeColor="$note" '
      'android:strokeWidth="${_n(_stemWidth)}" '
      'android:strokeLineCap="round" '
      'android:pathData="M${_n(_stemX)} ${_n(_noteCY)}V${_n(_stemTop)}"/>\n'
      '        <path android:fillColor="$note" '
      'android:pathData="${_ellipsePathData(_noteCX, _noteCY)}"/>\n'
      '    </group>\n'
      '</vector>\n';
}

String _ellipsePathData(double cx, double cy) {
  final p = _ellipsePoints(cx, cy, _rx, _ry, _rot);
  return 'M${_pt(p[0])}C${_pt(p[1])} ${_pt(p[2])} ${_pt(p[3])}'
      'C${_pt(p[4])} ${_pt(p[5])} ${_pt(p[6])}'
      'C${_pt(p[7])} ${_pt(p[8])} ${_pt(p[9])}'
      'C${_pt(p[10])} ${_pt(p[11])} ${_pt(p[0])}Z';
}

String _pt(ui.Offset p) => '${_n(p.dx)} ${_n(p.dy)}';

String _staffPathData() => _staffYs
    .map((y) => 'M${_n(_staffX0)} ${_n(y)}H${_n(_staffX1)}')
    .join();

String _n(double v) {
  var s = v.toStringAsFixed(2);
  if (s.contains('.')) {
    s = s.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  }
  return s;
}

// ---------------------------------------------------------------------------
// Preview
// ---------------------------------------------------------------------------

Future<void> _printPreview() async {
  const pixels = 96;
  const cols = 48;
  final image = await _render(
    pixels,
    scale: _plainScale,
    radius: 0.223,
  );
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final bytes = data!.buffer.asUint8List();
  final rows = cols ~/ 2;
  final blockX = pixels / cols;
  final blockY = pixels / rows;
  const ramp = '@%#*+=-:. ';
  final buffer = StringBuffer();
  for (var row = 0; row < rows; row++) {
    for (var col = 0; col < cols; col++) {
      var r = 0.0, g = 0.0, b = 0.0;
      var count = 0;
      for (var y = 0; y < blockY; y++) {
        for (var x = 0; x < blockX; x++) {
          final px = (col * blockX + x).floor();
          final py = (row * blockY + y).floor();
          final i = (py * pixels + px) * 4;
          r += bytes[i];
          g += bytes[i + 1];
          b += bytes[i + 2];
          count++;
        }
      }
      final lum = (0.299 * r + 0.587 * g + 0.114 * b) / (count * 255);
      final index = (lum * (ramp.length - 1)).round().clamp(0, ramp.length - 1);
      buffer.write(ramp[index]);
    }
    buffer.writeln();
  }
  // ignore: avoid_print
  print('\npreview:\n$buffer');
}
