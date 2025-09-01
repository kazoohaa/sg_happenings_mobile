plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.sg_happenings_mobile"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.sg_happenings_mobile"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["app_name"] = "SG Happenings Mobile"
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    flavorDimensions += "environment"
    productFlavors {
        create("dev") {
            dimension = "environment"
            applicationIdSuffix = ".dev"
            manifestPlaceholders["app_name"] = "Dev SG Happenings"
        }
        create("sit") {
            dimension = "environment"
            applicationIdSuffix = ".sit"
            manifestPlaceholders["app_name"] = "SIT SG Happenings"
        }
        create("uat") {
            dimension = "environment"
            applicationIdSuffix = ".uat"
            manifestPlaceholders["app_name"] = "UAT SG Happenings"
        }
        create("prod") {
            dimension = "environment"
            applicationIdSuffix = ".prod"
            manifestPlaceholders["app_name"] = "SG Happenings"
        }
    }
}

flutter {
    source = "../.."
}
