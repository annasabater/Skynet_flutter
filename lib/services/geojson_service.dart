import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

class FlightZone {
  final String name;
  final bool droneAllowed;
  final List<LatLng> points;
  final Map<String, dynamic> restrictions;

  FlightZone({
    required this.name,
    required this.droneAllowed,
    required this.points,
    required this.restrictions,
  });

  factory FlightZone.fromJson(Map<String, dynamic> json) {
    final coordinates = (json['geometry']['coordinates'][0] as List)
        .map((coord) => LatLng(coord[1] as double, coord[0] as double))
        .toList();

    return FlightZone(
      name: json['properties']['zona'] as String? ?? 'Zona sin nombre',
      droneAllowed: (json['properties']['tipus'] as String?)?.toLowerCase() != 'prohibida',
      points: coordinates,
      restrictions: json['properties'],
    );
  }
}

class GeoJSONService {
  static final GeoJSONService _instance = GeoJSONService._internal();
  factory GeoJSONService() => _instance;
  GeoJSONService._internal();

  Future<List<FlightZone>> loadFlightZones() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/geojson/zguas_aero.geojson');
      final Map<String, dynamic> geojsonMap = json.decode(jsonString);
      final List<dynamic> features = geojsonMap['features'] as List;
      List<dynamic> realFeatures = features;
      if (features.isNotEmpty && features[0]['type'] == 'FeatureCollection') {
        realFeatures = features[0]['features'] as List;
      }
      // Procesar cada feature para asignar el tipo según población
      List<Future<FlightZone>> zoneFutures = [];
      for (var feature in realFeatures) {
        final f = feature as Map<String, dynamic>;
        zoneFutures.add(_clasificaZonaPorPoblacion(f));
      }
      return await Future.wait(zoneFutures);
    } catch (e) {
      print('Error cargando zonas de vuelo: $e');
      return [];
    }
  }

  Future<FlightZone> _clasificaZonaPorPoblacion(Map<String, dynamic> f) async {
    // Calcular centroide
    final coords = (f['geometry']['coordinates'][0] as List)
        .map((coord) => LatLng(coord[1] as double, coord[0] as double))
        .toList();
    double lat = 0, lon = 0;
    for (var p in coords) {
      lat += p.latitude;
      lon += p.longitude;
    }
    lat /= coords.length;
    lon /= coords.length;
    String tipus = 'no clasificada';
    try {
      final url = Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon&zoom=10&addressdetails=1');
      final response = await http.get(url, headers: {'User-Agent': 'SkyNetApp/1.0'}).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['address'] ?? {};
        final city = address['city'] ?? address['town'] ?? address['village'] ?? address['municipality'] ?? null;
        if (city != null) {
          // Consultar población con GeoNames
          final geoUrl = Uri.parse('https://secure.geonames.org/searchJSON?q=$city&maxRows=1&username=demo');
          final geoResp = await http.get(geoUrl).timeout(const Duration(seconds: 5));
          if (geoResp.statusCode == 200) {
            final geoData = json.decode(geoResp.body);
            if (geoData['totalResultsCount'] > 0) {
              final pop = geoData['geonames'][0]['population'] ?? 0;
              if (pop is int && pop > 50000) {
                tipus = 'prohibida';
              } else if (pop is int && pop > 10000) {
                tipus = 'restringida';
              } else if (pop is int && pop > 0) {
                tipus = 'permitida';
              }
            }
          }
        }
      }
    } catch (e) {
      print('Error clasificando zona: $e');
      // Si falla, dejar como no clasificada
    }
    f['properties']['tipus'] = tipus;
    return FlightZone.fromJson(f);
  }

  bool isPointInFlightZone(LatLng point, List<FlightZone> zones) {
    for (var zone in zones) {
      if (_isPointInPolygon(point, zone.points)) {
        return true;
      }
    }
    return false;
  }

  bool _isPointInPolygon(LatLng point, List<LatLng> polygon) {
    bool inside = false;
    
    for (int i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
      final xi = polygon[i].longitude;
      final yi = polygon[i].latitude;
      final xj = polygon[j].longitude;
      final yj = polygon[j].latitude;
      
      final intersect = ((yi > point.latitude) != (yj > point.latitude)) &&
          (point.longitude < (xj - xi) * (point.latitude - yi) / (yj - yi) + xi);
      
      if (intersect) inside = !inside;
    }
    
    return inside;
  }

  FlightZone? getZoneAtPoint(LatLng point, List<FlightZone> zones) {
    for (var zone in zones) {
      if (_isPointInPolygon(point, zone.points)) {
        return zone;
      }
    }
    return null;
  }

  // Método para obtener el nombre o descripción de una zona
  String getZoneInfo(FlightZone zone) {
    return zone.name;
  }

  // Método para verificar si una zona permite el vuelo de drones
  bool isFlightAllowed(FlightZone zone) {
    return zone.droneAllowed;
  }

  // Método para obtener las restricciones de una zona
  Map<String, dynamic> getZoneRestrictions(FlightZone zone) {
    return zone.restrictions;
  }
} 