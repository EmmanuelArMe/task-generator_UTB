import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Servicio de **autenticación con Firebase Authentication** (Paso 2).
///
/// Envuelve `FirebaseAuth` exponiendo métodos sencillos para registrar,
/// iniciar y cerrar sesión, y traduce los códigos de error de Firebase a
/// mensajes claros en español. Extiende [ChangeNotifier] para poder
/// escucharlo con `provider`, aunque el estado de sesión se observa
/// principalmente mediante el stream [authStateChanges].
class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Usuario actualmente autenticado (o `null` si no hay sesión).
  User? get currentUser => _auth.currentUser;

  /// Stream que emite cada vez que cambia el estado de sesión.
  /// La pantalla raíz lo escucha para decidir entre Login y Home.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Registra un nuevo usuario con correo y contraseña.
  Future<UserCredential> register({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      // Convertimos la excepción técnica en un mensaje legible.
      throw AuthException(_mapErrorCode(e.code));
    }
  }

  /// Inicia sesión con correo y contraseña.
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapErrorCode(e.code));
    }
  }

  /// Envía un correo para restablecer la contraseña.
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapErrorCode(e.code));
    }
  }

  /// Cierra la sesión del usuario actual.
  Future<void> signOut() => _auth.signOut();

  /// Traduce los códigos de error de Firebase a mensajes en español.
  String _mapErrorCode(String code) {
    switch (code) {
      case 'invalid-email':
        return 'El correo electrónico no es válido.';
      case 'user-disabled':
        return 'Esta cuenta ha sido deshabilitada.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Correo o contraseña incorrectos.';
      case 'email-already-in-use':
        return 'Ya existe una cuenta con este correo.';
      case 'weak-password':
        return 'La contraseña es demasiado débil (mínimo 6 caracteres).';
      case 'network-request-failed':
        return 'Sin conexión a internet. Verifica tu red.';
      case 'too-many-requests':
        return 'Demasiados intentos. Inténtalo más tarde.';
      default:
        return 'Ocurrió un error de autenticación. Inténtalo de nuevo.';
    }
  }
}

/// Excepción de dominio para errores de autenticación con mensaje en español.
class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}
