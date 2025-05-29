import 'package:flutter/material.dart';
import 'package:SkyNet/services/geojson_service.dart';

class FlightZoneInfo extends StatelessWidget {
  final FlightZone zone;
  final VoidCallback onClose;

  const FlightZoneInfo({
    super.key,
    required this.zone,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  zone.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: onClose,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  zone.droneAllowed ? Icons.check_circle : Icons.cancel,
                  color: zone.droneAllowed ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  zone.droneAllowed 
                      ? 'Vuelo permitido'
                      : 'Vuelo no permitido',
                  style: TextStyle(
                    color: zone.droneAllowed ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Restricciones:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...zone.restrictions.entries.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Text(
                    '${entry.key}: ',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(entry.value.toString()),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
} 