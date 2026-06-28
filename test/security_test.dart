import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/utils/validators.dart';

/// Pruebas de **seguridad** de la capa de validación y sanitización de
/// entradas. Verifican que la app resiste entradas maliciosas o malformadas
/// (inyección de caracteres de control, cadenas tipo script/SQL, longitudes
/// abusivas) antes de que lleguen a Firebase.
void main() {
  group('Sanitización de entradas (anti-inyección)', () {
    test('elimina caracteres de control (saltos de línea, tabulaciones)', () {
      const malicioso = 'Tarea\nmaliciosa\r\t';
      final limpio = Validators.sanitize(malicioso);
      expect(limpio.contains('\n'), isFalse);
      expect(limpio.contains('\r'), isFalse);
      expect(limpio.contains('\t'), isFalse);
      expect(limpio, 'Tareamaliciosa');
    });

    test('recorta espacios al inicio y final', () {
      expect(Validators.sanitize('   hola   '), 'hola');
    });

    test('limita la longitud máxima (evita abuso/DoS)', () {
      final largo = 'a' * 5000;
      final limpio = Validators.sanitize(largo, maxLength: 100);
      expect(limpio.length, 100);
    });

    test('conserva texto legítimo con acentos y emojis', () {
      const texto = 'Reunión en la oficina 📍';
      expect(Validators.sanitize(texto), texto);
    });

    test('una cadena tipo inyección queda como texto inerte', () {
      // En una base NoSQL no se interpreta SQL, y además neutralizamos los
      // caracteres de control; el contenido se trata siempre como dato.
      const inyeccion = "'; DROP TABLE users; --";
      final limpio = Validators.sanitize(inyeccion);
      expect(limpio.contains('\n'), isFalse);
      expect(limpio, isNotEmpty); // se conserva como texto plano inofensivo
    });
  });

  group('Límites de longitud en validadores', () {
    test('correo excesivamente largo es rechazado', () {
      final correo = '${'a' * 250}@x.com';
      expect(Validators.email(correo), isNotNull);
    });

    test('campo obligatorio que excede el máximo es rechazado', () {
      final titulo = 'a' * 200;
      expect(Validators.required(titulo, maxLength: 100), isNotNull);
    });

    test('contraseña excesivamente larga es rechazada', () {
      final pass = 'Aa1${'x' * 200}';
      expect(Validators.password(pass), isNotNull);
    });
  });
}
