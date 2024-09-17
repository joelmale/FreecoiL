import java.util.Properties

plugins {
    id("com.android.library")
    id("kotlin-android")
}
java {
    toolchain {
        languageVersion.set(JavaLanguageVersion.of(17))
    }
}
kotlin {
    jvmToolchain(17)
}

android {
    namespace = "com.feralbytes.games.freecoilkotlin"
    compileSdk = 34

    defaultConfig {
        minSdk = 25
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
        //versionCode = 3
        //versionName = "0.3.2"
        // Load Map API
        // Define a function to read properties from secrets.properties
        val properties = Properties()
        val secretsFile = rootProject.file("secrets.properties")
        if (secretsFile.exists()) {
            properties.load(secretsFile.inputStream())
        }

        // Get the API key and set it as a build config field
        val apiKey = properties.getProperty("MAPS_API_KEY", "DEFAULT_API_KEY")
        buildConfigField("String", "MAPS_API_KEY", "\"$apiKey\"")
    }

    lint {
        abortOnError = false
    }

    buildFeatures {
        buildConfig = true
        dataBinding = true
    }
    /*buildTypes {
        getByName("debug") {
            buildConfigField("String", "ApiKeyMap", ApiKeyMap)
            resValue("string", "api_key_map", ApiKeyMap)
        }
        getByName("release") {
            buildConfigField("String", "ApiKeyMap", ApiKeyMap)
            resValue("string", "api_key_map", ApiKeyMap)
        }
    }*/
}

dependencies {
    implementation("com.google.android.gms:play-services-maps:19.0.0")
    implementation("org.jetbrains.kotlin:kotlin-stdlib:2.0.20")
    implementation("com.google.android.gms:play-services-location:21.3.0")
    implementation("com.google.android.gms:play-services-auth:21.2.0")
    implementation("androidx.appcompat:appcompat:1.7.0")
    implementation("androidx.legacy:legacy-support-v4:1.0.0")
    implementation("androidx.core:core-ktx:1.15.0-alpha02")
    implementation("com.google.android.gms:play-services-gcm:17.0.0")
    implementation("com.android.support:multidex:1.0.3")

    testImplementation("junit:junit:4.13.2")
    androidTestImplementation("androidx.test:runner:1.6.2")
    androidTestImplementation("androidx.test.espresso:espresso-core:3.6.1")

    compileOnly(fileTree(mapOf("dir" to "libs", "include" to listOf("godot-lib*.aar"))))
}

repositories {
    mavenCentral()
}
