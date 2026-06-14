/// Funciones de validación reutilizables para los formularios.
///
/// Devuelven `null` cuando el valor es válido o un mensaje de error en
/// español cuando no lo es (formato esperado por `TextFormField.validator`).
class Validators {
  /// Valida un correo electrónico con una expresión regular sencilla.
  static String? email(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Ingresa tu correo electrónico.';
    final regex = RegExp(r'^[\w.\-]+@([\w\-]+\.)+[\w\-]{2,}$');
    if (!regex.hasMatch(v)) return 'Ingresa un correo válido.';
    return null;
  }

  /// Valida una contraseña (mínimo 6 caracteres, requisito de Firebase).
  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Ingresa tu contraseña.';
    if (v.length < 6) return 'La contraseña debe tener al menos 6 caracteres.';
    return null;
  }

  /// Valida que un campo de texto no esté vacío.
  static String? required(String? value, {String field = 'Este campo'}) {
    if ((value ?? '').trim().isEmpty) return '$field es obligatorio.';
    return null;
  }
}
