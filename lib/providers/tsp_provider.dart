import 'package:flutter/material.dart';
import 'package:proyecto/algorithms/genetic_tsp.dart';
import 'package:proyecto/models/distance.dart';
import 'package:proyecto/models/node.dart';

enum AppMode { placingNodes, deletingNodes, settingWeights, none }

class TSPProvider with ChangeNotifier {
  List<Node> _nodes = [];
  List<Distance> _distances = [];
  List<Node>? _bestRoute;
  AppMode _currentMode = AppMode.placingNodes;
  Node? _selectedNodeForWeight;

  // Getters
  List<Node> get nodes => List.unmodifiable(_nodes);
  List<Distance> get distances => List.unmodifiable(_distances);
  List<Node>? get bestRoute => _bestRoute;
  AppMode get currentMode => _currentMode;

  // Cambiar modo y limpiar selección
  void setMode(AppMode mode) {
    _currentMode = mode;
    _selectedNodeForWeight = null;
    notifyListeners();
  }

  // Agregar nodo y notificar
  void addNode(Node node) {
    _nodes.add(node);
    notifyListeners();
  }

  // Borrar nodo y distancias relacionadas
  void deleteNode(String id) {
    _nodes.removeWhere((node) => node.id == id);
    _distances.removeWhere((d) => d.fromNodeId == id || d.toNodeId == id);
    notifyListeners();
  }

  // Agregar distancia si no existe y valor válido (>0)
  void addDistance(Distance distance) {
    if (distance.value <= 0) return; // evitar distancias inválidas

    final exists = _distances.any((d) =>
        d.fromNodeId == distance.fromNodeId && d.toNodeId == distance.toNodeId);

    if (!exists) {
      _distances.add(distance);
      notifyListeners();
    }
  }

  // Manejar taps en modo asignar peso
  void handleNodeTap(Node node, BuildContext context) {
    if (_currentMode != AppMode.settingWeights) return;

    if (_selectedNodeForWeight == null) {
      _selectedNodeForWeight = node;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Selecciona nodo destino para "${node.name}"')),
      );
    } else {
      if (_selectedNodeForWeight!.id == node.id) {
        // No permitir seleccionar mismo nodo como destino
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No puedes seleccionar el mismo nodo')),
        );
        return;
      }
      _showDistanceDialog(context, _selectedNodeForWeight!, node);
      _selectedNodeForWeight = null;
    }
  }

  // Diálogo para ingresar distancia
  void _showDistanceDialog(BuildContext context, Node from, Node to) {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Distancia ${from.name} → ${to.name}'),
        content: TextField(
          controller: controller,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            hintText: 'Distancia en unidades',
            suffixText: 'u',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                final value = double.tryParse(text);
                if (value == null || value <= 0) {
                  // Mostrar error simple
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ingrese un valor numérico positivo'),
                    ),
                  );
                  return;
                }
                addDistance(Distance(
                  fromNodeId: from.id,
                  toNodeId: to.id,
                  value: value,
                ));
                Navigator.pop(context);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  // Ejecutar algoritmo genético
  Future<void> runGeneticAlgorithm() async {
    if (_nodes.length < 2) {
      throw Exception('Debe haber al menos 2 nodos para ejecutar el algoritmo');
    }

    try {
      final genetic = GeneticTSP(nodes: _nodes);
      _bestRoute = await genetic.run();
      notifyListeners();
    } catch (e) {
      throw Exception('Error en algoritmo genético: $e');
    }
  }
}
