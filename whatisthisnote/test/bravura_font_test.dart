import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whatisthisnote/core/clef.dart';

/// Renders a single music glyph at [baselineY] using the same placement logic
/// as `NotationPainter` and returns the vertical ink bounds.
Future<({int minY, int maxY})> _renderGlyph(
  String glyph,
  double fontSize,
  int baselineY,
) async {
  const int width = 400;
  const int height = 400;

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final painter = TextPainter(
    text: TextSpan(
      text: glyph,
      style: TextStyle(
        fontFamily: 'Bravura',
        fontSize: fontSize,
        color: const Color(0xFF000000),
        height: 1.0,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();

  final baselineOffset =
      painter.computeDistanceToActualBaseline(TextBaseline.alphabetic);
  painter.paint(canvas, Offset(150, baselineY - baselineOffset));

  final image = await recorder.endRecording().toImage(width, height);
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final bytes = data!.buffer.asUint8List();

  var minY = height;
  var maxY = -1;
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final alpha = bytes[(y * width + x) * 4 + 3];
      if (alpha > 20) {
        if (y < minY) minY = y;
        if (y > maxY) maxY = y;
      }
    }
  }
  return (minY: minY, maxY: maxY);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final loader = FontLoader('Bravura')
      ..addFont(rootBundle.load('assets/fonts/Bravura.otf'));
    await loader.load();
  });

  test('the C clef is vertically symmetric about its origin line', () async {
    const fontSize = 40.0;
    const baselineY = 200;
    final ink = await _renderGlyph(Clef.alto.glyph, fontSize, baselineY);

    final above = baselineY - ink.minY;
    final below = ink.maxY - baselineY;
    expect(above, greaterThan(0));
    expect((above - below).abs(), lessThan(6));
  });

  test('the G clef sits on its reference line (the G line)', () async {
    const fontSize = 40.0;
    const baselineY = 200;
    final ink = await _renderGlyph(Clef.treble.glyph, fontSize, baselineY);

    final above = baselineY - ink.minY;
    final below = ink.maxY - baselineY;
    // Bravura's gClef is much taller above the line than below it.
    expect(above / below, greaterThan(1.4));
    expect(above / below, lessThan(2.0));
  });

  test('a notehead is centred on its origin line', () async {
    const fontSize = 40.0;
    const baselineY = 200;
    final ink = await _renderGlyph('\uE0A4', fontSize, baselineY);

    final above = baselineY - ink.minY;
    final below = ink.maxY - baselineY;
    expect((above - below).abs(), lessThan(4));
  });
}
