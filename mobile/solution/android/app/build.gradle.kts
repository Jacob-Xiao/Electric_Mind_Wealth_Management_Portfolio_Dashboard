plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android gradle plugin.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.electricmind.electric_mind_portfolio"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Required by flutter_local_notifications (Task 6).
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        applicationId = "com.electricmind.electric_mind_portfolio"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }
    buildTypes {
        release { signingConfig = signingConfigs.getByName("debug") }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter { source = "../.." }

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
