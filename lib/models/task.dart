/// Modelo de dominio que representa una **tarea** del usuario.
///
/// Cada tarea puede tener, además del título y la descripción, una fecha
/// límite y una ubicación geográfica (latitud/longitud) opcional. Esto permite
/// asociar tareas a lugares concretos (Paso 3 de la actividad).
///
/// El modelo incluye serialización hacia/desde `Map<String, dynamic>` para
/// poder guardarlo y leerlo en **Firebase Realtime Database**.
class Task {
  /// Identificador único. En Realtime Database es la *key* del nodo (push id).
  final String id;
  final String title;
  final String description;

  /// Indica si la tarea está completada.
  final bool isDone;

  /// Fecha de creación (epoch en milisegundos para ordenar fácilmente).
  final int createdAt;

  /// Fecha límite opcional (epoch en milisegundos). `null` = sin fecha.
  final int? dueDate;

  /// Ubicación asociada (opcional).
  final double? latitude;
  final double? longitude;

  /// Nombre legible del lugar (ej. "Cra 7 #45, Cartagena"). Opcional.
  final String? locationName;

  const Task({
    required this.id,
    required this.title,
    required this.description,
    this.isDone = false,
    required this.createdAt,
    this.dueDate,
    this.latitude,
    this.longitude,
    this.locationName,
  });

  /// `true` si la tarea tiene coordenadas válidas.
  bool get hasLocation => latitude != null && longitude != null;

  /// Crea una copia modificando solo los campos indicados (inmutabilidad).
  Task copyWith({
    String? id,
    String? title,
    String? description,
    bool? isDone,
    int? createdAt,
    int? dueDate,
    double? latitude,
    double? longitude,
    String? locationName,
    bool clearDueDate = false,
    bool clearLocation = false,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isDone: isDone ?? this.isDone,
      createdAt: createdAt ?? this.createdAt,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      latitude: clearLocation ? null : (latitude ?? this.latitude),
      longitude: clearLocation ? null : (longitude ?? this.longitude),
      locationName: clearLocation ? null : (locationName ?? this.locationName),
    );
  }

  /// Convierte la tarea a un mapa para escribir en Realtime Database.
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'isDone': isDone,
      'createdAt': createdAt,
      'dueDate': dueDate,
      'latitude': latitude,
      'longitude': longitude,
      'locationName': locationName,
    };
  }

  /// Reconstruye una tarea desde un nodo de Realtime Database.
  ///
  /// [id] es la *key* del nodo y [map] son los valores hijos. Se hace casting
  /// defensivo porque RTDB puede devolver `int`, `double` o `num`.
  factory Task.fromMap(String id, Map<dynamic, dynamic> map) {
    double? toDouble(dynamic v) => v == null ? null : (v as num).toDouble();
    int? toInt(dynamic v) => v == null ? null : (v as num).toInt();

    return Task(
      id: id,
      title: (map['title'] ?? '') as String,
      description: (map['description'] ?? '') as String,
      isDone: (map['isDone'] ?? false) as bool,
      createdAt: toInt(map['createdAt']) ?? 0,
      dueDate: toInt(map['dueDate']),
      latitude: toDouble(map['latitude']),
      longitude: toDouble(map['longitude']),
      locationName: map['locationName'] as String?,
    );
  }
}
