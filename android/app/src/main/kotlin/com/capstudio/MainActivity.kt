package com.capstudio

import android.content.ContentValues
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import androidx.core.content.FileProvider
import java.io.File
import java.io.IOException
import kotlin.concurrent.thread

class MainActivity : FlutterActivity() {
    private val PERMISSIONS_CHANNEL = "com.capstudio.ai/permissions"
    private val WHISPER_CHANNEL = "com.capstudio/whisper"
    private val SHARE_CHANNEL = "com.capstudio/share"
    private val NATIVE_CHANNEL = "com.capstudio/native"
    
    private val whisperJNI = WhisperJNI()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Permissions Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PERMISSIONS_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestStoragePermission" -> {
                    // No-op / always success since we removed MANAGE_EXTERNAL_STORAGE.
                    // CapStudio uses scoped/app-specific storage directories which do not require permissions.
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        // Whisper Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WHISPER_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "loadModel" -> {
                    val modelPath = call.argument<String>("modelPath")
                    if (modelPath == null) {
                        result.error("INVALID_ARGS", "modelPath is required", null)
                        return@setMethodCallHandler
                    }
                    thread {
                        try {
                            val res = whisperJNI.loadModel(modelPath)
                            runOnUiThread { result.success(res) }
                        } catch (e: Exception) {
                            runOnUiThread { result.error("LOAD_FAILED", e.message, null) }
                        }
                    }
                }
                "transcribe" -> {
                    val wavPath = call.argument<String>("wavPath")
                    val language = call.argument<String>("language") ?: ""
                    val threads = call.argument<Int>("threads") ?: 4
                    val useVad = call.argument<Boolean>("useVad") ?: false
                    val vadThreshold = (call.argument<Double>("vadThreshold") ?: 0.5).toFloat()
                    val translate = call.argument<Boolean>("translate") ?: false

                    if (wavPath == null) {
                        result.error("INVALID_ARGS", "wavPath is required", null)
                        return@setMethodCallHandler
                    }

                    thread {
                        try {
                            val jsonResult = whisperJNI.transcribe(wavPath, language, threads, useVad, vadThreshold, translate)
                            runOnUiThread { result.success(jsonResult) }
                        } catch (e: Exception) {
                            runOnUiThread { result.error("TRANSCRIBE_FAILED", e.message, null) }
                        }
                    }
                }
                "freeModel" -> {
                    thread {
                        try {
                            whisperJNI.freeModel()
                            runOnUiThread { result.success(null) }
                        } catch (e: Exception) {
                            runOnUiThread { result.error("FREE_FAILED", e.message, null) }
                        }
                    }
                }
                "getAvailableThreads" -> {
                    try {
                        val threads = whisperJNI.getAvailableThreads()
                        result.success(threads)
                    } catch (e: Exception) {
                        result.error("THREADS_FAILED", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        // Native Channel (PhotoKit / MediaStore Gallery Saving)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NATIVE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "saveVideoToGallery", "saveToGallery" -> {
                    val path = call.argument<String>("path")
                    if (path == null) {
                        result.error("INVALID_ARGS", "path is required", null)
                        return@setMethodCallHandler
                    }
                    val name = call.argument<String>("name")
                    val mimeType = call.argument<String>("mimeType") ?: "video/mp4"
                    val relativeFolder = call.argument<String>("relativeFolder")
                    saveVideoToGallery(path, name, mimeType, relativeFolder, result)
                }
                else -> result.notImplemented()
            }
        }

        // Share Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SHARE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "shareFile" -> {
                    val path = call.argument<String>("path")
                    if (path == null) {
                        result.error("INVALID_ARGS", "path is required", null)
                        return@setMethodCallHandler
                    }
                    val mimeType = call.argument<String>("mimeType") ?: "*/*"
                    try {
                        val file = File(path)
                        val uri = FileProvider.getUriForFile(
                            this, "${applicationContext.packageName}.provider", file
                        )
                        val intent = Intent(Intent.ACTION_SEND).apply {
                            type = mimeType
                            putExtra(Intent.EXTRA_STREAM, uri)
                            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                        }
                        startActivity(Intent.createChooser(intent, "Share via"))
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("SHARE_FAILED", e.message, null)
                    }
                }
                "saveVideoToGallery", "saveToGallery" -> {
                    val path = call.argument<String>("path")
                    if (path == null) {
                        result.error("INVALID_ARGS", "path is required", null)
                        return@setMethodCallHandler
                    }
                    val name = call.argument<String>("name")
                    val mimeType = call.argument<String>("mimeType") ?: "video/mp4"
                    val relativeFolder = call.argument<String>("relativeFolder")
                    saveVideoToGallery(path, name, mimeType, relativeFolder, result)
                }
                "saveToDownloads" -> {
                    val path = call.argument<String>("path")
                    val name = call.argument<String>("name")
                    val mimeType = call.argument<String>("mimeType") ?: "video/mp4"
                    if (path == null) {
                        result.error("INVALID_ARGS", "path is required", null)
                        return@setMethodCallHandler
                    }
                    saveVideoToGallery(path, name, mimeType, Environment.DIRECTORY_DOWNLOADS, result)
                }
                else -> result.notImplemented()
            }
        }
    }

    /**
     * Saves an exported video directly into MediaStore (Camera Roll / Gallery) using Scoped Storage.
     * Uses MediaStore.Video.Media with RELATIVE_PATH = Environment.DIRECTORY_MOVIES + "/CapStudio"
     * (or Environment.DIRECTORY_DOWNLOADS) and IS_PENDING flag for Android 10+ (API 29+) and Android 13+ (API 33+)
     * cleanly without requiring obsolete WRITE_EXTERNAL_STORAGE permissions.
     */
    private fun saveVideoToGallery(
        path: String,
        name: String?,
        mimeType: String?,
        relativeFolder: String?,
        result: MethodChannel.Result
    ) {
        val file = File(path)
        if (!file.exists()) {
            result.error("FILE_NOT_FOUND", "Source video file not found at $path", null)
            return
        }

        val videoName = name ?: file.name
        val videoMimeType = mimeType ?: "video/mp4"
        val destinationFolder = relativeFolder ?: (Environment.DIRECTORY_MOVIES + "/CapStudio")

        thread {
            try {
                val resolver = contentResolver
                val contentValues = ContentValues().apply {
                    put(MediaStore.Video.Media.DISPLAY_NAME, videoName)
                    put(MediaStore.Video.Media.MIME_TYPE, videoMimeType)
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        put(MediaStore.Video.Media.RELATIVE_PATH, destinationFolder)
                        put(MediaStore.Video.Media.IS_PENDING, 1)
                    }
                }

                val collection = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    MediaStore.Video.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
                } else {
                    MediaStore.Video.Media.EXTERNAL_CONTENT_URI
                }

                val uri = resolver.insert(collection, contentValues)
                if (uri == null) {
                    runOnUiThread { result.error("INSERT_FAILED", "Failed to insert MediaStore entry", null) }
                    return@thread
                }

                val outputStream = resolver.openOutputStream(uri)
                if (outputStream == null) {
                    throw IOException("Failed to open output stream for MediaStore URI: $uri")
                }

                val inputStream = file.inputStream()
                inputStream.use { input ->
                    outputStream.use { output ->
                        input.copyTo(output)
                    }
                }

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    contentValues.clear()
                    contentValues.put(MediaStore.Video.Media.IS_PENDING, 0)
                    resolver.update(uri, contentValues, null, null)
                }

                runOnUiThread { result.success(true) }
            } catch (e: Exception) {
                runOnUiThread { result.error("SAVE_FAILED", e.message, null) }
            }
        }
    }
}
