// Builds the launcher-icon sources from assets/icon/AVD.png:
//  - icon_foreground.png : white "AV" mark on transparent (Android adaptive foreground, inside the safe zone)
//  - icon_full.png       : the mark on a full-bleed navy square (iOS / legacy Android)
// Run: dart run tool/make_icons.dart
import 'dart:io';

import 'package:image/image.dart' as img;

void main() {
  final src = img.decodePng(File('assets/icon/AVD.png').readAsBytesSync())!;
  final navy = src.getPixel(600, 1000);
  final bg = img.ColorRgb8(navy.r.toInt(), navy.g.toInt(), navy.b.toInt());
  final hex = '#${navy.r.toInt().toRadixString(16).padLeft(2, '0')}${navy.g.toInt().toRadixString(16).padLeft(2, '0')}${navy.b.toInt().toRadixString(16).padLeft(2, '0')}';
  print('navy $hex');

  // The AV mark sits in this box (white on navy).
  const x0 = 160, y0 = 410, w = 935, h = 440;
  final crop = img.copyCrop(src, x: x0, y: y0, width: w, height: h);

  // Luminance → alpha, so the mark becomes pure white with soft edges.
  final mark = img.Image(width: w, height: h, numChannels: 4);
  for (final p in crop) {
    final lum = (p.r + p.g + p.b) / 3;
    final navyLum = (navy.r + navy.g + navy.b) / 3;
    final a = ((lum - navyLum) / (255 - navyLum)).clamp(0.0, 1.0);
    mark.setPixelRgba(p.x, p.y, 255, 255, 255, (a * 255).round());
  }

  const size = 1024;
  img.Image place(double fraction, {required bool opaque}) {
    final canvas = opaque ? img.Image(width: size, height: size, numChannels: 4) : img.Image(width: size, height: size, numChannels: 4);
    if (opaque) img.fill(canvas, color: bg);
    final targetW = (size * fraction).round();
    final scaled = img.copyResize(mark, width: targetW, interpolation: img.Interpolation.cubic);
    img.compositeImage(canvas, scaled, dstX: (size - scaled.width) ~/ 2, dstY: (size - scaled.height) ~/ 2);
    return canvas;
  }

  File('assets/icon/icon_foreground.png').writeAsBytesSync(img.encodePng(place(0.58, opaque: false)));
  File('assets/icon/icon_full.png').writeAsBytesSync(img.encodePng(place(0.72, opaque: true)));
}
