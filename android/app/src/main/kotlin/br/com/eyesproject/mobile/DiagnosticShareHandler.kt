package br.com.eyesproject.mobile

import android.content.Intent
import android.os.Build
import android.util.AtomicFile
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import org.json.JSONObject

/** Explicit export of app-owned support data. Never reads camera or logcat. */
class DiagnosticShareHandler(private val activity: FlutterActivity) {
    private val directory get() = File(activity.cacheDir, "support-diagnostics")
    private val stored get() = AtomicFile(File(activity.noBackupFilesDir, "support-diagnostic.json"))

    fun handle(call: MethodCall, result: MethodChannel.Result) {
        if (!activity.packageName.endsWith(".dev")) {
            result.error("diagnostics_unavailable", "Diagnostics unavailable.", null)
            return
        }
        try {
            when (call.method) {
                "readReport" -> {
                    val file = stored
                    val text = if (file.baseFile.exists() && file.baseFile.length() <= 100000) file.readFully().toString(Charsets.UTF_8) else null
                    result.success(text)
                }
                "writeReport" -> {
                    val text = call.argument<String>("report") ?: throw IllegalArgumentException()
                    validate(text)
                    val file = stored
                    val stream = file.startWrite()
                    try {
                        stream.write(text.toByteArray(Charsets.UTF_8))
                        file.finishWrite(stream)
                    } catch (failure: Exception) {
                        file.failWrite(stream)
                        throw failure
                    }
                    result.success(null)
                }
                "clearReport" -> {
                    stored.delete()
                    File(directory, FILE_NAME).delete()
                    result.success(null)
                }
                "clearSharedReport" -> {
                    File(directory, FILE_NAME).delete()
                    result.success(null)
                }
                "shareReport" -> {
                    val text = call.argument<String>("report")
                        ?: throw IllegalArgumentException()
                    val report = validate(text)
                    require(report.getString("status") != "recording_snapshot")
                    val packageInfo = activity.packageManager.getPackageInfo(activity.packageName, 0)
                    val wrapper = JSONObject().put("report", report).put("device", JSONObject()
                        .put("manufacturer", Build.MANUFACTURER)
                        .put("model", Build.MODEL)
                        .put("android_api", Build.VERSION.SDK_INT)
                        .put("application_id", activity.packageName)
                        .put("version_name", packageInfo.versionName))
                    directory.mkdirs()
                    val file = File(directory, FILE_NAME)
                    file.writeText(wrapper.toString(2), Charsets.UTF_8)
                    val uri = FileProvider.getUriForFile(activity, "${activity.packageName}.diagnostics", file)
                    val intent = Intent(Intent.ACTION_SEND).apply {
                        type = "application/json"
                        putExtra(Intent.EXTRA_STREAM, uri)
                        clipData = android.content.ClipData.newRawUri("Diagnóstico Eyes", uri)
                        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                    }
                    activity.startActivity(Intent.createChooser(intent, "Compartilhar diagnóstico Eyes"))
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        } catch (_: Exception) {
            result.error("diagnostic_export_failed", "Unable to export diagnostics.", null)
        }
    }

    fun pruneExpired() {
        val file = File(directory, FILE_NAME)
        if (file.exists() && System.currentTimeMillis() - file.lastModified() >= 7L * 24 * 60 * 60 * 1000) file.delete()
        val local = stored
        if (local.baseFile.exists() && System.currentTimeMillis() - local.baseFile.lastModified() >= 7L * 24 * 60 * 60 * 1000) local.delete()
    }

    private fun validate(text: String): JSONObject {
        require(text.toByteArray(Charsets.UTF_8).size <= 100000)
        val report = JSONObject(text)
        require(report.getInt("schema_version") == 1)
        require(report.getString("purpose") == "local_support_diagnostic_not_scientific_evaluation")
        return report
    }

    private companion object { const val FILE_NAME = "eyes-diagnostico.json" }
}
