import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:math';

class Municipio {
  final String nombre;
  final double lat;
  final double lon;
  final int poblacion;
  Municipio(this.nombre, this.lat, this.lon, this.poblacion);
}

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

    // Nombre robusto
    String nombre = json['properties']?['zona'] as String? ??
        json['properties']?['message'] as String? ??
        'Zona sin nombre';
    // Si sigue siendo 'Zona sin nombre', añade un id único
    if (nombre == 'Zona sin nombre') {
      nombre += ' #' + (json['properties']?['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString());
    }

    return FlightZone(
      name: nombre,
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

  List<Municipio>? _municipios;

  Future<void> _loadMunicipios() async {
    if (_municipios != null) return;
    // Leer coordenadas
    final csvGeo = await rootBundle.loadString('assets/geojson/Municipis_Catalunya_Geo.csv');
    final geoLines = const LineSplitter().convert(csvGeo);
    final geoHeader = geoLines.first.split(',');
    final idxNom = geoHeader.indexOf('Nom');
    final idxLat = geoHeader.indexOf('Latitud');
    final idxLon = geoHeader.indexOf('Longitud');
    Map<String, LatLng> coords = {};
    for (var l in geoLines.skip(1)) {
      final parts = l.split(',');
      if (parts.length > idxLat && parts.length > idxLon && parts.length > idxNom) {
        final nombre = parts[idxNom].replaceAll('"', '').trim();
        final lat = double.tryParse(parts[idxLat].replaceAll('"', '').trim());
        final lon = double.tryParse(parts[idxLon].replaceAll('"', '').trim());
        if (lat != null && lon != null) {
          coords[nombre] = LatLng(lat, lon);
        }
      }
    }
    // Leer población
    final csvPob = await rootBundle.loadString('assets/geojson/poblacio_catalunya.csv');
    final pobLines = const LineSplitter().convert(csvPob);
    final pobHeader = pobLines.first.split(';');
    final idxMun = pobHeader.indexOf('municipi');
    final idxSexe = pobHeader.indexOf('sexe');
    final idxConc = pobHeader.indexOf('concepte');
    final idxValor = pobHeader.indexOf('valor');
    Map<String, int> poblacion = {};
    for (var l in pobLines.skip(1)) {
      final parts = l.split(';');
      if (parts.length > idxMun && parts.length > idxSexe && parts.length > idxConc && parts.length > idxValor) {
        if (parts[idxSexe].trim() == 'total' && parts[idxConc].trim() == 'població') {
          final nombre = parts[idxMun].replaceAll('"', '').trim();
          final valor = int.tryParse(parts[idxValor].replaceAll('"', '').trim()) ?? 0;
          poblacion[nombre] = (poblacion[nombre] ?? 0) + valor;
        }
      }
    }
    // Unir datos
    _municipios = [];
    for (final nombre in coords.keys) {
      final pop = poblacion[nombre] ?? 0;
      final lat = coords[nombre]!.latitude;
      final lon = coords[nombre]!.longitude;
      _municipios!.add(Municipio(nombre, lat, lon, pop));
    }
  }

  Future<List<FlightZone>> loadFlightZones() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/geojson/dades.geojson');
      final Map<String, dynamic> geojsonMap = json.decode(jsonString);
      final List<dynamic> features = geojsonMap['features'] as List;
      List<dynamic> realFeatures = features;
      if (features.isNotEmpty && features[0]['type'] == 'FeatureCollection') {
        realFeatures = features[0]['features'] as List;
      }
      List<FlightZone> zones = [];
      int i = 0;
      for (var feature in realFeatures) {
        final f = feature as Map<String, dynamic>;
        // Asignar color fijo o alterno para que se vean
        f['properties'] ??= {};
        f['properties']['tipus'] = i % 3 == 0 ? 'permitida' : (i % 3 == 1 ? 'restringida' : 'prohibida');
        zones.add(FlightZone.fromJson(f));
        i++;
      }
      print('Cargadas zonas: ' + zones.length.toString());
      return zones;
    } catch (e) {
      print('Error cargando zonas de vuelo: $e');
      return [];
    }
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