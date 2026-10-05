plugins {
    id("com.android.application")
}

// Each CI build gets a higher version code so the APK installs as an update.
val buildNumber = (System.getenv("GITHUB_RUN_NUMBER") ?: "1").toInt()

android {
    namespace = "com.swarnacalc.app"
    compileSdk = 35

    defaultConfig {
        applicationId = "com.swarnacalc.app"
        minSdk = 24
        targetSdk = 35
        versionCode = buildNumber
        versionName = "1.0.$buildNumber"
    }

    // One signing key for every build (kept in the GitHub Actions cache, never
    // in the code), so each new APK installs over the last one and keeps data.
    val buildKey = file("swarnacalc-build.jks")
    signingConfigs {
        if (buildKey.exists()) {
            create("build") {
                storeFile = buildKey
                storePassword = "swarnacalc-build"
                keyAlias = "swarnacalc"
                keyPassword = "swarnacalc-build"
            }
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            signingConfig = if (buildKey.exists()) signingConfigs.getByName("build") else signingConfigs.getByName("debug")
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    // The web app itself is bundled straight from public/swarnacalc.
    sourceSets {
        getByName("main") {
            assets.srcDir("../../public")
        }
    }
}

dependencies {
    implementation("androidx.webkit:webkit:1.12.1")
    implementation("androidx.core:core:1.13.1")
}
