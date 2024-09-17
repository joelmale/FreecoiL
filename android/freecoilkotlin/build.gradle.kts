plugins {
    id("com.android.library")
    id("kotlin-android")
}

import com.android.build.gradle.tasks.BundleAar

        android {
            namespace = "com.feralbytes.games.freecoilkotlin"
            compileSdk = 34

            defaultConfig {
                minSdk = 25
                testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
                //versionCode = 3
                //versionName = "0.3.2"
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

// Configure the BundleAar tasks to set the custom output file name
tasks.withType<BundleAar>().configureEach {
    archiveFileName.set("FreecoiL.${variantName}.aar")
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
