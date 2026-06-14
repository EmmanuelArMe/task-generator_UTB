import 'package:firebase_database/firebase_database.dart';

import '../models/task.dart';

/// Repositorio de tareas sobre **Firebase Realtime Database** (Paso 4).
///
/// Estructura de datos en la base:
/// ```
/// /tasks
///    /{uid}                 <- nodo por usuario (aislamiento de datos)
///        /{taskId}          <- push id autogenerado
///            title: ...
///            description: ...
///            isDone: ...
///            createdAt: ...
///            ...
/// ```
///
/// Las tareas se sincronizan en **tiempo real** entre dispositivos gracias al
/// stream [watchTasks], y la **persistencia offline** (habilitada en `main`)
/// permite seguir creando/leyendo tareas sin conexión; los cambios se
/// reenvían automáticamente al recuperar la red.
class TaskRepository {
  final String uid;
  final DatabaseReference _ref;

  TaskRepository({required this.uid})
      : _ref = FirebaseDatabase.instance.ref('tasks/$uid') {
    // Mantiene este nodo sincronizado en disco para acceso offline.
    _ref.keepSynced(true);
  }

  /// Stream en tiempo real con la lista de tareas del usuario,
  /// ordenadas por fecha de creación descendente (más recientes primero).
  Stream<List<Task>> watchTasks() {
    return _ref.orderByChild('createdAt').onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) return <Task>[];

      final map = data as Map<dynamic, dynamic>;
      final tasks = map.entries
          .map((e) => Task.fromMap(e.key as String, e.value as Map))
          .toList();

      // RTDB ordena ascendente; invertimos para mostrar lo más nuevo arriba.
      tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return tasks;
    });
  }

  /// Crea una nueva tarea y devuelve su id generado.
  Future<String> addTask(Task task) async {
    final newRef = _ref.push();
    await newRef.set(task.toMap());
    return newRef.key!;
  }

  /// Actualiza una tarea existente (por su id).
  Future<void> updateTask(Task task) async {
    await _ref.child(task.id).update(task.toMap());
  }

  /// Cambia únicamente el estado completado/pendiente (operación frecuente).
  Future<void> toggleDone(Task task) async {
    await _ref.child(task.id).update({'isDone': !task.isDone});
  }

  /// Elimina una tarea.
  Future<void> deleteTask(String taskId) async {
    await _ref.child(taskId).remove();
  }
}
