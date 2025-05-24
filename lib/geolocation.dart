// lib/geolocation.dart

// Importamos ambas implementaciones y exportamos la apropiada
// según la plataforma (web o móvil)
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:latlong2/latlong.dart' as latlng2;

// Si estamos en web (dart:html existe), usaremos geolocation_web.dart
// Si no (móvil), usaremos geolocation_mobile.dart
export 'geolocation_mobile.dart'
    if (dart.library.html) 'geolocation_web.dart';

// Función de utilidad para convertir entre diferentes tipos de LatLng
LatLng? convertToGoogleMaps(dynamic position) {
  if (position == null) return null;
  
  if (position is LatLng) {
    return position;
  } else if (position is latlng2.LatLng) {
    return LatLng(position.latitude, position.longitude);
  } else if (position is dynamic && 
            position.latitude != null && 
            position.longitude != null) {
    return LatLng(position.latitude, position.longitude);
  }
  
  return null;
}

latlng2.LatLng? convertToLatLng2(dynamic position) {
  if (position == null) return null;
  
  if (position is latlng2.LatLng) {
    return position;
  } else if (position is LatLng) {
    return latlng2.LatLng(position.latitude, position.longitude);
  } else if (position is dynamic && 
            position.latitude != null && 
            position.longitude != null) {
    return latlng2.LatLng(position.latitude, position.longitude);
  }
  
  return null;
}