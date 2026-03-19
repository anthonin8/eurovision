plugins {
    id("com.android.application")
    id("kotlin-android")
    // Le plugin Gradle de Flutter doit être appliqué après les plugins Android et Kotlin.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.flutter_application_1"
    
    // Correction : On force la version 34 demandée par les nouveaux plugins
    compileSdk = 35
    
    // Correction : On force la version précise du NDK réclamée par share_plus et path_provider
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.flutter_application_1"
        
        // On garde le minSdk par défaut de Flutter (souvent 21)
        minSdk = flutter.minSdkVersion
        
        // Correction : On force le targetSdk à 34
        targetSdk = 35
        
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Configuration de signature pour le build release
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}