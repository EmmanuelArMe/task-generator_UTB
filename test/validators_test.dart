import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/utils/validators.dart';

/// Pruebas unitarias de las validaciones de formularios (Paso 5).
/// Se ejecutan con `flutter test` y no requieren Firebase ni dispositivo.
void main() {
  group('Validators.email', () {
    test('rechaza vacío', () {
      expect(Validators.email(''), isNotNull);
    });
    test('rechaza formato inválido', () {
      expect(Validators.email('correo'), isNotNull);
      expect(Validators.email('correo@'), isNotNull);
      expect(Validators.email('correo@dominio'), isNotNull);
    });
    test('acepta correo válido', () {
      expect(Validators.email('estudiante@utb.edu.co'), isNull);
    });
  });

  group('Validators.password', () {
    test('rechaza menos de 6 caracteres', () {
      expect(Validators.password('123'), isNotNull);
    });
    test('acepta 6 o más caracteres', () {
      expect(Validators.password('123456'), isNull);
    });
  });

  group('Validators.required', () {
    test('rechaza texto en blanco', () {
      expect(Validators.required('   '), isNotNull);
    });
    test('acepta texto', () {
      expect(Validators.required('Hola'), isNull);
    });
  });
}
