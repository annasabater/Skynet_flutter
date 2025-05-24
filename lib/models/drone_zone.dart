import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' as latlng2;

enum DroneZoneType {
  permesa,
  regulada,
  prohibida,
}

class DroneZone {
  final String id;
  final String name;
  final DroneZoneType type;
  final List<dynamic> points;  // Puede contener LatLng de diferentes tipos
  final String? description;

  DroneZone({
    required this.id,
    required this.name,
    required this.type,
    required this.points,
    this.description,
  });

  Color get color {
    switch (type) {
      case DroneZoneType.permesa:
        return Colors.green.withOpacity(0.3);
      case DroneZoneType.regulada:
        return Colors.orange.withOpacity(0.3);
      case DroneZoneType.prohibida:
        return Colors.red.withOpacity(0.3);
    }
  }

  Color get borderColor {
    switch (type) {
      case DroneZoneType.permesa:
        return Colors.green;
      case DroneZoneType.regulada:
        return Colors.orange;
      case DroneZoneType.prohibida:
        return Colors.red;
    }
  }

  String get typeLabel {
    switch (type) {
      case DroneZoneType.permesa:
        return "Zona permesa";
      case DroneZoneType.regulada:
        return "Zona regulada";
      case DroneZoneType.prohibida:
        return "Zona prohibida";
    }
  }
  
  // Método de fábrica para crear zonas desde diferentes tipos de coordenadas
  factory DroneZone.fromLatLng2({
    required String id,
    required String name,
    required DroneZoneType type,
    required List<latlng2.LatLng> points,
    String? description,
  }) {
    return DroneZone(
      id: id,
      name: name,
      type: type,
      points: points,
      description: description,
    );
  }
} 