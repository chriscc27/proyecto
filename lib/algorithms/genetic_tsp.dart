import 'dart:math';
import 'package:proyecto/models/node.dart';

class GeneticTSP {
  List<Node> nodes;
  int populationSize;
  double mutationRate;
  int maxGenerations;
  final Random _random = Random();

  GeneticTSP({
    required this.nodes,
    this.populationSize = 100,
    this.mutationRate = 0.01,
    this.maxGenerations = 1000,
  });

  // 1. Generar población inicial
  List<List<Node>> _initializePopulation() {
    List<List<Node>> population = [];
    for (int i = 0; i < populationSize; i++) {
      List<Node> individual = List.from(nodes);
      individual.shuffle(_random);
      population.add(individual);
    }
    return population;
  }

  // 2. Función de fitness (distancia total)
  double _calculateFitness(List<Node> route) {
    double totalDistance = 0;
    for (int i = 0; i < route.length; i++) {
      Node from = route[i];
      Node to = route[(i + 1) % route.length]; // Conecta el último al primero
      totalDistance += _calculateDistance(from, to);
    }
    return totalDistance;
  }

  // Método auxiliar para distancia euclidiana
  double _calculateDistance(Node a, Node b) {
    return sqrt(pow(a.x - b.x, 2) + pow(a.y - b.y, 2));
  }

  // 3. Selección por torneo
  List<Node> _selection(List<List<Node>> population) {
    List<List<Node>> tournament = [];
    for (int i = 0; i < 5; i++) {
      tournament.add(population[_random.nextInt(population.length)]);
    }
    return tournament.reduce(
      (a, b) => _calculateFitness(a) < _calculateFitness(b) ? a : b,
    );
  }

  // 4. Cruzamiento OX (Ordered Crossover) corregido
  List<Node> _crossover(List<Node> parent1, List<Node> parent2) {
    int start = _random.nextInt(parent1.length);
    int end = _random.nextInt(parent1.length - start) + start;

    List<Node?> child = List.filled(parent1.length, null);

    // Copiar el segmento de parent1
    for (int i = start; i < end; i++) {
      child[i] = parent1[i];
    }

    // Llenar el resto con parent2, evitando duplicados
    int currentIndex = end % parent1.length;
    for (Node node in parent2) {
      if (!child.contains(node)) {
        child[currentIndex] = node;
        currentIndex = (currentIndex + 1) % parent1.length;
      }
    }

    // Convertir List<Node?> a List<Node> (no nulls)
    return child.map((e) => e!).toList();
  }

  // 5. Mutación (intercambio aleatorio)
  void _mutate(List<Node> route) {
    int index1 = _random.nextInt(route.length);
    int index2 = _random.nextInt(route.length);
    Node temp = route[index1];
    route[index1] = route[index2];
    route[index2] = temp;
  }

  double totalDistanceForRoute(List<Node> route) {
    double total = 0;
    for (int i = 0; i < route.length; i++) {
      total += _calculateDistance(route[i], route[(i + 1) % route.length]);
    }
    return total;
  }

  // Ejecutar algoritmo (versión optimizada)
  Future<List<Node>> run() async {
    List<List<Node>> population = _initializePopulation();

    for (int gen = 0; gen < maxGenerations; gen++) {
      List<List<Node>> newPopulation = [];

      while (newPopulation.length < populationSize) {
        List<Node> parent1 = _selection(population);
        List<Node> parent2 = _selection(population);
        List<Node> child = _crossover(parent1, parent2);

        if (_random.nextDouble() < mutationRate) {
          _mutate(child);
        }

        newPopulation.add(child);
      }

      population = newPopulation;
    }

    return population.reduce(
      (a, b) => _calculateFitness(a) < _calculateFitness(b) ? a : b,
    );
  }
}
