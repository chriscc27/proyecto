import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/node.dart';
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
            }
          },
          child: CustomPaint(
            painter: NodePainter(
              nodes: tspProvider.nodes,
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
            onPressed: () => Navigator.pop(context, nameController.text.trim()),
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

  NodePainter({required this.nodes});

  @override
  void paint(Canvas canvas, Size size) {
    final nodePaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

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

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    for (final node in nodes) {
      final nodeOffset = Offset(node.x, node.y);
      final markerPath = createMapMarkerPath(nodeOffset, 30, 40);
      canvas.drawPath(markerPath, nodePaint);

      // Círculo interior blanco
      final headPaint = Paint()..color = Colors.white;
      canvas.drawCircle(nodeOffset.translate(0, -12), 8, headPaint);

      // Nombre del nodo
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
    path.quadraticBezierTo(center.dx, center.dy + height / 4, leftPoint.dx, leftPoint.dy);
    path.quadraticBezierTo(topCurveControlLeft.dx, topCurveControlLeft.dy, center.dx, center.dy - height / 2);
    path.quadraticBezierTo(topCurveControlRight.dx, topCurveControlRight.dy, rightPoint.dx, rightPoint.dy);
    path.quadraticBezierTo(center.dx, center.dy + height / 4, bottomPoint.dx, bottomPoint.dy);

    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
