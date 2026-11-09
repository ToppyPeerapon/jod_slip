package com.peeraponch.jod_slip

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

/** Home-screen widget: one tap opens JodSlip and starts searching all photos for slips. */
class ScanSlipWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, widgetIds: IntArray) {
        val launch = Intent(context, MainActivity::class.java)
            .setAction(MainActivity.ACTION_SCAN_LIBRARY)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
        val pending = PendingIntent.getActivity(
            context,
            0,
            launch,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val views = RemoteViews(context.packageName, R.layout.widget_scan_slip).apply {
            setOnClickPendingIntent(R.id.widget_root, pending)
        }
        manager.updateAppWidget(widgetIds, views)
    }
}
