pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

// These versions match the Flutter 3.47 Android template
// (flutter/packages/flutter_tools/lib/src/android/gradle_utils.dart) and satisfy the
// minimums the Flutter Gradle plugin enforces:
//   Gradle >= 8.14.0, AGP >= 8.11.1, KGP >= 2.2.20
// AGP 9.1.0 is paired with Gradle 9.3.1 by Flutter's own compatibility table.
// Note: KGP is declared (but not applied) here because AGP 9 + `android.builtInKotlin=false`
// compiles Kotlin through the legacy KGP, which Flutter's Gradle plugin applies to each
// module that applies AGP without declaring KGP itself.
plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "9.1.0" apply false
    id("org.jetbrains.kotlin.android") version "2.4.0" apply false
}

include(":app")
