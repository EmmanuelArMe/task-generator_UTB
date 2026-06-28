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

  group('Validators.password (registro: política fuerte)', () {
    test('rechaza menos de 8 caracteres', () {
      expect(Validators.password('Ab1'), isNotNull);
    });
    test('rechaza sin números', () {
      expect(Validators.password('SoloLetras'), isNotNull);
    });
    test('rechaza sin letras', () {
      expect(Validators.password('12345678'), isNotNull);
    });
    test('acepta una contraseña fuerte', () {
      expect(Validators.password('Segura123'), isNull);
    });
  });

  group('Validators.loginPassword (permisiva)', () {
    test('rechaza vacía', () {
      expect(Validators.loginPassword(''), isNotNull);
    });
    test('acepta cualquier valor no vacío', () {
      expect(Validators.loginPassword('123456'), isNull);
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

  group('Validators.maxLen', () {
    test('rechaza texto que supera el máximo', () {
      expect(Validators.maxLen('abcdef', 3), isNotNull);
    });
    test('acepta texto dentro del límite', () {
      expect(Validators.maxLen('abc', 5), isNull);
    });
    test('acepta valor nulo', () {
      expect(Validators.maxLen(null, 5), isNull);
    });
  });
}
