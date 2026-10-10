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
      // Load the vendored WASM core locally (web/vendor/ffmpeg-core.js) so the
      // web app works without a CDN. Always pass an absolute URL to prevent Jerome Wu's
      // webpack bundle from resolving relative URLs against build-time "file:///home/jeromewu/...".
      const localCoreUrl = new URL('vendor/ffmpeg-core.js', window.location.origin).href;
      try {
        const localCore = await fetch(localCoreUrl);
        if (!localCore.ok) {
          throw new Error('Local ffmpeg core returned status ' + localCore.status);
        }
        ffmpegInstance = createFFmpeg({
          log: true,
          corePath: localCoreUrl,
        });
      } catch (e) {
        console.warn('Local ffmpeg core unavailable, falling back to CDN:', e);
        ffmpegInstance = createFFmpeg({
          log: true,
          corePath: 'https://unpkg.com/@ffmpeg/core@0.11.0/dist/ffmpeg-core.js',
        });
      }
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
    // Ensure videoUrl is an absolute URL to avoid Jerome Wu's webpack bundle resolving
    // relative paths to build-time "file:///home/jeromewu/...".
    const absoluteVideoUrl = (videoUrl.startsWith('http://') || videoUrl.startsWith('https://') || videoUrl.startsWith('blob:') || videoUrl.startsWith('data:'))
      ? videoUrl
      : new URL(videoUrl, window.location.origin).href;
    
    let inputBytes;
    try {
      inputBytes = await fetchFile(absoluteVideoUrl);
    } catch (fetchErr) {
      console.warn("fetchFile failed, trying direct fetch:", fetchErr);
      const res = await fetch(absoluteVideoUrl);
      if (!res.ok) {
        throw new Error(`Failed to load video file from ${absoluteVideoUrl} (Status ${res.status})`);
      }
      inputBytes = new Uint8Array(await res.arrayBuffer());
    }
    if (inputBytes.byteLength > 350 * 1024 * 1024) {
      throw new Error("Input video exceeds 350MB browser WebAssembly RAM limit. Please export on desktop for very large files.");
    }
    ffmpegInstance.FS('writeFile', 'input.mp4', inputBytes);
    
    // 2. Mount Fonts and ASS Subtitles Timing Script
    try {
      ffmpegInstance.FS('mkdir', '/fonts');
    } catch (_) {}

    try {
      // Attempt to load standard font into WASM virtual filesystem so libass can render glyphs
      const fontUrl = new URL('assets/assets/fonts/design/Montserrat-Variable.ttf', window.location.origin).href;
      const fontRes = await fetch(fontUrl);
      if (fontRes.ok) {
        const fontBytes = new Uint8Array(await fontRes.arrayBuffer());
        ffmpegInstance.FS('writeFile', '/fonts/default.ttf', fontBytes);
      }
    } catch (fErr) {
      console.warn("Could not preload default font into WASM filesystem:", fErr);
    }

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
      '-vf', 'subtitles=subtitles.ass:fontsdir=/fonts',
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
      const val = 0.25 + ratio * 0.70;
      onProgressCallback(val, `Encoding frame data: ${Math.round(ratio * 100)}%`);
    });
    
    onProgressCallback(0.25, "Rendering video & burning subtitles (client-side)...");
    try {
      await ffmpegInstance.run(...args);
    } catch (primaryRunErr) {
      console.warn("Primary render with fontsdir failed, trying basic subtitles filter:", primaryRunErr);
      // Fallback without fontsdir
      const fallbackArgs = [
        ...(trimStart > 0 || (trimEnd > 0 && trimEnd < duration) ? ['-ss', trimStart.toString(), ...(trimEnd > 0 ? ['-to', trimEnd.toString()] : [])] : []),
        '-i', 'input.mp4',
        '-vf', 'subtitles=subtitles.ass',
        '-c:v', 'libx264',
        '-preset', 'ultrafast',
        '-pix_fmt', 'yuv420p',
        '-c:a', 'aac',
        '-b:a', '128k',
        '-y',
        'output.mp4'
      ];
      await ffmpegInstance.run(...fallbackArgs);
    }
    
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
    
    // Trigger download directly in the browser with error recovery
    try {
      const anchor = document.createElement('a');
      anchor.href = url;
      anchor.download = options.fileName || 'output.mp4';
      document.body.appendChild(anchor);
      anchor.click();
      setTimeout(() => {
        try { document.body.removeChild(anchor); } catch (_) {}
      }, 1000);
    } catch (downloadErr) {
      console.error("Browser download failed:", downloadErr);
      throw new Error(`Browser failed to initiate download: ${downloadErr.message}. Please check browser download permissions.`);
    }
    
    // Revoke object URL after a delay to ensure browser completes handoff
    setTimeout(() => {
      URL.revokeObjectURL(url);
    }, 10000);
    
    return "SUCCESS";
  } catch (error) {
    onProgressCallback(0.0, `Error: ${error.message}`);
    console.error("FFmpeg WASM Export Error: ", error);
    throw error;
  }
}

// Bind to window for direct JS-Interop invocation from Dart
window.exportVideoWeb = exportVideoWeb;
