// lib/geolocation_web.dart

import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as latlng2;

/// Devuelve la posición actual utilizando Geolocator para web.
/// Puede devolver null si hay algún error o se deniegan los permisos.
Future<latlng2.LatLng?> getCurrentPosition() async {
  try {
    // Verificamos que la geolocalización esté disponible
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('Servicios de localización desactivados.');
      return null;
    }

    // Verificamos permisos
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied || 
        permission == LocationPermission.deniedForever) {
      print('Permiso de localización denegado.');
      return null;
    }
    
    // Obtenemos la posición
    Position pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    // Convertimos Position a LatLng
    return latlng2.LatLng(pos.latitude, pos.longitude);
  } catch (e) {
    print('Error obteniendo ubicación: $e');
    return null;
  }
} 