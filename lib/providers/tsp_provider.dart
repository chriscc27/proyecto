// lib/providers/tsp_provider.dart

import 'package:flutter/material.dart';
import 'package:proyecto/models/distance.dart';  // Modelo de distancias manuales
import 'package:proyecto/models/node.dart';
import 'package:proyecto/algorithms/genetic_tsp.dart';
import 'package:latlong2/latlong.dart' as ll;

enum AppMode { placingNodes, deletingNodes, settingWeights }

class TSPProvider with ChangeNotifier {
  final List<Node> _nodes = [];
  final List<Distance> _distances = [];
  List<Node>? _bestRoute;
  AppMode _currentMode = AppMode.placingNodes;
  Node? _selectedForWeight;

  // Getters
  List<Node> get nodes => List.unmodifiable(_nodes);
  List<Distance> get distances => List.unmodifiable(_distances);
  List<Node>? get bestRoute => _bestRoute;
  AppMode get currentMode => _currentMode;

  // Cambiar de modo
  void setMode(AppMode mode) {
    _currentMode = mode;
    _selectedForWeight = null;
    notifyListeners();
  }

  // Agregar nodos
  void addNode(Node node) {
    _nodes.add(node);
    notifyListeners();
  }

  // Borrar nodo específico
  void deleteNode(String id) {
    _nodes.removeWhere((n) => n.id == id);
    _distances.removeWhere((d) => d.fromNodeId == id || d.toNodeId == id);
    notifyListeners();
  }

  // Borrar nodo más cercano a cierta ubicación
  void deleteNearest(ll.LatLng pt) {
    if (_nodes.isEmpty) return;
    final distCalc = ll.Distance();
    int bestIdx = 0;
    double bestD = double.infinity;
    for (int i = 0; i < _nodes.length; i++) {
      final d = distCalc.as(
        ll.LengthUnit.Meter,
        pt,
        ll.LatLng(_nodes[i].x, _nodes[i].y),
      );
      if (d < bestD) {
        bestD = d;
        bestIdx = i;
      }
    }
    _nodes.removeAt(bestIdx);
    notifyListeners();
  }

  // Asignar pesos manualmente
  void handleNodeTap(Node node, BuildContext context) {
    if (_currentMode != AppMode.settingWeights) return;
    if (_selectedForWeight == null) {
      _selectedForWeight = node;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Selecciona nodo destino para ${node.name}')),
      );
    } else {
      if (_selectedForWeight!.id == node.id) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No puedes elegir el mismo nodo')),
        );
        return;
      }
      _askDistance(context, _selectedForWeight!, node);
      _selectedForWeight = null;
    }
  }

  void _askDistance(BuildContext context, Node from, Node to) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Distancia ${from.name} → ${to.name}'),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(hintText: 'metros'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(onPressed: () {
            final v = double.tryParse(ctrl.text);
            if (v == null || v <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Ingresa un número válido')),
              );
              return;
            }
            _distances.add(Distance(
              fromNodeId: from.id,
              toNodeId: to.id,
              value: v,
            ));
            notifyListeners();
            Navigator.pop(context);
          }, child: const Text('Guardar')),
        ],
      ),
    );
  }

  // Limpiar todo
  void clearAll() {
    _nodes.clear();
    _distances.clear();
    _bestRoute = null;
    notifyListeners();
  }

  // Distancia real en metros
  double distanceBetween(Node a, Node b) {
    return ll.Distance().as(
      ll.LengthUnit.Meter,
      ll.LatLng(a.x, a.y),
      ll.LatLng(b.x, b.y),
    );
  }

  

  // Ejecutar algoritmo genético y guardar la mejor ruta
  Future<void> runGeneticAlgorithm({
    required int populationSize,
    required double mutationRate,
    required int maxGenerations,
  }) async {
    if (_nodes.length < 2) {
      throw Exception('Al menos 2 nodos requeridos');
    }
    final ga = GeneticTSP(
      nodes: _nodes,
      populationSize: populationSize,
      mutationRate: mutationRate,
      maxGenerations: maxGenerations,
    );
    _bestRoute = await ga.run();
    notifyListeners();
  }
}
