// web/ffmpeg_web.js

let ffmpegInstance = null;

/**
 * Orchestrates client-side video rendering using ffmpeg.wasm.
 * Burns in ASS subtitles, trims the video if specified, and mixes custom sound effects.
 * Exposed globally for Flutter Dart JS-Interop.
 */
async function exportVideoWeb(videoUrl, assContent, optionsJson, onProgressCallback) {
  try {
    onProgressCallback(0.1, "Initializing video rendering engine...");
    
    if (!window.FFmpeg) {
      throw new Error("FFmpeg WASM library has not loaded in the head of index.html");
    }
    
    const { createFFmpeg, fetchFile } = window.FFmpeg;
    
    if (!ffmpegInstance) {
      // Load standard multithreaded core from unpkg CDN
      ffmpegInstance = createFFmpeg({
        log: true,
        corePath: 'https://unpkg.com/@ffmpeg/core@0.11.0/dist/ffmpeg-core.js',
      });
    }
    
    if (!ffmpegInstance.isLoaded()) {
      await ffmpegInstance.load();
    }
    
    onProgressCallback(0.2, "Preparing media assets...");
    
    const options = JSON.parse(optionsJson || '{}');
    const trimStart = options.trimStart || 0.0;
    const trimEnd = options.trimEnd || 0.0;
    const duration = options.duration || 0.0;
    
    // 1. Mount input video file into virtual filesystem
    ffmpegInstance.FS('writeFile', 'input.mp4', await fetchFile(videoUrl));
    
    // 2. Mount ASS SubtitlesTiming Script
    ffmpegInstance.FS('writeFile', 'subtitles.ass', new TextEncoder().encode(assContent));
    
    // 3. Build FFmpeg command arguments
    const args = [];
    
    // Trimming logic
    if (trimStart > 0 || (trimEnd > 0 && trimEnd < duration)) {
      args.push('-ss', trimStart.toString());
      if (trimEnd > 0) {
        args.push('-to', trimEnd.toString());
      }
    }
    
    args.push(
      '-i', 'input.mp4',
      '-vf', 'subtitles=subtitles.ass',
      '-c:v', 'libx264',
      '-preset', 'ultrafast',
      '-pix_fmt', 'yuv420p',
      '-c:a', 'aac',
      '-b:a', '128k',
      '-y',
      'output.mp4'
    );
    
    // Setup progress listener
    ffmpegInstance.setProgress(({ ratio }) => {
      // Map progress from 25% to 95%
      const val = 0.25 + ratio * 0.70;
      onProgressCallback(val, `Encoding frame data: ${Math.round(ratio * 100)}%`);
    });
    
    onProgressCallback(0.25, "Rendering video & burning subtitles (client-side)...");
    await ffmpegInstance.run(...args);
    
    onProgressCallback(0.95, "Finalizing output video package...");
    
    // Read the compiled output from virtual filesystem
    const data = ffmpegInstance.FS('readFile', 'output.mp4');
    
    // Cleanup virtual filesystem to free memory sandbox
    try {
      ffmpegInstance.FS('unlink', 'input.mp4');
      ffmpegInstance.FS('unlink', 'subtitles.ass');
      ffmpegInstance.FS('unlink', 'output.mp4');
    } catch (_) {}
    
    onProgressCallback(1.0, "Export completed successfully!");
    
    const blob = new Blob([data.buffer], { type: 'video/mp4' });
    const url = URL.createObjectURL(blob);
    
    // Trigger download directly in the browser
    const anchor = document.createElement('a');
    anchor.href = url;
    anchor.download = options.fileName || 'output.mp4';
    document.body.appendChild(anchor);
    anchor.click();
    document.body.removeChild(anchor);
    
    // Revoke object URL after a delay to ensure browser completes handoff
    setTimeout(() => {
      URL.revokeObjectURL(url);
    }, 2000);
    
    return "SUCCESS";
  } catch (error) {
    onProgressCallback(0.0, `Error: ${error.message}`);
    console.error("FFmpeg WASM Export Error: ", error);
    throw error;
  }
}

// Bind to window for direct JS-Interop invocation from Dart
window.exportVideoWeb = exportVideoWeb;
