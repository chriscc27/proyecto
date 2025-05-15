// lib/algorithms/genetic_tsp.dart
import 'dart:math';
import 'package:latlong2/latlong.dart';
import 'package:proyecto/models/node.dart';

class GeneticTSP {
  final List<Node> nodes;
  final int populationSize;
  final double mutationRate;
  final int maxGenerations;
  final Random _random = Random();
  // Calculador de distancias geodésicas
  final Distance _geodist = const Distance();

  GeneticTSP({
    required this.nodes,
    this.populationSize = 100,
    this.mutationRate = 0.01,
    this.maxGenerations = 1000,
  });

  // 1. Población inicial
  List<List<Node>> _initializePopulation() {
    return List.generate(populationSize, (_) {
      final individual = List<Node>.from(nodes);
      individual.shuffle(_random);
      return individual;
    });
  }

  // 2. Fitness = longitud total de la ruta (en metros)
  double _calculateFitness(List<Node> route) {
    double total = 0;
    for (var i = 0; i < route.length; i++) {
      total += _calculateDistance(
        route[i],
        route[(i + 1) % route.length],
      );
    }
    return total;
  }

  // Distancia geodésica entre dos nodos
  double _calculateDistance(Node a, Node b) {
    return _geodist.as(
      LengthUnit.Meter,
      LatLng(a.x, a.y),
      LatLng(b.x, b.y),
    );
  }

  // 3. Selección por torneo
  List<Node> _selection(List<List<Node>> population) {
    final tournament = List<List<Node>>.generate(
      5,
      (_) => population[_random.nextInt(population.length)],
    );
    return tournament.reduce((a, b) =>
        _calculateFitness(a) < _calculateFitness(b) ? a : b);
  }

  // 4. Cruzamiento OX
  List<Node> _crossover(List<Node> p1, List<Node> p2) {
    final len = p1.length;
    final start = _random.nextInt(len);
    final end = start + _random.nextInt(len - start);
    final child = List<Node?>.filled(len, null);

    // copiar segmento
    for (var i = start; i < end; i++) {
      child[i] = p1[i];
    }
    // rellenar con p2 sin duplicados
    var idx = end % len;
    for (var node in p2) {
      if (!child.contains(node)) {
        child[idx] = node;
        idx = (idx + 1) % len;
      }
    }
    return child.cast<Node>();
  }

  // 5. Mutación (swap)
  void _mutate(List<Node> route) {
    final i = _random.nextInt(route.length);
    final j = _random.nextInt(route.length);
    final tmp = route[i];
    route[i] = route[j];
    route[j] = tmp;
  }

  // Distancia total auxiliar
  double totalDistanceForRoute(List<Node> route) => _calculateFitness(route);

  // Ejecutar el algoritmo
  Future<List<Node>> run() async {
    var population = _initializePopulation();
    for (var gen = 0; gen < maxGenerations; gen++) {
      final newPop = <List<Node>>[];
      while (newPop.length < populationSize) {
        final parent1 = _selection(population);
        final parent2 = _selection(population);
        final child = _crossover(parent1, parent2);
        if (_random.nextDouble() < mutationRate) {
          _mutate(child);
        }
        newPop.add(child);
      }
      population = newPop;
    }
    // devolver el mejor individuo final
    return population.reduce((a, b) =>
        _calculateFitness(a) < _calculateFitness(b) ? a : b);
  }
}
