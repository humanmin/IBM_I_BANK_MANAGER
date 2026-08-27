package com.ibm.money.ibm_money_app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import java.io.File
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId
import java.time.temporal.ChronoUnit

class SavingsGoalWidgetProvider : HomeWidgetProvider() {
    companion object {
        private const val GOAL_AVAILABLE = "goal_available"
        private const val GOAL_NAME = "goal_name"
        private const val GOAL_TARGET_MILLIS = "goal_target_millis"
        private const val GOAL_IMAGE = "goal_image"
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            val hasGoal = widgetData.getBoolean(GOAL_AVAILABLE, false)
            val goalName = if (hasGoal) {
                widgetData.getString(GOAL_NAME, null)
                    ?.takeIf { it.isNotBlank() }
                    ?: context.getString(R.string.savings_goal_widget_empty)
            } else {
                context.getString(R.string.savings_goal_widget_empty)
            }
            val targetMillis = readTargetMillis(widgetData)
            val dDay = if (hasGoal && targetMillis > 0L) {
                formatDDay(targetMillis)
            } else {
                context.getString(R.string.savings_goal_widget_no_goal)
            }

            val views = RemoteViews(
                context.packageName,
                R.layout.savings_goal_widget,
            ).apply {
                setTextViewText(R.id.widget_goal_name, goalName)
                setTextViewText(R.id.widget_goal_dday, dDay)

                val image = widgetData.getString(GOAL_IMAGE, null)
                    ?.takeIf { File(it).isFile }
                    ?.let(::decodeWidgetBitmap)
                if (image != null) {
                    setImageViewBitmap(R.id.widget_goal_image, image)
                } else {
                    setImageViewResource(
                        R.id.widget_goal_image,
                        R.drawable.ic_widget_gift,
                    )
                }

                val launchIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("ibankmanager://goal"),
                )
                setOnClickPendingIntent(R.id.widget_goal_container, launchIntent)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    private fun readTargetMillis(widgetData: SharedPreferences): Long {
        return when (val value = widgetData.all[GOAL_TARGET_MILLIS]) {
            is Long -> value
            is Int -> value.toLong()
            else -> 0L
        }
    }

    private fun formatDDay(targetMillis: Long): String {
        val target = Instant.ofEpochMilli(targetMillis)
            .atZone(ZoneId.systemDefault())
            .toLocalDate()
        val days = ChronoUnit.DAYS.between(LocalDate.now(), target)
            .coerceAtLeast(0)
        return if (days == 0L) "D-DAY" else "D-$days"
    }

    private fun decodeWidgetBitmap(path: String): Bitmap? {
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeFile(path, bounds)
        if (bounds.outWidth <= 0 || bounds.outHeight <= 0) return null

        var sampleSize = 1
        while (
            bounds.outWidth / sampleSize > 256 ||
            bounds.outHeight / sampleSize > 256
        ) {
            sampleSize *= 2
        }
        return BitmapFactory.decodeFile(
            path,
            BitmapFactory.Options().apply { inSampleSize = sampleSize },
        )
    }
}
