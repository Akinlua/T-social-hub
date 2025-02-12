package com.example.letsgo

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.os.Bundle
import android.content.Intent
import android.net.Uri
import android.app.ActivityOptions
import android.graphics.Rect
import android.content.pm.PackageManager
import android.view.WindowManager
import android.view.Gravity
import android.graphics.PixelFormat
import android.provider.Settings
import android.app.AppOpsManager
import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import java.io.File
import java.io.FileOutputStream
import android.app.ActivityManager

class MainActivity: FlutterActivity() {
    private val APP_LAUNCHER_CHANNEL = "com.example.letsgo/app_launcher"
    private val APP_ICONS_CHANNEL = "com.example.letsgo/app_icons"

    private companion object {
        const val LAST_APP_PREF = "last_opened_app"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Existing app launcher channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, APP_LAUNCHER_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "launchApp" -> {
                        val packageName = call.argument<String>("packageName")
                        if (packageName != null) {
                            launchAppOverlay(packageName, result)
                        } else {
                            result.error("INVALID_PACKAGE", "Package name is required", null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }

        // New channel for app icons
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, APP_ICONS_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getAppIcon" -> {
                        val packageName = call.argument<String>("packageName")
                        if (packageName != null) {
                            try {
                                val drawable = packageManager.getApplicationIcon(packageName)
                                val bitmap = drawableToBitmap(drawable)
                                val file = saveBitmapToFile(bitmap)
                                result.success(file.absolutePath)
                            } catch (e: Exception) {
                                result.error("ICON_ERROR", e.message, null)
                            }
                        } else {
                            result.error("INVALID_PACKAGE", "Package name is required", null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun launchAppOverlay(packageName: String, result: MethodChannel.Result) {
        try {
            // Save as last opened app
            getSharedPreferences("app_prefs", Context.MODE_PRIVATE)
                .edit()
                .putString(LAST_APP_PREF, packageName)
                .apply()

            // Check for overlay permission
            if (!android.provider.Settings.canDrawOverlays(this)) {
                val intent = android.content.Intent(
                    android.provider.Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                    android.net.Uri.parse("package:$packageName")
                )
                startActivityForResult(intent, 1234)
                result.error("OVERLAY_PERMISSION", "Overlay permission is required", null)
                return
            }

            val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
            val taskId = activityManager.appTasks.firstOrNull()?.taskInfo?.id ?: -1

            // Start floating navigation service
            val serviceIntent = Intent(this, FloatingNavigationService::class.java)
            startService(serviceIntent)

            // Launch the requested app with no animation and exclude from recents
            val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
            if (launchIntent != null) {
                launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_DOCUMENT)
                launchIntent.addFlags(Intent.FLAG_ACTIVITY_MULTIPLE_TASK)
                launchIntent.addFlags(Intent.FLAG_ACTIVITY_NO_ANIMATION)
                launchIntent.addFlags(Intent.FLAG_ACTIVITY_EXCLUDE_FROM_RECENTS)
                launchIntent.putExtra("android.activity.taskId", taskId)
                startActivity(launchIntent)
                overridePendingTransition(0, 0)
                result.success(true)
            } else {
                result.error("APP_NOT_FOUND", "Application $packageName not installed", null)
            }
        } catch (e: Exception) {
            result.error("LAUNCH_ERROR", e.message, null)
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == 1234) {
            if (android.provider.Settings.canDrawOverlays(this)) {
                // Permission granted, retry launching the app
                val serviceIntent = Intent(this, FloatingNavigationService::class.java)
                startService(serviceIntent)
            }
        }
    }

    private fun dpToPx(dp: Int): Int {
        val density = resources.displayMetrics.density
        return (dp * density).toInt()
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Check if launched from recents or app icon
        if (intent.flags and Intent.FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY == 0) {
            // Not launched from history, try to restore last app
            val prefs = getSharedPreferences("app_prefs", Context.MODE_PRIVATE)
            val lastApp = prefs.getString(LAST_APP_PREF, null)
            
            if (lastApp != null) {
                launchAppOverlay(lastApp, object : MethodChannel.Result {
                    override fun success(result: Any?) {}
                    override fun error(code: String, msg: String?, details: Any?) {}
                    override fun notImplemented() {}
                })
            }
        }
        
        // Configure window for overlay support
        window.apply {
            setFlags(
                WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
                WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS
            )
            addFlags(WindowManager.LayoutParams.FLAG_DRAWS_SYSTEM_BAR_BACKGROUNDS)
            statusBarColor = android.graphics.Color.TRANSPARENT
            navigationBarColor = android.graphics.Color.TRANSPARENT
        }

        requestUsageStatsPermission()
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

    override fun onPause() {
        super.onPause()
        overridePendingTransition(0, 0)
    }

    private fun requestUsageStatsPermission() {
        if (!hasUsageStatsPermission()) {
            startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
        }
    }

    private fun hasUsageStatsPermission(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = appOps.checkOpNoThrow(
            AppOpsManager.OPSTR_GET_USAGE_STATS,
            android.os.Process.myUid(),
            packageName
        )
        return mode == AppOpsManager.MODE_ALLOWED
    }

    private fun drawableToBitmap(drawable: Drawable): Bitmap {
        if (drawable is BitmapDrawable) {
            return drawable.bitmap
        }

        val bitmap = Bitmap.createBitmap(
            drawable.intrinsicWidth.coerceAtLeast(1),
            drawable.intrinsicHeight.coerceAtLeast(1),
            Bitmap.Config.ARGB_8888
        )
        val canvas = Canvas(bitmap)
        drawable.setBounds(0, 0, canvas.width, canvas.height)
        drawable.draw(canvas)
        return bitmap
    }

    private fun saveBitmapToFile(bitmap: Bitmap): File {
        val file = File(cacheDir, "app_icon_${System.currentTimeMillis()}.png")
        FileOutputStream(file).use { out ->
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, out)
        }
        return file
    }
}
