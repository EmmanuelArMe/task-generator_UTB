# Informe Técnico — Gestor de Tareas UTB

**Asignatura:** Software para Dispositivos Móviles
**Especialización:** Ingeniería del Software — Universidad Tecnológica de Bolívar (UTB)
**Tecnología principal:** Flutter (Dart) · Plataforma: Android
**Servicios web:** Firebase Authentication · Firebase Realtime Database · Google Maps Platform

> 📄 *Este documento está pensado para exportarse a PDF (ver sección final).
> Reemplaza los marcadores `[CAPTURA: ...]` por tus capturas de pantalla reales.*

---

## 1. Introducción y objetivo

El objetivo de esta actividad fue **evolucionar una aplicación de tareas** hasta
convertirla en una solución móvil completa, integrando autenticación de
usuarios, servicios de ubicación y almacenamiento en la nube, con una interfaz
optimizada y accesible.

La aplicación resultante permite que un usuario se **registre e inicie sesión**,
**cree y gestione tareas** que se **sincronizan en tiempo real** entre
dispositivos, y **asocie ubicaciones geográficas** a esas tareas visualizándolas
en un mapa de Google.

### Arquitectura general

Se adoptó una arquitectura por **capas** que separa responsabilidades, lo que
facilita el mantenimiento y las pruebas:

```
┌─────────────────────────────────────────────┐
│  Presentación (screens/ + widgets/)           │  Flutter / Material 3
├─────────────────────────────────────────────┤
│  Servicios (services/)                        │  Lógica de negocio
│   • AuthService      → Firebase Auth          │
│   • TaskRepository   → Realtime Database      │
│   • LocationService  → Geolocator / Geocoding │
├─────────────────────────────────────────────┤
│  Dominio (models/)                            │  Modelo Task
├─────────────────────────────────────────────┤
│  Servicios externos en la nube                │  Firebase · Google Maps
└─────────────────────────────────────────────┘
```

El estado de la sesión se propaga con el paquete `provider`, y la
sincronización con la base de datos se realiza mediante **streams** reactivos,
de modo que la interfaz se actualiza sola cuando cambian los datos.

---

## 2. Procedimiento de integración

### 2.1 Entorno y configuración inicial

El proyecto se desarrolló con **Flutter 3.44.2 (Dart 3.12)** para Android. Las
dependencias se declararon en `pubspec.yaml`:

```yaml
dependencies:
  firebase_core: ^3.6.0
  firebase_auth: ^5.3.1
  firebase_database: ^11.1.4     # Almacenamiento en la nube + offline
  google_maps_flutter: ^2.9.0
  geolocator: ^14.0.0            # Ubicación del dispositivo (GPS)
  geocoding: ^4.0.0              # Coordenadas → dirección legible
  provider: ^6.1.2               # Estado / inyección de dependencias
  intl: ^0.20.2                  # Fechas en español (lo fija flutter_localizations)
  flutter_localizations:
    sdk: flutter
```

La configuración nativa de Android usa **Gradle 9.1 con el Android Gradle Plugin
9.0.1** en formato **Kotlin DSL** (`.gradle.kts`). En `settings.gradle.kts` se
registró el plugin de Google Services y en `app/build.gradle.kts` se aplicó junto
con la *Bill of Materials* (BoM) de Firebase, que alinea las versiones de los SDK
nativos:

```kotlin
// settings.gradle.kts
id("com.google.gms.google-services") version "4.4.2" apply false

// app/build.gradle.kts
plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")   // procesa google-services.json
}
dependencies {
    implementation(platform("com.google.firebase:firebase-bom:33.5.1"))
}
```

La app se inicializa en `main.dart`, donde además se **habilita la persistencia
offline** de Realtime Database:

```dart
WidgetsFlutterBinding.ensureInitialized();
await Firebase.initializeApp();                 // lee google-services.json
FirebaseDatabase.instance.setPersistenceEnabled(true); // caché offline
runApp(const TaskManagerApp());
```

### 2.2 Autenticación de usuario (Firebase Authentication)

Se encapsuló toda la lógica en `AuthService`, que expone métodos sencillos y
traduce los códigos de error técnicos de Firebase a mensajes en español:

