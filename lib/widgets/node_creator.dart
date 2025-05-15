import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/node.dart';
import '../models/distance.dart';
import '../providers/tsp_provider.dart';

class NodeCreator extends StatelessWidget {
  const NodeCreator({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TSPProvider>(
      builder: (context, tspProvider, _) {
        return GestureDetector(
          onTapDown: (details) async {
            final RenderBox renderBox = context.findRenderObject() as RenderBox;
            final offset = renderBox.globalToLocal(details.globalPosition);

            switch (tspProvider.currentMode) {
              case AppMode.placingNodes:
                await _handleAddNode(context, tspProvider, offset);
                break;
              case AppMode.deletingNodes:
                _handleDeleteNode(tspProvider, offset);
                break;
              case AppMode.settingWeights:
                _handleSetWeight(context, tspProvider, offset);
                break;
            }
          },
          child: CustomPaint(
            painter: NodePainter(
              nodes: tspProvider.nodes,
              distances: tspProvider.distances,
            ),
            size: Size.infinite,
          ),
        );
      },
    );
  }

  Future<void> _handleAddNode(
    BuildContext context,
    TSPProvider provider,
    Offset offset,
  ) async {
    final nameController = TextEditingController();

    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nombre del nodo'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Ingrese nombre'),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              Navigator.pop(context, value.trim());
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, nameController.text),
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

  void _handleDeleteNode(TSPProvider provider, Offset offset) {
    final node = _findNodeAtPosition(provider.nodes, offset);
    if (node != null) {
      provider.deleteNode(node.id);
    }
  }

  void _handleSetWeight(
    BuildContext context,
    TSPProvider provider,
    Offset offset,
  ) {
    final node = _findNodeAtPosition(provider.nodes, offset);
    if (node != null) {
      provider.handleNodeTap(node, context);
    }
  }

  Node? _findNodeAtPosition(
    List<Node> nodes,
    Offset position, {
    double tolerance = 20.0,
  }) {
    for (final node in nodes) {
      final distance = (Offset(node.x, node.y) - position).distance;
      if (distance <= tolerance) {
        return node;
      }
    }
    return null;
  }
}

class NodePainter extends CustomPainter {
  final List<Node> nodes;
  final List<Distance> distances;

  NodePainter({required this.nodes, required this.distances});

  @override
  void paint(Canvas canvas, Size size) {
    final nodePaint = Paint()
      ..color = Colors.red // Cambiado a rojo
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final textStyle = const TextStyle(
      color: Colors.white,
      fontSize: 14,
      shadows: [
        Shadow(
          blurRadius: 3,
          color: Colors.black54,
          offset: Offset(1, 1),
        ),
      ],
    );

    final weightStyle = const TextStyle(
      color: Colors.black,
      fontSize: 12,
      fontWeight: FontWeight.bold,
    );

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    // Dibujar arcos curvos con pesos (sin cambios)
    for (final d in distances) {
      final from = nodes.where((n) => n.id == d.fromNodeId).cast<Node?>().firstOrNull;
      final to = nodes.where((n) => n.id == d.toNodeId).cast<Node?>().firstOrNull;

      if (from == null || to == null) return;

      final fromOffset = Offset(from.x, from.y);
      final toOffset = Offset(to.x, to.y);

      final path = Path();
      path.moveTo(fromOffset.dx, fromOffset.dy);

      final controlPoint = Offset(
        (fromOffset.dx + toOffset.dx) / 2,
        (fromOffset.dy + toOffset.dy) / 2 - 40,
      );

      path.quadraticBezierTo(
        controlPoint.dx,
        controlPoint.dy,
        toOffset.dx,
        toOffset.dy,
      );

      canvas.drawPath(path, linePaint);

      final midX = (fromOffset.dx + toOffset.dx) / 2;
      final midY = (fromOffset.dy + toOffset.dy) / 2 - 40;

      textPainter.text = TextSpan(
        text: d.value.toStringAsFixed(1),
        style: weightStyle,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(midX - textPainter.width / 2, midY - textPainter.height / 2),
      );
    }

    // Dibujar nodos como marcadores tipo Google Maps rojos con círculo blanco central
    for (final node in nodes) {
      final nodeOffset = Offset(node.x, node.y);
      final markerPath = createMapMarkerPath(nodeOffset, 30, 40);
      canvas.drawPath(markerPath, nodePaint);

      // Círculo interior blanco (centro del marcador)
      final headPaint = Paint()..color = Colors.white;
      canvas.drawCircle(nodeOffset.translate(0, -12), 8, headPaint);

      // Nombre del nodo arriba del marcador
      textPainter.text = TextSpan(text: node.name, style: textStyle);
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(nodeOffset.dx - textPainter.width / 2, nodeOffset.dy - 30 - textPainter.height),
      );
    }
  }

  Path createMapMarkerPath(Offset center, double width, double height) {
    final path = Path();

    final bottomPoint = Offset(center.dx, center.dy + height / 2);
    final leftPoint = Offset(center.dx - width / 2, center.dy - height / 4);
    final rightPoint = Offset(center.dx + width / 2, center.dy - height / 4);
    final topCurveControlLeft = Offset(center.dx - width / 2, center.dy - height / 2);
    final topCurveControlRight = Offset(center.dx + width / 2, center.dy - height / 2);

    path.moveTo(bottomPoint.dx, bottomPoint.dy);

    path.quadraticBezierTo(
      center.dx,
      center.dy + height / 4,
      leftPoint.dx,
      leftPoint.dy,
    );

    path.quadraticBezierTo(
      topCurveControlLeft.dx,
      topCurveControlLeft.dy,
      center.dx,
      center.dy - height / 2,
    );

    path.quadraticBezierTo(
      topCurveControlRight.dx,
      topCurveControlRight.dy,
      rightPoint.dx,
      rightPoint.dy,
    );

    path.quadraticBezierTo(
      center.dx,
      center.dy + height / 4,
      bottomPoint.dx,
      bottomPoint.dy,
    );

    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
