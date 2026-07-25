package com.jacaloria.app

import android.Manifest
import android.content.ContentValues
import android.content.pm.PackageManager
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    companion object {
        private const val DOWNLOADS_CHANNEL = "com.jacaloria.app/downloads"
        private const val WRITE_STORAGE_REQUEST = 9471
    }

    private var pendingLegacySave: Pair<MethodCall, MethodChannel.Result>? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            DOWNLOADS_CHANNEL,
        ).setMethodCallHandler { call, result ->
            if (call.method != "saveToDownloads") {
                result.notImplemented()
                return@setMethodCallHandler
            }

            if (
                Build.VERSION.SDK_INT < Build.VERSION_CODES.Q &&
                ContextCompat.checkSelfPermission(
                    this,
                    Manifest.permission.WRITE_EXTERNAL_STORAGE,
                ) != PackageManager.PERMISSION_GRANTED
            ) {
                pendingLegacySave = call to result
                ActivityCompat.requestPermissions(
                    this,
                    arrayOf(Manifest.permission.WRITE_EXTERNAL_STORAGE),
                    WRITE_STORAGE_REQUEST,
                )
                return@setMethodCallHandler
            }

            saveToDownloads(call, result)
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != WRITE_STORAGE_REQUEST) return

        val pending = pendingLegacySave ?: return
        pendingLegacySave = null
        if (grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED) {
            saveToDownloads(pending.first, pending.second)
        } else {
            pending.second.error(
                "storage_permission_denied",
                "Permissão para salvar em Downloads negada.",
                null,
            )
        }
    }

    private fun saveToDownloads(call: MethodCall, result: MethodChannel.Result) {
        val bytes = call.argument<ByteArray>("bytes")
        val filename = call.argument<String>("filename")?.trim()
        val mimeType = call.argument<String>("mimeType") ?: "application/octet-stream"
        if (bytes == null || filename.isNullOrEmpty()) {
            result.error("invalid_download", "Arquivo inválido.", null)
            return
        }

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                saveWithMediaStore(bytes, filename, mimeType)
            } else {
                saveToLegacyDownloads(bytes, filename)
            }
            result.success(null)
        } catch (error: Exception) {
            result.error(
                "download_failed",
                "Não foi possível salvar a imagem em Downloads.",
                error.message,
            )
        }
    }

    private fun saveWithMediaStore(bytes: ByteArray, filename: String, mimeType: String) {
        val values = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, filename)
            put(MediaStore.MediaColumns.MIME_TYPE, mimeType)
            put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
            put(MediaStore.MediaColumns.IS_PENDING, 1)
        }
        val resolver = contentResolver
        val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
            ?: error("MediaStore recusou a criação do arquivo.")

        try {
            resolver.openOutputStream(uri)?.use { it.write(bytes) }
                ?: error("Não foi possível abrir o arquivo para escrita.")
            values.clear()
            values.put(MediaStore.MediaColumns.IS_PENDING, 0)
            resolver.update(uri, values, null, null)
        } catch (error: Exception) {
            resolver.delete(uri, null, null)
            throw error
        }
    }

    @Suppress("DEPRECATION")
    private fun saveToLegacyDownloads(bytes: ByteArray, filename: String) {
        val directory = Environment.getExternalStoragePublicDirectory(
            Environment.DIRECTORY_DOWNLOADS,
        )
        if (!directory.exists() && !directory.mkdirs()) {
            error("Não foi possível acessar a pasta Downloads.")
        }
        File(directory, filename).writeBytes(bytes)
    }
}
