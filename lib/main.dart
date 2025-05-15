// lib/main.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import 'package:proyecto/providers/tsp_provider.dart';
import 'package:proyecto/models/node.dart';
import 'package:proyecto/algorithms/genetic_tsp.dart';


void main() {
  runApp(
    ChangeNotifierProvider(create: (_) => TSPProvider(), child: const MyApp()),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'TSP Solver Genético',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(primarySwatch: Colors.blue),
        home: const HomeScreen(),
      );
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Node? selectedStartNode;
  List<Node> fullRoute = [];
  double totalDistance = 0;

  bool isAnimating = false, isPaused = false;
  double animationSpeed = 1.0;
  int currentStep = 0;
  Timer? _timer;

  int populationSize = 100, maxGenerations = 1000;
  double mutationRate = 0.01;

  final MapController _mapController = MapController();

  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red),
      );

  Future<void> _runAlgorithm() async {
    final prov = context.read<TSPProvider>();
    if (prov.nodes.length < 2) {
      _showError('¡Necesitas al menos 2 nodos!');
      return;
    }
    if (selectedStartNode == null) {
      _showError('Selecciona un nodo de inicio.');
      return;
    }

    // Ejecutar el algoritmo genético aquí
    final tsp = GeneticTSP(
      nodes: prov.nodes,
      populationSize: populationSize,
      mutationRate: mutationRate,
      maxGenerations: maxGenerations,
    );
    final route = await tsp.run();

    final start = route.indexWhere((n) => n.id == selectedStartNode!.id);
    if (start < 0) {
      _showError('El nodo inicial no está en la ruta.');
      return;
    }

    final reordered = [
      ...route.sublist(start),
      ...route.sublist(0, start),
      route[start],
    ];

    setState(() {
      fullRoute = reordered;
      currentStep = 0;
      // Calculamos la distancia total con el mismo tsp
      totalDistance = tsp.totalDistanceForRoute(reordered);
      isAnimating = true;
      isPaused = false;
    });
    _startAnimation();
  }

  void _startAnimation() {
    _timer?.cancel();
    _timer = Timer.periodic(
      Duration(milliseconds: (1000 ~/ animationSpeed).toInt()),
      (t) {
        if (isPaused) return;
        setState(() {
          if (currentStep < fullRoute.length - 1) {
            currentStep++;
          } else {
            isAnimating = false;
            t.cancel();
          }
        });
      },
    );
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      isAnimating = false;
      isPaused = false;
      currentStep = 0;
      fullRoute = [];
      totalDistance = 0;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext _) {
    final prov = context.watch<TSPProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('TSP Genético'),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            tooltip: 'Limpiar todo',
            onPressed: () => prov.clearAll(),
          ),
        ],
      ),
      body: Column(
        children: [
          if (prov.nodes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  const Text("Desde:"),
                  const SizedBox(width: 8),
                  DropdownButton<Node>(
                    value: selectedStartNode,
                    hint: const Text("—"),
                    items: prov.nodes
                        .map((n) => DropdownMenuItem(
                              value: n,
                              child: Text(n.name),
                            ))
                        .toList(),
                    onChanged: isAnimating
                        ? null
                        : (n) => setState(() => selectedStartNode = n),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: (selectedStartNode == null || isAnimating)
                        ? null
                        : _runAlgorithm,
                    child: const Text("Resolver TSP"),
                  ),
                  if (isAnimating) ...[
                    IconButton(
                      icon: Icon(isPaused ? Icons.play_arrow : Icons.pause),
                      onPressed: () =>
                          setState(() => isPaused = !isPaused),
                    ),
                    IconButton(
                      icon: const Icon(Icons.stop),
                      onPressed: _reset,
                    ),
                  ]
                ],
              ),
            ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _buildSlider(
                  label: "Población",
                  min: 10,
                  max: 500,
                  value: populationSize.toDouble(),
                  onChanged: (v) => setState(() => populationSize = v.toInt()),
                ),
                _buildSlider(
                  label: "Mutación",
                  min: 0.0,
                  max: 0.1,
                  divisions: 100,
                  value: mutationRate,
                  onChanged: (v) => setState(() => mutationRate = v),
                ),
                _buildSlider(
                  label: "Generaciones",
                  min: 100,
                  max: 10000,
                  value: maxGenerations.toDouble(),
                  onChanged: (v) => setState(() => maxGenerations = v.toInt()),
                ),
              ],
            ),
          ),

          if (totalDistance > 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                "Distancia total: ${totalDistance.toStringAsFixed(0)} m",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),

          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                center: LatLng(-16.5, -68.15),
                zoom: 13,
                interactiveFlags: InteractiveFlag.all,
                onTap: (_, p) {
                  switch (prov.currentMode) {
                    case AppMode.placingNodes:
                      prov.addNode(Node(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        name: 'N${prov.nodes.length + 1}',
                        x: p.latitude,
                        y: p.longitude,
                      ));
                      break;
                    case AppMode.deletingNodes:
                      prov.deleteNearest(p);
                      break;
                    case AppMode.settingWeights:
                      prov.handleNodeTap(
                        Node(id: '', name: '', x: p.latitude, y: p.longitude),
                        context,
                      );
                      break;
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c'],
                ),

                MarkerLayer(
                  markers: prov.nodes.map((n) {
                    final inRoute =
                        fullRoute.take(currentStep + 1).contains(n);
                    return Marker(
                      point: LatLng(n.x, n.y),
                      width: 40,
                      height: 40,
                      child: GestureDetector(
                        onTap: () => prov.handleNodeTap(n, context),
                        child: Icon(
                          Icons.location_on,
                          size: 30,
                          color: inRoute ? Colors.green : Colors.red,
                        ),
                      ),
                    );
                  }).toList(),
                ),

                if (fullRoute.length > 1 && currentStep > 0)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: fullRoute
                            .take(currentStep + 1)
                            .map((n) => LatLng(n.x, n.y))
                            .toList(),
                        strokeWidth: 4,
                        color: Colors.blueAccent,
                      ),
                    ],
                  ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _modeButton(Icons.add_location, AppMode.placingNodes),
                const SizedBox(width: 16),
                _modeButton(Icons.delete, AppMode.deletingNodes),
                const SizedBox(width: 16),
                _modeButton(Icons.line_weight, AppMode.settingWeights),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlider({
    required String label,
    required double min,
    required double max,
    required double value,
    int? divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        Text("$label:"),
        Expanded(
          child: Slider(
            min: min,
            max: max,
            value: value,
            divisions: divisions,
            label: value.toStringAsFixed(divisions != null ? 0 : 3),
            onChanged: isAnimating ? null : onChanged,
          ),
        ),
        SizedBox(width: 50, child: Text(value.toStringAsFixed(0))),
      ],
    );
  }

  Widget _modeButton(IconData icon, AppMode mode) {
    final prov = context.read<TSPProvider>();
    final active = prov.currentMode == mode;
    return IconButton(
      icon: Icon(icon, color: active ? Colors.amber : Colors.white),
      onPressed: () {
        if (isAnimating) return;
        prov.setMode(active ? AppMode.placingNodes : mode);
        setState(() {});
      },
    );
  }
}
