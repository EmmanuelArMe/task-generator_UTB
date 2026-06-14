import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import 'auth/login_screen.dart';
import 'home/home_screen.dart';

/// "Portero" de autenticación: decide qué pantalla mostrar según el estado
/// de la sesión, escuchando el stream `authStateChanges` de Firebase.
///
/// - Cargando  -> indicador de progreso (splash).
/// - Sin sesión -> [LoginScreen].
/// - Con sesión -> [HomeScreen].
///
/// Al cerrar sesión, el stream emite `null` y se vuelve a Login
/// automáticamente, sin navegación manual.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();

    return StreamBuilder<User?>(
      stream: auth.authStateChanges,
      builder: (context, snapshot) {
        // Esperando la primera emisión del estado de sesión.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _SplashView();
        }

        final user = snapshot.data;
        if (user == null) {
          return const LoginScreen();
        }
        return HomeScreen(user: user);
      },
    );
  }
}

/// Pantalla de carga inicial con la identidad visual de la app.
class _SplashView extends StatelessWidget {
  const _SplashView();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.checklist_rounded, size: 72, color: scheme.primary),
            const SizedBox(height: 16),
            Text('Gestor de Tareas',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
