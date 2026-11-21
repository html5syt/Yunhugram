plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

// 正式签名从运行设置读取，不把密钥或密码保存进仓库。
val storePath = System.getenv("ANDROID_KEYSTORE_PATH").orEmpty()
val storePasswordValue = System.getenv("ANDROID_KEYSTORE_PASSWORD").orEmpty()
val aliasValue = System.getenv("ANDROID_KEY_ALIAS").orEmpty()
val keyPasswordValue = System.getenv("ANDROID_KEY_PASSWORD").orEmpty()
val signingReady = listOf(storePath, storePasswordValue, aliasValue, keyPasswordValue).all { it.isNotBlank() }
if (System.getenv("YH_REQUIRE_SIGNING") == "1" && !signingReady) {
    throw GradleException("缺少正式签名设置，不生成或发布未正式签名的版本")
}

android {
    namespace = "com.html5syt.yunhugram"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "28.2.13676358"
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    defaultConfig {
        // 应用标识保持稳定，后续版本沿用以支持升级。
        applicationId = "com.html5syt.yunhugram"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }
    signingConfigs {
        if (signingReady) {
            create("release") {
                storeFile = file(storePath)
                storePassword = storePasswordValue
                keyAlias = aliasValue
                keyPassword = keyPasswordValue
            }
        }
    }
    buildTypes {
        release {
            // 没有密钥时保持未签名，绝不回退到调试签名。
            if (signingReady) signingConfig = signingConfigs.getByName("release")
        }
    }
}
kotlin {
    compilerOptions { jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17 }
}
flutter { source = "../.." }
