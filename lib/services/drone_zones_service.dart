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
      print('Error carregant dades reals: $e');
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
      // Simulamos datos reales con datos ficticios predefinidos para Cataluña
      final List<DroneZone> zones = [
        // Zonas prohibidas - aeropuertos principales de Cataluña
        DroneZone(
          id: 'bcn',
          name: 'Aeroport Barcelona-El Prat',
          type: DroneZoneType.prohibida,
          description: 'Espai aeri controlat CTR',
          points: [
            latlng2.LatLng(41.3097, 2.0786),
            latlng2.LatLng(41.3297, 2.0986),
            latlng2.LatLng(41.2997, 2.1186),
            latlng2.LatLng(41.2797, 2.0986),
          ],
        ),
        DroneZone(
          id: 'girona',
          name: 'Aeroport Girona-Costa Brava',
          type: DroneZoneType.prohibida,
          description: 'Espai aeri controlat CTR',
          points: [
            latlng2.LatLng(41.9000, 2.7500),
            latlng2.LatLng(41.9200, 2.7700),
            latlng2.LatLng(41.8800, 2.7900),
            latlng2.LatLng(41.8600, 2.7700),
          ],
        ),
        
        // Zonas reguladas - zonas próximas a aeródromos pequeños e infraestructuras críticas
        DroneZone(
          id: 'sabadell',
          name: 'Aeròdrom de Sabadell',
          type: DroneZoneType.regulada,
          description: 'Requereix autorització prèvia',
          points: [
            latlng2.LatLng(41.5200, 2.1000),
            latlng2.LatLng(41.5400, 2.1200),
            latlng2.LatLng(41.5000, 2.1400),
            latlng2.LatLng(41.4800, 2.1200),
          ],
        ),
        DroneZone(
          id: 'montseny',
          name: 'Parc Natural del Montseny',
          type: DroneZoneType.regulada,
          description: 'Zona natural amb restriccions',
          points: [
            latlng2.LatLng(41.7500, 2.3800),
            latlng2.LatLng(41.8500, 2.4000),
            latlng2.LatLng(41.8300, 2.5000),
            latlng2.LatLng(41.7300, 2.4800),
          ],
        ),
        
        // Zonas permitidas - áreas rurales sin población
        DroneZone(
          id: 'rural1',
          name: 'Zona Rural Plana de Vic',
          type: DroneZoneType.permesa,
          description: 'Vol permès complint normativa',
          points: [
            latlng2.LatLng(41.9300, 2.2500),
            latlng2.LatLng(41.9500, 2.2700),
            latlng2.LatLng(41.9300, 2.2900),
            latlng2.LatLng(41.9100, 2.2700),
          ],
        ),
        DroneZone(
          id: 'rural2',
          name: 'Camps Agrícoles Baix Llobregat',
          type: DroneZoneType.permesa,
          description: 'Vol permès fins a 120m',
          points: [
            latlng2.LatLng(41.3200, 2.0000),
            latlng2.LatLng(41.3400, 2.0200),
            latlng2.LatLng(41.3200, 2.0400),
            latlng2.LatLng(41.3000, 2.0200),
          ],
        ),
      ];
      
      await Future.delayed(const Duration(milliseconds: 300)); // Simular carga de red
      return zones;
    } catch (e) {
      print('Error carregant zones des d\'assets: $e');
      return [];
    }
  }
  
  // Datos simulados generados alrededor de la ubicación del usuario
  List<DroneZone> _getSimulatedZones(double lat, double lng) {
    return [
      // Zona prohibida (aeropuerto ficticio)
      DroneZone(
        id: 'zona1',
        name: 'Aeroport Internacional',
        type: DroneZoneType.prohibida,
        description: 'Zona prohibida per a drons: Espai aeri controlat',
        points: [
          latlng2.LatLng(lat + 0.02, lng - 0.02),
          latlng2.LatLng(lat + 0.02, lng + 0.02),
          latlng2.LatLng(lat - 0.01, lng + 0.02),
          latlng2.LatLng(lat - 0.01, lng - 0.02),
        ],
      ),
      
      // Zona regulada (área con restricciones)
      DroneZone(
        id: 'zona2',
        name: 'Zona d\'Infraestructura Crítica',
        type: DroneZoneType.regulada,
        description: 'Requereix autorització especial',
        points: [
          latlng2.LatLng(lat - 0.015, lng - 0.03),
          latlng2.LatLng(lat - 0.015, lng - 0.01),
          latlng2.LatLng(lat - 0.035, lng - 0.01),
          latlng2.LatLng(lat - 0.035, lng - 0.03),
        ],
      ),
      
      // Zona permitida (área rural ficticia)
      DroneZone(
        id: 'zona3',
        name: 'Àrea Rural',
        type: DroneZoneType.permesa,
        description: 'Vol permès per sota de 120m d\'alçada',
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
      print('Error carregant dades d\'ENAIRE: $e');
      return [];
    }
  }
} 