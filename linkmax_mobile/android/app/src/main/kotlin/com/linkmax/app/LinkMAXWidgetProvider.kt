package com.linkmax.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.res.Configuration
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import org.json.JSONArray

class LinkMAXWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        for (id in ids) {
            manager.updateAppWidget(id, buildViews(context))
        }
    }

    companion object {
        private val ROW_IDS = intArrayOf(
            R.id.widget_row_0,
            R.id.widget_row_1,
            R.id.widget_row_2,
            R.id.widget_row_3
        )
        private val CHIP_IDS = intArrayOf(
            R.id.widget_chip_0,
            R.id.widget_chip_1,
            R.id.widget_chip_2,
            R.id.widget_chip_3
        )
        private val NAME_IDS = intArrayOf(
            R.id.widget_name_0,
            R.id.widget_name_1,
            R.id.widget_name_2,
            R.id.widget_name_3
        )

        private val CHIP_DRAWABLES = intArrayOf(
            R.drawable.widget_chip_c0, R.drawable.widget_chip_c1,
            R.drawable.widget_chip_c2, R.drawable.widget_chip_c3,
            R.drawable.widget_chip_c4, R.drawable.widget_chip_c5,
            R.drawable.widget_chip_c6, R.drawable.widget_chip_c7,
            R.drawable.widget_chip_c8, R.drawable.widget_chip_c9
        )

        fun pushRefresh(context: Context) {
            try {
                val manager = AppWidgetManager.getInstance(context)
                val ids = manager.getAppWidgetIds(
                    ComponentName(context, LinkMAXWidgetProvider::class.java)
                )
                if (ids.isNotEmpty()) {
                    val views = buildViews(context)
                    for (id in ids) manager.updateAppWidget(id, views)
                }
            } catch (_: Exception) {
            }
        }

        fun buildViews(context: Context): RemoteViews {
            val dark = (context.resources.configuration.uiMode and
                    Configuration.UI_MODE_NIGHT_MASK) == Configuration.UI_MODE_NIGHT_YES
            val titleColor = if (dark) 0xFFF0F4F8.toInt() else 0xFF101828.toInt()
            val subColor = if (dark) 0xFF7C8896.toInt() else 0xFF98A2B3.toInt()

            val views = RemoteViews(context.packageName, R.layout.linkmax_widget)
            views.setInt(
                R.id.widget_root, "setBackgroundResource",
                if (dark) R.drawable.widget_bg_dark else R.drawable.widget_bg_light
            )
            views.setTextColor(R.id.widget_title, titleColor)
            views.setTextColor(R.id.widget_empty, subColor)

            // Header opens the app
            try {
                val launch = context.packageManager.getLaunchIntentForPackage(context.packageName)
                if (launch != null) {
                    views.setOnClickPendingIntent(
                        R.id.widget_header,
                        PendingIntent.getActivity(
                            context, 0, launch,
                            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                        )
                    )
                }
            } catch (_: Exception) {
            }

            val prefs = context.getSharedPreferences(
                "FlutterSharedPreferences", Context.MODE_PRIVATE
            )
            val json = prefs.getString("flutter.widget_links", null)

            var shown = 0
            if (json != null) {
                try {
                    val arr = JSONArray(json)
                    while (shown < arr.length() && shown < ROW_IDS.size) {
                        val o = arr.getJSONObject(shown)
                        val name = o.optString("name", "")
                        val url = o.optString("url", "")
                        val letter = o.optString("letter", "?")
                        val colorIndex = o.optInt("colorIndex", 0)
                            .coerceIn(0, CHIP_DRAWABLES.size - 1)

                        views.setTextViewText(NAME_IDS[shown], name)
                        views.setTextColor(NAME_IDS[shown], titleColor)
                        views.setTextViewText(CHIP_IDS[shown], letter)
                        views.setInt(
                            CHIP_IDS[shown], "setBackgroundResource",
                            CHIP_DRAWABLES[colorIndex]
                        )
                        views.setViewVisibility(ROW_IDS[shown], View.VISIBLE)

                        if (url.isNotEmpty()) {
                            val open = Intent(Intent.ACTION_VIEW, Uri.parse(url))
                                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            val pi = PendingIntent.getActivity(
                                context, shown + 1, open,
                                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                            )
                            views.setOnClickPendingIntent(ROW_IDS[shown], pi)
                        }
                        shown++
                    }
                } catch (_: Exception) {
                    shown = 0
                }
            }

            if (shown == 0) {
                views.setViewVisibility(R.id.widget_empty, View.VISIBLE)
                views.setTextViewText(
                    R.id.widget_empty,
                    "No pinned links yet — add some in LinkMAX"
                )
            } else {
                views.setViewVisibility(R.id.widget_empty, View.GONE)
            }
            for (i in shown until ROW_IDS.size) {
                views.setViewVisibility(ROW_IDS[i], View.GONE)
            }
            return views
        }
    }
}
