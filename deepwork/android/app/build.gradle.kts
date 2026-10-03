import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.niranjan.deepwork"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Needed by the notifications plugin for scheduled reminders on older Android.
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.niranjan.deepwork"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Store native libraries compressed: a much smaller APK, unpacked once at install.
    packaging {
        jniLibs {
            useLegacyPackaging = true
        }
    }

    // Release signing comes from android/key.properties (written by the build
    // workflow, never committed). Without it, the debug key is used so local
    // builds still work.
    val keyProps = Properties()
    val keyFile = rootProject.file("key.properties")
    if (keyFile.exists()) keyFile.inputStream().use { keyProps.load(it) }

    signingConfigs {
        if (keyFile.exists()) {
            create("release") {
                storeFile = file(keyProps.getProperty("storeFile"))
                storePassword = keyProps.getProperty("storePassword")
                keyAlias = keyProps.getProperty("keyAlias")
                keyPassword = keyProps.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (keyFile.exists()) signingConfigs.getByName("release")
                else signingConfigs.getByName("debug")
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

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
