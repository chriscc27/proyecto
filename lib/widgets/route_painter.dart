import 'package:flutter/material.dart';
import 'package:proyecto/models/node.dart';

// Extensión para normalizar Offsets
extension OffsetExtension on Offset {
  Offset normalized() {
    final length = distance;
    return length == 0 ? this : this / length;
  }
}

class RoutePainter extends CustomPainter {
  final List<Node> route;
  final int currentStep;
  final bool showDistances;
  final bool useCurves;
  final double curveLevel;

  RoutePainter({
    required this.route,
    this.currentStep = 0,
    this.showDistances = false,
    this.useCurves = false,
    this.curveLevel = 40.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paintLine = Paint()
      ..color = const Color.fromARGB(255, 52, 222, 77)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    if (route.length < 2) return;
    final maxStep = currentStep.clamp(0, route.length - 2);

    for (int i = 0; i <= maxStep; i++) {
      final node1 = route[i];
      final node2 = route[i + 1];

      final p1 = Offset(node1.x, node1.y);
      final p2 = Offset(node2.x, node2.y);

      if (useCurves) {
        final controlPoint = _calculateControlPoint(p1, p2, curveLevel);
        final path = Path()
          ..moveTo(p1.dx, p1.dy)
          ..quadraticBezierTo(
            controlPoint.dx,
            controlPoint.dy,
            p2.dx,
            p2.dy,
          );
        canvas.drawPath(path, paintLine);
      } else {
        canvas.drawLine(p1, p2, paintLine);
      }

      if (showDistances) {
        final dist = (p1 - p2).distance;
        textPainter.text = TextSpan(
          text: dist.toStringAsFixed(1),
          style: const TextStyle(color: Colors.white, fontSize: 12),
        );
        textPainter.layout();
        textPainter.paint(canvas, _getTextPosition(p1, p2, textPainter));
      }
    }
  }

  Offset _calculateControlPoint(Offset p1, Offset p2, double curvature) {
    final center = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
    final normal = Offset(-(p2.dy - p1.dy), p2.dx - p1.dx).normalized();
    return center + normal * curvature;
  }

  Offset _getTextPosition(Offset p1, Offset p2, TextPainter painter) {
    final mid = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
    return mid - Offset(painter.width / 2, painter.height / 2);
  }

  @override
  bool shouldRepaint(covariant RoutePainter oldDelegate) {
    return oldDelegate.route != route ||
        oldDelegate.currentStep != currentStep ||
        oldDelegate.showDistances != showDistances ||
        oldDelegate.useCurves != useCurves ||
        oldDelegate.curveLevel != curveLevel;
  }
}