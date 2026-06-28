# Gestor de Tareas UTB 📋

Aplicación móvil de gestión de tareas desarrollada en **Flutter** para la
asignatura *Software para Dispositivos Móviles* (Especialización en Ingeniería
del Software – UTB).

Integra tres servicios clave:

| Servicio | Tecnología | Para qué |
|----------|-----------|----------|
| 🔐 Autenticación | **Firebase Authentication** | Registro, inicio y cierre de sesión con correo y contraseña |
| 🗺️ Ubicación | **Google Maps SDK + Geolocator** | Ver el mapa, marcar y asociar ubicaciones a las tareas |
| ☁️ Almacenamiento | **Firebase Realtime Database** | Guardar tareas en la nube, en tiempo real y con **soporte offline** |

---

## 📁 Estructura del proyecto

```
lib/
├── main.dart                     # Punto de entrada: inicializa Firebase y la app
├── models/
│   └── task.dart                 # Modelo de datos Tarea (+ serialización)
├── services/
│   ├── auth_service.dart         # Lógica de autenticación (Firebase Auth)
│   ├── task_repository.dart      # CRUD en Realtime Database (tiempo real + offline)
│   └── location_service.dart     # Permisos y obtención de ubicación (GPS)
├── screens/
│   ├── auth_gate.dart            # Decide entre Login y Home según la sesión
│   ├── auth/
│   │   ├── login_screen.dart     # Inicio de sesión
│   │   └── register_screen.dart  # Registro
│   ├── home/
│   │   └── home_screen.dart      # Lista de tareas + filtros + logout
│   ├── tasks/
│   │   └── task_form_screen.dart # Crear / editar tarea
│   └── map/
│       ├── location_picker_screen.dart # Elegir ubicación en el mapa
│       └── tasks_map_screen.dart       # Ver todas las tareas en el mapa
├── widgets/
│   └── task_tile.dart            # Tarjeta visual de una tarea
├── theme/
│   └── app_theme.dart            # Tema Material 3 (claro/oscuro, accesible)
└── utils/
    └── validators.dart           # Validaciones de formularios

test/                             # Pruebas unitarias (flutter test)
android/                          # Configuración nativa de Android
INFORME_TECNICO.md                # Informe técnico de la actividad
```

---

## 🚀 Puesta en marcha (paso a paso)

