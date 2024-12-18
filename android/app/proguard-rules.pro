-keep class io.flutter.app.** { *; }
-keep class com.t3aisat.t3aisat.** { *; }
-keep public class * extends android.app.Application
-keep public class * extends io.flutter.embedding.android.FlutterActivity
-dontwarn io.flutter.embedding.**

# Mapbox
-keep class com.mapbox.** { *; }
-keep class okhttp3.** { *; }
-dontwarn com.mapbox.**

# FFmpeg
-keep class com.arthenica.ffmpegkit.** { *; }
-dontwarn com.arthenica.ffmpegkit.**

# Photo Manager and Native Exif
-keep class com.fluttercandies.photo_manager.** { *; }
-keep class com.fluttercandies.exif.** { *; }

# Permissions Handler
-dontwarn com.baseflow.permissionhandler.**

# URL Launcher
-dontwarn io.flutter.plugins.urllauncher.**

# ObjectBox (native databases)
-keep class io.objectbox.** { *; }
-dontwarn io.objectbox.**

# Image Picker
-dontwarn io.flutter.plugins.imagepicker.**

# Geolocator
-keep class com.baseflow.geolocator.** { *; }
-dontwarn com.baseflow.geolocator.**

# Video Player
-keep class io.flutter.plugins.videoplayer.** { *; }
-dontwarn io.flutter.plugins.videoplayer.**

# Shared Preferences
-dontwarn io.flutter.plugins.sharedpreferences.**

# Flutter Native Splash
-dontwarn dev.fluttercommunity.plus.splashscreen.**

# Flutter Dotenv
-dontwarn io.github.dotenv.**

# Flutter Markdown
-dontwarn io.flutter.plugins.markdown.**

# Path Provider
-dontwarn io.flutter.plugins.pathprovider.**

# Saver Gallery
-dontwarn io.flutter.plugins.savergallery.**

# Vibration
-dontwarn com.example.vibration.**

# Camera
-keep class io.flutter.plugins.camera.** { *; }
-dontwarn io.flutter.plugins.camera.**

# Share Plus
-dontwarn dev.fluttercommunity.plus.share.**

# Please add these rules to your existing keep rules in order to suppress warnings.
# This is generated automatically by the Android Gradle plugin.
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication

# Flutter specific rules
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# SharedPreferences rules
-keep class android.app.** { *; }
-keep class androidx.preference.** { *; }

# Keep your Markdown files
-keep class assets.** { *; }
-keep class assets.documents.** { *; }
