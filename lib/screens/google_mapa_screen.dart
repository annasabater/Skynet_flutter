import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:SkyNet/models/drone_zone.dart';
import 'package:SkyNet/services/drone_zones_service.dart';
import 'package:SkyNet/widgets/map_legend.dart';
import 'package:SkyNet/geolocation.dart';

class GoogleMapaScreen extends StatefulWidget {
  const GoogleMapaScreen({Key? key}) : super(key: key);

  @override
  State<GoogleMapaScreen> createState() => _GoogleMapaScreenState();
}

class _GoogleMapaScreenState extends State<GoogleMapaScreen> {
  // Controlador para el mapa
  final Completer<GoogleMapController> _controller = Completer<GoogleMapController>();
  
  // Ubicación inicial (Madrid)
  static const CameraPosition _kMadrid = CameraPosition(
    target: LatLng(40.4168, -3.7038),
    zoom: 14,
  );
  
  // Estado de la UI
  bool _isLoading = false;
  bool _showZones = true;
  bool _showLegend = true;
  
  // Colección de polígonos para las zonas de drones
  final Set<Polygon> _zonePolygons = {};
  
  // Marcador para la ubicación actual
  final Set<Marker> _markers = {};
  
  @override
  void initState() {
    super.initState();
    _loadZones();
    _tryGetUserLocation();
  }
  
  // Intentar obtener la ubicación del usuario al inicio
  Future<void> _tryGetUserLocation() async {
    try {
      final userPosition = await getCurrentPosition();
      if (userPosition != null && mounted) {
        final googlePosition = convertToGoogleMaps(userPosition);
        if (googlePosition != null) {
          _updateUserLocation(googlePosition);
        }
      }
    } catch (e) {
      print('Error al obtener ubicación inicial: $e');
    }
  }
  
  // Actualizar la ubicación del usuario en el mapa
  void _updateUserLocation(LatLng position) async {
    if (_controller.isCompleted) {
      final controller = await _controller.future;
      controller.animateCamera(CameraUpdate.newLatLng(position));
    }
    
    setState(() {
      _markers.clear();
      _markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: position,
          infoWindow: const InfoWindow(title: 'Tu ubicación'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ),
      );
    });
  }
  
  // Cargar zonas de drones
  Future<void> _loadZones() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }
    
    try {
      // Usamos Madrid como ubicación predeterminada
      final zones = await DroneZonesService().getZonesNearLocation(_kMadrid.target);
      
      if (mounted) {
        setState(() {
          _zonePolygons.clear();
          
          // Convertir las zonas a polígonos de Google Maps
          for (final zone in zones) {
            final points = <LatLng>[];
            
            // Convertir puntos de cualquier tipo a LatLng de Google Maps
            for (final point in zone.points) {
              final googlePoint = convertToGoogleMaps(point);
              if (googlePoint != null) {
                points.add(googlePoint);
              }
            }
            
            if (points.isNotEmpty) {
              _zonePolygons.add(
                Polygon(
                  polygonId: PolygonId(zone.id),
                  points: points,
                  fillColor: zone.color,
                  strokeColor: zone.borderColor,
                  strokeWidth: 2,
                ),
              );
            }
          }
          
          // Añadir un marcador en el centro de Madrid si no hay ubicación actual
          if (_markers.isEmpty) {
            _markers.add(
              Marker(
                markerId: const MarkerId('default_location'),
                position: _kMadrid.target,
                infoWindow: const InfoWindow(title: 'Madrid'),
              ),
            );
          }
          
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error cargando zonas: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  // Intentar obtener la ubicación actual del usuario
  Future<void> _getCurrentLocation() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }
    
    try {
      final userPosition = await getCurrentPosition();
      if (userPosition != null && mounted) {
        final googlePosition = convertToGoogleMaps(userPosition);
        if (googlePosition != null) {
          _updateUserLocation(googlePosition);
        }
      }
    } catch (e) {
      print('Error obteniendo ubicación: $e');
      // Mostrar un mensaje de error al usuario
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo obtener tu ubicación: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
          // Mapa de Google
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: _kMadrid,
            polygons: _showZones ? _zonePolygons : {},
            markers: _markers,
            onMapCreated: (controller) {
              _controller.complete(controller);
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: true,
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
          
          // Controles personalizados
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
                  onPressed: () async {
                    final controller = await _controller.future;
                    controller.animateCamera(CameraUpdate.zoomIn());
                  },
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: 'zoom_out',
                  mini: true,
                  child: const Icon(Icons.remove),
                  onPressed: () async {
                    final controller = await _controller.future;
                    controller.animateCamera(CameraUpdate.zoomOut());
                  },
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: 'my_location',
                  mini: true,
                  child: const Icon(Icons.my_location),
                  onPressed: _getCurrentLocation,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 