import 'package:flutter/material.dart';
import 'package:proyecto/algorithms/genetic_tsp.dart';
import 'package:proyecto/models/node.dart';

enum AppMode { placingNodes, deletingNodes }

class TSPProvider with ChangeNotifier {
  List<Node> _nodes = [];
  List<Node>? _bestRoute;
  AppMode _currentMode = AppMode.placingNodes;

  // Getters
  List<Node> get nodes => List.unmodifiable(_nodes);
  List<Node>? get bestRoute => _bestRoute;
  AppMode get currentMode => _currentMode;

  // Cambiar modo
  void setMode(AppMode mode) {
    _currentMode = mode;
    notifyListeners();
  }

  // Agregar nodo
  void addNode(Node node) {
    _nodes.add(node);
    notifyListeners();
  }

  // Borrar nodo y ruta relacionada
  void deleteNode(String id) {
    _nodes.removeWhere((node) => node.id == id);
    _bestRoute = null;
    notifyListeners();
  }

  // Limpiar todo
  void clearNodes() {
    _nodes.clear();
    _bestRoute = null;
    notifyListeners();
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
