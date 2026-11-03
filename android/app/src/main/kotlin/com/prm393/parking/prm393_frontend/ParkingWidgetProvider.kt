package com.prm393.parking.prm393_frontend

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.SystemClock
import android.view.View
import android.widget.RemoteViews
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Widget màn hình chính: vé đang gửi (biển số, ô, đồng hồ thời gian gửi, mã ra cổng),
 * đặt chỗ sắp tới, hoặc lối tắt mở app. Dữ liệu do app ghi mỗi lần tải lại lượt gửi;
 * đồng hồ là Chronometer của hệ thống nên tự chạy cả khi app đã tắt.
 */
class ParkingWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        for (id in ids) manager.updateAppWidget(id, render(context))
    }

    companion object {
        private const val PREFS = "pbms_home_widget"
        /** Dữ liệu cũ hơn mức này (app lâu không mở, xe có thể đã ra) thì không hiện vé nữa. */
        private const val STALE_MS = 24L * 60 * 60 * 1000

        fun save(context: Context, data: Map<String, Any?>) {
            val editor = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().clear()
            for ((key, value) in data) {
                when (value) {
                    is String -> editor.putString(key, value)
                    is Number -> editor.putLong(key, value.toLong())
                }
            }
            editor.putLong("savedAt", System.currentTimeMillis()).apply()
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(ComponentName(context, ParkingWidgetProvider::class.java))
            for (id in ids) manager.updateAppWidget(id, render(context))
        }

        /** Mở app bằng link pbms://widget/<action>; app chuyển thành việc cần làm (mở mã ra cổng...). */
        private fun open(context: Context, action: String, parkingId: String? = null): PendingIntent {
            val link = Uri.parse("pbms://widget/$action").buildUpon()
            if (parkingId != null) link.appendQueryParameter("lot", parkingId)
            val intent = Intent(Intent.ACTION_VIEW, link.build(), context, MainActivity::class.java)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            return PendingIntent.getActivity(
                context, action.hashCode(), intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
        }

        private fun render(context: Context): RemoteViews {
            val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            val stale = System.currentTimeMillis() - prefs.getLong("savedAt", 0) > STALE_MS
            val state = if (stale) "idle" else prefs.getString("state", "idle")
            val views = RemoteViews(context.packageName, R.layout.parking_widget)
            val time = SimpleDateFormat("HH:mm", Locale.forLanguageTag("vi-VN"))

            views.setViewVisibility(R.id.widget_chrono, View.GONE)
            views.setViewVisibility(R.id.widget_code, View.GONE)
            when (state) {
                "parking" -> {
                    val slot = prefs.getString("slot", null)
                    views.setTextViewText(R.id.widget_label, if (slot != null) "Đang gửi xe · Ô $slot" else "Đang gửi xe")
                    views.setTextViewText(R.id.widget_title, prefs.getString("plate", ""))
                    // Chronometer tính theo đồng hồ khởi động máy: quy giờ vào bãi về mốc đó.
                    val entry = prefs.getLong("entryAt", System.currentTimeMillis())
                    val base = SystemClock.elapsedRealtime() - (System.currentTimeMillis() - entry)
                    views.setChronometer(R.id.widget_chrono, base, null, true)
                    views.setViewVisibility(R.id.widget_chrono, View.VISIBLE)
                    val code = prefs.getString("exitCode", null)
                    if (code != null) {
                        views.setTextViewText(R.id.widget_code, "Mã ra cổng $code")
                        views.setViewVisibility(R.id.widget_code, View.VISIBLE)
                        views.setTextViewText(R.id.widget_action, "Mở mã ra cổng")
                    } else {
                        views.setTextViewText(R.id.widget_action, "Trả trước để ra nhanh")
                    }
                    views.setOnClickPendingIntent(R.id.widget_root, open(context, "exit-pass"))
                }
                "reservation" -> {
                    views.setTextViewText(R.id.widget_label, "Đặt chỗ sắp tới")
                    views.setTextViewText(R.id.widget_title, prefs.getString("time", ""))
                    views.setTextViewText(R.id.widget_code, prefs.getString("place", ""))
                    views.setViewVisibility(R.id.widget_code, View.VISIBLE)
                    views.setTextViewText(R.id.widget_action, "Đường vào bãi")
                    views.setOnClickPendingIntent(R.id.widget_root, open(context, "reservation", prefs.getString("parkingId", null)))
                }
                else -> {
                    views.setTextViewText(R.id.widget_label, "PBMS")
                    views.setTextViewText(R.id.widget_title, "Không có xe đang gửi")
                    views.setTextViewText(R.id.widget_action, "Tìm bãi đỗ")
                    views.setOnClickPendingIntent(R.id.widget_root, open(context, "home"))
                }
            }
            val savedAt = prefs.getLong("savedAt", 0)
            views.setTextViewText(
                R.id.widget_updated,
                if (savedAt > 0 && !stale) "Cập nhật ${time.format(Date(savedAt))}" else "",
            )
            return views
        }
    }
}
