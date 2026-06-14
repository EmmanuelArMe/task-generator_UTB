import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../services/location_service.dart';

/// Resultado devuelto por el selector de ubicación.
class PickedLocation {
  final LatLng position;
  final String? address;
  const PickedLocation(this.position, this.address);
}

/// Pantalla con **Google Maps** para elegir una ubicación (Paso 3).
///
/// El usuario puede:
///  - Tocar el mapa para colocar el marcador.
///  - Pulsar el botón de ubicación para centrar en su posición actual (GPS).
///  - Confirmar la selección, que se devuelve a la pantalla anterior junto con
///    una dirección legible (geocodificación inversa).
class LocationPickerScreen extends StatefulWidget {
  final LatLng? initial;
  const LocationPickerScreen({super.key, this.initial});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  // Posición por defecto: Cartagena de Indias (UTB) si no hay nada más.
  static const LatLng _fallback = LatLng(10.391, -75.479);

  GoogleMapController? _controller;
  LatLng? _selected;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    _selected = widget.initial;
  }

  /// Obtiene la ubicación actual del dispositivo y centra el mapa en ella.
  Future<void> _goToCurrentLocation() async {
    setState(() => _locating = true);
    try {
      final pos = await context.read<LocationService>().getCurrentPosition();
      final target = LatLng(pos.latitude, pos.longitude);
      setState(() => _selected = target);
      await _controller?.animateCamera(
        CameraUpdate.newLatLngZoom(target, 16),
      );
    } on LocationException catch (e) {
      _showError(e.message);
    } catch (_) {
      _showError('No se pudo obtener la ubicación.');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  /// Confirma la selección, resolviendo la dirección legible antes de volver.
  Future<void> _confirm() async {
    if (_selected == null) {
      _showError('Toca el mapa para elegir un punto.');
      return;
    }
    final address = await context
        .read<LocationService>()
        .getAddressFromCoordinates(_selected!.latitude, _selected!.longitude);
    if (mounted) {
      Navigator.of(context).pop(PickedLocation(_selected!, address));
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final initialTarget = _selected ?? widget.initial ?? _fallback;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Elegir ubicación'),
        actions: [
          TextButton.icon(
            onPressed: _confirm,
            icon: const Icon(Icons.check),
            label: const Text('Listo'),
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: initialTarget,
              zoom: 14,
            ),
            onMapCreated: (c) => _controller = c,
            onTap: (pos) => setState(() => _selected = pos),
            myLocationEnabled: true,
            myLocationButtonEnabled: false, // Usamos un botón propio.
            markers: {
              if (_selected != null)
                Marker(
                  markerId: const MarkerId('seleccion'),
                  position: _selected!,
                  draggable: true,
                  onDragEnd: (pos) => setState(() => _selected = pos),
                ),
            },
          ),

          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.touch_app_outlined),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Toca el mapa para marcar el lugar, o usa el botón '
                        'para tu ubicación actual.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: _locating ? null : _goToCurrentLocation,
        tooltip: 'Mi ubicación actual',
        child: _locating
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              )
            : const Icon(Icons.my_location),
      ),
    );
  }
}
