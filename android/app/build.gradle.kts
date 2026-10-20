import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Host used for verified share links (Android App Links). Sharing stays off until a real
// owned domain is deployed and configured; ".invalid" is reserved and never resolves.
val shareHost: String = (project.findProperty("schediel.shareHost") as String?) ?: "schediel.invalid"
// Optional second owned host the browser preview hands off to. Browsers keep same-host
// navigation in the browser, so it must differ from shareHost. When unset it repeats
// shareHost: on Android 11 and lower every autoVerify host must verify, so an
// unresolvable placeholder would stop the real share host from opening the app.
val appLinkHost: String = (project.findProperty("schediel.appLinkHost") as String?) ?: shareHost

// Release signing comes from android/key.properties (git-ignored; see README
// "Release signing"). Without it, release builds fall back to the debug key so
// `flutter run --release` keeps working.
val keyProperties = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) file.inputStream().use { load(it) }
}

android {
    namespace = "com.manalogadiel.schediel"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Required by flutter_local_notifications for scheduled notifications.
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.manalogadiel.schediel"
        // Proposed baseline (spec D02): Android API 26+.
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["shareHost"] = shareHost
        manifestPlaceholders["appLinkHost"] = appLinkHost
    }

    testOptions {
        // JVM tests read the shared cross-language fixtures (CONTRACTS.md section 8).
        unitTests.all {
            it.systemProperty("schediel.contractsDir", rootProject.file("../contracts").absolutePath)
        }
    }

    signingConfigs {
        if (keyProperties.getProperty("storeFile") != null) {
            create("release") {
                storeFile = file(keyProperties.getProperty("storeFile"))
                storePassword = keyProperties.getProperty("storePassword")
                keyAlias = keyProperties.getProperty("keyAlias")
                keyPassword = keyProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.findByName("release") ?: signingConfigs.getByName("debug")
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    testImplementation("junit:junit:4.13.2")
    // Real org.json for JVM tests (android.jar only ships stubs).
    testImplementation("org.json:json:20240303")
}

flutter {
    source = "../.."
}
