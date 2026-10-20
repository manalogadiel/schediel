import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Sharing settings the app also builds with (--dart-define-from-file=env/sharing.json;
// git-ignored, see README "Online sharing"). Gradle properties override them.
val sharingDefines: Map<*, *> = rootProject.file("../env/sharing.json").let { file ->
    if (file.exists()) groovy.json.JsonSlurper().parse(file) as Map<*, *> else emptyMap<String, String>()
}

// Host used for verified share links (Android App Links). Sharing stays off until a real
// owned domain is deployed and configured; ".invalid" is reserved and never resolves.
val shareHost: String = (project.findProperty("schediel.shareHost") as String?)
    ?: (sharingDefines["SCHEDIEL_SHARE_HOST"] as String?)?.takeIf { it.isNotBlank() }
    ?: "schediel.invalid"
// Optional second owned host the browser preview hands off to. Browsers keep same-host
// navigation in the browser, so it must differ from shareHost. When unset it repeats
// shareHost: on Android 11 and lower every autoVerify host must verify, so an
// unresolvable placeholder would stop the real share host from opening the app.
val appLinkHost: String = (project.findProperty("schediel.appLinkHost") as String?)
    ?: (sharingDefines["SCHEDIEL_APP_LINK_HOST"] as String?)?.takeIf { it.isNotBlank() }
    ?: shareHost

// Release signing comes from android/key.properties (git-ignored; see README
// "Release signing"). A relative storeFile is read from android/, next to
// key.properties. Without the file, release builds fall back to the debug key
// so `flutter run --release` keeps working, and say so; a key.properties that
// names a missing keystore fails the build instead of silently falling back.
val keyProperties = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) file.inputStream().use { load(it) }
}
val releaseStoreFile: File? = keyProperties.getProperty("storeFile")?.let { rootProject.file(it) }
if (releaseStoreFile != null && !releaseStoreFile.exists()) {
    throw GradleException("android/key.properties names a keystore that does not exist: $releaseStoreFile")
}
val buildsRelease = gradle.startParameter.taskNames.any { it.contains("release", ignoreCase = true) }
if (releaseStoreFile == null && buildsRelease) {
    logger.warn("WARNING: android/key.properties not found; this release build is signed with the DEBUG key (see README \"Release signing\").")
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
        if (releaseStoreFile != null) {
            create("release") {
                storeFile = releaseStoreFile
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
