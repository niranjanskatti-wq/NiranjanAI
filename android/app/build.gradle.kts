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

    // A fixed key so every new APK installs over the old one and keeps your data.
    signingConfigs {
        create("release") {
            storeFile = file("swarnacalc.keystore")
            storePassword = "swarnacalc"
            keyAlias = "swarnacalc"
            keyPassword = "swarnacalc"
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            signingConfig = signingConfigs.getByName("release")
        }
        debug {
            signingConfig = signingConfigs.getByName("release")
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
