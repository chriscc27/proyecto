import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proyecto/widgets/route_painter.dart';
import '../models/node.dart';
import '../providers/tsp_provider.dart';

class NodeCreator extends StatefulWidget {
  const NodeCreator({super.key});

  @override
  State<NodeCreator> createState() => _NodeCreatorState();
}

class _NodeCreatorState extends State<NodeCreator> {
  static const double curveLevel = 40.0;

  Offset? _dragStartPosition;
  String? _draggedEdgeKey; // Nueva variable para saber si se está arrastrando el punto de control

  @override
  Widget build(BuildContext context) {
    final tspProvider = Provider.of<TSPProvider>(context);
    return GestureDetector(
      onTapDown: (details) => _handleTap(tspProvider, details.localPosition),
      onPanStart: (details) => _handlePanStart(tspProvider, details.localPosition),
      onPanUpdate: (details) => _handlePanUpdate(tspProvider, details),
      onPanEnd: (_) => _handlePanEnd(tspProvider),
      child: CustomPaint(
        painter: NodePainter(
          nodes: tspProvider.nodes,
          selectedNode: tspProvider.selectedNode,
        ),
        size: Size.infinite,
      ),
    );
  }

  void _handleTap(TSPProvider provider, Offset position) {
    final node = _findNodeAtPosition(provider.nodes, position);

    if (node != null) {
      if (provider.currentMode == AppMode.deletingNodes) {
        provider.deleteNode(node.id);
      } else {
        provider.selectNode(node);
        provider.selectEdge(null);
      }
    } else {
      if (provider.currentMode == AppMode.placingNodes) {
        _showNodeNameDialog(context, provider, position);
      } else {
        _handleEdgeTap(provider, position);
      }
    }
  }

  Offset _calculateControlPoint(Offset p1, Offset p2, double curvature) {
    final center = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
    final normal = Offset(-(p2.dy - p1.dy), p2.dx - p1.dx).normalized();
    return center + normal * curvature;
  }

  void _handleEdgeTap(TSPProvider provider, Offset position) {
    const detectionRadius = 16.0; // Un poco más grande para el punto de control

    for (int i = 0; i < provider.nodes.length - 1; i++) {
      final start = provider.nodes[i];
      final end = provider.nodes[i + 1];
      final edgeKey = provider.getEdgeKey(start.id, end.id);

      final p1 = Offset(start.x, start.y);
      final p2 = Offset(end.x, end.y);
      final curvature = provider.edgeCurvatures[edgeKey] ?? curveLevel;
      final controlPoint = _calculateControlPoint(p1, p2, curvature);

      // Detectar si se tocó el punto de control
      if ((controlPoint - position).distance < detectionRadius) {
        provider.selectEdge(edgeKey);
        _draggedEdgeKey = edgeKey;
        _dragStartPosition = position;
        return;
      }

      // Detectar si se tocó la arista (opcional, para selección normal)
      final path = Path()
        ..moveTo(p1.dx, p1.dy)
        ..quadraticBezierTo(controlPoint.dx, controlPoint.dy, p2.dx, p2.dy);

      final metrics = path.computeMetrics();
      for (final metric in metrics) {
        final pos = metric.getTangentForOffset(metric.length * 0.5)?.position;
        if (pos != null && (pos - position).distance < detectionRadius) {
          provider.selectEdge(edgeKey);
          _draggedEdgeKey = null;
          return;
        }
      }
    }
    provider.selectEdge(null);
    _draggedEdgeKey = null;
  }

  void _handlePanStart(TSPProvider provider, Offset position) {
    _dragStartPosition = position;
    final node = _findNodeAtPosition(provider.nodes, position);
    if (node != null) {
      provider.selectNode(node);
      _draggedEdgeKey = null;
    } else {
      // Intentar seleccionar el punto de control de una arista
      _handleEdgeTap(provider, position);
    }
  }

