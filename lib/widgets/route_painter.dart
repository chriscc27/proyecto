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
  final Map<String, double> edgeCurvatures;
  final String? selectedEdgeKey;
  final List<EdgeHandle> edgeHandles;

  RoutePainter({
    required this.route,
    this.currentStep = 0,
    this.showDistances = false,
    this.useCurves = false,
    this.curveLevel = 40.0,
    required this.edgeCurvatures,
    required this.selectedEdgeKey,
    required this.edgeHandles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paintLine = Paint()
      ..color = const Color.fromARGB(255, 52, 222, 77)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final selectedPaint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final handlePaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    if (route.length < 2) return;
    final maxStep = currentStep.clamp(0, route.length - 2);

    for (int i = 0; i <= maxStep; i++) {
      final node1 = route[i];
      final node2 = route[i + 1];
      final edgeKey = _getEdgeKey(node1.id, node2.id);
      final curvature = edgeCurvatures[edgeKey] ?? curveLevel;
      
      final p1 = Offset(node1.x, node1.y);
      final p2 = Offset(node2.x, node2.y);
      final isSelected = edgeKey == selectedEdgeKey;

      if (useCurves) {
        final controlPoint = _calculateControlPoint(p1, p2, curvature);
        final path = Path()
          ..moveTo(p1.dx, p1.dy)
          ..quadraticBezierTo(
            controlPoint.dx,
            controlPoint.dy,
            p2.dx,
            p2.dy,
          );
        canvas.drawPath(path, isSelected ? selectedPaint : paintLine);
      } else {
        canvas.drawLine(p1, p2, isSelected ? selectedPaint : paintLine);
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

    // Dibujar handles de curvatura
    for (final handle in edgeHandles) {
      canvas.drawCircle(handle.position, 4, handlePaint);
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

  String _getEdgeKey(String id1, String id2) {
    final list = [id1, id2];
    list.sort((a, b) => a.compareTo(b));
    return list.join('_');
  }

  @override
  bool shouldRepaint(covariant RoutePainter oldDelegate) {
    return oldDelegate.route != route ||
        oldDelegate.currentStep != currentStep ||
        oldDelegate.showDistances != showDistances ||
        oldDelegate.useCurves != useCurves ||
        oldDelegate.curveLevel != curveLevel ||
        oldDelegate.edgeCurvatures != edgeCurvatures ||
        oldDelegate.selectedEdgeKey != selectedEdgeKey ||
        oldDelegate.edgeHandles != edgeHandles;
  }

  String? hitTestEdge(Offset tapPosition, {double tolerance = 30}) { // tolerancia aumentada
    if (route.length < 2) return null;
    for (int i = 0; i < route.length - 1; i++) {
      final node1 = route[i];
      final node2 = route[i + 1];
      final p1 = Offset(node1.x, node1.y);
      final p2 = Offset(node2.x, node2.y);

      // Distancia punto-recta
      final distance = _distanceToSegment(tapPosition, p1, p2);
      if (distance <= tolerance) {
        return _getEdgeKey(node1.id, node2.id);
      }

      // También verifica si el tap está cerca del peso
      final mid = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
      if ((tapPosition - mid).distance <= tolerance + 10) {
        return _getEdgeKey(node1.id, node2.id);
      }
    }
    return null;
  }

  double _distanceToSegment(Offset p, Offset a, Offset b) {
    final ap = p - a;
    final ab = b - a;
    final ab2 = ab.dx * ab.dx + ab.dy * ab.dy;
    final t = ab2 == 0 ? 0 : (ap.dx * ab.dx + ap.dy * ab.dy) / ab2;
    if (t < 0) return (p - a).distance;
    if (t > 1) return (p - b).distance;
    final proj = Offset(a.dx + ab.dx * t, a.dy + ab.dy * t);
    return (p - proj).distance;
  }
}

class EdgeHandle {
  final String edgeKey;
  final Offset position;

  EdgeHandle(this.edgeKey, this.position);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EdgeHandle &&
          runtimeType == other.runtimeType &&
          edgeKey == other.edgeKey &&
          position == other.position;

  @override
  int get hashCode => edgeKey.hashCode ^ position.hashCode;
}