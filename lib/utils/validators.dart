/// Validaciones y **sanitización de entradas** reutilizables (capa de seguridad).
///
/// Forman la **primera barrera** contra entradas maliciosas o malformadas
/// (validación del lado del cliente). La barrera definitiva es la validación
/// del lado del servidor, implementada con reglas `.validate` en Firebase
/// Realtime Database (ver `database.rules.json`). Defensa en profundidad.
///
/// Cada función devuelve `null` si el valor es válido, o un mensaje de error en
/// español (formato esperado por `TextFormField.validator`).
class Validators {
  // Longitudes máximas para evitar abuso (DoS por entradas enormes) y para
  // alinear el cliente con las reglas `.validate` del servidor.
  static const int maxEmailLength = 254; // RFC 5321
  static const int maxPasswordLength = 128;
  static const int maxTitleLength = 100;
  static const int maxDescriptionLength = 1000;

  /// Valida un correo electrónico (formato + longitud máxima).
  static String? email(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Ingresa tu correo electrónico.';
    if (v.length > maxEmailLength) return 'El correo es demasiado largo.';
    // Expresión regular conservadora para el formato de correo.
    final regex = RegExp(r'^[\w.\-]+@([\w\-]+\.)+[\w\-]{2,}$');
    if (!regex.hasMatch(v)) return 'Ingresa un correo válido.';
    return null;
  }

  /// Política de contraseña **fuerte** para el REGISTRO (cuentas nuevas):
  /// mínimo 8 caracteres, con al menos una letra y un número.
  ///
  /// Endurece el mínimo de 6 de Firebase para reducir contraseñas débiles
  /// (mitiga ataques de fuerza bruta / diccionario).
  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Ingresa tu contraseña.';
    if (v.length < 8) return 'La contraseña debe tener al menos 8 caracteres.';
    if (v.length > maxPasswordLength) return 'La contraseña es demasiado larga.';
    if (!RegExp(r'[A-Za-z]').hasMatch(v)) {
      return 'La contraseña debe incluir al menos una letra.';
    }
    if (!RegExp(r'\d').hasMatch(v)) {
      return 'La contraseña debe incluir al menos un número.';
    }
    return null;
  }

  /// Validación **permisiva** para el INICIO DE SESIÓN: solo verifica que no
  /// esté vacía. No se aplica la política fuerte aquí para no bloquear a
  /// usuarios cuya contraseña se creó con reglas anteriores; la verificación
  /// real la hace Firebase Authentication.
  static String? loginPassword(String? value) {
    if ((value ?? '').isEmpty) return 'Ingresa tu contraseña.';
    return null;
  }

  /// Valida un campo de texto obligatorio con longitud máxima.
  static String? required(String? value,
      {String field = 'Este campo', int maxLength = maxTitleLength}) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return '$field es obligatorio.';
    if (v.length > maxLength) {
      return '$field no puede superar $maxLength caracteres.';
    }
    return null;
  }

  /// Valida un texto opcional solo por su longitud máxima.
  static String? maxLen(String? value, int maxLength) {
    if ((value ?? '').length > maxLength) {
      return 'Máximo $maxLength caracteres.';
    }
    return null;
  }

  /// **Sanitiza** una entrada de texto antes de persistirla:
  ///  - recorta espacios al inicio/fin,
  ///  - elimina caracteres de control (no imprimibles), que podrían usarse
  ///    para inyectar saltos/secuencias en logs u otros sistemas,
  ///  - recorta a una longitud máxima de seguridad.
  ///
  /// No es un sustituto de la validación del servidor, sino una capa adicional.
  static String sanitize(String input, {int maxLength = maxDescriptionLength}) {
    // Elimina caracteres de control ASCII (0x00–0x1F y 0x7F) excepto que ya
    // los recortamos; preservamos letras acentuadas y emojis.
    final cleaned = input
        .replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '')
        .trim();
    return cleaned.length > maxLength
        ? cleaned.substring(0, maxLength)
        : cleaned;
  }
}
