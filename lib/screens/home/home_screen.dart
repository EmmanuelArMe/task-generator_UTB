import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/task.dart';
import '../../services/auth_service.dart';
import '../../services/task_repository.dart';
import '../../widgets/task_tile.dart';
import '../map/tasks_map_screen.dart';
import '../tasks/task_form_screen.dart';

/// Pantalla **principal**: lista de tareas del usuario autenticado.
///
/// - Lee las tareas en tiempo real desde Firebase Realtime Database.
/// - Permite filtrar entre todas / pendientes / completadas.
/// - Da acceso a crear/editar tareas y a ver todas las ubicaciones en un mapa.
/// - Permite cerrar sesión.
class HomeScreen extends StatefulWidget {
  final User user;
  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

/// Filtros disponibles para la lista.
enum _Filter { todas, pendientes, completadas }

class _HomeScreenState extends State<HomeScreen> {
  late final TaskRepository _repo;
  _Filter _filter = _Filter.todas;

  @override
  void initState() {
    super.initState();
    // Cada usuario tiene su propio espacio de tareas (aislado por uid).
    _repo = TaskRepository(uid: widget.user.uid);
  }

  /// Aplica el filtro seleccionado a la lista de tareas.
  List<Task> _applyFilter(List<Task> tasks) {
    switch (_filter) {
      case _Filter.pendientes:
        return tasks.where((t) => !t.isDone).toList();
      case _Filter.completadas:
        return tasks.where((t) => t.isDone).toList();
      case _Filter.todas:
        return tasks;
    }
  }

  Future<void> _confirmDelete(Task task) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar tarea'),
        content: Text('¿Seguro que deseas eliminar "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _repo.deleteTask(task.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tarea eliminada.')),
        );
      }
    }
  }

  void _openForm({Task? task}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TaskFormScreen(repo: _repo, existing: task),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis tareas'),
        actions: [
          IconButton(
            tooltip: 'Ver tareas en el mapa',
            icon: const Icon(Icons.map_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => TasksMapScreen(repo: _repo),
              ),
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Cuenta',
            icon: const Icon(Icons.account_circle_outlined),
            onSelected: (value) {
              if (value == 'logout') context.read<AuthService>().signOut();
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                enabled: false,
                child: Text(widget.user.email ?? 'Usuario'),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.logout),
                  title: Text('Cerrar sesión'),
                ),
              ),
            ],
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Nueva tarea'),
      ),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: SegmentedButton<_Filter>(
              segments: const [
                ButtonSegment(value: _Filter.todas, label: Text('Todas')),
                ButtonSegment(
                    value: _Filter.pendientes, label: Text('Pendientes')),
                ButtonSegment(
                    value: _Filter.completadas, label: Text('Completadas')),
              ],
              selected: {_filter},
              onSelectionChanged: (s) => setState(() => _filter = s.first),
            ),
          ),

          Expanded(
            child: StreamBuilder<List<Task>>(
              stream: _repo.watchTasks(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return _ErrorState(message: '${snapshot.error}');
                }

                final all = snapshot.data ?? [];
                final tasks = _applyFilter(all);

                if (all.isEmpty) {
                  return const _EmptyState(
                    icon: Icons.note_add_outlined,
                    title: 'Aún no tienes tareas',
                    subtitle: 'Toca "Nueva tarea" para crear la primera.',
                  );
                }
                if (tasks.isEmpty) {
                  return _EmptyState(
                    icon: Icons.filter_alt_off_outlined,
                    title: 'Sin resultados',
                    subtitle:
                        'No hay tareas en el filtro "${_filter.name}".',
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 96, top: 4),
                  itemCount: tasks.length,
                  itemBuilder: (context, i) {
                    final task = tasks[i];
                    return TaskTile(
                      task: task,
                      onToggle: () => _repo.toggleDone(task),
                      onTap: () => _openForm(task: task),
                      onDelete: () => _confirmDelete(task),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Estado visual cuando no hay datos que mostrar (mejora la UX).
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 72, color: scheme.primary.withValues(alpha: 0.7)),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

/// Estado visual de error.
class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: scheme.error),
            const SizedBox(height: 16),
            const Text('Ocurrió un error al cargar las tareas'),
            const SizedBox(height: 4),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(color: scheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
