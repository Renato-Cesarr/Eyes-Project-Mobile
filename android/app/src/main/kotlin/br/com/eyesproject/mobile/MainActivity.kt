package br.com.eyesproject.mobile

import android.content.Context
import android.content.pm.ApplicationInfo
import android.media.AudioAttributes
import android.os.Build
import android.os.VibrationAttributes
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            HAPTICS_CHANNEL,
        ).setMethodCallHandler { call, result ->
            val vibrator = systemVibrator()
            when (call.method) {
                "isAvailable" -> result.success(vibrator.hasVibrator())
                "vibrate" -> {
                    if (!vibrator.hasVibrator()) {
                        result.success(false)
                        return@setMethodCallHandler
                    }
                    val pattern = call.argument<String>("pattern")
                    vibrate(vibrator, pattern)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CALIBRATION_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getSessionConfiguration" -> {
                    val configuration = calibrationConfiguration()
                    result.success(configuration)
                }
                "emitEvent" -> {
                    val payload = call.argument<String>("payload")
                    if (payload.isNullOrBlank()) {
                        result.error(
                            "invalid_calibration_event",
                            "Calibration payload must not be blank.",
                            null,
                        )
                        return@setMethodCallHandler
                    }
                    Log.i(CALIBRATION_LOG_TAG, payload)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
        super.configureFlutterEngine(flutterEngine)
    }

    private fun systemVibrator(): Vibrator =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            getSystemService(VibratorManager::class.java).defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        }

    private fun vibrate(vibrator: Vibrator, patternName: String?) {
        val timings: LongArray
        val amplitudes: IntArray
        when (patternName) {
            "critical" -> {
                timings = longArrayOf(0, 180, 100, 220)
                amplitudes = intArrayOf(0, 255, 0, 255)
            }
            "warning" -> {
                timings = longArrayOf(0, 180)
                amplitudes = intArrayOf(0, 220)
            }
            else -> {
                timings = longArrayOf(0, 120)
                amplitudes = intArrayOf(0, 190)
            }
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val effect = if (vibrator.hasAmplitudeControl()) {
                VibrationEffect.createWaveform(timings, amplitudes, -1)
            } else {
                VibrationEffect.createWaveform(timings, -1)
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                vibrator.vibrate(
                    effect,
                    VibrationAttributes.Builder()
                        .setUsage(VibrationAttributes.USAGE_ACCESSIBILITY)
                        .build(),
                )
            } else {
                @Suppress("DEPRECATION")
                vibrator.vibrate(
                    effect,
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ASSISTANCE_ACCESSIBILITY)
                        .build(),
                )
            }
        } else {
            @Suppress("DEPRECATION")
            vibrator.vibrate(timings, -1)
        }
    }

    private fun calibrationConfiguration(): Map<String, Any?> = mapOf(
        "enabled" to (
            isDiagnosticsBuild() &&
                intent.getBooleanExtra("calibrationEnabled", false)
            ),
        "sessionId" to intent.getStringExtra("calibrationSessionId"),
        "scenarioId" to intent.getStringExtra("calibrationScenarioId"),
        "datasetSplit" to intent.getStringExtra("calibrationDatasetSplit"),
        "expectedKind" to intent.getStringExtra("calibrationExpectedKind"),
        "expectedBand" to intent.getStringExtra("calibrationExpectedBand"),
        "lighting" to intent.getStringExtra("calibrationLighting"),
        "occlusion" to intent.getStringExtra("calibrationOcclusion"),
    )

    private fun isDiagnosticsBuild(): Boolean =
        applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE != 0

    private companion object {
        const val HAPTICS_CHANNEL =
            "br.com.eyesproject.mobile/assistive_haptics"
        const val CALIBRATION_CHANNEL =
            "br.com.eyesproject.mobile/calibration"
        const val CALIBRATION_LOG_TAG = "EyesCalibration"
    }
}
