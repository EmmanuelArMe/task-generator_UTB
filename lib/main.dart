import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'screens/auth_gate.dart';
import 'services/auth_service.dart';
import 'services/location_service.dart';
import 'theme/app_theme.dart';

/// Punto de entrada de la aplicación.
///
/// Inicializa Firebase, habilita la persistencia offline de Realtime Database
/// e instala los servicios compartidos con `provider` antes de arrancar la UI.
Future<void> main() async {
  // Necesario para usar plugins (Firebase) antes de runApp.
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa Firebase. En Android, la configuración se lee automáticamente
  // del archivo android/app/google-services.json.
  await Firebase.initializeApp();

  // Habilita la caché offline: la app puede crear/leer tareas sin conexión
  // y se sincronizan al recuperar la red (requisito de la actividad).
  // Se envuelve en try/catch porque en un "hot restart" la persistencia ya
  // podría estar configurada y lanzaría una excepción inofensiva.
  try {
    FirebaseDatabase.instance.setPersistenceEnabled(true);
  } catch (_) {/* ya estaba habilitada */}

  // Carga los datos de localización en español para formatear fechas.
  await initializeDateFormatting('es');

  runApp(const TaskManagerApp());
}

class TaskManagerApp extends StatelessWidget {
  const TaskManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Servicios disponibles en todo el árbol de widgets.
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        Provider(create: (_) => LocationService()),
      ],
      child: MaterialApp(
        title: 'Gestor de Tareas UTB',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system, // Respeta la preferencia del sistema.

        // Localización en español (DatePicker, textos de Material, etc.).
        locale: const Locale('es'),
        supportedLocales: const [Locale('es'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],

        home: const AuthGate(),
      ),
    );
  }
}
