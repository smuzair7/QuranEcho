import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A faint eight-point-star lattice, the kind found bordering illuminated
/// Quran manuscripts. Used once, behind the home header, as the app's single
/// bold decorative gesture — everywhere else stays quiet and flat.
class GeometricLattice extends StatelessWidget {
  final Color color;
  final double tileSize;
  final double strokeWidth;

  const GeometricLattice({
    super.key,
    required this.color,
    this.tileSize = 46,
    this.strokeWidth = 1.1,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _LatticePainter(
        color: color,
        tileSize: tileSize,
        strokeWidth: strokeWidth,
      ),
      size: Size.infinite,
    );
  }
}

class _LatticePainter extends CustomPainter {
  final Color color;
  final double tileSize;
  final double strokeWidth;

  _LatticePainter({
    required this.color,
    required this.tileSize,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final half = tileSize / 2;
    final rowHeight = tileSize * 0.75;
    final rows = (size.height / rowHeight).ceil() + 2;
    final cols = (size.width / tileSize).ceil() + 2;

    for (int row = -1; row < rows; row++) {
      final offsetX = row.isOdd ? half : 0.0;
      for (int col = -1; col < cols; col++) {
        final center = Offset(col * tileSize + offsetX, row * rowHeight);
        _drawUnit(canvas, paint, center, half * 0.82);
      }
    }
  }

  void _drawUnit(Canvas canvas, Paint paint, Offset center, double r) {
    canvas.save();
    canvas.translate(center.dx, center.dy);

    canvas.drawPath(_square(r), paint);

    canvas.rotate(math.pi / 4);
    canvas.drawPath(_square(r * 0.7), paint);

    canvas.restore();
  }

  Path _square(double r) {
    return Path()
      ..moveTo(-r, -r)
      ..lineTo(r, -r)
      ..lineTo(r, r)
      ..lineTo(-r, r)
      ..close();
  }

  @override
  bool shouldRepaint(covariant _LatticePainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.tileSize != tileSize ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
