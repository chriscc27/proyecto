import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/node.dart';
import '../providers/tsp_provider.dart';

class NodeCreator extends StatefulWidget {
  final Node? startNode;
  const NodeCreator({super.key, this.startNode});

  @override
  State<NodeCreator> createState() => _NodeCreatorState();
}

class _NodeCreatorState extends State<NodeCreator> {
  Node? draggingNode;
  Offset? dragOffset;

  @override
  Widget build(BuildContext context) {
    final tspProvider = Provider.of<TSPProvider>(context);
    return GestureDetector(
      onPanStart: (details) {
        final RenderBox renderBox = context.findRenderObject() as RenderBox;
        final localPos = renderBox.globalToLocal(details.globalPosition);

        // Detectar si se toca un nodo existente
        for (final node in tspProvider.nodes) {
          if ((Offset(node.x, node.y) - localPos).distance < 25) {
            setState(() {
              draggingNode = node;
              dragOffset = localPos - Offset(node.x, node.y);
            });
            tspProvider.selectNode(node);
            return;
          }
        }
      },
      onPanUpdate: (details) {
        if (draggingNode != null) {
          final RenderBox renderBox = context.findRenderObject() as RenderBox;
          final localPos = renderBox.globalToLocal(details.globalPosition);
          final newPos = localPos - (dragOffset ?? Offset.zero);

          // Actualiza la posición del nodo arrastrado
          tspProvider.updateNodePosition(draggingNode!.id, newPos);
        }
      },
      onPanEnd: (_) {
        setState(() {
          draggingNode = null;
          dragOffset = null;
        });
      },
      onTapUp: (details) async {
        final tspProvider = Provider.of<TSPProvider>(context, listen: false);
        final RenderBox renderBox = context.findRenderObject() as RenderBox;
        final localPos = renderBox.globalToLocal(details.globalPosition);

        // Si se toca un nodo existente
        for (final node in tspProvider.nodes) {
          if ((Offset(node.x, node.y) - localPos).distance < 25) {
            if (tspProvider.currentMode == AppMode.deletingNodes) {
              tspProvider.deleteNode(node.id);
            } else {
              tspProvider.selectNode(node);
            }
            return;
          }
        }

        // Si no hay nodo cerca y el modo es añadir, crea uno nuevo (pide nombre)
        if (tspProvider.currentMode == AppMode.placingNodes) {
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
              x: localPos.dx,
              y: localPos.dy,
            );
            tspProvider.addNode(newNode);
          }
        }
      },
      child: CustomPaint(
        painter: NodePainter(
          nodes: tspProvider.nodes,
          selectedNode: tspProvider.selectedNode,
          startNode: widget.startNode, // <-- Aquí
        ),
        size: Size.infinite,
      ),
    );
  }
}

class NodePainter extends CustomPainter {
  final List<Node> nodes;
  final Node? selectedNode;
  final Node? startNode; // <-- Agrega esto si quieres nodo de inicio en verde

  NodePainter({
    required this.nodes,
    this.selectedNode,
    this.startNode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final nodePaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    final selectedPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    final startPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.fill;

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
      final offset = Offset(node.x, node.y);

      // Decide el color del nodo
      Paint paintToUse = nodePaint;
      if (startNode != null && node.id == startNode!.id) {
        paintToUse = startPaint;
      } else if (selectedNode != null && node.id == selectedNode!.id) {
        paintToUse = selectedPaint;
      }

      // Dibuja el marcador personalizado
      canvas.drawPath(
        createMapMarkerPath(offset, 30, 40),
        paintToUse,
      );

      // Círculo interior blanco
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
