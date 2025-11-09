import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.gmail.farajiMohsen.daily_work"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "29.0.13113456"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.gmail.farajiMohsen.daily_work"
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }
    flavorDimensions += listOf("abi")
    productFlavors {
        create("armv7a") {
            dimension = "abi"
//            ndk {
//                abiFilters += listOf("armeabi-v7a")
//            }
            versionCode = 1021
        }
        create("arm64") {
            dimension = "abi"
//            ndk {
//                abiFilters += listOf("arm64-v8a")
//            }
            versionCode = 1022
        }
        create("x86_64") {
            dimension = "abi"
//            ndk {
//                abiFilters += listOf("x86_64")
//            }
            versionCode = 1023
        }
//        create("universal") {
//            dimension = "abi"
//            ndk {
//                abiFilters += listOf("armeabi-v7a", "arm64-v8a", "x86_64")
//            }
//            versionCode = 1024
//        }
    }

    signingConfigs {
        create("release") {
            val keystoreProperties = Properties()
            val keystorePropertiesFile = rootProject.file("key.properties")
            if (keystorePropertiesFile.exists()) {
                keystoreProperties.load(FileInputStream(keystorePropertiesFile))
                keyAlias = keystoreProperties["keyAlias"].toString()
                keyPassword = keystoreProperties["keyPassword"].toString()
                storeFile = file(keystoreProperties["storeFile"].toString())
                storePassword = keystoreProperties["storePassword"].toString()
            }
        }
    }


    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            // signingConfig = signingConfigs.getByName("debug")
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
        }
    }
}

flutter {
    source = "../.."
}

// برای ساخت هر خروجی، دستور زیر را اجرا کنید:
// flutter build apk --flavor armv7a --release
// flutter build apk --flavor arm64 --release
// flutter build apk --flavor x86_64 --release
// flutter build apk --release --split-per-abi