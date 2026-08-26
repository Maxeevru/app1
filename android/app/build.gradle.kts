plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.untitled"
    compileSdk = 34 // Явно указали 34
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.example.untitled"
        minSdk = 22    // Подняли до 22 ради окон поверх экрана
        targetSdk = 34 // Выставили 34
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
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
