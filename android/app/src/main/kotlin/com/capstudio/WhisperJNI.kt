package com.capstudio

import androidx.annotation.Keep

@Keep
class WhisperJNI {
    companion object {
        init {
            System.loadLibrary("whisper_jni")
        }
    }

    external fun loadModel(modelPath: String): Int
    external fun transcribe(
        wavPath: String,
        language: String,
        threads: Int,
        useVad: Boolean,
        vadThreshold: Float,
        translate: Boolean,
    ): String
    external fun freeModel()
    external fun getAvailableThreads(): Int
}
