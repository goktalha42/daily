package com.dailygames.daily_games

import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

class RetentionNotificationReceiver : BroadcastReceiver() {
    companion object {
        const val CHANNEL_ID = "zuhtu_retention_channel"
        const val CHANNEL_NAME = "Zühtü Günlük Seri ve Zeka Raporu"
        const val EXTRA_NOTIFICATION_ID = "notification_id"
        const val EXTRA_TITLE = "title"
        const val EXTRA_BODY = "body"
        const val EXTRA_REPEAT_INTERVAL_MS = "repeat_interval_ms"

        const val ID_STREAK_REMINDER = 1001
        const val ID_SUNDAY_REPORT = 1002
        const val ID_TEST_NOTIFICATION = 1003

        fun ensureChannel(context: Context) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                val existing = manager.getNotificationChannel(CHANNEL_ID)
                if (existing == null) {
                    val channel = NotificationChannel(
                        CHANNEL_ID,
                        CHANNEL_NAME,
                        NotificationManager.IMPORTANCE_HIGH
                    ).apply {
                        description = "Günlük zeka serisi hatırlatmaları ve Pazar akşamı haftalık beyin karnesi bildirimleri"
                        enableVibration(true)
                    }
                    manager.createNotificationChannel(channel)
                }
            }
        }

        fun showNotificationNow(
            context: Context,
            notificationId: Int,
            title: String,
            body: String
        ) {
            ensureChannel(context)
            val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

            val launchIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val pendingFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            } else {
                PendingIntent.FLAG_UPDATE_CURRENT
            }
            val contentIntent = PendingIntent.getActivity(context, notificationId, launchIntent, pendingFlags)

            val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                Notification.Builder(context, CHANNEL_ID)
            } else {
                @Suppress("DEPRECATION")
                Notification.Builder(context)
            }

            builder.setSmallIcon(R.mipmap.ic_launcher)
                .setContentTitle(title)
                .setContentText(body)
                .setStyle(Notification.BigTextStyle().bigText(body))
                .setAutoCancel(true)
                .setContentIntent(contentIntent)

            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
                @Suppress("DEPRECATION")
                builder.setPriority(Notification.PRIORITY_HIGH)
            }

            manager.notify(notificationId, builder.build())
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        val notificationId = intent.getIntExtra(EXTRA_NOTIFICATION_ID, ID_STREAK_REMINDER)
        val title = intent.getStringExtra(EXTRA_TITLE) ?: "🔥 Zühtü Günlük Seri Hatırlatması"
        val body = intent.getStringExtra(EXTRA_BODY) ?: "Günün 6 zeka bulmacası seni bekliyor! Serini kaybetmemek için hemen çöz."
        val repeatIntervalMs = intent.getLongExtra(EXTRA_REPEAT_INTERVAL_MS, 0L)

        showNotificationNow(context, notificationId, title, body)

        // Tekrarlayan bildirimse bir sonraki periyodu otomatik kur (24 saat veya 7 gün)
        if (repeatIntervalMs > 0L) {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val nextIntent = Intent(context, RetentionNotificationReceiver::class.java).apply {
                putExtra(EXTRA_NOTIFICATION_ID, notificationId)
                putExtra(EXTRA_TITLE, title)
                putExtra(EXTRA_BODY, body)
                putExtra(EXTRA_REPEAT_INTERVAL_MS, repeatIntervalMs)
            }
            val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            } else {
                PendingIntent.FLAG_UPDATE_CURRENT
            }
            val pendingIntent = PendingIntent.getBroadcast(context, notificationId, nextIntent, flags)
            val nextTriggerMs = System.currentTimeMillis() + repeatIntervalMs

            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, nextTriggerMs, pendingIntent)
                } else {
                    alarmManager.set(AlarmManager.RTC_WAKEUP, nextTriggerMs, pendingIntent)
                }
            } catch (_: Exception) {
            }
        }
    }
}

