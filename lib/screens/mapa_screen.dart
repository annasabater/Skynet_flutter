//lib/screens/mapa_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../widgets/language_selector.dart';

// Import condicional para web
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

// Ubicación por defecto: EETAC UPC Campus del Baix Llobregat
const LatLng defaultLocation = LatLng(41.2756, 1.9881);

class MapaScreen extends StatefulWidget {
  const MapaScreen({Key? key}) : super(key: key);

  @override
  State<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends State<MapaScreen> {
  LatLng _currentPosition = defaultLocation;
  bool _loading = true;
  String? _error;
  bool _usandoUbicacionPredeterminada = true;

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  Future<void> _getLocation() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    
    try {
      if (kIsWeb) {
        // Enfoque para Web
        _getLocationWeb();
      } else {
        // Enfoque para móvil
        await _getLocationMobile();
      }
    } catch (e) {
      _usarUbicacionPredeterminada('Error general: $e');
    }
  }
  
  void _getLocationWeb() {
    try {
      html.window.navigator.geolocation.getCurrentPosition().then((pos) {
        final latitude = pos.coords?.latitude as double?;
        final longitude = pos.coords?.longitude as double?;
        
        if (latitude != null && longitude != null) {
          setState(() {
            _currentPosition = LatLng(latitude, longitude);
            _usandoUbicacionPredeterminada = false;
            _loading = false;
          });
        } else {
          _usarUbicacionPredeterminada('No se pudo obtener la ubicación');
        }
      }).catchError((e) {
        _usarUbicacionPredeterminada('Error web: $e');
      });
    } catch (e) {
      _usarUbicacionPredeterminada('Error obteniendo la ubicación (web): $e');
    }
  }
  
  Future<void> _getLocationMobile() async {
    final localizations = AppLocalizations.of(context)!;
    try {
      // Verificar si los servicios de ubicación están habilitados
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _usarUbicacionPredeterminada(localizations.locationError);
        return;
      }
      
      // Verificar permisos
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _usarUbicacionPredeterminada(localizations.locationDenied);
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        _usarUbicacionPredeterminada(localizations.locationDenied);
        return;
      }
      
      // Obtener ubicación con alta precisión
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );
      
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _usandoUbicacionPredeterminada = false;
        _loading = false;
      });
    } catch (e) {
      _usarUbicacionPredeterminada(localizations.locationError);
    }
  }
  
  void _usarUbicacionPredeterminada(String error) {
    setState(() {
      _currentPosition = defaultLocation;
      _usandoUbicacionPredeterminada = true;
      _error = error;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.map),
        actions: [
          const LanguageSelector(),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_usandoUbicacionPredeterminada && _error != null)
                  Container(
                    color: Colors.amber[100],
                    padding: const EdgeInsets.all(8),
                    width: double.infinity,
                    child: Row(
                      children: [
                        const Icon(Icons.info, color: Colors.amber),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            localizations.usingDefaultLocation,
                            style: const TextStyle(color: Colors.black87),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: _getLocation,
                          tooltip: localizations.retry,
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: FlutterMap(
                    options: MapOptions(
                      center: _currentPosition,
                      zoom: 15,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                        subdomains: const ['a', 'b', 'c'],
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _currentPosition,
                            width: 60,
                            height: 60,
                            child: Column(
                              children: [
                                const Icon(Icons.location_pin, color: Colors.red, size: 40),
                                if (_usandoUbicacionPredeterminada)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(4),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: const Text(
                                      'EETAC',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
} 