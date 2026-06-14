import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

import '../../models/task.dart';
import '../../services/task_repository.dart';
import '../../utils/validators.dart';
import '../map/location_picker_screen.dart';

/// Formulario para **crear o editar** una tarea (Pasos 3 y 4).
///
/// Permite definir título, descripción, fecha límite y una ubicación opcional
/// (elegida en un mapa). Al guardar, escribe en Firebase Realtime Database a
/// través de [TaskRepository].
class TaskFormScreen extends StatefulWidget {
  final TaskRepository repo;

  /// Si se pasa una tarea existente, el formulario entra en modo edición.
  final Task? existing;

  const TaskFormScreen({super.key, required this.repo, this.existing});

  bool get isEditing => existing != null;

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;

  DateTime? _dueDate;
  LatLng? _location;
  String? _locationName;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final t = widget.existing;
    _titleCtrl = TextEditingController(text: t?.title ?? '');
    _descCtrl = TextEditingController(text: t?.description ?? '');
    if (t?.dueDate != null) {
      _dueDate = DateTime.fromMillisecondsSinceEpoch(t!.dueDate!);
    }
    if (t != null && t.hasLocation) {
      _location = LatLng(t.latitude!, t.longitude!);
      _locationName = t.locationName;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  /// Abre el selector de fecha límite.
  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      locale: const Locale('es'),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  /// Abre el mapa para elegir una ubicación.
  Future<void> _pickLocation() async {
    final result = await Navigator.of(context).push<PickedLocation>(
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(initial: _location),
      ),
    );
    if (result != null) {
      setState(() {
        _location = result.position;
        _locationName = result.address;
      });
    }
  }

  /// Valida y guarda la tarea (crea o actualiza).
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      if (widget.isEditing) {
        // Actualización: conservamos id y fecha de creación originales.
        final updated = widget.existing!.copyWith(
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          dueDate: _dueDate?.millisecondsSinceEpoch,
          clearDueDate: _dueDate == null,
          latitude: _location?.latitude,
          longitude: _location?.longitude,
          locationName: _locationName,
          clearLocation: _location == null,
        );
        await widget.repo.updateTask(updated);
      } else {
        final task = Task(
          id: '', // Lo asigna Realtime Database (push id).
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          createdAt: DateTime.now().millisecondsSinceEpoch,
          dueDate: _dueDate?.millisecondsSinceEpoch,
          latitude: _location?.latitude,
          longitude: _location?.longitude,
          locationName: _locationName,
        );
        await widget.repo.addTask(task);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEditing
                ? 'Tarea actualizada.'
                : 'Tarea creada correctamente.'),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('No se pudo guardar la tarea.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat("d 'de' MMMM, y", 'es');

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Editar tarea' : 'Nueva tarea'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _titleCtrl,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Título',
                    prefixIcon: Icon(Icons.title),
                  ),
                  validator: (v) =>
                      Validators.required(v, field: 'El título'),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _descCtrl,
                  minLines: 3,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: 'Descripción (opcional)',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.notes),
                  ),
                ),
                const SizedBox(height: 16),

                _SelectorCard(
                  icon: Icons.event_outlined,
                  title: 'Fecha límite',
                  value: _dueDate == null
                      ? 'Sin fecha'
                      : dateFmt.format(_dueDate!),
                  onTap: _pickDate,
                  onClear: _dueDate == null
                      ? null
                      : () => setState(() => _dueDate = null),
                ),
                const SizedBox(height: 12),

                _SelectorCard(
                  icon: Icons.location_on_outlined,
                  title: 'Ubicación',
                  value: _location == null
                      ? 'Sin ubicación'
                      : (_locationName ??
                          '${_location!.latitude.toStringAsFixed(4)}, '
                              '${_location!.longitude.toStringAsFixed(4)}'),
                  onTap: _pickLocation,
                  onClear: _location == null
                      ? null
                      : () => setState(() {
                            _location = null;
                            _locationName = null;
                          }),
                ),
                const SizedBox(height: 28),

                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(widget.isEditing
                      ? 'Guardar cambios'
                      : 'Crear tarea'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Tarjeta reutilizable tipo "selector" (fecha / ubicación) con valor y
/// acciones de elegir y limpiar.
class _SelectorCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _SelectorCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: scheme.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontSize: 13, color: scheme.onSurfaceVariant)),
                    const SizedBox(height: 2),
                    Text(value,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              if (onClear != null)
                IconButton(
                  tooltip: 'Quitar',
                  icon: const Icon(Icons.close),
                  onPressed: onClear,
                )
              else
                Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
