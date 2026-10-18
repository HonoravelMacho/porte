import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// PORTE: assinatura release via key.properties (CI) — cai p/ debug no teste local.
val keystoreProps = Properties()
val keystorePropsFile = project.file("key.properties")
if (keystorePropsFile.exists()) keystoreProps.load(keystorePropsFile.inputStream())

android {
    namespace = "dev.porte.porte"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "dev.porte.porte"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("porteRelease") {
            if (keystorePropsFile.exists()) {
                storeFile = file(keystoreProps.getProperty("storeFile") ?: "release.keystore")
                storePassword = keystoreProps.getProperty("storePassword")
                keyAlias = keystoreProps.getProperty("keyAlias")
                keyPassword = keystoreProps.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (keystorePropsFile.exists()) {
                signingConfigs.getByName("porteRelease")
            } else {
                // Teste local/CI sem secrets: chaves de debug (instalável, não é Play).
                signingConfigs.getByName("debug")
            }
        }
    }

    packaging {
        jniLibs {
            // OBRIGATÓRIO para o MARTELOS: o Android 10+ só permite executar
            // binários do nativeLibraryDir, e por padrão (extractNativeLibs=false)
            // os .so ficam DENTRO do APK sem extração — libmartelos.so nunca
            // existiria no filesystem. useLegacyPackaging força a extração.
            useLegacyPackaging = true
        }
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
