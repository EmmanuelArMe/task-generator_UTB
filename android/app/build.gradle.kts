plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // Plugin de Google Services: necesario para Firebase (lee google-services.json).
    id("com.google.gms.google-services")
}

android {
    namespace = "com.utb.task_manager"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.utb.task_manager"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    lint {
        // Reporta los hallazgos pero no aborta el build; se revisan en el
        // informe de seguridad (INFORME_SEGURIDAD.md).
        abortOnError = false
        // Falsos positivos / hallazgos fuera de nuestro control:
        //  - PropertyEscape: aplica a 'local.properties' (archivo generado por
        //    Flutter, específico de la máquina y NO versionado).
        //  - NotificationPermission: proviene del plugin geolocator; la app NO
        //    usa ubicación en segundo plano, así que por mínimo privilegio NO
        //    declaramos POST_NOTIFICATIONS.
        //  - ObsoleteSdkInt: carpeta de recursos generada por la plantilla.
        //  - GradleDependency: la versión de firebase-bom (33.5.1) está fijada
        //    a propósito por compatibilidad con los plugins de Flutter; no es
        //    un problema de seguridad, solo un aviso de "existe versión nueva".
        //  - DataExtractionRules: los backups ya están TOTALMENTE desactivados
        //    con allowBackup="false" (todas las versiones de Android) y se
        //    declaran dataExtractionRules (Android 12+); el aviso restante solo
        //    pide el atributo legacy fullBackupContent, redundante en este caso.
        disable += setOf(
            "PropertyEscape",
            "NotificationPermission",
            "ObsoleteSdkInt",
            "GradleDependency",
            "DataExtractionRules",
        )
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    // BoM de Firebase: alinea automáticamente las versiones de los SDK nativos.
    implementation(platform("com.google.firebase:firebase-bom:33.5.1"))
}
