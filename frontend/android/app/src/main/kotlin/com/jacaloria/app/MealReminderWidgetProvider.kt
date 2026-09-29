package com.jacaloria.app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONArray
import java.util.Calendar

class MealReminderWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val viewsContent = resolveContent(widgetData)
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.meal_reminder_widget).apply {
                if (viewsContent.streakDays <= 0) {
                    setViewVisibility(R.id.widget_streak_days, android.view.View.GONE)
                    setTextViewText(R.id.widget_streak_unit, "Comece hoje")
                } else {
                    setViewVisibility(R.id.widget_streak_days, android.view.View.VISIBLE)
                    setTextViewText(R.id.widget_streak_days, "${viewsContent.streakDays}")
                    setTextViewText(
                        R.id.widget_streak_unit,
                        if (viewsContent.streakDays == 1) {
                            "dia de sequência"
                        } else {
                            "dias de sequência"
                        },
                    )
                }
                setTextViewText(R.id.widget_title, viewsContent.title)
                setTextViewText(R.id.widget_body, viewsContent.body)
                val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                )
                setOnClickPendingIntent(R.id.widget_root, pendingIntent)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    private data class WidgetContent(
        val streakDays: Int,
        val title: String,
        val body: String,
    )

    private fun resolveContent(widgetData: SharedPreferences): WidgetContent {
        val fallbackTitle = widgetData.getString("fallback_title", null)
            ?: "Hora de registrar"
        val fallbackBody = widgetData.getString("fallback_body", null)
            ?: "Que tal registrar uma refeição no JacalorIA?"
        val streakDays = widgetData.getString("streak_days", null)?.toIntOrNull() ?: 0
        val masterEnabled = widgetData.getString("master_enabled", "1") == "1"
        val reminder = if (masterEnabled) {
            pickReminder(widgetData.getString("reminders_json", "[]"))
        } else {
            null
        }

        return WidgetContent(
            streakDays = streakDays.coerceAtLeast(0),
            title = reminder?.first ?: widgetData.getString("message_title", null) ?: fallbackTitle,
            body = reminder?.second ?: widgetData.getString("message_body", null) ?: fallbackBody,
        )
    }

    private fun pickReminder(raw: String?): Pair<String, String>? {
        if (raw.isNullOrBlank()) {
            return null
        }

        return try {
            val items = JSONArray(raw)
            if (items.length() == 0) {
                return null
            }

            val now = Calendar.getInstance()
            val nowMinutes = now.get(Calendar.HOUR_OF_DAY) * 60 + now.get(Calendar.MINUTE)
            var lastPassed: Pair<String, String>? = null
            var first: Pair<String, String>? = null

            for (index in 0 until items.length()) {
                val item = items.optJSONObject(index) ?: continue
                val hour = item.optInt("hour", 0)
                val minute = item.optInt("minute", 0)
                val title = item.optString("title")
                val body = item.optString("body")
                if (title.isBlank() || body.isBlank()) {
                    continue
                }
                val pair = title to body
                if (first == null) {
                    first = pair
                }
                if (hour * 60 + minute <= nowMinutes) {
                    lastPassed = pair
                }
            }

            lastPassed ?: first
        } catch (_: Exception) {
            null
        }
    }
}
