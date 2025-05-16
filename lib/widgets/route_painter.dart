import 'package:flutter/material.dart';
import 'package:proyecto/models/node.dart';
import 'dart:math';

class RoutePainter extends CustomPainter {
  final List<Node> route;
  final int currentStep;
  final bool showDistances;
  final bool useCurves;
  final double curveLevel; // Nuevo parámetro

  RoutePainter({
    required this.route,
    this.currentStep = 0,
    this.showDistances = false,
    this.useCurves = false,
    this.curveLevel = 40.0, // Valor por defecto para la curva
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paintLine = Paint()
      ..color = const Color.fromARGB(255, 52, 222, 77)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final paintNode = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    if (route.length < 2) return;

    final maxStep = currentStep.clamp(0, route.length - 2);

    for (int i = 0; i <= maxStep; i++) {
      final p1 = Offset(route[i].x, route[i].y);
      final p2 = Offset(route[i + 1].x, route[i + 1].y);

      if (useCurves) {
        final midX = (p1.dx + p2.dx) / 2;
        final midY = (p1.dy + p2.dy) / 2;

        final dx = p2.dy - p1.dy;
        final dy = p1.dx - p2.dx;
        final length = sqrt(dx * dx + dy * dy);
        final normal = length == 0 ? Offset.zero : Offset(dx / length, dy / length);

        // Aquí usamos el curveLevel como fuerza de la curva
        final controlPoint = Offset(midX, midY) + normal * curveLevel;

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
        final label = dist.toStringAsFixed(1);

        final textOffset = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
        textPainter.text = TextSpan(
          text: label,
          style: const TextStyle(color: Colors.white, fontSize: 12),
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          textOffset - Offset(textPainter.width / 2, textPainter.height / 2),
        );
      }
    }

    for (int i = 0; i <= maxStep + 1 && i < route.length; i++) {
      final p = Offset(route[i].x, route[i].y);
      canvas.drawCircle(p, 8, paintNode);
    }
  }

  @override
  bool shouldRepaint(covariant RoutePainter oldDelegate) {
    return oldDelegate.route != route ||
        oldDelegate.currentStep != currentStep ||
        oldDelegate.showDistances != showDistances ||
        oldDelegate.useCurves != useCurves ||
        oldDelegate.curveLevel != curveLevel; // Incluimos la comparación aquí
  }
}
