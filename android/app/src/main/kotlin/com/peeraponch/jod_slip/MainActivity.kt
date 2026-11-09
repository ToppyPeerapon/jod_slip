package com.peeraponch.jod_slip

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var channel: MethodChannel? = null
    private var pendingAction: String? = null
    private var dartReady = false

    override fun onCreate(savedInstanceState: Bundle?) {
        // Only a fresh launch counts: not a restore or a relaunch from Recents.
        if (savedInstanceState == null &&
            (intent.flags and Intent.FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY) == 0
        ) {
            pendingAction = launchAction(intent)
        }
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    // Dart is listening: hand over the action the app was opened with.
                    "ready" -> {
                        dartReady = true
                        result.success(pendingAction)
                        pendingAction = null
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val action = launchAction(intent) ?: return
        if (dartReady) channel?.invokeMethod("onAction", action) else pendingAction = action
    }

    companion object {
        const val CHANNEL = "jod_slip/launch_action"

        /** Intent action for "search all photos for slips"; see ScanSlipWidgetProvider. */
        const val ACTION_SCAN_LIBRARY = "com.peeraponch.jod_slip.action.SCAN_LIBRARY"

        private fun launchAction(intent: Intent?): String? = when (intent?.action) {
            ACTION_SCAN_LIBRARY -> "scan-library"
            else -> null
        }
    }
}
