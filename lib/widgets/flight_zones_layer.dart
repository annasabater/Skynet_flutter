import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:SkyNet/services/geojson_service.dart';

class FlightZonesLayer extends StatelessWidget {
  final List<FlightZone> zones;
  final Function(FlightZone) onZoneTap;

  const FlightZonesLayer({
    super.key,
    required this.zones,
    required this.onZoneTap,
  });

  @override
  Widget build(BuildContext context) {
    Color getZoneColor(String? tipus) {
      switch (tipus?.toLowerCase()) {
        case 'permitida':
        case 'permitido':
        case 'permitted':
          return Colors.green.withOpacity(0.2);
        case 'restringida':
        case 'restringido':
        case 'restricted':
          return Colors.orange.withOpacity(0.2);
        case 'prohibida':
        case 'prohibido':
        case 'forbidden':
          return Colors.red.withOpacity(0.2);
        default:
          return Colors.grey.withOpacity(0.2);
      }
    }
    Color getBorderColor(String? tipus) {
      switch (tipus?.toLowerCase()) {
        case 'permitida':
        case 'permitido':
        case 'permitted':
          return Colors.green;
        case 'restringida':
        case 'restringido':
        case 'restricted':
          return Colors.orange;
        case 'prohibida':
        case 'prohibido':
        case 'forbidden':
          return Colors.red;
        default:
          return Colors.grey;
      }
    }
    return PolygonLayer(
      polygons: zones.map((zone) {
        final tipus = zone.restrictions['tipus'] as String?;
        return Polygon(
          points: zone.points,
          color: getZoneColor(tipus),
          borderColor: getBorderColor(tipus),
          borderStrokeWidth: 2,
          isFilled: true,
        );
      }).toList(),
    );
  }
} 