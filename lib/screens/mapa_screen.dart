//lib/screens/mapa_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:SkyNet/geolocation.dart';
import 'package:SkyNet/widgets/map_legend.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import '../../services/geojson_service.dart';
import '../widgets/flight_zones_layer.dart';

class MapaScreen extends StatefulWidget {
  const MapaScreen({super.key});

  @override
  State<MapaScreen> createState() => _MapaScreenState();
}

enum TransportMode { walking, driving }

class _MapaScreenState extends State<MapaScreen> {
  TransportMode _transportMode = TransportMode.walking;
  late final _orsApiKey;
  LatLng? _currentPosition;
  bool _loading = true;
  String? _error;
  final MapController _mapController = MapController();
  bool _mapInitialized = false;
  double _currentZoom = 15.0;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _suggestions = [];
  FocusNode _searchFocus = FocusNode();
  String? _selectedFilter = 'Zona Permitida';

  final List<String> _filterOptions = [
    'Zona Restringida',
    'Zona Permitida',
    'Zona Regulada',
    'Mostrar todas las zonas',
    'Limpiar mapa',
  ];

  // Nuevo: punto marcado por el usuario
  LatLng? _markedPoint;
  // Nuevo: puntos de la ruta
  List<LatLng> _routePoints = [];
  // Nuevo: distancia de la ruta en metros
  double? _routeDistance;
  // Nuevo: para mostrar loading en la ruta
  bool _fetchingRoute = false;

  List<FlightZone> _flightZones = [];
  bool _loadingZones = true;

  // Añadir variable para el destino buscado y su display
  String? _searchDestinationName;
  LatLng? _searchDestination;
  bool _showRoute = false;

