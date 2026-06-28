import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/theme/app_theme.dart';

/// Pruebas del tema visual: garantizan que los temas claro y oscuro se
/// construyen correctamente (Material 3 y esquema de color coherente).
void main() {
  group('AppTheme', () {
    test('el tema claro usa Material 3 y brillo claro', () {
      final theme = AppTheme.light;
      expect(theme, isA<ThemeData>());
      expect(theme.useMaterial3, isTrue);
      expect(theme.colorScheme.brightness, Brightness.light);
    });

    test('el tema oscuro usa Material 3 y brillo oscuro', () {
      final theme = AppTheme.dark;
      expect(theme, isA<ThemeData>());
      expect(theme.useMaterial3, isTrue);
      expect(theme.colorScheme.brightness, Brightness.dark);
    });

    test('define estilos clave (AppBar, inputs, botones, tarjetas)', () {
      final theme = AppTheme.light;
      expect(theme.appBarTheme, isNotNull);
      expect(theme.inputDecorationTheme, isNotNull);
      expect(theme.filledButtonTheme, isNotNull);
      expect(theme.cardTheme, isNotNull);
      expect(theme.snackBarTheme, isNotNull);
    });
  });
}