```dart
Future<UserCredential> signIn({required String email, required String password}) async {
  try {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(), password: password,
    );
  } on FirebaseAuthException catch (e) {
    throw AuthException(_mapErrorCode(e.code)); // mensaje legible
  }
}
```

La navegación entre "no autenticado" y "autenticado" se resuelve con un
**StreamBuilder** sobre `authStateChanges`, evitando navegación manual:

```dart
StreamBuilder<User?>(
  stream: auth.authStateChanges,
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) return _SplashView();
    return snapshot.data == null ? const LoginScreen() : HomeScreen(user: snapshot.data!);
  },
);
```

Esto da, "gratis", **persistencia de sesión** (el usuario sigue logueado tras
reiniciar) y **cierre de sesión reactivo**.

Pasos realizados en la consola de Firebase:
1. Crear el proyecto y registrar la app Android con el paquete `com.utb.task_manager`.
2. Descargar `google-services.json` a `android/app/`.
3. Activar el proveedor *Correo electrónico/contraseña* en Authentication.

### 2.3 Servicios de ubicación (Google Maps API)

Se habilitó *Maps SDK for Android* en Google Cloud y se registró la clave en el
`AndroidManifest.xml`:

```xml
<meta-data android:name="com.google.android.geo.API_KEY" android:value="AIza..." />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
```

`LocationService` centraliza el **flujo de permisos** y la obtención de la
posición, devolviendo errores claros:

```dart
final serviceEnabled = await Geolocator.isLocationServiceEnabled();
if (!serviceEnabled) throw LocationException('El servicio de ubicación está desactivado.');
var permission = await Geolocator.checkPermission();
if (permission == LocationPermission.denied) {
  permission = await Geolocator.requestPermission();
}
return Geolocator.getCurrentPosition(/* ... high accuracy ... */);
```

Se implementaron **dos pantallas de mapa**:
- `LocationPickerScreen`: el usuario toca el mapa (o usa su GPS) para asignar
  una ubicación a la tarea; se resuelve la dirección con geocodificación inversa.
- `TasksMapScreen`: muestra **todas** las tareas con ubicación como marcadores
  (verde = completada, rojo = pendiente), alimentado por el mismo stream.

### 2.4 Almacenamiento de datos (Firebase Realtime Database)

Se eligió **Realtime Database** porque la rúbrica valora la **sincronización
entre dispositivos**, y porque su caché offline cumple el requisito de "acceso
sin conexión". Los datos se aíslan por usuario:

```
/tasks/{uid}/{taskId} → { title, description, isDone, createdAt, dueDate, lat, lng, locationName }
```

`TaskRepository` ofrece el CRUD y un **stream en tiempo real** ordenado:

```dart
Stream<List<Task>> watchTasks() {
  return _ref.orderByChild('createdAt').onValue.map((event) {
    final data = event.snapshot.value;
    if (data == null) return <Task>[];
    final map = data as Map<dynamic, dynamic>;
    final tasks = map.entries
        .map((e) => Task.fromMap(e.key as String, e.value as Map))
        .toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return tasks;
  });
}
```

`keepSynced(true)` mantiene el nodo del usuario en disco para funcionar offline.

### 2.5 Optimización de la interfaz (UI/UX)

- **Material 3** con `ColorScheme.fromSeed`, que garantiza buen contraste.
- **Tema claro y oscuro** automáticos según el sistema (`ThemeMode.system`).
- **Accesibilidad:** botones con altura mínima de 52 dp (área táctil ≥ 48 dp),
  `tooltip` en íconos, `semanticLabel` en los checkboxes, tipografía con buen
  interlineado y campos de formulario amplios.
- **Retroalimentación:** indicadores de carga, *SnackBars* de éxito/error,
  validación en vivo, y **estados vacíos** ilustrados (sin tareas / sin
  resultados / error).
- **Navegación clara:** filtros con `SegmentedButton`, FAB para crear, menú de
  cuenta y acceso directo al mapa desde la barra superior.

---

## 3. Retos encontrados y soluciones implementadas

### 3.1 Retos de diseño e implementación

