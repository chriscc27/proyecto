import 'package:flutter/material.dart';
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
        fontFamily: 'Roboto',
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[800],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
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
  bool isAnimating = false;
  bool isPaused = false;
  double animationSpeed = 1.0;
  int currentStep = 0;
  Timer? _timer;
  int populationSize = 100;
  double mutationRate = 0.01;
  int maxGenerations = 1000;
  double curveLevel = 20; 

  // Clave para obtener tamaño del contenedor
  final GlobalKey _interactiveViewerKey = GlobalKey();

  EdgeInsets _boundaryMargin = EdgeInsets.zero;

  void _showErrorMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[800],
        behavior: SnackBarBehavior.floating,
      ),
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
      route[startIndex],
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
          if (currentStep < fullRoute.length - 1) {
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

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Ayuda de Controles'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Distancia: Muestra la distancia total actual de la ruta.',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: const [
                      Icon(Icons.play_arrow, size: 20),
                      SizedBox(width: 4),
                      Icon(Icons.pause, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text('Pausa o reanuda la animación de la ruta.'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: const [
                      Icon(Icons.stop, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Detiene y reinicia la animación, limpiando la ruta.',
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  const Text(
                    'Controles de nodos',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: const [
                      Icon(Icons.add_circle, size: 20, color: Colors.blue),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Añadir Nodo: Activa el modo para poner nodos tocando el mapa.',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: const [
                      Icon(Icons.delete, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Eliminar Nodo: Activa el modo para eliminar nodos tocando el mapa.',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: const [
                      Icon(Icons.settings, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Parámetros: Abre la configuración para ajustar tamaño de población, tasa de mutación, generaciones, velocidad de animación y tamaño de curva',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: const [
                      Icon(Icons.delete_sweep, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Limpiar Nodos: Elimina todos los nodos y reinicia la ruta y animación.',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                child: const Text('Cerrar'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
    );
  }

  void _showParametersDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Parámetros del Algoritmo'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setModalState) {
              return SingleChildScrollView(
                child: _buildParametersPanel(setModalState),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }


  void _calculateBoundaryMargin(BoxConstraints constraints) {

    final width = constraints.maxWidth;
    final height = constraints.maxHeight;

    const imageWidth = 1080.0;
    const imageHeight = 1920.0;

    double horizontalMargin = 0;
    double verticalMargin = 0;

    if (imageWidth > width) {
      horizontalMargin = 0;
    } else {
      horizontalMargin = (width - imageWidth) / 2;
    }

    if (imageHeight > height) {
      verticalMargin = 0;
    } else {
      verticalMargin = (height - imageHeight) / 2;
    }

    const marginPadding = 0;

    setState(() {
      _boundaryMargin = EdgeInsets.symmetric(
        horizontal: horizontalMargin + marginPadding,
        vertical: verticalMargin + marginPadding,
      );
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
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text(
          'TSP Genético',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue[800]!, Colors.blue[400]!],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: Colors.white),
            onPressed: _showParametersDialog,
            tooltip: 'Parámetros',
          ),
          IconButton(
            icon: Icon(Icons.delete_sweep, color: Colors.white),
            onPressed: () {
              final tspProvider = Provider.of<TSPProvider>(
                context,
                listen: false,
              );
              tspProvider.clearNodes();
              setState(() {
                fullRoute = [];
                totalDistance = 0;
                selectedStartNode = null;
                currentStep = 0;
                isAnimating = false;
                isPaused = false;
              });
            },
            tooltip: 'Limpiar nodos',
          ),
          ..._buildModeButtons(context),
        ],
      ),
      body: Column(
        children: [
          if (nodes.isNotEmpty)
            Material(
              elevation: 4,
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<Node>(
                            value: selectedStartNode,
                            icon: const Icon(
                              Icons.arrow_drop_down,
                              color: Colors.blueAccent,
                              size: 28,
                            ),
                            iconSize: 28,
                            elevation: 16,
                            isExpanded: true,
                            dropdownColor: Colors.white,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            hint: const Text(
                              'Selecciona nodo inicial',
                              style: TextStyle(color: Colors.grey),
                            ),
                            items:
                                nodes.map((node) {
                                  return DropdownMenuItem<Node>(
                                    value: node,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                      child: Text(node.name),
                                    ),
                                  );
                                }).toList(),
                            onChanged:
                                isAnimating
                                    ? null
                                    : (Node? newNode) {
                                      setState(() {
                                        selectedStartNode = newNode;
                                      });
                                    },
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.play_circle_fill, size: 20),
                      label: const Text('Resolver'),
                      onPressed:
                          (selectedStartNode == null || isAnimating)
                              ? null
                              : () => _runAlgorithm(context),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _calculateBoundaryMargin(constraints);
                });

                return InteractiveViewer(
                  key: _interactiveViewerKey,
                  minScale: 1.0,
                  maxScale: 5.0,
                  panEnabled: true,
                  boundaryMargin: _boundaryMargin,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Image.asset(
                          'assets/images/mapa.png',
                          fit: BoxFit.fill,
                        ),
                      ),
                      CustomPaint(
                        painter: RoutePainter(
                          route: fullRoute,
                          currentStep: currentStep,
                          showDistances: true,
                          useCurves: true,
                          curveLevel: curveLevel,  
                        ),
                        size: Size.infinite,
                      ),
                      const NodeCreator(),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text(
              "Distancia: ${totalDistance.toStringAsFixed(2)} km",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
              ),
            ),
            IconButton(
              icon: Icon(isPaused ? Icons.play_arrow : Icons.pause, size: 28),
              color: Colors.blue[800],
              onPressed: isAnimating ? _pauseOrResumeAnimation : null,
              tooltip: isPaused ? 'Reanudar animación' : 'Pausar animación',
            ),
            IconButton(
              icon: const Icon(Icons.stop, size: 28),
              color: Colors.blue[800],
              onPressed: isAnimating ? _resetAnimation : null,
              tooltip: 'Detener animación',
            ),
            IconButton(
              icon: const Icon(Icons.help_outline, size: 28),
              color: Colors.blue[800],
              onPressed: _showHelpDialog,
              tooltip: 'Ayuda',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParametersPanel(StateSetter setModalState) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildParameterSlider(
          label: 'Tamaño Población',
          value: populationSize.toDouble(),
          min: 10,
          max: 500,
          divisions: 49,
          formatValue: (v) => v.toInt().toString(),
          onChanged: (v) {
            setModalState(() => populationSize = v.toInt());
            setState(() {}); 
          },
        ),
        _buildParameterSlider(
          label: 'Tasa de Mutación',
          value: mutationRate,
          min: 0.0,
          max: 0.1,
          divisions: 100,
          formatValue: (v) => v.toStringAsFixed(3),
          onChanged: (v) {
            setModalState(() => mutationRate = v);
            setState(() {});
          },
        ),
        _buildParameterSlider(
          label: 'Máx. Generaciones',
          value: maxGenerations.toDouble(),
          min: 100,
          max: 10000,
          divisions: 99,
          formatValue: (v) => v.toInt().toString(),
          onChanged: (v) {
            setModalState(() => maxGenerations = v.toInt());
            setState(() {});
          },
        ),
        _buildParameterSlider(
          label: 'Velocidad Animación',
          value: animationSpeed,
          min: 0.1,
          max: 5,
          divisions: 49,
          formatValue: (v) => v.toStringAsFixed(1),
          onChanged: (v) {
            setModalState(() => animationSpeed = v);
            if (isAnimating && !isPaused) {
              _startAnimation();
            }
            setState(() {});
          },
        ),
        _buildParameterSlider(
          label: 'Nivel de Curva',
          value: curveLevel,
          min: 0.0,
          max: 100.0,
          divisions: 10,
          formatValue: (v) => v.toStringAsFixed(2),
          onChanged: (v) {
            setModalState(() => curveLevel = v);
            setState(() {}); 
          },
        ),
      ],
    );
  }

  Widget _buildParameterSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String Function(double) formatValue,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ${formatValue(value)}'),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            label: formatValue(value),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildModeButtons(BuildContext context) {
    final tspProvider = Provider.of<TSPProvider>(context);
    return [
      IconButton(
        icon: Icon(
          tspProvider.currentMode == AppMode.placingNodes
              ? Icons.add_circle
              : Icons.add_circle_outline,
          color: Colors.white,
        ),
        tooltip: 'Modo Añadir Nodo',
        onPressed: () => tspProvider.setMode(AppMode.placingNodes),
      ),
      IconButton(
        icon: Icon(
          tspProvider.currentMode == AppMode.deletingNodes
              ? Icons.delete
              : Icons.delete_outline,
          color: Colors.white,
        ),
        tooltip: 'Modo Eliminar Nodo',
        onPressed: () => tspProvider.setMode(AppMode.deletingNodes),
      ),
    ];
  }
}
