// android/app/src/main/kotlin/com/example/letsgo/FloatingNavigationService.kt
package com.example.letsgo

import android.app.Service
import android.content.Intent
import android.graphics.PixelFormat
import android.graphics.drawable.LayerDrawable
import android.os.IBinder
import android.view.Gravity
import android.view.LayoutInflater
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.ImageView
import android.widget.LinearLayout
import android.util.DisplayMetrics
import androidx.core.content.ContextCompat
import android.os.Handler
import android.os.Looper
import android.app.usage.UsageStatsManager
import android.content.Context
import android.app.ActivityManager
import android.app.ActivityOptions
import android.net.Uri
import android.provider.Settings
import android.content.IntentSender
import android.content.IntentSender.SendIntentException
import android.content.pm.PackageManager

class FloatingNavigationService : Service() {
    private lateinit var windowManager: WindowManager
    private lateinit var floatingView: View
    private lateinit var params: WindowManager.LayoutParams
    private lateinit var usageStatsManager: UsageStatsManager
    private var isTracking = true
    private val handler = Handler(Looper.getMainLooper())
    private val socialApps = setOf(
        "com.twitter.android",
        "com.facebook.katana",
        "com.instagram.android",
        "com.linkedin.android",
        "com.zhiliaoapp.musically",
        "com.whatsapp",
        "org.telegram.messenger"
    )
    private var isHidden = false

    private val checkForegroundApp = object : Runnable {
        private var lastApp: String? = null
        
        override fun run() {
            if (isTracking) {
                val currentApp = getCurrentForegroundApp()
                
                if (currentApp.isNotEmpty()) {
                    if (currentApp in socialApps) {
                        showFloatingView()
                        lastApp = currentApp
                    } else {
                        // Immediate hide when not in social apps
                        hideFloatingView()
                        lastApp = currentApp
                    }
                }
                handler.postDelayed(this, 100) // Check very frequently
            }
        }
    }

    // Add these variables for touch handling
    private var initialX: Int = 0
    private var initialY: Int = 0
    private var initialTouchX: Float = 0f
    private var initialTouchY: Float = 0f

    override fun onCreate() {
        super.onCreate()
        usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
        
        floatingView = LayoutInflater.from(this).inflate(R.layout.floating_navigation, null)

        params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.BOTTOM
            y = dpToPx(16)
        }

