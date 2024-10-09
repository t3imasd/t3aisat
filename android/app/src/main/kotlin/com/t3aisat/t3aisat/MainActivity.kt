package com.t3aisat.t3aisat

import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.t3aisat.version"

    override fun configureFlutterEngine(flutterEngine: io.flutter.embedding.engine.FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getAndroidSDKVersion") {
                // Obtén la versión del SDK de Android
                val sdkInt = Build.VERSION.SDK_INT
                result.success(sdkInt)
            } else {
                result.notImplemented()
            }
        }
    }
}
