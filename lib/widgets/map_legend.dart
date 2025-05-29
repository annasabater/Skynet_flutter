import 'package:flutter/material.dart';

class MapLegend extends StatelessWidget {
  const MapLegend({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Llegenda', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            _buildColorLegendItem(Colors.green, 'Zona Permitida'),
            const SizedBox(height: 4),
            _buildColorLegendItem(Colors.orange, 'Zona Restringida'),
            const SizedBox(height: 4),
            _buildColorLegendItem(Colors.red, 'Zona Prohibida'),
            const SizedBox(height: 4),
            _buildColorLegendItem(Colors.grey, 'Zona No Clasificada'),
            const SizedBox(height: 8),
            _buildIconLegendItem(Icons.location_pin, Colors.red, 'La teva ubicació'),
          ],
        ),
      ),
    );
  }

  Widget _buildColorLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }

  Widget _buildIconLegendItem(IconData icon, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }
} 