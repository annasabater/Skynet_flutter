import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart' as latlng2;
import 'package:http/http.dart' as http;
import '../models/drone_zone.dart';

class DroneZonesService {
  // Singleton pattern
  static final DroneZonesService _instance = DroneZonesService._internal();
  factory DroneZonesService() => _instance;
  DroneZonesService._internal();
  
  // Cache para no tener que cargar datos cada vez
  List<DroneZone>? _cachedZones;
  
  // Obtiene zonas desde datos reales o simulados
  Future<List<DroneZone>> getZonesNearLocation(dynamic location) async {
    // Si ya tenemos datos en caché, los devolvemos inmediatamente
    if (_cachedZones != null && _cachedZones!.isNotEmpty) {
      return _cachedZones!;
    }
    
    try {
      // Primero intentamos cargar datos reales
      final zones = await _loadFromAssets();
      if (zones.isNotEmpty) {
        _cachedZones = zones;
        return zones;
      }
    } catch (e) {
      print('Error cargando datos reales: $e');
      // Si falla, usamos datos simulados
    }
    
    // Extraemos la latitud y longitud de cualquier tipo de ubicación
    double lat = 0.0;
    double lng = 0.0;
    
    if (location is latlng2.LatLng) {
      lat = location.latitude;
      lng = location.longitude;
    } else if (location is dynamic && location.latitude != null && location.longitude != null) {
      // Soporte para Google Maps LatLng o cualquier objeto con lat/lng
      lat = location.latitude;
      lng = location.longitude;
    }
    
    // Si llegamos aquí, usamos datos simulados
    return _getSimulatedZones(lat, lng);
  }
  
  // Carga datos desde archivo JSON local (simulando datos de ENAIRE/AESA)
  Future<List<DroneZone>> _loadFromAssets() async {
    try {
      // Simulamos datos reales con datos ficticios predefinidos 
      // (en una app real cargaríamos desde un archivo JSON o una API)
      final List<DroneZone> zones = [
        // Zonas prohibidas - aeropuertos principales de España
        DroneZone(
          id: 'mad',
          name: 'Aeropuerto Madrid-Barajas',
          type: DroneZoneType.prohibida,
          description: 'Espacio aéreo controlado CTR',
          points: [
            latlng2.LatLng(40.4983, -3.5676),
            latlng2.LatLng(40.5083, -3.5476),
            latlng2.LatLng(40.4883, -3.5276),
            latlng2.LatLng(40.4783, -3.5476),
          ],
        ),
        DroneZone(
          id: 'bcn',
          name: 'Aeropuerto Barcelona-El Prat',
          type: DroneZoneType.prohibida,
          description: 'Espacio aéreo controlado CTR',
          points: [
            latlng2.LatLng(41.3097, 2.0786),
            latlng2.LatLng(41.3197, 2.0986),
            latlng2.LatLng(41.2997, 2.1186),
            latlng2.LatLng(41.2897, 2.0986),
          ],
        ),
        
        // Zonas restringidas - bases militares
        DroneZone(
          id: 'military1',
          name: 'Base Militar Torrejón',
          type: DroneZoneType.restringida,
          description: 'Requiere autorización previa',
          points: [
            latlng2.LatLng(40.4867, -3.4414),
            latlng2.LatLng(40.4967, -3.4214),
            latlng2.LatLng(40.4767, -3.4014),
            latlng2.LatLng(40.4667, -3.4214),
          ],
        ),
        
        // Zonas permitidas - parques y áreas recreativas
        DroneZone(
          id: 'park1',
          name: 'Parque del Retiro',
          type: DroneZoneType.permitida,
          description: 'Vuelo permitido por debajo de 120m',
          points: [
            latlng2.LatLng(40.4150, -3.6892),
            latlng2.LatLng(40.4250, -3.6792),
            latlng2.LatLng(40.4150, -3.6692),
            latlng2.LatLng(40.4050, -3.6792),
          ],
        ),
      ];
      
      await Future.delayed(const Duration(milliseconds: 300)); // Simular carga de red
      return zones;
    } catch (e) {
      print('Error cargando zonas desde assets: $e');
      return [];
    }
  }
  
  // Datos simulados generados alrededor de la ubicación del usuario
  List<DroneZone> _getSimulatedZones(double lat, double lng) {
    return [
      // Zona prohibida (aeropuerto ficticio)
      DroneZone(
        id: 'zona1',
        name: 'Aeropuerto Internacional',
        type: DroneZoneType.prohibida,
        description: 'Zona prohibida para drones: Espacio aéreo controlado',
        points: [
          latlng2.LatLng(lat + 0.02, lng - 0.02),
          latlng2.LatLng(lat + 0.02, lng + 0.02),
          latlng2.LatLng(lat - 0.01, lng + 0.02),
          latlng2.LatLng(lat - 0.01, lng - 0.02),
        ],
      ),
      
      // Zona restringida (área militar ficticia)
      DroneZone(
        id: 'zona2',
        name: 'Zona Militar',
        type: DroneZoneType.restringida,
        description: 'Requiere autorización especial',
        points: [
          latlng2.LatLng(lat - 0.015, lng - 0.03),
          latlng2.LatLng(lat - 0.015, lng - 0.01),
          latlng2.LatLng(lat - 0.035, lng - 0.01),
          latlng2.LatLng(lat - 0.035, lng - 0.03),
        ],
      ),
      
      // Zona permitida (parque ficticio)
      DroneZone(
        id: 'zona3',
        name: 'Parque Municipal',
        type: DroneZoneType.permitida,
        description: 'Vuelo permitido por debajo de 120m de altura',
        points: [
          latlng2.LatLng(lat + 0.01, lng - 0.04),
          latlng2.LatLng(lat + 0.03, lng - 0.04),
          latlng2.LatLng(lat + 0.03, lng - 0.06),
          latlng2.LatLng(lat + 0.01, lng - 0.06),
        ],
      ),
    ];
  }
  
  // Para una versión futura - cargar datos GeoJSON de ENAIRE
  Future<List<DroneZone>> loadFromENAIRE() async {
    try {
      // En una app real, aquí haríamos una llamada a la API de ENAIRE
      // Ejemplo: https://drones.enaire.es/api/...
      final response = await http.get(Uri.parse('https://ejemplo-api-enaire.com/zonas'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Procesar los datos GeoJSON
        // ... implementación futura
      }
      
      return [];
    } catch (e) {
      print('Error cargando datos de ENAIRE: $e');
      return [];
    }
  }
} 