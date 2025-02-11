package com.example.letsgo

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.os.Bundle
import android.content.Intent
import android.net.Uri
import android.app.ActivityOptions
import android.graphics.Rect
import android.view.Display

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.letsgo/app_info"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            call, result ->
            if (call.method == "getPackageName") {
                result.success(packageName)
            } else {
                result.notImplemented()
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
        
        // Set up display metrics for app embedding
        val metrics = resources.displayMetrics
        val rect = Rect(0, 0, metrics.widthPixels, metrics.heightPixels)
        
        window.decorView.post {
            try {
                val options = ActivityOptions.makeBasic()
                options.launchBounds = rect
                // This will help contain the launched app within our app's bounds
                window.attributes.type = android.view.WindowManager.LayoutParams.TYPE_APPLICATION
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent) {
        if (Intent.ACTION_VIEW == intent.action) {
            val uri = intent.data
            // Handle the URI here
        }
    }
}
