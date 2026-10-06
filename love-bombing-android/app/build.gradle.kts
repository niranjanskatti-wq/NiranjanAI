plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("org.jetbrains.kotlin.plugin.compose")
    id("com.google.devtools.ksp")
}

// Release signing: CI or local env vars win; otherwise the bundled keystore
// is used so every build installs as an update over the previous one.
val keystorePath = System.getenv("LB_KEYSTORE_PATH") ?: rootProject.file("keystore/love-bombing.jks").path
val keystorePass = System.getenv("LB_KEYSTORE_PASSWORD") ?: "lovebombing"
val keyAliasName = System.getenv("LB_KEY_ALIAS") ?: "lovebombing"
val keyPass = System.getenv("LB_KEY_PASSWORD") ?: keystorePass

android {
    namespace = "com.lovebombing.app"
    compileSdk = 35

    defaultConfig {
        applicationId = "com.lovebombing.app"
        minSdk = 26
        targetSdk = 35
        versionCode = (System.getenv("LB_VERSION_CODE") ?: "1").toInt()
        versionName = "1.0." + (System.getenv("LB_VERSION_CODE") ?: "0")
    }

    signingConfigs {
        create("release") {
            storeFile = file(keystorePath)
            storePassword = keystorePass
            keyAlias = keyAliasName
            keyPassword = keyPass
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
            signingConfig = signingConfigs.getByName("release")
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = "17"
    }
    buildFeatures {
        compose = true
        buildConfig = false
    }
    packaging {
        resources.excludes += "/META-INF/{AL2.0,LGPL2.1}"
    }
    dependenciesInfo {
        // No Google Play dependency metadata blob in the APK.
        includeInApk = false
        includeInBundle = false
    }
}

dependencies {
    val composeBom = platform("androidx.compose:compose-bom:2024.10.01")
    implementation(composeBom)
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.foundation:foundation")
    implementation("androidx.compose.material3:material3")
    implementation("androidx.compose.material:material-icons-core")
    implementation("androidx.core:core-ktx:1.13.1")
    implementation("androidx.activity:activity-compose:1.9.3")
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.8.7")
    implementation("androidx.lifecycle:lifecycle-viewmodel-compose:2.8.7")
    implementation("androidx.room:room-runtime:2.6.1")
    implementation("androidx.room:room-ktx:2.6.1")
    implementation("androidx.sqlite:sqlite:2.4.0")
    ksp("androidx.room:room-compiler:2.6.1")
}