  // Mejorar el buscador: sugerencias rápidas y debounce
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _orsApiKey = dotenv.env['ORS_API_KEY'] ?? '';
    print('ORS API Key: [38;5;5m$_orsApiKey[0m');
    _getLocation();
    // Cargar zonas desde GeoJSON
    GeoJSONService().loadFlightZones().then((zones) {
      setState(() {
        _flightZones = zones;
        _loadingZones = false;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
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

        // Centrar el mapa en la ubicación actual
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

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      if (value.trim().isEmpty) {
        setState(() => _suggestions = []);
        return;
      }
      setState(() => _loading = true);
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(value)}&format=json&addressdetails=1&limit=7&countrycodes=es',
      );
      try {
        final response = await http.get(url);
        if (response.statusCode == 200) {
          final List data = jsonDecode(response.body);
          setState(() {
            _suggestions = data.cast<Map<String, dynamic>>();
            _loading = false;
          });
        } else {
          setState(() {
            _suggestions = [];
            _loading = false;
          });
        }
      } catch (_) {
        setState(() {
          _suggestions = [];
          _loading = false;
        });
      }
    });
  }

  void _onMapSecondaryTap(TapPosition tapPosition, LatLng latlng) {
    if (_currentPosition != null) {
      final distance = const Distance().as(
        LengthUnit.Meter,
        _currentPosition!,
        latlng,
      );
      final distanceStr =
          distance >= 1000
              ? (distance / 1000).toStringAsFixed(2) + ' km'
              : distance.toStringAsFixed(0) + ' m';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Distancia desde tu ubicación: $distanceStr')),
      );
    }
  }

  // Nuevo: función para obtener la ruta usando OSRM
  Future<void> _getRoute(LatLng from, LatLng to) async {
    setState(() {
      _fetchingRoute = true;
      _routePoints = [];
      _routeDistance = null;
    });
    if (_transportMode == TransportMode.walking) {
      final url = Uri.parse(
        'https://api.openrouteservice.org/v2/directions/foot-walking',
      );
      final body = jsonEncode({
        "coordinates": [
          [from.longitude, from.latitude],
          [to.longitude, to.latitude],
        ],
      });

      try {
        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': _orsApiKey,
          },
          body: body,
        );

        if (response.statusCode != 200) {
          throw Exception('ORS HTTP ${response.statusCode}');
        }

        final data = jsonDecode(response.body);
        final route = data['routes'][0];

        // 1) Distancia en metros
        final distance = (route['summary']['distance'] as num).toDouble();

        // 2) Polyline encodeada
        final encoded = route['geometry'] as String;
        final poly = PolylinePoints();
        final decoded = poly.decodePolyline(encoded);

        // 3) Mapa de PointLatLng → LatLng
        final pts =
            decoded.map((pt) => LatLng(pt.latitude, pt.longitude)).toList();

        setState(() {
          _routeDistance = distance;
          _routePoints = pts;
        });
      } catch (e) {
        print('Error ORS: $e');
        setState(() {
          _routePoints = [];
          _routeDistance = null;
        });
      }
    } else {
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/foot/'
        '${from.longitude},${from.latitude};${to.longitude},${to.latitude}'
        '?overview=full&geometries=geojson',
      );

      try {
        final response = await http.get(url);
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['routes'] != null && data['routes'].isNotEmpty) {
            final route = data['routes'][0];
            final geometry = route['geometry']['coordinates'] as List;
            final distance = route['distance'] as num;
            setState(() {
              _routePoints =
                  geometry
                      .map<LatLng>(
                        (c) => LatLng(
                          (c[1] as num).toDouble(),
                          (c[0] as num).toDouble(),
                        ),
                      )
                      .toList();
              _routeDistance = distance.toDouble();
            });
          }
        }
      } catch (e) {
        setState(() {
          _routePoints = [];
          _routeDistance = null;
        });
      }
    }
    setState(() => _fetchingRoute = false);
  }

  // Nuevo: manejar tap izquierdo en el mapa
  void _onMapTap(TapPosition tapPosition, LatLng latlng) {
    if (_currentPosition != null) {
      setState(() {
        _markedPoint = latlng;
      });
      _getRoute(_currentPosition!, latlng);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa'),
        actions: [
          IconButton(
            icon: Icon(
              Icons.drive_eta,
              color:
                  _transportMode == TransportMode.driving
                      ? Colors.white
                      : Colors.white70,
            ),
            onPressed:
                () => setState(() => _transportMode = TransportMode.driving),
          ),
          IconButton(
            icon: Icon(
              Icons.directions_walk,
              color:
                  _transportMode == TransportMode.walking
                      ? Colors.white
                      : Colors.white70,
            ),
            onPressed:
                () => setState(() => _transportMode = TransportMode.walking),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Filtro de color
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    const Text('Filtrar zonas por color: '),
                    DropdownButton<String>(
                      value: _selectedFilter,
                      items:
                          _filterOptions.map((opt) {
                            return DropdownMenuItem<String>(
                              value: opt,
                              child: Text(opt),
                            );
                          }).toList(),
                      onChanged:
                          (value) => {
                            setState(() {
                              _selectedFilter = value;
                            }),
                          },
                    ),
                    const SizedBox(width: 24),
                    if (_routeDistance != null && _markedPoint != null)
                      Row(
                        children: [
                          Text(
                            'Distancia al punto indicado: '
                            '${_routeDistance! >= 1000 ? (_routeDistance! / 1000).toStringAsFixed(2) + ' km' : _routeDistance!.toStringAsFixed(0) + ' m'}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _markedPoint = null;
                                _routePoints = [];
                                _routeDistance = null;
                              });
                            },
                            icon: const Icon(Icons.clear),
                            label: const Text('Limpiar distancia'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.blue,
                              side: const BorderSide(color: Colors.blue),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              // Mapa
              Expanded(
                child:
                    _loading
                        ? const Center(child: CircularProgressIndicator())
                        : _error != null
                        ? Center(
                          child: Text(
                            _error!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        )
                        : Stack(
                          children: [
                            FlutterMap(
                              mapController: _mapController,
                              options: MapOptions(
                                center:
                                    _currentPosition ??
                                    const LatLng(
                                      41.3851,
                                      2.1734,
                                    ), // Barcelona por defecto
                                zoom: _currentZoom,
                                onMapReady: () {
                                  setState(() {
                                    _mapInitialized = true;
                                  });
                                  if (_currentPosition != null && mounted) {
                                    _mapController.move(
                                      _currentPosition!,
                                      _currentZoom,
                                    );
                                  }
                                },
                                onSecondaryTap:
                                    _onMapSecondaryTap, // <-- Añadido para click derecho
                                onTap: _onMapTap, // <-- Nuevo: tap izquierdo
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate:
                                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName: 'com.example.SkyNet',
                                  tileProvider: NetworkTileProvider(),
                                ),
                                // Zonas de restricción de vuelo
                                if (!_loadingZones)
                                  FlightZonesLayer(
                                    zones: _flightZones.where((zone) {
                                      final tipus = zone.restrictions['tipus']?.toLowerCase();
                                      if (_selectedFilter == null || _selectedFilter == 'Mostrar todas las zonas') return true;
                                      if (_selectedFilter == 'Zona Restringida') return ['restringida','restringido','restricted'].contains(tipus);
                                      if (_selectedFilter == 'Zona Permitida') return ['permitida','permitido','permitted'].contains(tipus);
                                      if (_selectedFilter == 'Zona Regulada') return ['prohibida','prohibido','forbidden'].contains(tipus);
                                      return false;
                                    }).toList(),
                                  ),
                                // Polyline de la ruta
                                if (_routePoints.isNotEmpty)
                                  PolylineLayer(
                                    polylines: [
                                      Polyline(
                                        points: _routePoints,
                                        color: Colors.blue,
                                        strokeWidth: 5,
                                      ),
                                    ],
                                  ),
                                if (_currentPosition != null)
                                  MarkerLayer(
                                    markers: [
                                      Marker(
                                        point: _currentPosition!,
                                        width: 60,
                                        height: 60,
                                        child: const Icon(
                                          Icons.location_pin,
                                          color: Colors.red,
                                          size: 40,
                                        ),
                                      ),
                                    ],
                                  ),
                                // Icono en el punto marcado
                                if (_markedPoint != null)
                                  MarkerLayer(
                                    markers: [
                                      Marker(
                                        point: _markedPoint!,
                                        width: 60,
                                        height: 60,
                                        child: const Icon(
                                          Icons.add_location,
                                          color: Colors.blue,
                                          size: 40,
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                            // Leyenda
                            Positioned(
                              right: 16,
                              top: MediaQuery.of(context).size.height * 0.4,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  MapLegend(),
                                  const SizedBox(height: 12),
                                ],
                              ),
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
                          ],
                        ),
              ),
            ],
          ),
          // Buscador petit a la part superior dreta
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
                      hintText: 'Buscar lloc...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 0,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: _onSearchChanged,
                  ),
                  if (_searchController.text.isNotEmpty &&
                      _suggestions.isNotEmpty &&
                      _searchFocus.hasFocus)
                    Container(
                      width: 350,
                      constraints: const BoxConstraints(maxHeight: 200),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(color: Colors.black26, blurRadius: 4),
                        ],
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _suggestions.length,
                        itemBuilder: (context, index) {
                          final s = _suggestions[index];
                          final display = s['display_name'] ?? '';
                          return ListTile(
                            title: Text(
                              display,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () {
                              final lat = double.tryParse(s['lat'] ?? '');
                              final lon = double.tryParse(s['lon'] ?? '');
                              if (lat != null && lon != null) {
                                final dest = LatLng(lat, lon);
                                _mapController.move(dest, 16);
                                setState(() {
                                  _searchController.text = display;
                                  _suggestions = [];
                                  _searchDestination = dest;
                                  _searchDestinationName = display;
                                  _showRoute = false;
                                  _routePoints = [];
                                  _routeDistance = null;
                                });
                                _searchFocus.unfocus();
                              }
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Mostrar pop-up de destino y botón para calcular ruta
          if (_searchDestination != null && !_showRoute)
            Positioned(
              bottom: 24,
              left: 24,
              right: 24,
              child: Card(
                elevation: 8,
                color: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Destino seleccionado', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blue[900])),
                            const SizedBox(height: 8),
                            if (_searchDestinationName != null)
                              Text(_searchDestinationName!, style: const TextStyle(fontSize: 16)),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.directions),
                        label: const Text('Cómo llegar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () async {
                          if (_currentPosition != null && _searchDestination != null) {
                            await _getRoute(_currentPosition!, _searchDestination!);
                            setState(() {
                              _showRoute = true;
                            });
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            _searchDestination = null;
                            _searchDestinationName = null;
                            _routePoints = [];
                            _routeDistance = null;
                            _showRoute = false;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          // Mostrar pop-up de ruta solo si _showRoute es true
          if (_searchDestination != null && _showRoute && _routePoints.isNotEmpty && _routeDistance != null)
            Positioned(
              bottom: 24,
              left: 24,
              right: 24,
              child: Card(
                elevation: 8,
                color: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Cómo llegar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blue[900])),
                            const SizedBox(height: 8),
                            if (_searchDestinationName != null)
                              Text(_searchDestinationName!, style: const TextStyle(fontSize: 16)),
                            const SizedBox(height: 4),
                            Text('Distancia: '
                              '${_routeDistance! >= 1000 ? (_routeDistance! / 1000).toStringAsFixed(2) + ' km' : _routeDistance!.toStringAsFixed(0) + ' m'}',
                              style: const TextStyle(fontSize: 15)),
                            const SizedBox(height: 4),
                            Text('Tiempo estimado: ' + _getEstimatedTime(_routeDistance!, _transportMode), style: const TextStyle(fontSize: 15)),
                            const SizedBox(height: 4),
                            Text('Modo: ' + (_transportMode == TransportMode.walking ? 'A pie' : 'En coche'), style: const TextStyle(fontSize: 15)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            _searchDestination = null;
                            _searchDestinationName = null;
                            _routePoints = [];
                            _routeDistance = null;
                            _showRoute = false;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _getLocation,
            tooltip: 'Mi ubicació',
            heroTag: 'my-location',
            child: const Icon(Icons.my_location),
          ),
        ],
      ),
    );
  }

  // Añadir función para calcular tiempo estimado
  String _getEstimatedTime(double distance, TransportMode mode) {
    // Velocidad media: a pie 5km/h, en coche 40km/h
    final speed = mode == TransportMode.walking ? 5.0 : 40.0;
    final hours = distance / 1000 / speed;
    final mins = (hours * 60).round();
    if (mins < 60) return '$mins min';
    final h = mins ~/ 60;
    final m = mins % 60;
    return '$h h $m min';
  }
}