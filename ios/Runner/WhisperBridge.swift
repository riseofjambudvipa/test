import Foundation
import Accelerate
import Flutter
import UIKit

// Custom WAV reader to read 16kHz 16-bit mono PCM audio
func readWavFile(at path: String) -> [Float]? {
    guard let file = FileHandle(forReadingAtPath: path) else {
        return nil
    }
    defer {
        try? file.close()
    }
    
    // Read RIFF header (12 bytes)
    guard let riffData = try? file.read(upToCount: 12), riffData.count == 12 else {
        return nil
    }
    let riffHeader = [UInt8](riffData)
    
    // Check RIFF/WAVE signature
    if riffHeader[0] != 82 /* R */ || riffHeader[1] != 73 /* I */ || riffHeader[2] != 70 /* F */ || riffHeader[3] != 70 /* F */ ||
       riffHeader[8] != 87 /* W */ || riffHeader[9] != 65 /* A */ || riffHeader[10] != 86 /* V */ || riffHeader[11] != 69 /* E */ {
        return nil
    }
    
    var fmtFound = false
    var audioFormat: UInt16 = 0
    var numChannels: UInt16 = 0
    var sampleRate: UInt32 = 0
    var bitsPerSample: UInt16 = 0
    var dataSize: UInt32 = 0
    
    while true {
        guard let chunkIdData = try? file.read(upToCount: 4), chunkIdData.count == 4 else {
            return nil
        }
        let chunkId = [UInt8](chunkIdData)
        
        guard let chunkSizeData = try? file.read(upToCount: 4), chunkSizeData.count == 4 else {
            return nil
        }
        let chunkSizeBytes = [UInt8](chunkSizeData)
        let chunkSize = UInt32(chunkSizeBytes[0]) |
                        (UInt32(chunkSizeBytes[1]) << 8) |
                        (UInt32(chunkSizeBytes[2]) << 16) |
                        (UInt32(chunkSizeBytes[3]) << 24)
        
        // Handle chunk size bounds check (max 2GB)
        guard chunkSize < 2_000_000_000 else {
            return nil
        }
        
        if chunkId[0] == 102 /* f */ && chunkId[1] == 109 /* m */ && chunkId[2] == 116 /* t */ && chunkId[3] == 32 /*   */ {
            guard chunkSize >= 16 else {
                return nil
            }
            guard let fmtData = try? file.read(upToCount: 16), fmtData.count == 16 else {
                return nil
            }
            let fmtBytes = [UInt8](fmtData)
            
            audioFormat = UInt16(fmtBytes[0]) | (UInt16(fmtBytes[1]) << 8)
            numChannels = UInt16(fmtBytes[2]) | (UInt16(fmtBytes[3]) << 8)
            sampleRate = UInt32(fmtBytes[4]) | (UInt32(fmtBytes[5]) << 8) | (UInt32(fmtBytes[6]) << 16) | (UInt32(fmtBytes[7]) << 24)
            bitsPerSample = UInt16(fmtBytes[14]) | (UInt16(fmtBytes[15]) << 8)
            
            if audioFormat != 1 || numChannels != 1 || sampleRate != 16000 || bitsPerSample != 16 {
                return nil
            }
            
            if chunkSize > 16 {
                try? file.seek(toOffset: file.offsetInFile + UInt64(chunkSize - 16))
            }
            fmtFound = true
        } else if chunkId[0] == 100 /* d */ && chunkId[1] == 97 /* a */ && chunkId[2] == 116 /* t */ && chunkId[3] == 97 /* a */ {
            guard fmtFound else {
                return nil
            }
            dataSize = chunkSize
            break
        } else {
            // Seek past unknown chunk, padded to even boundary
            let seekSize = (chunkSize + 1) & ~1
            try? file.seek(toOffset: file.offsetInFile + UInt64(seekSize))
        }
    }
    
    // Read PCM samples iteratively in chunks to avoid massive intermediate memory spike
    let expectedSampleCount = Int(dataSize) / 2
    // Safety check on sample count to prevent OOM array allocations (max ~4 hours)
    guard expectedSampleCount > 0 && expectedSampleCount < 250_000_000 else {
        return nil
    }
    var floatSamples = [Float](repeating: 0.0, count: expectedSampleCount)
    
    let chunkSize = 32768 // 32KB per read
    var samplesRead = 0
    
    while samplesRead < expectedSampleCount {
        let bytesRemaining = Int(dataSize) - (samplesRead * 2)
        let bytesToRead = min(chunkSize, bytesRemaining)
        guard let chunkData = try? file.read(upToCount: bytesToRead), !chunkData.isEmpty else {
            break
        }
        
        chunkData.withUnsafeBytes { rawBufferPointer in
            let chunkSamples = chunkData.count / 2
            for i in 0..<chunkSamples {
                let sample = rawBufferPointer.load(fromByteOffset: i * 2, as: Int16.self)
                floatSamples[samplesRead + i] = Float(sample) / 32768.0
            }
            samplesRead += chunkSamples
        }
    }
    
    if samplesRead < expectedSampleCount {
        floatSamples.removeLast(expectedSampleCount - samplesRead)
    }
    
    return floatSamples
}

