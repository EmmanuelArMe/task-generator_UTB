import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

/// Servicio de **geolocalización** (Paso 3).
///
/// Encapsula la lógica de permisos y obtención de la posición del dispositivo
/// con el paquete `geolocator`, además de la conversión opcional de
/// coordenadas a una dirección legible con `geocoding`.
class LocationService {
  /// Obtiene la ubicación actual del dispositivo.
  ///
  /// Gestiona, en orden: (1) que el servicio de ubicación esté activo,
  /// (2) que el usuario conceda permisos. Lanza [LocationException] con un
  /// mensaje claro si algo falla, para que la UI lo muestre.
  Future<Position> getCurrentPosition() async {
    // 1. ¿Está activado el GPS / servicio de ubicación del sistema?
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationException(
        'El servicio de ubicación está desactivado. Actívalo en los ajustes.',
      );
    }

    // 2. Revisar y solicitar permisos.
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw LocationException('Permiso de ubicación denegado.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw LocationException(
        'El permiso de ubicación fue denegado permanentemente. '
        'Habilítalo manualmente en los ajustes de la app.',
      );
    }

    // 3. Obtener la posición con precisión alta.
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  }

  /// Convierte unas coordenadas en una dirección legible (calle, ciudad).
  /// Devuelve `null` si no se pudo resolver (no es un error crítico).
  Future<String?> getAddressFromCoordinates(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isEmpty) return null;
      final p = placemarks.first;
      // Construimos una dirección compacta evitando campos vacíos.
      final parts = [p.street, p.locality, p.administrativeArea]
          .where((s) => s != null && s.isNotEmpty)
          .toList();
      return parts.isEmpty ? null : parts.join(', ');
    } catch (_) {
      return null;
    }
  }
}

/// Excepción de dominio para errores de ubicación con mensaje en español.
class LocationException implements Exception {
  final String message;
  LocationException(this.message);

  @override
  String toString() => message;
}
