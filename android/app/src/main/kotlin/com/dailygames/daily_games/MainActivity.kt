package com.dailygames.daily_games

import android.Manifest
import android.app.AlarmManager
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioTrack
import android.media.SoundPool
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.Executors
import kotlin.math.PI
import kotlin.math.exp
import kotlin.math.sin

class MainActivity : FlutterActivity() {
    private val channelName = "com.dailygames.daily_games/retention"
    private val audioExecutor = Executors.newSingleThreadExecutor()
    private var soundPool: SoundPool? = null
    private val soundIdMap = ConcurrentHashMap<String, Int>()
    private val activeStreamIds = ConcurrentHashMap.newKeySet<Int>()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        RetentionNotificationReceiver.ensureChannel(applicationContext)

        initSoundPool()

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "playSound" -> {
                        val soundType = call.argument<String>("type") ?: "pencilTap"
                        val soundId = soundIdMap[soundType]
                        if (soundPool != null && soundId != null && soundId > 0) {
                            val priority = when (soundType) {
                                "victory", "milestone" -> 3
                                "error" -> 2
                                else -> 1
                            }
                            val streamId = soundPool?.play(soundId, 0.95f, 0.95f, priority, 0, 1.0f) ?: 0
                            if (streamId != 0) {
                                activeStreamIds.add(streamId)
                            }
                        } else {
                            // SoundPool henüz hazır değilse arka planda doğrudan çal
                            audioExecutor.execute {
                                playSynthesizedSketchSound(soundType)
                            }
                        }
                        result.success(true)
                    }
                    "stopAllSounds" -> {
                        stopAllSounds()
                        result.success(true)
                    }
                    "requestNotificationPermission" -> {
                        if (Build.VERSION.SDK_INT >= 33) {
                            val granted = checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) ==
                                PackageManager.PERMISSION_GRANTED
                            if (!granted) {
                                requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 2026)
                            }
                            result.success(granted)
                        } else {
                            result.success(true)
                        }
                    }
                    "scheduleNotification" -> {
                        val id = call.argument<Int>("id") ?: RetentionNotificationReceiver.ID_STREAK_REMINDER
                        val triggerAtMs = call.argument<Number>("triggerAtMs")?.toLong()
                            ?: (System.currentTimeMillis() + 3600_000L)
                        val repeatIntervalMs = call.argument<Number>("repeatIntervalMs")?.toLong() ?: 0L
                        val title = call.argument<String>("title") ?: "🔥 Zühtü Günlük Seri Hatırlatması"
                        val body = call.argument<String>("body") ?: "Günün 6 zeka bulmacası seni bekliyor!"

                        scheduleAlarmNotification(id, triggerAtMs, repeatIntervalMs, title, body)
                        result.success(true)
                    }
                    "cancelNotification" -> {
                        val id = call.argument<Int>("id") ?: RetentionNotificationReceiver.ID_STREAK_REMINDER
                        cancelAlarmNotification(id)
                        result.success(true)
                    }
                    "showTestNotification" -> {
                        val title = call.argument<String>("title") ?: "🔥 Zühtü Bildirim Testi"
                        val body = call.argument<String>("body")
                            ?: "Harika! Günlük seri ve Pazar akşamı zeka raporu bildirimlerin aktif."
                        RetentionNotificationReceiver.showNotificationNow(
                            applicationContext,
                            RetentionNotificationReceiver.ID_TEST_NOTIFICATION,
                            title,
                            body
                        )
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun scheduleAlarmNotification(
        id: Int,
        triggerAtMs: Long,
        repeatIntervalMs: Long,
        title: String,
        body: String
    ) {
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(applicationContext, RetentionNotificationReceiver::class.java).apply {
            putExtra(RetentionNotificationReceiver.EXTRA_NOTIFICATION_ID, id)
            putExtra(RetentionNotificationReceiver.EXTRA_TITLE, title)
            putExtra(RetentionNotificationReceiver.EXTRA_BODY, body)
            putExtra(RetentionNotificationReceiver.EXTRA_REPEAT_INTERVAL_MS, repeatIntervalMs)
        }
        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        val pendingIntent = PendingIntent.getBroadcast(applicationContext, id, intent, flags)

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAtMs, pendingIntent)
            } else {
                alarmManager.set(AlarmManager.RTC_WAKEUP, triggerAtMs, pendingIntent)
            }
        } catch (_: Exception) {
        }
    }

    private fun cancelAlarmNotification(id: Int) {
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(applicationContext, RetentionNotificationReceiver::class.java)
        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        val pendingIntent = PendingIntent.getBroadcast(applicationContext, id, intent, flags)
        try {
            alarmManager.cancel(pendingIntent)
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            nm.cancel(id)
        } catch (_: Exception) {
        }
    }

    private fun initSoundPool() {
        try {
            val audioAttributes = AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_GAME)
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .build()

            val pool = SoundPool.Builder()
                .setMaxStreams(8)
                .setAudioAttributes(audioAttributes)
                .build()

            soundPool = pool

            // Arka planda 6 sesi WAV olarak önbelleğe yaz ve SoundPool'a anında yükle
            audioExecutor.execute {
                val soundTypes = listOf("pencilTap", "symbolPlace", "erase", "error", "victory", "milestone")
                val sampleRate = 44100
                for (type in soundTypes) {
                    try {
                        val file = File(cacheDir, "zuhtu_sfx_${type}.wav")
                        val samples = generateSamplesForType(type, sampleRate)
                        writeWavFile(file, sampleRate, samples)
                        val soundId = pool.load(file.absolutePath, 1)
                        if (soundId > 0) {
                            soundIdMap[type] = soundId
                        }
                    } catch (_: Exception) {
                    }
                }
            }
        } catch (_: Exception) {
        }
    }

    private fun stopAllSounds() {
        try {
            soundPool?.autoPause()
            for (streamId in activeStreamIds) {
                soundPool?.stop(streamId)
            }
            activeStreamIds.clear()
        } catch (_: Exception) {
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        try {
            stopAllSounds()
            soundPool?.release()
            soundPool = null
            audioExecutor.shutdownNow()
        } catch (_: Exception) {
        }
    }

    private fun writeWavFile(file: File, sampleRate: Int, samples: ShortArray) {
        val totalAudioLen = samples.size * 2
        val totalDataLen = totalAudioLen + 36
        val byteRate = sampleRate * 1 * 2 // 1 kanal, 16-bit mono

        FileOutputStream(file).use { out ->
            val header = ByteArray(44)
            // RIFF
            header[0] = 'R'.code.toByte()
            header[1] = 'I'.code.toByte()
            header[2] = 'F'.code.toByte()
            header[3] = 'F'.code.toByte()
            header[4] = (totalDataLen and 0xff).toByte()
            header[5] = ((totalDataLen shr 8) and 0xff).toByte()
            header[6] = ((totalDataLen shr 16) and 0xff).toByte()
            header[7] = ((totalDataLen shr 24) and 0xff).toByte()
            // WAVE
            header[8] = 'W'.code.toByte()
            header[9] = 'A'.code.toByte()
            header[10] = 'V'.code.toByte()
            header[11] = 'E'.code.toByte()
            // fmt 
            header[12] = 'f'.code.toByte()
            header[13] = 'm'.code.toByte()
            header[14] = 't'.code.toByte()
            header[15] = ' '.code.toByte()
            header[16] = 16
            header[17] = 0
            header[18] = 0
            header[19] = 0
            header[20] = 1 // PCM
            header[21] = 0
            header[22] = 1 // Mono
            header[23] = 0
            // SampleRate
            header[24] = (sampleRate and 0xff).toByte()
            header[25] = ((sampleRate shr 8) and 0xff).toByte()
            header[26] = ((sampleRate shr 16) and 0xff).toByte()
            header[27] = ((sampleRate shr 24) and 0xff).toByte()
            // ByteRate
            header[28] = (byteRate and 0xff).toByte()
            header[29] = ((byteRate shr 8) and 0xff).toByte()
            header[30] = ((byteRate shr 16) and 0xff).toByte()
            header[31] = ((byteRate shr 24) and 0xff).toByte()
            // BlockAlign
            header[32] = 2
            header[33] = 0
            // BitsPerSample
            header[34] = 16
            header[35] = 0
            // data
            header[36] = 'd'.code.toByte()
            header[37] = 'a'.code.toByte()
            header[38] = 't'.code.toByte()
            header[39] = 'a'.code.toByte()
            header[40] = (totalAudioLen and 0xff).toByte()
            header[41] = ((totalAudioLen shr 8) and 0xff).toByte()
            header[42] = ((totalAudioLen shr 16) and 0xff).toByte()
            header[43] = ((totalAudioLen shr 24) and 0xff).toByte()

            out.write(header)

            val buffer = ByteArray(samples.size * 2)
            for (i in samples.indices) {
                val s = samples[i].toInt()
                buffer[i * 2] = (s and 0xff).toByte()
                buffer[i * 2 + 1] = ((s shr 8) and 0xff).toByte()
            }
            out.write(buffer)
        }
    }

    private fun generateSamplesForType(type: String, sampleRate: Int): ShortArray {
        return when (type) {
            "pencilTap" -> synthesizeToneSequence(
                sampleRate,
                listOf(ToneStep(startHz = 740.0, endHz = 460.0, durationMs = 32, amplitude = 0.28, decay = 22.0))
            )
            "symbolPlace" -> synthesizeToneSequence(
                sampleRate,
                listOf(
                    ToneStep(startHz = 523.25, endHz = 587.33, durationMs = 42, amplitude = 0.34, decay = 16.0),
                    ToneStep(startHz = 783.99, endHz = 880.0, durationMs = 58, amplitude = 0.38, decay = 14.0)
                )
            )
            "erase" -> synthesizeToneSequence(
                sampleRate,
                listOf(ToneStep(startHz = 410.0, endHz = 250.0, durationMs = 50, amplitude = 0.24, decay = 18.0))
            )
            "error" -> synthesizeToneSequence(
                sampleRate,
                listOf(
                    ToneStep(startHz = 220.0, endHz = 185.0, durationMs = 70, amplitude = 0.36, decay = 10.0),
                    ToneStep(startHz = 175.0, endHz = 145.0, durationMs = 95, amplitude = 0.36, decay = 9.0)
                )
            )
            "victory" -> synthesizeToneSequence(
                sampleRate,
                listOf(
                    ToneStep(startHz = 523.25, endHz = 523.25, durationMs = 80, amplitude = 0.36, decay = 9.0),
                    ToneStep(startHz = 659.25, endHz = 659.25, durationMs = 80, amplitude = 0.38, decay = 9.0),
                    ToneStep(startHz = 783.99, endHz = 783.99, durationMs = 90, amplitude = 0.40, decay = 8.0),
                    ToneStep(startHz = 1046.50, endHz = 1046.50, durationMs = 210, amplitude = 0.45, decay = 5.5)
                )
            )
            "milestone" -> synthesizeToneSequence(
                sampleRate,
                listOf(
                    ToneStep(startHz = 587.33, endHz = 587.33, durationMs = 75, amplitude = 0.36, decay = 9.0),
                    ToneStep(startHz = 739.99, endHz = 739.99, durationMs = 75, amplitude = 0.38, decay = 9.0),
                    ToneStep(startHz = 880.00, endHz = 880.00, durationMs = 85, amplitude = 0.40, decay = 8.0),
                    ToneStep(startHz = 1174.66, endHz = 1174.66, durationMs = 240, amplitude = 0.46, decay = 5.0)
                )
            )
            else -> synthesizeToneSequence(
                sampleRate,
                listOf(ToneStep(startHz = 660.0, endHz = 440.0, durationMs = 28, amplitude = 0.25, decay = 24.0))
            )
        }
    }

    /**
     * SoundPool henüz hazır değilse ilk açılışta kullanılan hafif yedek oynatıcı
     */
    private fun playSynthesizedSketchSound(type: String) {
        try {
            val sampleRate = 44100
            val samples = generateSamplesForType(type, sampleRate)
            val bufferSizeBytes = samples.size * 2
            val track = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                AudioTrack.Builder()
                    .setAudioAttributes(
                        AudioAttributes.Builder()
                            .setUsage(AudioAttributes.USAGE_GAME)
                            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                            .build()
                    )
                    .setAudioFormat(
                        AudioFormat.Builder()
                            .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                            .setSampleRate(sampleRate)
                            .setChannelMask(AudioFormat.CHANNEL_OUT_MONO)
                            .build()
                    )
                    .setBufferSizeInBytes(bufferSizeBytes.coerceAtLeast(1024))
                    .setTransferMode(AudioTrack.MODE_STATIC)
                    .build()
            } else {
                @Suppress("DEPRECATION")
                AudioTrack(
                    AudioManager.STREAM_MUSIC,
                    sampleRate,
                    AudioFormat.CHANNEL_OUT_MONO,
                    AudioFormat.ENCODING_PCM_16BIT,
                    bufferSizeBytes.coerceAtLeast(1024),
                    AudioTrack.MODE_STATIC
                )
            }

            track.write(samples, 0, samples.size)
            track.play()
            val totalDurationMs = (samples.size * 1000L / sampleRate) + 20L
            Thread.sleep(totalDurationMs)
            track.stop()
            track.release()
        } catch (_: Exception) {
        }
    }

    private data class ToneStep(
        val startHz: Double,
        val endHz: Double,
        val durationMs: Int,
        val amplitude: Double,
        val decay: Double
    )

    private fun synthesizeToneSequence(sampleRate: Int, steps: List<ToneStep>): ShortArray {
        val totalSamples = steps.sumOf { (it.durationMs * sampleRate) / 1000 }
        val output = ShortArray(totalSamples)
        var offset = 0

        for (step in steps) {
            val count = (step.durationMs * sampleRate) / 1000
            var phase = 0.0
            for (i in 0 until count) {
                val progress = i.toDouble() / count.coerceAtLeast(1)
                val freq = step.startHz + (step.endHz - step.startHz) * progress
                phase += 2.0 * PI * freq / sampleRate
                // Yumuşak atak (ilk 3ms) ve üstel sönümlenme (tıklama/çıtırtıyı önler)
                val attack = (i.toDouble() / (sampleRate * 0.003)).coerceAtMost(1.0)
                val env = attack * exp(-step.decay * progress)
                // Sıcak akustik tını için temel dalga + hafif 2. harmonik
                val wave = (0.82 * sin(phase)) + (0.18 * sin(phase * 2.0))
                val sampleVal = (wave * step.amplitude * env * Short.MAX_VALUE).toInt()
                    .coerceIn(Short.MIN_VALUE.toInt(), Short.MAX_VALUE.toInt())
                if (offset + i < output.size) {
                    output[offset + i] = sampleVal.toShort()
                }
            }
            offset += count
        }
        return output
    }
}
