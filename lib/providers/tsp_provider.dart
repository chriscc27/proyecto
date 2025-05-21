import 'package:flutter/material.dart';
import 'package:proyecto/algorithms/genetic_tsp.dart';
import 'package:proyecto/models/node.dart';

enum AppMode { placingNodes, deletingNodes, movingNodes }

class TSPProvider with ChangeNotifier {
  List<Node> _nodes = [];
  List<Node>? _bestRoute;
  AppMode _currentMode = AppMode.placingNodes;
  Node? selectedNode;

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
}