  void _handlePanUpdate(TSPProvider provider, DragUpdateDetails details) {
    if (_draggedEdgeKey != null) {
      // Si estamos arrastrando el punto de control de una arista
      final edgeKey = _draggedEdgeKey!;
      final nodes = provider.nodes;
      int idx = -1;
      for (int i = 0; i < nodes.length - 1; i++) {
        if (provider.getEdgeKey(nodes[i].id, nodes[i + 1].id) == edgeKey) {
          idx = i;
          break;
        }
      }
      if (idx != -1) {
        final start = nodes[idx];
        final end = nodes[idx + 1];
        final p1 = Offset(start.x, start.y);
        final p2 = Offset(end.x, end.y);

        // Calcular la nueva curvatura según la posición del drag
        final center = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
        final normal = Offset(-(p2.dy - p1.dy), p2.dx - p1.dx).normalized();
        final dragOffset = details.localPosition - center;
        final newCurvature = dragOffset.dx * normal.dx + dragOffset.dy * normal.dy;

        provider.setEdgeCurvature(edgeKey, newCurvature);
      }
    } else if (provider.selectedNode != null) {
      provider.updateNodePosition(
        provider.selectedNode!.id,
        details.localPosition,
      );
    }
  }

  void _handlePanEnd(TSPProvider provider) {
    provider.deselectNode();
    _draggedEdgeKey = null;
  }

  Node? _findNodeAtPosition(
    List<Node> nodes,
    Offset position, {
    double tolerance = 20.0,
  }) {
    for (final node in nodes) {
      final distance = (Offset(node.x, node.y) - position).distance;
      if (distance <= tolerance) return node;
    }
    return null;
  }

  Future<void> _showNodeNameDialog(
    BuildContext context,
    TSPProvider provider,
    Offset offset,
  ) async {
    final nameController = TextEditingController();

    final name = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Nombre del nodo'),
            content: TextField(
              controller: nameController,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'Ingrese nombre'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed:
                    () => Navigator.pop(context, nameController.text.trim()),
                child: const Text('Crear'),
              ),
            ],
          ),
    );

    if (name != null && name.isNotEmpty) {
      final newNode = Node(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        x: offset.dx,
        y: offset.dy,
      );
      provider.addNode(newNode);
    }
  }
}

class NodePainter extends CustomPainter {
  final List<Node> nodes;
  final Node? selectedNode;

  NodePainter({required this.nodes, this.selectedNode});

  @override
  void paint(Canvas canvas, Size size) {
    final nodePaint =
        Paint()
          ..color = Colors.red
          ..style = PaintingStyle.fill;

    final selectedPaint =
        Paint()
          ..color = Colors.blue
          ..style = PaintingStyle.fill
          ..strokeWidth = 3;

    const textStyle = TextStyle(
      color: Colors.white,
      fontSize: 14,
      shadows: [
        Shadow(blurRadius: 3, color: Colors.black54, offset: Offset(1, 1)),
      ],
    );

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    for (final node in nodes) {
      final isSelected = node == selectedNode;
      final offset = Offset(node.x, node.y);

      // Dibujar marcador
      canvas.drawPath(
        createMapMarkerPath(offset, 30, 40),
        isSelected ? selectedPaint : nodePaint,
      );

      // Círculo interior
      canvas.drawCircle(
        offset.translate(0, -12),
        8,
        Paint()..color = Colors.white,
      );

      // Nombre del nodo
      textPainter.text = TextSpan(text: node.name, style: textStyle);
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          offset.dx - textPainter.width / 2,
          offset.dy - 30 - textPainter.height,
        ),
      );
    }
  }

  Path createMapMarkerPath(Offset center, double width, double height) {
    final path = Path();
    final bottomPoint = Offset(center.dx, center.dy + height / 2);
    path.moveTo(bottomPoint.dx, bottomPoint.dy);
    path.quadraticBezierTo(
      center.dx,
      center.dy + height / 4,
      center.dx - width / 2,
      center.dy - height / 4,
    );
    path.quadraticBezierTo(
      center.dx - width / 2,
      center.dy - height / 2,
      center.dx,
      center.dy - height / 2,
    );
    path.quadraticBezierTo(
      center.dx + width / 2,
      center.dy - height / 2,
      center.dx + width / 2,
      center.dy - height / 4,
    );
    path.quadraticBezierTo(
      center.dx,
      center.dy + height / 4,
      bottomPoint.dx,
      bottomPoint.dy,
    );
    return path..close();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