| # | Reto | Solución implementada |
|---|------|------------------------|
| 1 | **Tipos numéricos inconsistentes** de Realtime Database (a veces `int`, a veces `double`). | Casting defensivo con helpers `toDouble`/`toInt` en `Task.fromMap`, evitando excepciones de tipo. |
| 2 | **Sincronizar la UI con la sesión** sin navegación manual frágil. | `AuthGate` con `StreamBuilder` sobre `authStateChanges`: la pantalla cambia sola al iniciar/cerrar sesión. |
| 3 | **Mensajes de error crípticos** de Firebase (`wrong-password`, etc.). | Mapeo a mensajes claros en español dentro de `AuthService._mapErrorCode`. |
| 4 | **Permisos de ubicación** y GPS apagado provocaban cierres inesperados. | Flujo de permisos por capas en `LocationService` con `LocationException`; la UI muestra el motivo y no se cae. |
| 5 | **Acceso offline.** | `setPersistenceEnabled(true)` + `keepSynced(true)`: las tareas se crean/leen sin red y se sincronizan al reconectar. |
| 6 | **Pérdida de datos al editar** (id y fecha de creación). | Modelo inmutable con `copyWith`; en edición se conservan `id` y `createdAt`. |
| 7 | **Aislamiento de datos entre usuarios.** | Ruta `/tasks/{uid}` + reglas de seguridad que validan `auth.uid === $uid`. |

### 3.2 Retos de entorno y compilación (Android / Gradle)

Estos fueron los problemas reales enfrentados al construir el proyecto, y son
representativos de los desafíos de un entorno profesional Flutter:

| # | Reto | Solución implementada |
|---|------|------------------------|
| 8 | **Conflicto de versión de `intl`:** `flutter_localizations` (SDK) exige `intl 0.20.2`, pero se había fijado `^0.19.0`. | Se ajustó la restricción a `^0.20.2` en `pubspec.yaml`. |
| 9 | **Incompatibilidad Gradle 9.1 ↔ AGP 8.1** (error `DependencyHandler.module` al evaluar el proyecto). | Se migró la configuración de Android de Groovy a **Kotlin DSL** con **AGP 9.0.1 / Kotlin 2.3.20** (las versiones que genera Flutter 3.44), reinyectando el plugin de Google Services y la BoM de Firebase. |
| 10 | **Error de metadatos AAR:** los plugins `geocoding_android`/`geolocator_android` antiguos se compilaban contra `compileSdk 33`, pero sus dependencias `androidx` exigían 34+. | Se actualizaron `geocoding` a `^4.0.0` y `geolocator` a `^14.0.0`. |
| 11 | **Windows:** la compilación con plugins requería soporte de *symlinks*. | Se activó el **Modo de desarrollador** de Windows. |
| 12 | **`google-services.json` sin la URL de la base** (`firebase_url`), por haberlo descargado antes de crear la Realtime Database. | Se volvió a descargar el archivo después de crear la base de datos. |
| 13 | **Error de autenticación genérico** al iniciar sesión. | Faltaba **guardar/habilitar** el proveedor *Correo electrónico/contraseña* en Firebase Authentication; al activarlo, el login funcionó. |

### Ejemplo de solución clave (reto #1 — casting defensivo)

```dart
factory Task.fromMap(String id, Map<dynamic, dynamic> map) {
  double? toDouble(dynamic v) => v == null ? null : (v as num).toDouble();
  int? toInt(dynamic v) => v == null ? null : (v as num).toInt();
  return Task(
    id: id,
    title: (map['title'] ?? '') as String,
    createdAt: toInt(map['createdAt']) ?? 0,
    latitude: toDouble(map['latitude']),
    /* ... */
  );
}
```

### Ejemplo de solución clave (reto #9 — migración a Kotlin DSL)

```kotlin
// android/settings.gradle.kts — versiones compatibles con Gradle 9.1
plugins {
    id("com.android.application") version "9.0.1" apply false
    id("org.jetbrains.kotlin.android") version "2.3.20" apply false
    id("com.google.gms.google-services") version "4.4.2" apply false
}
```

---

## 4. Pruebas de funcionalidad y estabilidad

### 4.1 Pruebas automatizadas

Se incluyeron pruebas unitarias (`flutter test`) sobre las validaciones y la
serialización del modelo, que se ejecutan sin necesidad de Firebase. En la
verificación final del proyecto:

```bash
flutter analyze   # → No issues found!  (0 errores, 0 advertencias)
flutter test      # → All tests passed! (11/11 pruebas superadas)
flutter build apk --debug   # → APK generado sin errores
```

