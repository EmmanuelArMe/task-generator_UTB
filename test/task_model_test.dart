import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/models/task.dart';

/// Pruebas del modelo [Task]: serialización y utilidades (Paso 5).
void main() {
  group('Task.toMap / fromMap', () {
    test('serializa y reconstruye conservando los datos', () {
      const task = Task(
        id: 'abc123',
        title: 'Entregar informe',
        description: 'Subir el PDF a la plataforma',
        isDone: false,
        createdAt: 1700000000000,
        dueDate: 1700500000000,
        latitude: 10.391,
        longitude: -75.479,
        locationName: 'UTB, Cartagena',
      );

      final map = task.toMap();
      final restored = Task.fromMap('abc123', map);

      expect(restored.id, 'abc123');
      expect(restored.title, 'Entregar informe');
      expect(restored.latitude, closeTo(10.391, 0.0001));
      expect(restored.hasLocation, isTrue);
      expect(restored.dueDate, 1700500000000);
    });

    test('hasLocation es falso sin coordenadas', () {
      const task = Task(id: '1', title: 't', description: '', createdAt: 0);
      expect(task.hasLocation, isFalse);
    });
  });

  group('Task.copyWith', () {
    test('clearLocation elimina las coordenadas', () {
      const task = Task(
        id: '1',
        title: 't',
        description: '',
        createdAt: 0,
        latitude: 1,
        longitude: 2,
      );
      final cleared = task.copyWith(clearLocation: true);
      expect(cleared.hasLocation, isFalse);
    });

    test('toggle de isDone mediante copyWith', () {
      const task = Task(id: '1', title: 't', description: '', createdAt: 0);
      expect(task.copyWith(isDone: true).isDone, isTrue);
    });

    test('clearDueDate elimina la fecha límite', () {
      const task = Task(
        id: '1',
        title: 't',
        description: '',
        createdAt: 0,
        dueDate: 123456,
      );
      expect(task.copyWith(clearDueDate: true).dueDate, isNull);
    });

    test('actualiza título, descripción y fecha de creación', () {
      const task = Task(id: '1', title: 'viejo', description: '', createdAt: 0);
      final nuevo = task.copyWith(
        title: 'nuevo',
        description: 'desc',
        createdAt: 999,
      );
      expect(nuevo.title, 'nuevo');
      expect(nuevo.description, 'desc');
      expect(nuevo.createdAt, 999);
      expect(nuevo.id, '1'); // se conserva
    });
  });

  group('Task.fromMap (casos límite)', () {
    test('reconstruye una tarea sin ubicación ni fecha (campos nulos)', () {
      final task = Task.fromMap('k', {
        'title': 'Solo título',
        'isDone': true,
        'createdAt': 100,
      });
      expect(task.hasLocation, isFalse);
      expect(task.dueDate, isNull);
      expect(task.locationName, isNull);
      expect(task.isDone, isTrue);
    });

    test('acepta coordenadas como int o double (num)', () {
      final task = Task.fromMap('k', {
        'title': 't',
        'createdAt': 0,
        'latitude': 10, // int
        'longitude': -75.5, // double
      });
      expect(task.latitude, 10.0);
      expect(task.longitude, -75.5);
      expect(task.hasLocation, isTrue);
    });

    test('usa valores por defecto si faltan title/createdAt', () {
      final task = Task.fromMap('k', {});
      expect(task.title, '');
      expect(task.createdAt, 0);
    });
  });
}