class WhisperLib {
    static func initFromFile(_ modelPath: String) -> OpaquePointer? {
        let cparams = whisper_context_default_params()
        var params = cparams
        params.use_gpu = false
        return whisper_init_from_file_with_params(modelPath, params)
    }
    
    static func transcribe(
        ctx: OpaquePointer,
        wavPath: String,
        language: String,
        threads: Int,
        useVad: Bool,
        vadThreshold: Float,
        translate: Bool
    ) -> String {
        guard let pcmf32 = readWavFile(at: wavPath) else {
            return "{\"error\":\"Failed to read WAV file\"}"
        }
        
        var params = whisper_full_default_params(WHISPER_SAMPLING_GREEDY)
        params.print_realtime = false
        params.print_progress = false
        params.print_timestamps = true
        params.print_special = false
        params.translate = translate
        
        let langCode = language.isEmpty ? "auto" : language
        params.n_threads = Int32(threads)
        params.token_timestamps = true
        params.thold_pt = 0.01
        params.max_len = 0
        
        if useVad {
            params.vad = true
            params.vad_params.threshold = vadThreshold
        }
        
        let sampleCount = Int32(pcmf32.count)
        let result = langCode.withCString { cLanguage in
            params.language = cLanguage
            return whisper_full(ctx, params, pcmf32, sampleCount)
        }
        if result != 0 {
            return "{\"error\":\"Transcription failed with code \(result)\"}"
        }
        
        var json = "{\"transcription\":["
        var firstWord = true
        
        let n_segments = whisper_full_n_segments(ctx)
        for i in 0..<n_segments {
            let n_tokens = whisper_full_n_tokens(ctx, i)
            for j in 0..<n_tokens {
                let token = whisper_full_get_token_data(ctx, i, j)
                
                // Skip special tokens
                if token.id >= whisper_token_eot(ctx) {
                    continue
                }
                
                guard let cText = whisper_full_get_token_text(ctx, i, j) else {
                    continue
                }
                let word = String(cString: cText)
                if word.isEmpty || word == " " {
                    continue
                }
                
                // Timestamps in milliseconds (from centiseconds)
                let t0 = token.t0 * 10
                let t1 = token.t1 * 10
                let prob = token.p
                
                if !firstWord {
                    json += ","
                }
                firstWord = false
                
                // Escape all JSON-unsafe characters:
                // - double-quote, backslash, and all ASCII control chars (0x00-0x1F).
                // Swift string interpolation handles locale correctly for floats,
                // but raw character values must be escaped manually.
                var escaped = ""
                for scalar in word.unicodeScalars {
                    let v = scalar.value
                    switch v {
                    case 0x22: escaped += "\\\""          // "
                    case 0x5C: escaped += "\\\\"          // \
                    case 0x08: escaped += "\\b"
                    case 0x0C: escaped += "\\f"
                    case 0x0A: escaped += "\\n"
                    case 0x0D: escaped += "\\r"
                    case 0x09: escaped += "\\t"
                    case 0x00..<0x20:                      // other control characters
                        escaped += String(format: "\\u%04x", v)
                    default:
                        escaped += String(scalar)
                    }
                }
                
                json += "{\"text\":\"\(escaped)\","
                json += "\"timestamps\":{\"from\":\(t0),\"to\":\(t1)},"
                json += "\"p\":\(prob)}"
            }
        }
        
        json += "]"
        let langId = whisper_full_lang_id(ctx)
        if let cLangStr = whisper_lang_str(langId) {
            let langStr = String(cString: cLangStr)
            json += ",\"language\":\"\(langStr)\""
        } else {
            json += ",\"language\":\"en\""
        }
        json += "}"
        
        let tempPath = (wavPath as NSString).deletingPathExtension + "_transcription.json"
        do {
            try json.write(toFile: tempPath, atomically: true, encoding: .utf8)
            return tempPath
        } catch {
            return json // fallback
        }
    }
}

