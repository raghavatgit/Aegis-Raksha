plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.raksha_emergency_mesh"
    compileSdk = 36
    // ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.raksha_emergency_mesh"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}

tasks.matching { it.name == "assembleRelease" }.configureEach {
    doLast {
        val srcApk = file("C:/flutter_builds/Raksha-Net/app/outputs/flutter-apk/app-release.apk")
        val dstDir = file("${project.rootDir}/../build/app/outputs/flutter-apk")
        if (srcApk.exists()) {
            dstDir.mkdirs()
            srcApk.copyTo(file("$dstDir/app-release.apk"), overwrite = true)
            println("✅ Mirrored newly compiled release APK to: $dstDir/app-release.apk")
        }
    }
}