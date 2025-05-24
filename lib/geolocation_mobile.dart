// lib/geolocation_mobile.dart

import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart'; // o el paquete que uses para LatLng

/// Devuelve la posición usando Geolocator en iOS/Android.
/// Puede devolver null si hay algún error o se deniegan los permisos.
Future<LatLng?> getCurrentPosition() async {
  try {
    // 1) Comprueba servicios y permisos...
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('Servicios de localización desactivados.');
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      print('Permiso de localización denegado.');
      return null;
    }
    
    Position pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    // ¡Aquí es donde mapeas Position → LatLng!
    return LatLng(pos.latitude, pos.longitude);
  } catch (e) {
    print('Error obteniendo ubicación: $e');
    return null;
  }
}