public class WhisperBridge: NSObject, FlutterPlugin {
    private var whisperContext: OpaquePointer?
    private var isModelLoading = false
    // Serial queue ensures whisperContext is only accessed from one thread at a time,
    // preventing freeModel() from freeing the context while transcription is running.
    private let whisperQueue = DispatchQueue(label: "com.capstudio.whisper", qos: .userInitiated)
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "com.capstudio/whisper",
            binaryMessenger: registrar.messenger()
        )
        let instance = WhisperBridge()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "loadModel":
            guard let args = call.arguments as? [String: Any],
                  let modelPath = args["modelPath"] as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: "modelPath required", details: nil))
                return
            }
            if isModelLoading {
                result(FlutterError(code: "LOAD_IN_PROGRESS", message: "Model load is already in progress", details: nil))
                return
            }
            isModelLoading = true
            loadModel(path: modelPath, result: result)
            
        case "transcribe":
            guard let args = call.arguments as? [String: Any],
                  let wavPath = args["wavPath"] as? String,
                  let language = args["language"] as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: "wavPath and language required", details: nil))
                return
            }
            let threads = (args["threads"] as? Int) ?? 4
            let useVad = (args["useVad"] as? Bool) ?? false
            let vadThreshold = Float((args["vadThreshold"] as? Double) ?? 0.5)
            let translate = (args["translate"] as? Bool) ?? false
            
            transcribe(wavPath: wavPath, language: language, threads: threads,
                       useVad: useVad, vadThreshold: vadThreshold, translate: translate, result: result)
            
        case "freeModel":
            freeModel()
            result(nil)
            
        case "getAvailableThreads":
            let threads = ProcessInfo.processInfo.activeProcessorCount
            result(threads)
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func loadModel(path: String, result: @escaping FlutterResult) {
        whisperQueue.async { [weak self] in
            guard let self = self else { return }
            if self.whisperContext != nil {
                whisper_free(self.whisperContext)
                self.whisperContext = nil
            }
            guard let ctx = WhisperLib.initFromFile(path) else {
                DispatchQueue.main.async {
                    self.isModelLoading = false
                    result(FlutterError(code: "LOAD_FAILED", message: "Failed to load model: \(path)", details: nil))
                }
                return
            }
            self.whisperContext = ctx
            DispatchQueue.main.async {
                self.isModelLoading = false
                result(0)
            }
        }
    }
    
    private func transcribe(
        wavPath: String, language: String, threads: Int,
        useVad: Bool, vadThreshold: Float, translate: Bool, result: @escaping FlutterResult
    ) {
        whisperQueue.async { [weak self] in
            guard let self = self else { return }
            guard let ctx = self.whisperContext else {
                DispatchQueue.main.async {
                    result(FlutterError(code: "NOT_LOADED", message: "Load a model first", details: nil))
                }
                return
            }
            let json = WhisperLib.transcribe(
                ctx: ctx, wavPath: wavPath, language: language,
                threads: threads, useVad: useVad, vadThreshold: vadThreshold, translate: translate
            )
            DispatchQueue.main.async { result(json) }
        }
    }
    
    private func freeModel() {
        whisperQueue.async { [weak self] in
            guard let self = self else { return }
            if self.whisperContext != nil {
                whisper_free(self.whisperContext)
                self.whisperContext = nil
            }
        }
    }
}
