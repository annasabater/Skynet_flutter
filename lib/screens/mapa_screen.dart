//lib/screens/mapa_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:SkyNet/geolocation.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';
import 'package:SkyNet/widgets/map_legend.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:SkyNet/services/geojson_service.dart';
import 'package:SkyNet/widgets/flight_zones_layer.dart';
import 'package:SkyNet/widgets/flight_zone_info.dart';

class MapaScreen extends StatefulWidget {
  const MapaScreen({super.key});

  @override
  State<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends State<MapaScreen> {
  final GeoJSONService _geoJSONService = GeoJSONService();
  List<FlightZone> _zones = [];
  FlightZone? _selectedZone;
  final MapController _mapController = MapController();
  LatLng? _currentPosition;
  bool _loading = true;
  String? _error;
  bool _mapInitialized = false;
  double _currentZoom = 10.0;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _suggestions = [];
  bool _searchLoading = false;
  FocusNode _searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadZones();
    _getLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _loadZones() async {
    final zones = await _geoJSONService.loadFlightZones();
    setState(() {
      _zones = zones;
    });
  }

  Future<void> _getLocation() async {
    setState(() => _loading = true);
    try {
      final latLng = await getCurrentPosition();
      if (mounted) {
        setState(() {
          _currentPosition = latLng as LatLng?;
          _loading = false;
        });
        if (_currentPosition != null && _mapInitialized && mounted) {
          _mapController.move(_currentPosition!, _currentZoom);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error obteniendo ubicación: $e';
          _loading = false;
        });
      }
      print('Error obteniendo ubicación: $e');
    }
  }

  void _zoomIn() {
    if (_mapInitialized && mounted) {
      setState(() {
        _currentZoom = _currentZoom + 1;
        if (_currentZoom > 18) _currentZoom = 18;
      });
      _mapController.move(_mapController.center, _currentZoom);
    }
  }

  void _zoomOut() {
    if (_mapInitialized && mounted) {
      setState(() {
        _currentZoom = _currentZoom - 1;
        if (_currentZoom < 3) _currentZoom = 3;
      });
      _mapController.move(_mapController.center, _currentZoom);
    }
  }

  void _onSearchChanged(String value) async {
    if (value.trim().isEmpty) {
      setState(() => _suggestions = []);
      return;
    }
    setState(() => _searchLoading = true);
    final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(value)}&format=json&addressdetails=1&limit=5&countrycodes=es');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        setState(() {
          _suggestions = data.cast<Map<String, dynamic>>();
          _searchLoading = false;
        });
      } else {
        setState(() {
          _suggestions = [];
          _searchLoading = false;
        });
      }
    } catch (_) {
      setState(() {
        _suggestions = [];
        _searchLoading = false;
      });
    }
  }

  void _onZoneTap(FlightZone zone) {
    setState(() {
      _selectedZone = zone;
    });
    final center = _calculateZoneCenter(zone.points);
    _mapController.move(center, 13.0);
  }

  LatLng _calculateZoneCenter(List<LatLng> points) {
    double lat = 0;
    double lon = 0;
    for (var point in points) {
      lat += point.latitude;
      lon += point.longitude;
    }
    return LatLng(lat / points.length, lon / points.length);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de Zonas de Vuelo'),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(41.3851, 2.1734),
              initialZoom: _currentZoom,
              onMapReady: () {
                setState(() {
                  _mapInitialized = true;
                });
                if (_currentPosition != null && mounted) {
                  _mapController.move(_currentPosition!, _currentZoom);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.app',
              ),
              FlightZonesLayer(
                zones: _zones,
                onZoneTap: _onZoneTap,
              ),
              if (_currentPosition != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _currentPosition!,
                      width: 60,
                      height: 60,
                      child: const Icon(Icons.location_pin, color: Colors.red, size: 40),
                    ),
                  ],
                ),
            ],
          ),
          // Buscador
          Positioned(
            top: 16,
            right: 32,
            child: SizedBox(
              width: 350,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  TextField(
                    controller: _searchController,
                    focusNode: _searchFocus,
                    decoration: InputDecoration(
                      hintText: 'Buscar lugar...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: _onSearchChanged,
                  ),
                  if (_searchController.text.isNotEmpty && _suggestions.isNotEmpty && _searchFocus.hasFocus)
                    Container(
                      width: 350,
                      constraints: const BoxConstraints(maxHeight: 200),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _suggestions.length,
                        itemBuilder: (context, index) {
                          final s = _suggestions[index];
                          final display = s['display_name'] ?? '';
                          return ListTile(
                            title: Text(display, maxLines: 2, overflow: TextOverflow.ellipsis),
                            onTap: () {
                              final lat = double.tryParse(s['lat'] ?? '');
                              final lon = double.tryParse(s['lon'] ?? '');
                              if (lat != null && lon != null) {
                                _mapController.move(LatLng(lat, lon), 16);
                              }
                              setState(() {
                                _searchController.text = display;
                                _suggestions = [];
                              });
                              _searchFocus.unfocus();
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Leyenda
          Positioned(
            right: 16,
            top: MediaQuery.of(context).size.height * 0.4,
            child: MapLegend(),
          ),
          // Botones de zoom
          Positioned(
            left: 16,
            bottom: 90,
            child: Column(
              children: [
                FloatingActionButton(
                  mini: true,
                  onPressed: _zoomIn,
                  child: const Icon(Icons.add),
                  heroTag: 'zoom-in',
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  mini: true,
                  onPressed: _zoomOut,
                  child: const Icon(Icons.remove),
                  heroTag: 'zoom-out',
                ),
              ],
            ),
          ),
          // Botón de ubicación
          Positioned(
            left: 16,
            bottom: 16,
            child: FloatingActionButton(
              onPressed: _getLocation,
              tooltip: 'Mi ubicación',
              child: const Icon(Icons.my_location),
              heroTag: 'my-location',
            ),
          ),
          // Info de zona
          if (_selectedZone != null)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: FlightZoneInfo(
                zone: _selectedZone!,
                onClose: () => setState(() => _selectedZone = null),
              ),
            ),
        ],
      ),
    );
  }
} 