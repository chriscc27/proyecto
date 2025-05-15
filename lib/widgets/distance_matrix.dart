import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proyecto/models/distance.dart';
import 'package:proyecto/models/node.dart';
import '../providers/tsp_provider.dart';

class DistanceMatrix extends StatelessWidget {
  const DistanceMatrix({super.key});

  @override
  Widget build(BuildContext context) {
    final tspProvider = Provider.of<TSPProvider>(context);
    final nodes = tspProvider.nodes;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          DataColumn(label: Text('Desde/Hasta')),
          for (final node in nodes) DataColumn(label: Text(node.name)),
        ],
        rows: nodes.map((fromNode) {
          return DataRow(
            cells: [
              DataCell(Text(fromNode.name)),
              for (final toNode in nodes)
                DataCell(
                  fromNode.id == toNode.id
                      ? Text('0', style: TextStyle(color: Colors.grey))
                      : DistanceCell(fromNode: fromNode, toNode: toNode),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class DistanceCell extends StatefulWidget {
  final Node fromNode;
  final Node toNode;

  const DistanceCell({super.key, required this.fromNode, required this.toNode});

  @override
  _DistanceCellState createState() => _DistanceCellState();
}

class _DistanceCellState extends State<DistanceCell> {
  final controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final tspProvider = Provider.of<TSPProvider>(context, listen: false);
    
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(hintText: 'Distancia'),
      onChanged: (value) {
        if (value.isNotEmpty) {
          tspProvider.addDistance(
            Distance(
              fromNodeId: widget.fromNode.id,
              toNodeId: widget.toNode.id,
              value: double.parse(value),
            )
          );
        }
      },
    );
  }
}