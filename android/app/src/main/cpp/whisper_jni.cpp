#include <jni.h>
#include <string>
#include <vector>
#include <fstream>
#include <thread>
#include <mutex>
#include <android/log.h>
#include "whisper.h"

#define LOG_TAG "WhisperJNI"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

// Global context (one model loaded at a time)
static whisper_context* g_ctx = nullptr;
static std::string g_model_path;
static std::mutex g_mutex;

// Custom WAV reader to read 16kHz 16-bit mono PCM audio
bool read_wav_custom(const std::string& filename, std::vector<float>& pcmf32) {
    std::ifstream file(filename, std::ios::binary);
    if (!file.is_open()) {
        LOGE("Failed to open WAV file: %s", filename.c_str());
        return false;
    }

    // Read RIFF header (12 bytes)
    char riffHeader[12];
    file.read(riffHeader, 12);
    if (file.gcount() < 12) {
        LOGE("WAV file too short for RIFF header");
        return false;
    }

    if (riffHeader[0] != 'R' || riffHeader[1] != 'I' || riffHeader[2] != 'F' || riffHeader[3] != 'F' ||
        riffHeader[8] != 'W' || riffHeader[9] != 'A' || riffHeader[10] != 'V' || riffHeader[11] != 'E') {
        LOGE("Invalid RIFF/WAVE signature");
        return false;
    }

    bool fmtFound = false;
    short audioFormat = 0;
    short numChannels = 0;
    int sampleRate = 0;
    short bitsPerSample = 0;

    // Loop through subchunks
    char chunkId[4];
    unsigned int chunkSize = 0;

    while (true) {
        file.read(chunkId, 4);
        if (file.gcount() < 4) {
            LOGE("Unexpected EOF while reading chunk ID");
            return false;
        }

        file.read(reinterpret_cast<char*>(&chunkSize), 4);
        if (file.gcount() < 4) {
            LOGE("Unexpected EOF while reading chunk size");
            return false;
        }

        // Handle chunk size bounds check
        if (chunkSize > 1000000000) {
            LOGE("Invalid chunk size: %u", chunkSize);
            return false;
        }

        if (chunkId[0] == 'f' && chunkId[1] == 'm' && chunkId[2] == 't' && chunkId[3] == ' ') {
            if (chunkSize < 16) {
                LOGE("fmt chunk too small: %u", chunkSize);
                return false;
            }

            // Read the core 16 bytes of fmt chunk
            char fmtData[16];
            file.read(fmtData, 16);
            if (file.gcount() < 16) {
                LOGE("Unexpected EOF inside fmt chunk");
                return false;
            }

            audioFormat = *reinterpret_cast<short*>(&fmtData[0]);
            numChannels = *reinterpret_cast<short*>(&fmtData[2]);
            sampleRate = *reinterpret_cast<int*>(&fmtData[4]);
            bitsPerSample = *reinterpret_cast<short*>(&fmtData[14]);

            if (audioFormat != 1) {
                LOGE("WAV is not PCM (format=%d)", audioFormat);
                return false;
            }
            if (numChannels != 1) {
                LOGE("WAV is not mono (channels=%d)", numChannels);
                return false;
            }
            if (sampleRate != 16000) {
                LOGE("WAV sample rate is not 16000Hz (rate=%d)", sampleRate);
                return false;
            }
            if (bitsPerSample != 16) {
                LOGE("WAV bits per sample is not 16-bit (bits=%d)", bitsPerSample);
                return false;
            }

            // Skip any extra format bytes (e.g. if chunkSize > 16)
            if (chunkSize > 16) {
                file.seekg(chunkSize - 16, std::ios::cur);
            }
            fmtFound = true;
        }
        else if (chunkId[0] == 'd' && chunkId[1] == 'a' && chunkId[2] == 't' && chunkId[3] == 'a') {
            if (!fmtFound) {
                LOGE("Found data chunk before fmt chunk");
                return false;
            }

            // Read PCM samples from the data chunk
            // Allocate with padding to prevent odd-byte heap buffer overflow
            std::vector<short> samples((chunkSize + 1) / 2);
            file.read(reinterpret_cast<char*>(samples.data()), chunkSize);
            size_t bytesRead = file.gcount();
            samples.resize(bytesRead / 2);

            // Convert to float
            pcmf32.resize(samples.size());
            for (size_t i = 0; i < samples.size(); ++i) {
                pcmf32[i] = static_cast<float>(samples[i]) / 32768.0f;
            }

            LOGI("Successfully loaded %zu samples from WAV file", pcmf32.size());
            return true;
        }
        else {
            // Unknown or unsupported chunk (like LIST, JUNK, metadata, etc.)
            // Seek past it (padded to even boundary per RIFF spec)
            unsigned int seekSize = (chunkSize + 1) & ~1;
            file.seekg(seekSize, std::ios::cur);
        }
    }
}

