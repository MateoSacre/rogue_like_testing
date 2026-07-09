import 'dart:math' as math;
import 'dart:ui';

import '../models/board.dart';
import '../models/hex.dart';

/// Pointy-top hex pixel layout. [size] is the circumradius (centre to corner);
/// [origin] is the pixel position of Hex(0, 0).
class HexLayout {
  final double size;
  final Offset origin;

  const HexLayout({required this.size, required this.origin});

  static const double _sqrt3 = 1.7320508075688772;

  /// Fits [board] inside [canvas] with a margin, returning a centred layout.
  factory HexLayout.fit(Board board, Size canvas, {double margin = 12}) {
    // Compute pixel extents at unit size, then scale to fit.
    var minX = double.infinity, minY = double.infinity;
    var maxX = -double.infinity, maxY = -double.infinity;
    for (final h in board.cells) {
      final x = _sqrt3 * (h.q + h.r / 2);
      final y = 1.5 * h.r;
      minX = math.min(minX, x);
      maxX = math.max(maxX, x);
      minY = math.min(minY, y);
      maxY = math.max(maxY, y);
    }
    // Add one hex of padding on each side (corners stick out by ~1 unit).
    final spanX = (maxX - minX) + 2;
    final spanY = (maxY - minY) + 2;
    final usableW = canvas.width - 2 * margin;
    final usableH = canvas.height - 2 * margin;
    final size = math.min(usableW / spanX, usableH / spanY);

    // Centre of the board in unit space.
    final cx = (minX + maxX) / 2;
    final cy = (minY + maxY) / 2;
    final origin = Offset(
      canvas.width / 2 - cx * size,
      canvas.height / 2 - cy * size,
    );
    return HexLayout(size: size, origin: origin);
  }

  Offset hexToPixel(Hex h) {
    final x = size * _sqrt3 * (h.q + h.r / 2);
    final y = size * 1.5 * h.r;
    return origin + Offset(x, y);
  }

  /// Inverse mapping with cube rounding.
  Hex pixelToHex(Offset p) {
    final local = p - origin;
    final r = (2 / 3 * local.dy) / size;
    final q = (local.dx / (_sqrt3 * size)) - r / 2;
    return _roundAxial(q, r);
  }

  List<Offset> corners(Hex h) {
    final c = hexToPixel(h);
    return [
      for (var i = 0; i < 6; i++)
        () {
          final angle = math.pi / 180 * (60 * i - 30);
          return c + Offset(size * math.cos(angle), size * math.sin(angle));
        }(),
    ];
  }

  static Hex _roundAxial(double q, double r) {
    final s = -q - r;
    var rq = q.roundToDouble();
    var rr = r.roundToDouble();
    var rs = s.roundToDouble();
    final dq = (rq - q).abs();
    final dr = (rr - r).abs();
    final ds = (rs - s).abs();
    if (dq > dr && dq > ds) {
      rq = -rr - rs;
    } else if (dr > ds) {
      rr = -rq - rs;
    }
    return Hex(rq.toInt(), rr.toInt());
  }
}
