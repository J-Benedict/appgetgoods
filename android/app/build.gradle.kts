plugins {
    id("com.android.application")
    id("com.google.gms.google-services") // Firebase configuration
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id ("org.jetbrains.kotlin.android")
}



buildscript {
    dependencies {
        classpath 'com.google.gms:google-services:4.3.15'
    }
}

android {
    namespace = "com.example.getgoods"
    compileSdk = 33
    ndkVersion = "25.2.9519653"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    defaultConfig {
        applicationId = "com.example.getgoods"
        minSdk = 21
        targetSdk = 33
        compileSdkVersion = 33
        versionCode = 2
        versionName = "2.0.0"
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug") // Replace with "release" for production
            isMinifyEnabled = false
            isShrinkResources = false
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:33.5.1"))
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.firebase:firebase-firestore")
    classpath 'com.google.gms:google-services:4.3.15'
}

flutter {
    source = "../.."
}

plugins {
    id("com.google.gms.google-services") version "4.4.0" apply false
}

