package com.example.episode

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.provider.OpenableColumns
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import kotlin.concurrent.thread

class MainActivity : FlutterActivity() {
    private val channelName = "otakulog/file_transfer"
    private val pickRequestCode = 7411
    private val saveRequestCode = 7412
    private var pendingResult: MethodChannel.Result? = null
    private var pendingSaveBytes: ByteArray? = null
    private var pendingMaxBytes: Int = 10 * 1024 * 1024

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName,
        ).setMethodCallHandler { call, result ->
            if (pendingResult != null) {
                result.error("busy", "Another file operation is already active.", null)
                return@setMethodCallHandler
            }
            when (call.method) {
                "pickFile" -> {
                    pendingResult = result
                    pendingMaxBytes = call.argument<Int>("maxBytes") ?: pendingMaxBytes
                    val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                        addCategory(Intent.CATEGORY_OPENABLE)
                        type = "*/*"
                        putExtra(
                            Intent.EXTRA_MIME_TYPES,
                            arrayOf(
                                "application/json",
                                "application/xml",
                                "text/xml",
                                "application/gzip",
                                "application/x-gzip",
                                "application/octet-stream",
                            ),
                        )
                    }
                    startActivityForResult(intent, pickRequestCode)
                }
                "saveFile" -> {
                    val bytes = call.argument<ByteArray>("bytes")
                    if (bytes == null) {
                        result.error("invalid_bytes", "No export bytes were provided.", null)
                        return@setMethodCallHandler
                    }
                    pendingResult = result
                    pendingSaveBytes = bytes
                    val safeName = safeFileName(
                        call.argument<String>("name") ?: "otakulog-export",
                    )
                    val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                        addCategory(Intent.CATEGORY_OPENABLE)
                        type = call.argument<String>("mimeType") ?: "application/octet-stream"
                        putExtra(Intent.EXTRA_TITLE, safeName)
                    }
                    startActivityForResult(intent, saveRequestCode)
                }
                else -> result.notImplemented()
            }
        }
    }

    @Deprecated("Deprecated in Android, retained for FlutterActivity compatibility")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != pickRequestCode && requestCode != saveRequestCode) {
            return
        }
        val result = pendingResult ?: return
        if (resultCode != Activity.RESULT_OK || data?.data == null) {
            clearPending()
            result.success(null)
            return
        }
        val uri = data.data!!
        if (requestCode == pickRequestCode) {
            readSelectedFile(uri, result)
        } else {
            writeSelectedFile(uri, result)
        }
    }

    private fun readSelectedFile(uri: Uri, result: MethodChannel.Result) {
        thread(name = "otakulog-file-import") {
            try {
                val metadata = queryMetadata(uri)
                val declaredSize = metadata.second
                if (declaredSize != null && declaredSize > pendingMaxBytes) {
                    throw IllegalArgumentException("The selected file exceeds the size limit.")
                }
                val output = ByteArrayOutputStream()
                contentResolver.openInputStream(uri).use { input ->
                    requireNotNull(input) { "The selected file could not be opened." }
                    val buffer = ByteArray(16 * 1024)
                    var total = 0
                    while (true) {
                        val read = input.read(buffer)
                        if (read < 0) break
                        total += read
                        if (total > pendingMaxBytes) {
                            throw IllegalArgumentException("The selected file exceeds the size limit.")
                        }
                        output.write(buffer, 0, read)
                    }
                }
                val response = mapOf(
                    "name" to safeFileName(metadata.first ?: "import"),
                    "mimeType" to contentResolver.getType(uri),
                    "bytes" to output.toByteArray(),
                )
                runOnUiThread {
                    clearPending()
                    result.success(response)
                }
            } catch (error: Exception) {
                runOnUiThread {
                    clearPending()
                    result.error("file_read_failed", error.message, null)
                }
            }
        }
    }

    private fun writeSelectedFile(uri: Uri, result: MethodChannel.Result) {
        val bytes = pendingSaveBytes
        thread(name = "otakulog-file-export") {
            try {
                requireNotNull(bytes) { "No export bytes are available." }
                contentResolver.openOutputStream(uri, "wt").use { output ->
                    requireNotNull(output) { "The destination could not be opened." }
                    output.write(bytes)
                    output.flush()
                }
                runOnUiThread {
                    clearPending()
                    result.success(true)
                }
            } catch (error: Exception) {
                runOnUiThread {
                    clearPending()
                    result.error("file_write_failed", error.message, null)
                }
            }
        }
    }

    private fun queryMetadata(uri: Uri): Pair<String?, Long?> {
        contentResolver.query(
            uri,
            arrayOf(OpenableColumns.DISPLAY_NAME, OpenableColumns.SIZE),
            null,
            null,
            null,
        ).use { cursor ->
            if (cursor == null || !cursor.moveToFirst()) return Pair(null, null)
            val nameIndex = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
            val sizeIndex = cursor.getColumnIndex(OpenableColumns.SIZE)
            val name = if (nameIndex >= 0 && !cursor.isNull(nameIndex)) {
                cursor.getString(nameIndex)
            } else {
                null
            }
            val size = if (sizeIndex >= 0 && !cursor.isNull(sizeIndex)) {
                cursor.getLong(sizeIndex)
            } else {
                null
            }
            return Pair(name, size)
        }
    }

    private fun safeFileName(value: String): String {
        return value.substringAfterLast('/').substringAfterLast('\\')
            .replace(Regex("[<>:\"/\\\\|?*\\u0000-\\u001F]"), "_")
    }

    private fun clearPending() {
        pendingResult = null
        pendingSaveBytes = null
    }
}