Las pruebas cubren `Validators.email / password / required` y
`Task.toMap / fromMap / copyWith`.

### 4.2 Plan de pruebas manuales

| Caso de prueba | Pasos | Resultado esperado |
|----------------|-------|--------------------|
| Registro | Crear cuenta con correo nuevo | Entra directo a la lista de tareas |
| Registro inválido | Usar un correo ya registrado | Mensaje "Ya existe una cuenta con este correo" |
| Inicio de sesión | Correo y contraseña correctos | Acceso a la app |
| Login fallido | Contraseña incorrecta | Mensaje "Correo o contraseña incorrectos" |
| Recuperar contraseña | "¿Olvidaste tu contraseña?" | Llega correo de restablecimiento |
| Sesión persistente | Cerrar y reabrir la app | Sigue logueado |
| Cerrar sesión | Menú → Cerrar sesión | Vuelve al login |
| Crear tarea | Nueva tarea con título | Aparece de inmediato en la lista |
| Completar tarea | Tocar el checkbox | Se tacha y cambia a "Completadas" |
| Editar tarea | Tocar una tarea y guardar cambios | Se reflejan los cambios |
| Eliminar tarea | Ícono de papelera → confirmar | Desaparece de la lista |
| Sincronización | Crear tarea en un dispositivo | Aparece en otro con la misma cuenta |
| Offline | Activar modo avión, crear tarea | Se guarda; al reconectar se sincroniza |
| Ubicación GPS | "Mi ubicación actual" en el mapa | Centra el mapa en la posición real |
| Ubicación en tarea | Asignar lugar y guardar | La tarea muestra el chip de ubicación |
| Mapa de tareas | Abrir el mapa desde la barra | Marcadores de las tareas geolocalizadas |

### 4.3 Estabilidad

- Todas las operaciones de red están envueltas en `try/catch` con mensajes al
  usuario, evitando cierres inesperados.
- Se usan comprobaciones `if (mounted)` antes de actualizar el estado tras
  operaciones asíncronas, previniendo errores de *widget desmontado*.
- Estados de carga (`CircularProgressIndicator`) impiden acciones duplicadas.

---

## 5. Evidencia de funcionamiento

> Reemplaza cada marcador por la captura correspondiente. Sugerencia: usa el
> emulador de Android Studio o un dispositivo físico.

1. **Pantalla de inicio de sesión** — `[CAPTURA: login]`
2. **Registro de usuario** — `[CAPTURA: registro]`
3. **Usuario creado en Firebase Authentication** (consola) — `[CAPTURA: firebase_auth_consola]`
4. **Lista de tareas (vacía y con tareas)** — `[CAPTURA: lista_tareas]`
5. **Crear/editar tarea con fecha y ubicación** — `[CAPTURA: formulario_tarea]`
6. **Selector de ubicación en Google Maps** — `[CAPTURA: mapa_picker]`
7. **Mapa con todas las tareas** — `[CAPTURA: mapa_tareas]`
8. **Datos en Firebase Realtime Database** (consola) — `[CAPTURA: realtime_database]`
9. **Sincronización entre dos dispositivos / prueba offline** — `[CAPTURA o VIDEO]`

> 🎥 **Video sugerido (1–3 min):** muestra el flujo completo —
> registro → login → crear tarea con ubicación → ver en el mapa →
> completar/editar/eliminar → prueba offline → cerrar sesión.

---

## 6. Conclusiones

Se logró una aplicación funcional que integra de forma robusta tres servicios
web (autenticación, base de datos en tiempo real y mapas), con una interfaz
moderna y accesible. La arquitectura por capas y el uso de *streams* hacen el
código mantenible y reactivo, mientras que el manejo cuidadoso de errores y
permisos garantiza estabilidad durante el uso de todas las funcionalidades.

---

## Anexo: cómo exportar este informe a PDF

- **VS Code:** instala la extensión *Markdown PDF* → clic derecho sobre este
  archivo → *Markdown PDF: Export (pdf)*.
- **Alternativa:** abre el archivo en [dillinger.io](https://dillinger.io/) o
  Typora y usa *Exportar → PDF*.
- Antes de exportar, inserta las capturas reemplazando los marcadores
  `[CAPTURA: ...]`.