        setupTouchListener()
        setupNavigationButtons()
        addToggleButton()
        startTracking()
    }

    private fun setupTouchListener() {
        floatingView.setOnTouchListener { view, event ->
            when (event.action) {
                MotionEvent.ACTION_DOWN -> {
                    initialX = params.x
                    initialY = params.y
                    initialTouchX = event.rawX
                    initialTouchY = event.rawY
                    true
                }
                MotionEvent.ACTION_MOVE -> {
                    // Invert the Y movement calculation
                    params.x = initialX + (event.rawX - initialTouchX).toInt()
                    params.y = initialY - (event.rawY - initialTouchY).toInt()
                    
                    // Add bounds checking
                    val displayMetrics = resources.displayMetrics
                    params.x = params.x.coerceIn(0, displayMetrics.widthPixels - view.width)
                    params.y = params.y.coerceIn(0, displayMetrics.heightPixels - view.height)
                    
                    windowManager.updateViewLayout(floatingView, params)
                    true
                }
                else -> false
            }
        }
    }

    private fun setupNavigationButtons() {
        val navigationLayout = floatingView.findViewById<LinearLayout>(R.id.navigationLayout)
        val appIcon = floatingView.findViewById<ImageView>(R.id.appIcon)
        var isCollapsed = false
        
        // Icon size and margin
        val iconSize = dpToPx(36)  // Slightly smaller icons
        val marginSize = dpToPx(4)  // Smaller margins for compact layout
        
        val platforms = listOf("twitter", "facebook", "instagram", "linkedin", "tiktok", "whatsapp", "telegram")
        
        // Add platform buttons
        platforms.forEach { platform ->
            val button = ImageView(this).apply {
                setImageResource(getIconResource(platform))
                layoutParams = LinearLayout.LayoutParams(iconSize, iconSize).apply {
                    marginStart = marginSize
                    marginEnd = marginSize
                }
                background = ContextCompat.getDrawable(
                    this@FloatingNavigationService,
                    R.drawable.icon_background
                )
                setPadding(dpToPx(6), dpToPx(6), dpToPx(6), dpToPx(6))
                setOnClickListener {
                    launchApp(platform)
                }
            }
            navigationLayout.addView(button)
        }

        // Setup app icon click behavior
        appIcon.setOnClickListener {
            isCollapsed = !isCollapsed
            navigationLayout.visibility = if (isCollapsed) View.GONE else View.VISIBLE
            
            // Update layout params for collapsed/expanded state
            floatingView.layoutParams = params.apply {
                width = if (isCollapsed) WindowManager.LayoutParams.WRAP_CONTENT 
                       else WindowManager.LayoutParams.WRAP_CONTENT
            }
            windowManager.updateViewLayout(floatingView, params)
        }
    }

    private fun launchApp(platform: String) {
        val packageName = when (platform) {
            "twitter" -> "com.twitter.android"
            "facebook" -> "com.facebook.katana"
            "instagram" -> "com.instagram.android"
            "linkedin" -> "com.linkedin.android"
            "tiktok" -> "com.zhiliaoapp.musically"
            "whatsapp" -> "com.whatsapp"
            "telegram" -> "org.telegram.messenger"
            else -> return
        }

        try {
            val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
            
            // Check if app is already running
            val runningTasks = activityManager.getRunningTasks(10)
            val isAppRunning = runningTasks.any { it.baseActivity?.packageName == packageName }

            val intent = packageManager.getLaunchIntentForPackage(packageName)?.apply {
                if (isAppRunning) {
                    // If app is running, bring it to front without creating new instance
                    flags = Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or
                            Intent.FLAG_ACTIVITY_NO_ANIMATION or
                            Intent.FLAG_ACTIVITY_NEW_TASK
                } else {
                    // Launch new instance but preserve state
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                            Intent.FLAG_ACTIVITY_NO_ANIMATION or
                            Intent.FLAG_ACTIVITY_EXCLUDE_FROM_RECENTS or
                            Intent.FLAG_ACTIVITY_RETAIN_IN_RECENTS
                }
            }
            
            val options = ActivityOptions.makeCustomAnimation(this, 0, 0).toBundle()
            startActivity(intent, options)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun getIconResource(platform: String): Int {
        return when (platform) {
            "twitter" -> R.drawable.ic_twitter
            "facebook" -> R.drawable.ic_facebook
            "instagram" -> R.drawable.ic_instagram
            "linkedin" -> R.drawable.ic_linkedin
            "tiktok" -> R.drawable.ic_tiktok
            "whatsapp" -> R.drawable.ic_whatsapp
            "telegram" -> R.drawable.ic_telegram
            else -> android.R.drawable.ic_menu_more
        }
    }

    private fun dpToPx(dp: Int): Int {
        val displayMetrics = resources.displayMetrics
        return (dp * displayMetrics.density).toInt()
    }

    private fun startTracking() {
        isTracking = true
        handler.post(checkForegroundApp)
    }

    private fun getCurrentForegroundApp(): String {
        try {
            val time = System.currentTimeMillis()
            val stats = usageStatsManager.queryUsageStats(
                UsageStatsManager.INTERVAL_BEST,
                time - 500, // Look back only 500ms
                time
            )
            
            return stats.maxByOrNull { it.lastTimeUsed }?.packageName ?: ""
        } catch (e: Exception) {
            e.printStackTrace()
            return ""
        }
    }

    private fun showFloatingView() {
        try {
            if (floatingView.parent == null) {
                windowManager.addView(floatingView, params)
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun hideFloatingView() {
        try {
            if (floatingView.parent != null) {
                windowManager.removeView(floatingView)
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun addToggleButton() {
        val toggleButton = ImageView(this).apply {
            setImageResource(android.R.drawable.ic_menu_more)
            layoutParams = WindowManager.LayoutParams(
                dpToPx(40),
                dpToPx(40),
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
                PixelFormat.TRANSLUCENT
            ).apply {
                gravity = Gravity.TOP or Gravity.START
                x = dpToPx(16)
                y = dpToPx(16)
            }
            background = ContextCompat.getDrawable(
                this@FloatingNavigationService,
                R.drawable.toggle_button_background
            )
            setPadding(dpToPx(8), dpToPx(8), dpToPx(8), dpToPx(8))
            setOnClickListener {
                isHidden = !isHidden
                if (isHidden) {
                    hideFloatingView()
                } else {
                    showFloatingView()
                }
            }
        }
        windowManager.addView(toggleButton, toggleButton.layoutParams)
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        super.onDestroy()
        isTracking = false
        handler.removeCallbacks(checkForegroundApp)
        hideFloatingView()
    }
}