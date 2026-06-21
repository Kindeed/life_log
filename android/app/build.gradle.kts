import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.wzh.lifelog"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.wzh.lifelog"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    val keystoreProperties = Properties()
    val keystorePropertiesFile = rootProject.file("key.properties")
    if (keystorePropertiesFile.exists()) {
        keystoreProperties.load(FileInputStream(keystorePropertiesFile))
    }
    val releaseKeyAlias = keystoreProperties.getProperty("keyAlias")
    val releaseKeyPassword = keystoreProperties.getProperty("keyPassword")
    val releaseStorePassword = keystoreProperties.getProperty("storePassword")
    val releaseStoreFilePath = keystoreProperties.getProperty("storeFile")
    val releaseStoreFile = releaseStoreFilePath?.let { file(it) }
    val releaseSigningReady = !releaseKeyAlias.isNullOrBlank() &&
        !releaseKeyPassword.isNullOrBlank() &&
        !releaseStorePassword.isNullOrBlank() &&
        !releaseStoreFilePath.isNullOrBlank() &&
        releaseStoreFile?.exists() == true

    signingConfigs {
        create("release") {
            if (releaseSigningReady) {
                keyAlias = releaseKeyAlias
                keyPassword = releaseKeyPassword
                storePassword = releaseStorePassword
                storeFile = releaseStoreFile
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            
            // Enable R8 shrinking and obfuscation
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }

    gradle.taskGraph.whenReady {
        val hasReleaseTask = allTasks.any { it.name.contains("Release") }
        if (hasReleaseTask && !releaseSigningReady) {
            throw GradleException(
                "Release signing config missing. Configure android/key.properties with keyAlias, keyPassword, storePassword, and an existing storeFile; release builds must not fall back to debug signing."
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("com.google.mlkit:text-recognition-chinese:16.0.1")
}
