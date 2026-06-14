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
  });
}
