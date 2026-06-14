import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/task.dart';

/// Tarjeta visual que representa una tarea en la lista (Paso 1: UI/UX).
///
/// Muestra título, descripción, fecha límite y, si aplica, un indicador de
/// ubicación. Permite marcar como completada con un checkbox y expone acciones
/// de editar y eliminar. Usa `Semantics`/tooltips para accesibilidad.
class TaskTile extends StatelessWidget {
  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const TaskTile({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dateFmt = DateFormat("d 'de' MMM, y", 'es');

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              Checkbox(
                value: task.isDone,
                onChanged: (_) => onToggle(),
                semanticLabel: task.isDone
                    ? 'Marcar como pendiente'
                    : 'Marcar como completada',
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        decoration: task.isDone
                            ? TextDecoration.lineThrough
                            : null,
                        color: task.isDone ? scheme.onSurfaceVariant : null,
                      ),
                    ),
                    if (task.description.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        task.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        if (task.dueDate != null)
                          _Chip(
                            icon: Icons.event_outlined,
                            label: dateFmt.format(
                              DateTime.fromMillisecondsSinceEpoch(task.dueDate!),
                            ),
                          ),
                        if (task.hasLocation)
                          _Chip(
                            icon: Icons.location_on_outlined,
                            label: task.locationName ?? 'Ubicación',
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              IconButton(
                tooltip: 'Eliminar tarea',
                icon: Icon(Icons.delete_outline, color: scheme.error),
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pequeña etiqueta con icono usada para los metadatos de la tarea.
class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Chip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: scheme.primary),
        const SizedBox(width: 4),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 160),
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}
