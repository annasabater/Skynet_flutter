//lib/screens/mapa_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:SkyNet/geolocation.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/drone_zone.dart';
import '../services/drone_zones_service.dart';
import '../widgets/map_legend.dart';

class MapaScreen extends StatefulWidget {
  const MapaScreen({Key? key}) : super(key: key);

  @override
  State<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends State<MapaScreen> {
  // Coordenadas predeterminadas (Madrid)
  final LatLng _defaultPosition = const LatLng(40.4168, -3.7038);
  late LatLng _currentPosition;
  final MapController _mapController = MapController();
  bool _isLoading = true;
  bool _showLegend = true;
  bool _showZones = true;
  List<DroneZone> _zones = [];
  
  @override
  void initState() {
    super.initState();
    _currentPosition = _defaultPosition;
    _initMap();
  }
  
  Future<void> _initMap() async {
    // Primero cargamos con la posición predeterminada
    _loadZones(_defaultPosition);
    
    // Luego intentamos obtener la ubicación real
    try {
      final position = await getCurrentPosition();
      if (mounted && position != null) {
        setState(() {
          _currentPosition = position;
          _mapController.move(_currentPosition, 14);
        });
        // Recargamos las zonas con la ubicación real
        _loadZones(position);
      }
    } catch (e) {
      print('Error al obtener ubicación: $e');
      // Continuamos con la ubicación predeterminada
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _loadZones(LatLng position) async {
    try {
      final zones = await DroneZonesService().getZonesNearLocation(position);
      if (mounted) {
        setState(() {
          _zones = zones;
        });
      }
    } catch (e) {
      print('Error al cargar zonas: $e');
    }
  }
  
  List<Polygon> _buildZonePolygons() {
    return _zones.map((zone) => Polygon(
      points: zone.points.map((point) {
        if (point is LatLng) {
          return point;
        } else if (point is dynamic && point.latitude != null && point.longitude != null) {
          return LatLng(point.latitude, point.longitude);
        } else {
          // Valor predeterminado en caso de error
          return const LatLng(0, 0);
        }
      }).toList(),
      color: zone.color,
      borderColor: zone.borderColor,
      borderStrokeWidth: 2,
    )).toList();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de Vuelo de Drones'),
        actions: [
          IconButton(
            icon: Icon(_showZones ? Icons.layers : Icons.layers_outlined),
            tooltip: 'Mostrar/Ocultar Zonas',
            onPressed: () {
              setState(() {
                _showZones = !_showZones;
              });
            },
          ),
          IconButton(
            icon: Icon(_showLegend ? Icons.info : Icons.info_outline),
            tooltip: 'Mostrar/Ocultar Leyenda',
            onPressed: () {
              setState(() {
                _showLegend = !_showLegend;
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Mapa principal
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              center: _currentPosition,
              zoom: 14,
              interactiveFlags: InteractiveFlag.all,
            ),
            children: [
              // Capa de mapa base
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.skynet.app',
              ),
              // Zonas de vuelo
              if (_showZones && _zones.isNotEmpty)
                PolygonLayer(
                  polygons: _buildZonePolygons(),
                ),
              // Marcador de ubicación
              MarkerLayer(
                markers: [
                  Marker(
                    point: _currentPosition,
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.my_location,
                      color: Colors.blue,
                      size: 30,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          // Indicador de carga
          if (_isLoading)
            Container(
              color: Colors.white.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
            
          // Leyenda
          if (_showLegend)
            const Positioned(
              right: 16,
              bottom: 16,
              child: MapLegend(),
            ),
            
          // Controles
          Positioned(
            left: 16,
            bottom: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton(
                  heroTag: 'zoom_in',
                  mini: true,
                  child: const Icon(Icons.add),
                  onPressed: () {
                    _mapController.move(
                      _mapController.center, 
                      _mapController.zoom + 1
                    );
                  },
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: 'zoom_out',
                  mini: true,
                  child: const Icon(Icons.remove),
                  onPressed: () {
                    _mapController.move(
                      _mapController.center, 
                      _mapController.zoom - 1
                    );
                  },
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: 'my_location',
                  mini: true,
                  child: const Icon(Icons.my_location),
                  onPressed: () async {
                    setState(() => _isLoading = true);
                    try {
                      final position = await getCurrentPosition();
                      if (position != null && mounted) {
                        setState(() {
                          _currentPosition = position;
                          _mapController.move(position, 15);
                        });
                      }
                    } catch (e) {
                      // Mostrar error si es necesario
                    } finally {
                      if (mounted) setState(() => _isLoading = false);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
} 