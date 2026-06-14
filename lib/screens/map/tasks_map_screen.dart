import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../models/task.dart';
import '../../services/task_repository.dart';

/// Mapa que muestra **todas las tareas con ubicación** del usuario (Paso 3).
///
/// Se alimenta del mismo stream en tiempo real del repositorio, por lo que los
/// marcadores se actualizan automáticamente al crear o mover tareas. Al tocar
/// un marcador se muestra el título y la descripción de la tarea.
class TasksMapScreen extends StatefulWidget {
  final TaskRepository repo;
  const TasksMapScreen({super.key, required this.repo});

  @override
  State<TasksMapScreen> createState() => _TasksMapScreenState();
}

class _TasksMapScreenState extends State<TasksMapScreen> {
  static const LatLng _fallback = LatLng(10.391, -75.479); // Cartagena

  /// Construye los marcadores a partir de las tareas geolocalizadas.
  Set<Marker> _buildMarkers(List<Task> tasks) {
    return tasks.where((t) => t.hasLocation).map((t) {
      return Marker(
        markerId: MarkerId(t.id),
        position: LatLng(t.latitude!, t.longitude!),
        infoWindow: InfoWindow(
          title: t.title,
          snippet: t.description.isNotEmpty
              ? t.description
              : (t.locationName ?? 'Tarea'),
        ),
        // Color distinto si la tarea ya está completada.
        icon: BitmapDescriptor.defaultMarkerWithHue(
          t.isDone ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed,
        ),
      );
    }).toSet();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tareas en el mapa')),
      body: StreamBuilder<List<Task>>(
        stream: widget.repo.watchTasks(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final tasks = snapshot.data ?? [];
          final located = tasks.where((t) => t.hasLocation).toList();
          final markers = _buildMarkers(tasks);

          // Centramos en la primera tarea con ubicación, si existe.
          final initial = located.isNotEmpty
              ? LatLng(located.first.latitude!, located.first.longitude!)
              : _fallback;

          return Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(target: initial, zoom: 12),
                markers: markers,
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
              ),

              // Aviso cuando no hay tareas geolocalizadas.
              if (located.isEmpty)
                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Ninguna tarea tiene ubicación todavía. '
                              'Agrega una ubicación al crear o editar una tarea.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