extern "C" {

// Load model — call once, reuse across transcriptions
JNIEXPORT jint JNICALL
Java_com_capstudio_WhisperJNI_loadModel(
    JNIEnv* env, jobject /* this */, jstring modelPath
) {
    std::lock_guard<std::mutex> lock(g_mutex);
    const char* path = env->GetStringUTFChars(modelPath, nullptr);
    
    // Free previous model if loaded
    if (g_ctx != nullptr) {
        whisper_free(g_ctx);
        g_ctx = nullptr;
    }
    
    whisper_context_params params = whisper_context_default_params();
    params.use_gpu = false; // Mobile CPU only
    
    // Copy path to a local std::string before releasing the JNI string,
    // so we can safely log it after ReleaseStringUTFChars without UAF.
    std::string local_path(path);
    g_ctx = whisper_init_from_file_with_params(path, params);
    env->ReleaseStringUTFChars(modelPath, path);
    
    if (g_ctx == nullptr) {
        LOGE("Failed to load model from: %s", local_path.c_str());
        return -1;
    }
    
    LOGI("Model loaded successfully from: %s", local_path.c_str());
    return 0;
}

// Transcribe WAV file — returns JSON string with word-level timestamps
JNIEXPORT jstring JNICALL
Java_com_capstudio_WhisperJNI_transcribe(
    JNIEnv* env, jobject /* this */,
    jstring wavPath, jstring language,
    jint threads, jboolean useVad, jfloat vadThreshold, jboolean translate
) {
    std::lock_guard<std::mutex> lock(g_mutex);
    if (g_ctx == nullptr) {
        return env->NewStringUTF("{\"error\":\"Model not loaded\"}");
    }
    
    const char* wav_path = env->GetStringUTFChars(wavPath, nullptr);
    if (wav_path == nullptr) {
        return env->NewStringUTF("{\"error\":\"Out of memory (wav path)\"}");
    }
    const char* lang = env->GetStringUTFChars(language, nullptr);
    if (lang == nullptr) {
        env->ReleaseStringUTFChars(wavPath, wav_path);
        return env->NewStringUTF("{\"error\":\"Out of memory (language)\"}");
    }
    
    // Load WAV file
    std::vector<float> pcmf32;
    if (!read_wav_custom(wav_path, pcmf32)) {
        env->ReleaseStringUTFChars(wavPath, wav_path);
        env->ReleaseStringUTFChars(language, lang);
        return env->NewStringUTF("{\"error\":\"Failed to read WAV file\"}");
    }
    
    // Configure transcription parameters
    whisper_full_params params = whisper_full_default_params(WHISPER_SAMPLING_GREEDY);
    
    params.print_realtime   = false;
    params.print_progress   = false;
    params.print_timestamps = true;
    params.print_special    = false;
    params.translate        = translate;
    params.language         = (lang != nullptr && strlen(lang) > 0) ? lang : "auto";
    params.n_threads        = threads;
    params.token_timestamps = true; // CRITICAL: word-level timestamps
    params.thold_pt         = 0.01f;
    params.max_len          = 0;
    
    if (useVad) {
        params.vad = true;
        params.vad_params.threshold = vadThreshold;
    }
    
    // Run transcription
    if (whisper_full(g_ctx, params, pcmf32.data(), (int)pcmf32.size()) != 0) {
        env->ReleaseStringUTFChars(wavPath, wav_path);
        env->ReleaseStringUTFChars(language, lang);
        return env->NewStringUTF("{\"error\":\"Transcription failed\"}");
    }
    
    env->ReleaseStringUTFChars(language, lang);
    
    // Build JSON output matching whisper-cli -oj format exactly
    std::string json = "{\"transcription\":[";
    bool firstWord = true;
    
    const int n_segments = whisper_full_n_segments(g_ctx);
    for (int i = 0; i < n_segments; i++) {
        const int n_tokens = whisper_full_n_tokens(g_ctx, i);
        for (int j = 0; j < n_tokens; j++) {
            whisper_token_data token = whisper_full_get_token_data(g_ctx, i, j);
            const char* text = whisper_full_get_token_text(g_ctx, i, j);
            
            // Skip special tokens
            if (token.id >= whisper_token_eot(g_ctx)) continue;
            
            std::string word(text);
            if (word.empty() || word == " ") continue;
            
            // Timestamps in milliseconds
            long long t0 = (long long)(token.t0 * 10); // whisper uses centiseconds
            long long t1 = (long long)(token.t1 * 10);
            float prob = token.p;
            
            if (!firstWord) json += ",";
            firstWord = false;
            
            // Escape word text for JSON safety.
            // - Must handle: ", \, and all control characters (0x00-0x1F).
            // - std::to_string(float) is locale-dependent on some Android devices
            //   (German/French locales use ',' as decimal separator).
            //   Use snprintf with "%.6f" which is always locale-independent.
            std::string escaped;
            escaped.reserve(word.size() + 8);
            for (unsigned char c : word) {
                switch (c) {
                    case '"':  escaped += "\\\""; break;
                    case '\\': escaped += "\\\\"; break;
                    case '\b': escaped += "\\b";  break;
                    case '\f': escaped += "\\f";  break;
                    case '\n': escaped += "\\n";  break;
                    case '\r': escaped += "\\r";  break;
                    case '\t': escaped += "\\t";  break;
                    default:
                        if (c < 0x20) {
                            char buf[8];
                            snprintf(buf, sizeof(buf), "\\u%04x", c);
                            escaped += buf;
                        } else {
                            escaped += (char)c;
                        }
                }
            }
            
            // Format float probability with snprintf (locale-independent)
            char probBuf[32];
            snprintf(probBuf, sizeof(probBuf), "%.6f", prob);
            
            json += "{\"text\":\"" + escaped + "\",";
            json += "\"timestamps\":{\"from\":" + std::to_string(t0) + ",\"to\":" + std::to_string(t1) + "},";
            json += "\"p\":" + std::string(probBuf) + "}";
        }
    }
    
    const int lang_id = whisper_full_lang_id(g_ctx);
    const char* lang_str = whisper_lang_str(lang_id);
    json += "],\"language\":\"" + std::string(lang_str ? lang_str : "en") + "\"}";
    
    // Memory Leak Fix: Write to temp file to avoid JNI NewStringUTF OutOfMemory for large JSONs
    std::string temp_path = std::string(wav_path) + ".json";
    env->ReleaseStringUTFChars(wavPath, wav_path);
    
    std::ofstream out_file(temp_path, std::ios::binary);
    if (out_file.is_open()) {
        out_file << json;
        out_file.close();
        return env->NewStringUTF(temp_path.c_str());
    }
    
    return env->NewStringUTF(json.c_str());
}

// Free model from memory
JNIEXPORT void JNICALL
Java_com_capstudio_WhisperJNI_freeModel(JNIEnv* /* env */, jobject /* this */) {
    std::lock_guard<std::mutex> lock(g_mutex);
    if (g_ctx != nullptr) {
        whisper_free(g_ctx);
        g_ctx = nullptr;
        LOGI("Model freed successfully");
    }
}

// Get available CPU threads
JNIEXPORT jint JNICALL
Java_com_capstudio_WhisperJNI_getAvailableThreads(JNIEnv* /* env */, jobject /* this */) {
    return std::thread::hardware_concurrency();
}

} // extern "C"