> **Requisitos previos:** [Flutter SDK](https://docs.flutter.dev/get-started/install)
> (**3.27 o superior**, Dart 3.6+), Android Studio con un emulador o un
> dispositivo físico, y una cuenta de Google.
>
> ⚠️ Si usas una versión de Flutter anterior a 3.27, ejecuta `flutter upgrade`.
> El proyecto emplea APIs modernas (`Color.withValues`, temas `*ThemeData`).
> Desarrollado y probado con **Flutter 3.44.2** (Gradle 9.1, AGP 9.0.1).

### 0. Generar los archivos nativos que faltan

Este repositorio incluye todo el código y la configuración personalizada, pero
**no** incluye archivos binarios (íconos, *wrapper* de Gradle). Genéralos con:

```bash
flutter create .
```

> `flutter create .` **conserva** todos los archivos existentes (tu código y la
> configuración) y solo crea los que faltan (íconos de la app, `gradlew`,
> recursos de arranque). Luego:

```bash
flutter pub get
```

### 1. Crear el proyecto en Firebase 🔥

1. Entra a [Firebase Console](https://console.firebase.google.com/) → **Agregar proyecto**.
2. Ponle un nombre (ej. `gestor-tareas-utb`) y créalo.
3. Dentro del proyecto, pulsa el ícono de **Android** para registrar una app:
   - **Nombre del paquete:** `com.utb.task_manager` *(debe ser exacto)*.
   - Registra la app y **descarga `google-services.json`**.
4. Copia ese archivo en: `android/app/google-services.json`

### 2. Activar los servicios de Firebase

En la consola de Firebase:

- **Authentication** → *Comenzar* → pestaña *Sign-in method* → habilita
  **Correo electrónico/contraseña**.
- **Realtime Database** → *Crear base de datos* → elige una ubicación →
  inicia en **modo de prueba** (o aplica las reglas de seguridad de abajo).

#### Reglas de seguridad recomendadas (Realtime Database)

Cada usuario solo puede leer y escribir **sus** tareas:

```json
{
  "rules": {
    "tasks": {
      "$uid": {
        ".read": "auth != null && auth.uid === $uid",
        ".write": "auth != null && auth.uid === $uid"
      }
    }
  }
}
```

### 3. Obtener la clave de Google Maps 🗺️

1. Ve a [Google Cloud Console](https://console.cloud.google.com/) y selecciona
   (o crea) el **mismo proyecto** que usa Firebase.
2. **APIs y servicios → Biblioteca** → habilita **Maps SDK for Android**.
3. **APIs y servicios → Credenciales → Crear credenciales → Clave de API**.
4. Copia la clave y pégala en `android/app/src/main/AndroidManifest.xml`,
   reemplazando `TU_API_KEY_DE_GOOGLE_MAPS`:

   ```xml
   <meta-data
       android:name="com.google.android.geo.API_KEY"
       android:value="AIza...tu_clave..." />
   ```

> 💡 *Recomendado:* restringe la clave por nombre de paquete
> (`com.utb.task_manager`) y huella SHA-1 (`./gradlew signingReport`).

### 4. Ejecutar la app ▶️

```bash
flutter run
```

Para compilar el APK de entrega:

```bash
flutter build apk --release
```

El APK queda en `build/app/outputs/flutter-apk/app-release.apk`.

---

## 🧪 Pruebas

```bash
flutter test           # Pruebas unitarias (validadores y modelo)
flutter analyze        # Análisis estático del código
```

Consulta la sección *Pruebas de funcionalidad* del
[informe técnico](INFORME_TECNICO.md) para el plan de pruebas manuales.

---

## 🔒 Nota sobre credenciales

Por seguridad, `google-services.json` y la clave de Maps **no se versionan**
(ver `.gitignore`). Para entregar el proyecto a un evaluador, inclúyelos por un
canal privado o añade tus credenciales de prueba siguiendo esta guía.

---

## ✅ Checklist de funcionalidades

- [x] Registro de usuario (Firebase Auth)
- [x] Inicio y cierre de sesión + recuperación de contraseña
- [x] Sesión persistente entre reinicios
- [x] Crear, editar, completar y eliminar tareas
- [x] Sincronización en tiempo real entre dispositivos (Realtime Database)
- [x] Acceso offline con sincronización automática al reconectar
- [x] Ubicación actual con GPS y selección de lugar en el mapa
- [x] Mapa con todas las tareas geolocalizadas
- [x] UI Material 3 con tema claro/oscuro y enfoque en accesibilidad
- [x] Manejo de errores y estados de carga/vacío

---

## 🔒 Seguridad

La aplicación fue auditada y endurecida siguiendo el **OWASP Mobile Top 10**.
Resumen de las medidas implementadas (detalle completo en
[INFORME_SEGURIDAD.md](INFORME_SEGURIDAD.md)):

- **Validación server-side** en Realtime Database (`database.rules.json`):
  acceso por usuario + reglas `.validate` de tipos, rangos y longitudes
  (defensa contra inyección de datos en NoSQL).
- **Validación y saneamiento de entradas** en el cliente: límites de longitud
  y eliminación de caracteres de control (`lib/utils/validators.dart`).
- **Política de contraseñas robusta** (mín. 8 caracteres con letras y números).
- **Solo HTTPS**: tráfico en claro bloqueado (`network_security_config.xml`).
- **Backup deshabilitado** (`allowBackup="false"`).
- **Credenciales fuera del control de versiones** y API key de Maps restringida.
- **APK de release ofuscado** (`--obfuscate`).

Análisis ejecutados: `flutter analyze` (sin problemas), `flutter test`
(incluye `test/security_test.dart`) y **Android Lint** (`gradlew :app:lintDebug`).
