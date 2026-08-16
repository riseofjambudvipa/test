// web/whisper_web.js

let whisperPipeline = null;

/**
 * Extracts and resamples the audio track from a video Blob URL to 16kHz mono Float32Array PCM.
 */
async function extractAudioBuffer(videoUrl) {
  const response = await fetch(videoUrl);
  const arrayBuffer = await response.arrayBuffer();
  
  // Use browser AudioContext to decode
  const AudioContextClass = window.AudioContext || window.webkitAudioContext;
  const audioCtx = new AudioContextClass();
  const audioBuffer = await audioCtx.decodeAudioData(arrayBuffer);
  
  // Downsample to 16000 Hz Mono for Whisper
  const targetSampleRate = 16000;
  const OfflineAudioContextClass = window.OfflineAudioContext || window.webkitOfflineAudioContext;
  const offlineCtx = new OfflineAudioContextClass(
    1, 
    Math.ceil(audioBuffer.duration * targetSampleRate), 
    targetSampleRate
  );
  
  const bufferSource = offlineCtx.createBufferSource();
  bufferSource.buffer = audioBuffer;
  bufferSource.connect(offlineCtx.destination);
  bufferSource.start();
  
  const resampled = await offlineCtx.startRendering();
  audioCtx.close();
  
  return resampled.getChannelData(0);
}

/**
 * Runs client-side automatic speech recognition using transformers.js
 * Exposed globally for Flutter Dart JS-Interop.
 */
async function transcribeWeb(videoUrl, modelName, language, translate, onProgressCallback) {
  try {
    onProgressCallback(0.1, "Extracting audio track from video...");
    const audioData = await extractAudioBuffer(videoUrl);
    
    onProgressCallback(0.3, `Configuring Whisper engine (${modelName})...`);
    
    // Ensure ONNX environment is ready
    if (!window.pipeline || !window.transformersEnv) {
      throw new Error("Hugging Face transformers.js library has not loaded in the head of index.html");
    }
    
    window.transformersEnv.allowLocalModels = false;
    
    if (!whisperPipeline) {
      whisperPipeline = await window.pipeline('automatic-speech-recognition', `Xenova/whisper-${modelName}`, {
        progress_callback: (data) => {
          if (data.status === 'progress') {
            // Map download progress to 30%-70% progress range
            const pct = data.progress || 0;
            const progressVal = 0.3 + (pct / 100) * 0.4;
            const fileName = data.file ? data.file.substring(data.file.lastIndexOf('/') + 1) : '';
            onProgressCallback(progressVal, `Loading model weights: ${fileName} (${Math.round(pct)}%)`);
          } else if (data.status === 'ready') {
            onProgressCallback(0.7, "Speech-to-text engine initialized.");
          }
        }
      });
    }
    
    onProgressCallback(0.75, "Analyzing speech pattern (transcribing)...");
    
    const task = translate ? 'translate' : 'transcribe';
    const langCode = (language === 'auto' || !language) ? null : language;
    
    const result = await whisperPipeline(audioData, {
      chunk_length_s: 30,
      stride_length_s: 5,
      language: langCode,
      task: task,
      return_timestamps: 'word',
    });
    
    onProgressCallback(0.95, "Formatting timing results...");
    
    // Convert transformers.js chunks into the exact JSON segments format expected by WhisperService
    const segments = [];
    if (result.chunks && result.chunks.length > 0) {
      for (let i = 0; i < result.chunks.length; i++) {
        const chunk = result.chunks[i];
        const words = [];
        
        if (chunk.words && chunk.words.length > 0) {
          for (let j = 0; j < chunk.words.length; j++) {
            const w = chunk.words[j];
            words.push({
              word: w.text,
              start: (w.timestamp && (w.timestamp[0] || w.timestamp[0] === 0)) ? w.timestamp[0] : 0.0,
              end: (w.timestamp && (w.timestamp[1] || w.timestamp[1] === 0)) ? w.timestamp[1] : 0.0,
              confidence: w.confidence || 0.95
            });
          }
        } else {
          // Fallback if token/word timings are missing in chunk
          words.push({
            word: chunk.text,
            start: (chunk.timestamp && chunk.timestamp[0]) ? chunk.timestamp[0] : 0.0,
            end: (chunk.timestamp && chunk.timestamp[1]) ? chunk.timestamp[1] : 0.0,
            confidence: 0.95
          });
        }
        
        segments.push({
          text: chunk.text,
          timestamps: {
            from: Math.round(((chunk.timestamp && chunk.timestamp[0]) ? chunk.timestamp[0] : 0.0) * 1000),
            to: Math.round(((chunk.timestamp && chunk.timestamp[1]) ? chunk.timestamp[1] : 0.0) * 1000)
          },
          words: words
        });
      }
    }
    
    onProgressCallback(1.0, "Transcription completed successfully!");
    
    const outputJson = {
      language: result.language || langCode || 'en',
      transcription: segments
    };
    
    return JSON.stringify(outputJson);
  } catch (error) {
    onProgressCallback(0.0, `Error: ${error.message}`);
    console.error("Whisper WASM Transcription Error: ", error);
    throw error;
  }
}

// Bind to window for direct JS-Interop invocation from Dart
window.transcribeWeb = transcribeWeb;
