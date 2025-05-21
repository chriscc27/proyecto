import 'package:flutter/material.dart';
import 'package:proyecto/algorithms/genetic_tsp.dart';
import 'package:proyecto/models/node.dart';
import 'package:proyecto/widgets/route_painter.dart'; // Importa aquí

enum AppMode { placingNodes, deletingNodes, movingNodes }

enum EdgeInteractionMode { none, edgeSelected }

class TSPProvider with ChangeNotifier {
  List<Node> _nodes = [];
  List<Node>? _bestRoute;
  AppMode _currentMode = AppMode.placingNodes;
  Node? selectedNode;
  String? selectedEdgeKey;
  Map<String, double> edgeCurvatures = {};
  EdgeInteractionMode edgeMode = EdgeInteractionMode.none;

  List<Node> get nodes => List.unmodifiable(_nodes);
  List<Node>? get bestRoute => _bestRoute;
  AppMode get currentMode => _currentMode;

  void setMode(AppMode mode) {
    _currentMode = mode;
    notifyListeners();
  }

  void addNode(Node node) {
    _nodes.add(node);
    notifyListeners();
  }

  void deleteNode(String id) {
    _nodes.removeWhere((node) => node.id == id);
    _bestRoute = null;
    notifyListeners();
  }

  void clearNodes() {
    _nodes.clear();
    _bestRoute = null;
    notifyListeners();
  }

  void selectNode(Node? node) {
    selectedNode = node;
    if (node != null) {
      selectedEdgeKey = null; // Deselecciona arista al seleccionar nodo
    }
    notifyListeners();
  }

  void deselectNode() {
    selectedNode = null;
    notifyListeners();
  }

  void updateNodePosition(String nodeId, Offset newPosition) {
    final node = _nodes.firstWhere((n) => n.id == nodeId);
    node.x = newPosition.dx;
    node.y = newPosition.dy;
    notifyListeners();
  }

  void selectEdge(String? edgeKey) {
    selectedEdgeKey = edgeKey;
    if (edgeKey != null) {
      selectedNode = null; // Deselecciona nodo al seleccionar arista
    }
    notifyListeners();
  }

  void setEdgeCurvature(String edgeKey, double curvature) {
    edgeCurvatures[edgeKey] = curvature;
    notifyListeners();
  }

  String getEdgeKey(String id1, String id2) {
    final sorted = [id1, id2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  Future<void> runGeneticAlgorithm() async {
    if (_nodes.length < 2) throw Exception('Debe haber al menos 2 nodos');

    try {
      final genetic = GeneticTSP(nodes: _nodes);
      _bestRoute = await genetic.run();
      notifyListeners();
    } catch (e) {
      throw Exception('Error en algoritmo genético: $e');
    }
  }

  List<EdgeHandle> edgeHandles = []; // Usa la clase importada
}
