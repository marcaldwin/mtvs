plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.mtvts_app"

    // SDK / NDK
    compileSdk = 36
    ndkVersion = "29.0.13599879"

    defaultConfig {
        applicationId = "com.example.mtvts_app"
        minSdk = flutter.minSdkVersion
        targetSdk = 35        // ✅ targetSdk belongs here
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Java / Kotlin 17
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = "17"
    }

    buildTypes {
        release {
            // TODO: replace with your release keystore
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

// Gradle toolchains will provision JDK 17 automatically
java {
    toolchain {
        languageVersion.set(JavaLanguageVersion.of(17))
    }
}
