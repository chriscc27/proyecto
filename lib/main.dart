import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import 'package:proyecto/providers/tsp_provider.dart';
import 'package:proyecto/widgets/node_creator.dart';
import 'package:proyecto/models/node.dart';
import 'package:proyecto/algorithms/genetic_tsp.dart';
import 'package:proyecto/widgets/route_painter.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => TSPProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TSP Solver Genético',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const HomeScreen(),
    );
  }
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

  // Animación
  bool isAnimating = false;
  bool isPaused = false;
  double animationSpeed = 1.0;
  int currentStep = 0;
  Timer? _timer;

  // Parámetros ajustables
  int populationSize = 100;
  double mutationRate = 0.01;
  int maxGenerations = 1000;

  // Controlador del mapa para mover/centrar el mapa si quieres
  final MapController _mapController = MapController();

  void _showErrorMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _runAlgorithm(BuildContext context) async {
    final tspProvider = Provider.of<TSPProvider>(context, listen: false);
    final nodes = tspProvider.nodes;

    if (nodes.length < 2) {
      _showErrorMessage(context, '¡Necesitas al menos 2 nodos!');
      return;
    }
    if (selectedStartNode == null) {
      _showErrorMessage(context, 'Selecciona un nodo de inicio.');
      return;
    }

    final tsp = GeneticTSP(
      nodes: nodes,
      populationSize: populationSize,
      mutationRate: mutationRate,
      maxGenerations: maxGenerations,
    );
    final route = await tsp.run();

    final startIndex = route.indexWhere(
      (node) => node.id == selectedStartNode!.id,
    );
    if (startIndex == -1) {
      _showErrorMessage(
        context,
        'El nodo inicial no se encuentra en la ruta generada.',
      );
      return;
    }

    final reorderedRoute = [
      ...route.sublist(startIndex),
      ...route.sublist(0, startIndex),
      route[startIndex], // cerrar ciclo
    ];

    setState(() {
      fullRoute = reorderedRoute;
      currentStep = 0;
      totalDistance = tsp.totalDistanceForRoute(reorderedRoute);
      isAnimating = true;
      isPaused = false;
    });

    _startAnimation();
  }

  void _startAnimation() {
    _timer?.cancel();
    _timer = Timer.periodic(
      Duration(milliseconds: (1000 ~/ animationSpeed).toInt()),
      (timer) {
        if (isPaused) return;

        setState(() {
          if (currentStep < fullRoute.length - 2) {
            currentStep++;
          } else {
            timer.cancel();
            isAnimating = false;
          }
        });
      },
    );
  }

  void _pauseOrResumeAnimation() {
    setState(() {
      isPaused = !isPaused;
    });
  }

  void _resetAnimation() {
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
  Widget build(BuildContext context) {
    final tspProvider = Provider.of<TSPProvider>(context);
    final nodes = tspProvider.nodes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('TSP con Algoritmo Genético'),
        centerTitle: true,
        actions: _buildModeButtons(context),
      ),
      body: Column(
        children: [
          if (nodes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  const Text("Desde: "),
                  DropdownButton<Node>(
                    value: selectedStartNode,
                    hint: const Text("Selecciona un nodo"),
                    items:
                        nodes
                            .map(
                              (node) => DropdownMenuItem<Node>(
                                value: node,
                                child: Text(node.name),
                              ),
                            )
                            .toList(),
                    onChanged:
                        isAnimating
                            ? null
                            : (Node? newNode) {
                              setState(() {
                                selectedStartNode = newNode;
                              });
                            },
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed:
                        (selectedStartNode == null || isAnimating)
                            ? null
                            : () => _runAlgorithm(context),
                    child: const Text("Resolver TSP"),
                  ),
                ],
              ),
            ),

          // Parámetros ajustables UI
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Parámetros del algoritmo:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                // Population Size
                Row(
                  children: [
                    const Text("Tamaño población: "),
                    Expanded(
                      child: Slider(
                        value: populationSize.toDouble(),
                        min: 10,
                        max: 500,
                        divisions: 49,
                        label: populationSize.toString(),
                        onChanged:
                            isAnimating
                                ? null
                                : (value) {
                                  setState(() {
                                    populationSize = value.toInt();
                                  });
                                },
                      ),
                    ),
                    SizedBox(
                      width: 50,
                      child: Text(
                        populationSize.toString(),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),

                // Mutation Rate
                Row(
                  children: [
                    const Text("Tasa mutación: "),
                    Expanded(
                      child: Slider(
                        value: mutationRate,
                        min: 0.0,
                        max: 0.1,
                        divisions: 100,
                        label: mutationRate.toStringAsFixed(3),
                        onChanged:
                            isAnimating
                                ? null
                                : (value) {
                                  setState(() {
                                    mutationRate = value;
                                  });
                                },
                      ),
                    ),
                    SizedBox(
                      width: 50,
                      child: Text(
                        mutationRate.toStringAsFixed(3),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),

                // Max Generations
                Row(
                  children: [
                    const Text("Máx. generaciones: "),
                    Expanded(
                      child: Slider(
                        value: maxGenerations.toDouble(),
                        min: 100,
                        max: 10000,
                        divisions: 99,
                        label: maxGenerations.toString(),
                        onChanged:
                            isAnimating
                                ? null
                                : (value) {
                                  setState(() {
                                    maxGenerations = value.toInt();
                                  });
                                },
                      ),
                    ),
                    SizedBox(
                      width: 70,
                      child: Text(
                        maxGenerations.toString(),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (totalDistance > 0)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                "Distancia total: ${totalDistance.toStringAsFixed(2)}",
              ),
            ),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Velocidad: "),
              Slider(
                value: animationSpeed,
                min: 0.5,
                max: 5.0,
                divisions: 9,
                label: "${animationSpeed.toStringAsFixed(1)}x",
                onChanged:
                    isAnimating
                        ? null
                        : (value) {
                          setState(() {
                            animationSpeed = value;
                          });
                        },
              ),
              IconButton(
                icon: Icon(isPaused ? Icons.play_arrow : Icons.pause),
                onPressed: isAnimating ? _pauseOrResumeAnimation : null,
              ),
              IconButton(
                icon: const Icon(Icons.stop),
                onPressed: isAnimating ? _resetAnimation : null,
              ),
            ],
          ),

          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    center: LatLng(-16.5, -68.15), // Centro en La Paz, Bolivia
                    zoom: 13.0,
                    maxZoom: 18,
                    minZoom: 3,
                    interactiveFlags: InteractiveFlag.all,
                    onTap: (tapPosition, point) {
                      final tspProvider = Provider.of<TSPProvider>(
                        context,
                        listen: false,
                      );
                      if (tspProvider.currentMode == AppMode.placingNodes) {
                        final newId =
                            DateTime.now().millisecondsSinceEpoch.toString();
                        final newNode = Node(
                          id: newId,
                          name: 'Nodo ${tspProvider.nodes.length + 1}',
                          x: point.latitude,
                          y: point.longitude,
                        );
                        tspProvider.addNode(newNode);
                      }
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c'],
                      userAgentPackageName: 'com.example.tsp_app',
                    ),

                    // MARKERS
                    MarkerLayer(
                      markers:
                          tspProvider.nodes
                              .map(
                                (node) => Marker(
                                  point: LatLng(node.x, node.y),
                                  width: 40,
                                  height: 40,
                                  child: GestureDetector(
                                    onTap: () {
                                      tspProvider.handleNodeTap(node, context);
                                    },
                                    child: Icon(
                                      Icons.location_on,
                                      color:
                                          tspProvider.bestRoute?.contains(
                                                    node,
                                                  ) ==
                                                  true
                                              ? Colors.green
                                              : Colors.red,
                                      size: 30,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                    ),

                    // Ruta animada con CustomPainter
                    if (fullRoute.length > 1 && currentStep > 0)
                      CustomPaint(
                        painter: RoutePainter(
                          route: fullRoute.sublist(0, currentStep + 1),
                        ),
                        child: Container(),
                      ),
                  ],
                ),

                // Overlay botones modo y controles
                if (tspProvider.currentMode == AppMode.placingNodes)
                  Positioned(
                    bottom: 80,
                    left: 20,
                    child: ElevatedButton(
                      child: const Text('Salir modo agregar nodos'),
                      onPressed: () => tspProvider.setMode(AppMode.none),
                    ),
                  ),
              ],
            ),
          ),

          // Mensajes o información extra
          Container(
            padding: const EdgeInsets.all(8),
            width: double.infinity,
            color: Colors.grey[200],
            child: Text(
              'Modo actual: ${tspProvider.currentMode.name}\n'
              'Nodos: ${nodes.length}',
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildModeButtons(BuildContext context) {
    final tspProvider = Provider.of<TSPProvider>(context, listen: false);
    return [
      IconButton(
        icon: const Icon(Icons.add_location_alt_outlined),
        tooltip: 'Agregar nodos',
        color:
            tspProvider.currentMode == AppMode.placingNodes
                ? Colors.white
                : Colors.white70,
        onPressed: () {
          if (isAnimating) return;
          if (tspProvider.currentMode == AppMode.placingNodes) {
            tspProvider.setMode(AppMode.none);
          } else {
            tspProvider.setMode(AppMode.placingNodes);
          }
        },
      ),
      IconButton(
        icon: const Icon(Icons.clear),
        tooltip: 'Limpiar nodos',
        onPressed: () {
          if (isAnimating) return;
          
          setState(() {
            selectedStartNode = null;
            fullRoute = [];
            currentStep = 0;
            totalDistance = 0;
          });
        },
      ),
    ];
  }
}
