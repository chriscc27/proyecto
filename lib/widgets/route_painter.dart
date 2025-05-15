import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math';
import 'dart:ui' as ui;

class RoutePainter extends CustomPainter {
  final List<LatLng> route;
  final MapController mapController;
  final int currentStep;
  final bool showDistances;
  final double curveOffsetFactor;

  RoutePainter({
    required this.route,
    required this.mapController,
    this.currentStep = 0,
    this.showDistances = false,
    this.curveOffsetFactor = 0.8,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (route.length < 2) return;

    final paintLine =
        Paint()
          ..color = Colors.deepPurple
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;

    final paintNode =
        Paint()
          ..color = Colors.red
          ..style = PaintingStyle.fill;

    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    // Convertir LatLng -> Offset en pantalla
    final points =
        route
            .map(
              (latlng) => mapController.latLngToScreenPoint(latlng).toOffset(),
            )
            .toList();

    final maxStep = currentStep.clamp(0, points.length - 2);

    for (int i = 0; i <= maxStep; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];

      final dx = p2.dx - p1.dx;
      final dy = p2.dy - p1.dy;
      final length = sqrt(dx * dx + dy * dy);
      if (length == 0) continue;

      final ux = -dy / length;
      final uy = dx / length;

      final mid = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
      final ctrl = mid.translate(
        ux * length * curveOffsetFactor,
        uy * length * curveOffsetFactor,
      );

      final path =
          ui.Path()
            ..moveTo(p1.dx, p1.dy)
            ..quadraticBezierTo(ctrl.dx, ctrl.dy, p2.dx, p2.dy);
      canvas.drawPath(path, paintLine);

      if (showDistances) {
        final label = length.toStringAsFixed(1);
        final textPos = mid.translate(0, -10);
        textPainter.text = TextSpan(
          text: label,
          style: const TextStyle(color: Colors.black, fontSize: 12),
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          textPos - Offset(textPainter.width / 2, textPainter.height / 2),
        );
      }
    }

    // Nodos
    for (int i = 0; i <= maxStep + 1 && i < points.length; i++) {
      canvas.drawCircle(points[i], 6, paintNode);
    }
  }

  @override
  bool shouldRepaint(covariant RoutePainter old) {
    return old.route != route ||
        old.currentStep != currentStep ||
        old.showDistances != showDistances ||
        old.curveOffsetFactor != curveOffsetFactor;
  }
}
