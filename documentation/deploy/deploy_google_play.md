# [Build and Release an Android App](https://docs.flutter.dev/deployment/android)

> **Ruta:** [Deployment](https://docs.flutter.dev/deployment) > Android

To test an app, you can use `flutter run` at the command line, or the **Run** and **Debug** options in your IDE.

When you're ready to prepare a _release_ version of your app, for example to [publish to the Google Play Store](https://play.google.com/), this page can help. Before publishing, you might want to put some finishing touches on your app. This guide explains how to perform the following tasks:

- [Add a launcher icon](#add-a-launcher-icon)
- [Enable Material Components](#enable-material-components)
- [Signing the app](#sign-the-app)
- [Shrink your code with R8](#shrink-your-code-with-r8)
- [Enable multidex support](#enable-multidex-support)
- [Review the app manifest](#review-the-app-manifest)
- [Review or Change the Gradle Build Configuration](#review-or-change-the-gradle-build-configuration)
- [Build the app for release](#build-the-app-for-release)
- [Publish to the Google Play Store](#publish-to-the-google-play-store)
- [Update the app’s version number](#update-the-apps-version-number)
- [Android release FAQ](#android-release-faq)

> 📌 **Note:**  
> Throughout this page, `[project]` refers to the directory that your application is in. While following these instructions, substitute `[project]` with your app’s directory.

## Add a Launcher Icon

When a new Flutter app is created, it has a default launcher icon. To customize this icon, you might want to check out the [flutter_launcher_icons](https://pub.dev/packages/flutter_launcher_icons) package.

Alternatively, you can do it manually using the following steps:

1. Review the [Material Design product icons](https://m3.material.io/styles/icons) guidelines for icon design.

2. In the `[project]/android/app/src/main/res/` directory, place your icon files in folders named using [configuration qualifiers](https://developer.android.com/guide/topics/resources/providing-resources#AlternativeResources). The default `mipmap-` folders demonstrate the correct naming convention.

3. In `AndroidManifest.xml`, update the [application](https://developer.android.com/guide/topics/manifest/application-element) tag’s `android:icon` attribute to reference icons from the previous step (for example, `<application android:icon="@mipmap/ic_launcher" ...>`).

4. To verify that the icon has been replaced, run your app and inspect the app icon in the Launcher.

## Enable Material Components

If your app uses [Platform Views](https://docs.flutter.dev/platform-integration/android/platform-views), you might want to enable Material Components by following the steps described in the [Getting Started guide for Android](https://m3.material.io/develop/android/mdc-android).

For example:

1. Add the dependency on Android's Material in `<my-app>/android/app/build.gradle`:

   ```kotlin
   dependencies {
        // ...
        implementation("com.google.android.material:material:<version>")
        // ...
    }
   ```

   To find out the latest version, visit [Google Maven](https://maven.google.com/web/index.html#com.google.android.material:material).

2. Set the light theme in `<my-app>/android/app/src/main/res/values/styles.xml`:

   ```xml
    - <style name="NormalTheme" parent="@android:style/Theme.Light.NoTitleBar">
    + <style name="NormalTheme" parent="Theme.MaterialComponents.Light.NoActionBar">
   ```

3. Set the dark theme in `<my-app>/android/app/src/main/res/values-night/styles.xml`:

   ```xml
    - <style name="NormalTheme" parent="@android:style/Theme.Black.NoTitleBar">
    + <style name="NormalTheme" parent="Theme.MaterialComponents.DayNight.NoActionBar">
   ```

## Sign the App

To publish on the Play Store, you need to sign your app with a digital certificate.

Android uses two signing keys: **upload key** and **app signing key**.

- Developers upload an `.aab` or `.apk` file signed with an **upload key** to the Play Store.
- The end-users download the `.apk` file signed with an **app signing key**.

To create your app signing key, use Play App Signing as described in the [official Play Store documentation](https://support.google.com/googleplay/android-developer/answer/7384423?hl=en).

To sign your app, use the following instructions.

### Create an Upload Keystore

If you have an existing keystore, skip to the next step. If not, create one using one of the following methods:

1. Follow the [Android Studio key generation steps](https://developer.android.com/studio/publish/app-signing).
2. Run the following command at the command line:

   ```bash
   keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA \
           -keysize 2048 -validity 10000 -alias upload
   ```

This command stores the `upload-keystore.jks` file in your home directory. If you want to store it elsewhere, change the argument you pass to the `-keystore` parameter.  
**However, keep the keystore file private; don’t check it into public source control!**

> 📌 **Note:**
>
> - The `keytool` command might not be in your path—it’s part of Java, which is installed as part of Android Studio. For the concrete path, run `flutter doctor -v` and locate the path printed after 'Java binary at:'. Then use that fully qualified path replacing `java` (at the end) with `keytool`.
> - If your path includes space-separated names, such as Program Files, use platform-appropriate notation for the names. For example, on macOS/Linux use `Program\ Files`, and on Windows use `"Program Files"`.
> - The `-storetype JKS` tag is only required for Java 9 or newer. As of the Java 9 release, the keystore type defaults to PKS12.

### Reference the Keystore from the App

Create a file named `[project]/android/key.properties` that contains a reference to your keystore. Don’t include the angle brackets (`< >`). They indicate that the text serves as a placeholder for your values.

```properties
storePassword=<password-from-previous-step>
keyPassword=<password-from-previous-step>
keyAlias=upload
storeFile=<keystore-file-location>
```

The `storeFile` might be located at `/Users/<user name>/upload-keystore.jks` on macOS.

> ⚠️ **Warning:**
>
> Keep the `key.properties` file private; don’t check it into public source control.

### Configure Signing in Gradle

When building your app in release mode, configure Gradle to use your upload key. To configure Gradle, edit the `<project>/android/app/build.gradle` file.

1. Define and load the keystore properties file before the `android` property block.

2. Set the `keystoreProperties` object to load the `key.properties` file.

   En el archivo `[project]/android/app/build.gradle`:

   ```kotlin
   + def keystoreProperties = new Properties()
   + def keystorePropertiesFile = rootProject.file('key.properties')
   + if (keystorePropertiesFile.exists()) {
   +     keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
   + }
   +
   android {
   ...
   }
   ```

3. Add the signing configuration before the `buildTypes` property block inside the `android` property block.

   En el archivo `[project]/android/app/build.gradle`:

   ```kotlin
   + android {
   +     // ...
   +
   +     signingConfigs {
   +         release {
   +             keyAlias = keystoreProperties['keyAlias']
   +             keyPassword = keystoreProperties['keyPassword']
   +             storeFile = keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
   +             storePassword = keystoreProperties['storePassword']
   +         }
   +     }
       buildTypes {
           release {
               // TODO: Add your own signing config for the release build.
               // Signing with the debug keys for now,
               // so `flutter run --release` works.
   -             signingConfig = signingConfigs.debug
   +             signingConfig = signingConfigs.release
           }
       }
   ...
   }
   ```

Flutter now signs all release builds.

> 📌 **Note:**
>
> You might need to run `flutter clean` after changing the Gradle file. This prevents cached builds from affecting the signing process.

To learn more about signing your app, check out [Sign your app](https://developer.android.com/studio/publish/app-signing.html#generate-key) on developer.android.com.

## Shrink Your Code with R8

[R8](https://developer.android.com/studio/build/shrink-code) is the new code shrinker from Google. It’s enabled by default when you build a release APK or AAB. To disable R8, pass the `--no-shrink` flag to `flutter build apk` or `flutter build appbundle`.

> 📌 **Note:**
>
> Obfuscation and minification can considerably extend compile time of the Android application.  
> The `--[no-]shrink` flag has no effect. Code shrinking is always enabled in release builds. To learn more, check out [Shrink, obfuscate, and optimize your app](https://developer.android.com/studio/build/shrink-code).

## Enable Multidex Support

When writing large apps or making use of large plugins, you might encounter Android’s dex limit of 64k methods when targeting a minimum API of 20 or below. This might also be encountered when running debug versions of your app using `flutter run` that does not have shrinking enabled.

Flutter tool supports easily enabling multidex. The simplest way is to opt into multidex support when prompted. The tool detects multidex build errors and asks before making changes to your Android project. Opting in allows Flutter to automatically depend on `androidx.multidex:multidex` and use a generated `FlutterMultiDexApplication` as the project’s application.

When you try to build and run your app with the **Run** and **Debug** options in your IDE, your build might fail with the following message:

```plaintext
DEBUG CONSOLE
BUILD FAILED in 3s
[!] App requires Multidex support
    Multidex support is required for your android app to build since the number of methods has exceeded 64k. See https://docs.flutter.dev/deployment/android#enabling-multidex-support for more information.
    You may pass the --no-multidex flag to skip Flutter's multidex support to use a manual solution.
    Flutter tool can add multidex support. The following file will be added by flutter:
        android/app/src/main/java/io/flutter/app/FlutterMultiDexApplication.java
    cannot prompt without a terminal ui
Exception: Gradle task assembleDebug failed with exit code 1
Exited
```

To enable multidex from the command line, run `flutter run --debug` and select an Android device:

```bash
Multiple devices found:
sdk gphone64 arm64 (mobile)       • emulator-5554                        • android-arm64  • Android 13 (API 33) (emulator)
iPhone 14 Pro Max (mobile)        • 8F367F76-7FB8-4452-B959-1DF41F189067 • ios            • com.apple.CoreSimulator.SimRuntime.iOS-16-1 (simulator)
macOS (desktop)                   • macos                                • darwin-arm64   • macOS 13.3 22E252 darwin-arm64
Chrome (web)                      • chrome                               • web-javascript • Google Chrome 111.0.5563.146

[1]: sdk gphone64 arm64 (emulator-5554)
[2]: iPhone 14 Pro Max (8F367F76-7FB8-4452-B959-1DF41F189067)
[3]: macOS (macos)
[4]: Chrome (chrome)
Please choose one (To quit, press "q/Q"): 1
```

When prompted, enter `y`. The Flutter tool enables multidex support and retries the build:

```plaintext
Running Gradle task 'assembleDebug'...
[!] App requires Multidex support
    Multidex support is required for your android app to build since the number of methods has exceeded 64k. See https://docs.flutter.dev/deployment/android#enabling-multidex-support for more information.
    You may pass the --no-multidex flag to skip Flutter's multidex support to use a manual solution.
    Flutter tool can add multidex support. The following file will be added by flutter:
        android/app/src/main/java/io/flutter/app/FlutterMultiDexApplication.java

Do you want to continue with adding multidex support for Android? [y/n]: y
Multidex enabled. Retrying build.

Retrying Gradle Build: #1, wait time: 100ms
Building with Flutter multidex support enabled...  9.2s
✔️ Running Gradle task 'assembleDebug'... done
Installing build/app/outputs/flutter-apk/app-debug-apk... 534ms
Syncing files to device sdk gphone64 arm64... 136ms

```

> 📌 **Note:**
>
> Multidex support is natively included when targeting Android SDK 21 or later. However, we don't recommend targeting API 21+ purely to resolve the multidex issue as this might inadvertently exclude users running older devices.

You might also choose to manually support multidex by following Android's guides and modifying your project's Android directory configuration. A [multidex keep file](https://developer.android.com/studio/build/multidex#keep) must be specified to include:

```text
io/flutter/embedding/engine/loader/FlutterLoader.class
io/flutter/util/PathUtils.class
```

Also, include any other classes used in app startup. For more detailed guidance on adding multidex support manually, check out the [official Android documentation](https://developer.android.com/studio/build/multidex).

## Review the App Manifest

Review the default [App Manifest](https://developer.android.com/guide/topics/manifest/manifest-intro) file.

En el archivo `[project]/android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application
        android:label="[project]"
        ...
    </application>
    ...
    <uses-permission android:name="android.permission.INTERNET"/>
</manifest>
```

Verify the following values:

| Tag                                                                                            | Attribute                                                                                                                                                                                                                                                                                                                                                              | Value                         |
| ---------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------- |
| [application](https://developer.android.com/guide/topics/manifest/application-element)         | Edit the `android:label` in the [application](https://developer.android.com/guide/topics/manifest/application-element) tag to reflect the final name of the app.                                                                                                                                                                                                       | The final name of the app     |
| [uses-permission](https://developer.android.com/guide/topics/manifest/uses-permission-element) | Add the `android.permission.INTERNET` [permission](https://developer.android.com/guide/topics/manifest/uses-permission-element) value to the `android:name` attribute if your app needs Internet access. The standard template doesn’t include this tag but allows Internet access during development to enable communication between Flutter tools and a running app. | `android.permission.INTERNET` |

## Review or Change the Gradle Build Configuration

To verify the Android build configuration, review the `android` block in the default [Gradle build script](https://developer.android.com/studio/build/#module-level). The default Gradle build script is found at `[project]/android/app/build.gradle`. You can change the values of any of these properties.

En el archivo `[project]/android/app/build.gradle`:

```kotlin
android {
    namespace = "com.example.[project]"
    // Any value starting with "flutter." gets its value from
    // the Flutter Gradle plugin.
    // To change from these defaults, make your changes in this file.
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    ...

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.[project]"
        // You can update the following values to match your application needs.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // These two properties use values defined elsewhere in this file.
        // You can set these values in the property declaration
        // or use a variable.
        versionCode = flutterVersionCode.toInteger()
        versionName = flutterVersionName
    }

    buildTypes {
        ...
    }
}
```

### Properties to Adjust in `build.gradle`

| Property             | Purpose                                                                                                                                                                                                                                                                   | Default Value              |
| -------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------- |
| `compileSdk`         | The Android API level against which your app is compiled. This should be the highest version available. If you set this property to 31, you run your app on a device running API 30 or earlier as long as your app makes no use of APIs specific to 31.                   |                            |
| `defaultConfig`      |                                                                                                                                                                                                                                                                           |                            |
| `.applicationId`     | The final, unique [application ID](https://developer.android.com/studio/build/application-id) that identifies your app.                                                                                                                                                   |                            |
| `.minSdk`            | The [minimum Android API level](https://developer.android.com/studio/publish/versioning#minsdk) for which you designed your app to run.                                                                                                                                   | `flutter.minSdkVersion`    |
| `.targetSdk`         | The Android API level against which you tested your app to run. Your app should run on all Android API levels up to this one.                                                                                                                                             | `flutter.targetSdkVersion` |
| `.versionCode`       | A positive integer that sets an [internal version number](https://developer.android.com/studio/publish/versioning). This number only determines which version is more recent than another. Greater numbers indicate more recent versions. App users never see this value. |                            |
| `.versionName`       | A string that your app displays as its version number. Set this property as a raw string or as a reference to a string resource.                                                                                                                                          |                            |
| `.buildToolsVersion` | The Gradle plugin specifies the default version of the Android build tools that your project uses. To specify a different version of the build tools, change this value.                                                                                                  |                            |

To learn more about Gradle, check out the module-level build section in the [Gradle build file](https://developer.android.com/studio/build/#module-level).

> 📌 **Note:**
>
> If you use a recent version of the Android SDK, you might get deprecation warnings about `compileSdkVersion`, `minSdkVersion` or `targetSdkVersion`. You can rename these properties to `compileSdk`, `minSdk`, and `targetSdk` respectively.

## Build the App for Release

You have two possible release formats when publishing to the Play Store:

- **App bundle** (preferred)
- **APK**

> 📌 **Note:**
>
> The Google Play Store prefers the app bundle format. To learn more, check out [About Android App Bundles](https://developer.android.com/guide/app-bundle).

### Build an App Bundle

This section describes how to build a release app bundle. If you completed the signing steps, the app bundle will be signed. At this point, you might consider [obfuscating your Dart code](https://developer.android.com/guide/app-bundle) to make it more difficult to reverse engineer. Obfuscating your code involves adding a couple of flags to your build command and maintaining additional files to de-obfuscate stack traces.

From the command line:

1. Enter `cd [project]`.
2. Run `flutter build appbundle`  
   (Running `flutter build` defaults to a release build.)

The release bundle for your app is created at `[project]/build/app/outputs/bundle/release/app.aab`.

By default, the app bundle contains your Dart code and the Flutter runtime compiled for [armeabi-v7a](https://developer.android.com/ndk/guides/abis#v7a) (ARM 32-bit), [arm64-v8a](https://developer.android.com/ndk/guides/abis#arm64-v8a) (ARM 64-bit), and [x86-64](https://developer.android.com/ndk/guides/abis#86-64) (x86 64-bit).

### Test the App Bundle

An app bundle can be tested in multiple ways. This section describes two.

#### Offline Using the Bundle Tool

1. If you haven’t done so already, download `bundletool` from the [GitHub repository](https://github.com/google/bundletool/releases/latest).
2. [Generate a set of APKs](https://developer.android.com/studio/command-line/bundletool#generate_apks) from your app bundle.
3. [Deploy the APKs](https://developer.android.com/studio/command-line/bundletool#deploy_with_bundletool) to connected devices.

#### Online Using Google Play

1. Upload your bundle to Google Play to test it. You can use the internal test track, or the alpha or beta channels to test the bundle before releasing it in production.
2. Follow [these steps to upload your bundle](https://developer.android.com/studio/publish/upload-bundle) to the Play Store.

### Build an APK

Although app bundles are preferred over APKs, there are stores that don’t yet support app bundles. In this case, build a release APK for each target ABI (Application Binary Interface).

If you completed the signing steps, the APK will be signed. At this point, you might consider [obfuscating your Dart code](https://docs.flutter.dev/deployment/obfuscate) to make it more difficult to reverse engineer. Obfuscating your code involves adding a couple of flags to your build command.

From the command line:

1. Enter `cd [project]`.
2. Run `flutter build apk --split-per-abi`. (The `flutter build` command defaults to `--release`.)

This command results in three APK files:

- `[project]/build/app/outputs/apk/release/app-armeabi-v7a-release.apk`
- `[project]/build/app/outputs/apk/release/app-arm64-v8a-release.apk`
- `[project]/build/app/outputs/apk/release/app-x86_64-release.apk`

Removing the `--split-per-abi` flag results in a fat APK that contains your code compiled for **all** the target ABIs. Such APKs are larger in size than their split counterparts, causing the user to download native binaries that are not applicable to their device's architecture.

### Install an APK on a Device

Follow these steps to install the APK on a connected Android device.

From the command line:

1. Connect your Android device to your computer with a USB cable.
2. Enter `cd [project]`.
3. Run `flutter install`.

## Publish to the Google Play Store

For detailed instructions on publishing your app to the Google Play Store, check out the [Google Play launch](https://developer.android.com/distribute) documentation.

## Update the App’s Version Number

The default version number of the app is `1.0.0`. To update it, navigate to the `pubspec.yaml` file and update the following line:

```yaml
version: 1.0.0+1
```

The version number is three numbers separated by dots, such as `1.0.0` in the example above, followed by an optional build number such as `1` in the example above, separated by a `+`.

Both the version and the build number can be overridden in Flutter’s build by specifying `--build-name` and `--build-number`, respectively.

In Android, `build-name` is used as `versionName` while `build-number` is used as `versionCode`. For more information, check out [Version your app](https://developer.android.com/studio/publish/versioning) in the Android documentation.

When you rebuild the app for Android, any updates in the version number from the `pubspec.yaml` file will update the `versionName` and `versionCode` in the `local.properties` file.

## Android Release FAQ

Here are some commonly asked questions about deployment for Android apps.

### When Should I Build App Bundles Versus APKs?

The Google Play Store recommends that you deploy app bundles over APKs because they allow a more efficient delivery of the application to your users. However, if you’re distributing your application by means other than the Play Store, an APK might be your only option.

### What Is a Fat APK?

A [fat APK](https://en.wikipedia.org/wiki/Fat_binary) is a single APK that contains binaries for multiple ABIs embedded within it. This has the benefit that the single APK runs on multiple architectures and thus has wider compatibility, but it has the drawback that its file size is much larger, causing users to download and store more bytes when installing your application. When building APKs instead of app bundles, it is strongly recommended to build split APKs, as described in [build an APK](https://docs.flutter.dev/deployment/android#build-an-apk) using the `--split-per-abi` flag.

### What Are the Supported Target Architectures?

When building your application in release mode, Flutter apps can be compiled for:

- [armeabi-v7a](https://developer.android.com/ndk/guides/abis#v7a) (ARM 32-bit)
- [arm64-v8a](https://developer.android.com/ndk/guides/abis#arm64-v8a) (ARM 64-bit)
- [x86-64](https://developer.android.com/ndk/guides/abis#86-64) (x86 64-bit)

### How Do I Sign the App Bundle Created by `flutter build appbundle`?

See [Signing the app](https://docs.flutter.dev/deployment/android#signing-the-app).

### How Do I Build a Release from Within Android Studio?

In Android Studio, open the existing `android/` folder under your app's folder. Then, select `build.gradle (Module: app)` in the project panel.

La estructura de archivos y directorios es la siguiente:

```plaintext
app/
├── manifests/
├── java/
├── generatedJava/
├── res/
└── Gradle Scripts/
    ├── build.gradle (Project: android)
    ├── build.gradle (Module: app)
    ├── gradle-wrapper.properties (Gradle Version)
    ├── gradle.properties (Project Properties)
    ├── settings.gradle (Project Settings)
    └── local.properties (SDK Location)
```

Next, select the build variant. Click **Build > Select Build Variant** in the main menu. Select any of the variants in the **Build Variants** panel (debug is the default):

La lista de variantes disponibles es:

- **debug**
- **dynamicProfile**
- **dynamicRelease**
- **profile**
- **release** (seleccionado)

The resulting app bundle or APK files are located in `build/app/outputs` within your app's folder.

---

_Unless stated otherwise, the documentation on this site reflects the latest stable version of Flutter. Page last updated on 2024-08-20._  
[View source](https://github.com/flutter/website/blob/main/src/content/deployment/android.md) or [report an issue](https://github.com/flutter/website/issues/new?template=1_page_issue.yml&&page-url=https://docs.flutter.dev/deployment/android/&page-source=https://github.com/flutter/website/tree/main/src/content/deployment/android.md).
