import http.server
import os
import sys

DEFAULT_PORT = 8080
DIRECTORY = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..', 'build', 'web'))

class DualHeaderHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)

    def end_headers(self):
        self.send_header('Cross-Origin-Opener-Policy', 'same-origin')
        self.send_header('Cross-Origin-Embedder-Policy', 'require-corp')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Cache-Control', 'no-cache')
        super().end_headers()

    def guess_type(self, path):
        if path.endswith('.wasm'):
            return 'application/wasm'
        if path.endswith('.js') or path.endswith('.mjs'):
            return 'text/javascript'
        return super().guess_type(path)

    def translate_path(self, path):
        resolved = super().translate_path(path)
        if not os.path.exists(resolved):
            # Flutter Web assets can be referenced as /assets/xyz or /assets/assets/xyz
            if '/assets/' in path and '/assets/assets/' not in path:
                alt_path = path.replace('/assets/', '/assets/assets/', 1)
                alt_resolved = super().translate_path(alt_path)
                if os.path.exists(alt_resolved):
                    return alt_resolved
        return resolved

    def do_POST(self):
        if self.path == '/save_snapshot':
            content_length = int(self.headers.get('Content-Length', 0))
            body = self.rfile.read(content_length).decode('utf-8')
            if ',' in body:
                body = body.split(',', 1)[1]
            import base64
            img_bytes = base64.b64decode(body)
            out_path = r'C:\Users\Sharansh\.gemini\antigravity\brain\e8e40e21-2a2c-4a6b-96bb-7f4fd50b4e21\editor_live_snapshot.png'
            with open(out_path, 'wb') as f:
                f.write(img_bytes)
            self.send_response(200)
            self.send_header('Content-Type', 'text/plain')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            self.wfile.write(f'Saved {len(img_bytes)} bytes'.encode('utf-8'))
            return
        self.send_response(404)
        self.end_headers()

    def log_message(self, format, *args):
        try:
            message = format % args if args else format
        except Exception:
            message = ' '.join(str(a) for a in args) if args else format
        sys.stdout.write(f"[{self.log_date_time_string()}] {message}\n")
        sys.stdout.flush()

def find_available_port(start_port=8080, max_attempts=10):
    import socket
    for p in range(start_port, start_port + max_attempts):
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            if s.connect_ex(('127.0.0.1', p)) != 0:
                return p
    return start_port

if __name__ == '__main__':
    port = int(sys.argv[1]) if len(sys.argv) > 1 else find_available_port(DEFAULT_PORT)
    server_address = ("127.0.0.1", port)
    
    # Threading server allows handling multiple browser asset requests simultaneously
    httpd = http.server.ThreadingHTTPServer(server_address, DualHeaderHandler)
    httpd.daemon_threads = True
    print(f"CapStudio Web Dev Server running at http://127.0.0.1:{port}")
    print(f"Serving directory: {DIRECTORY}")
    print("COOP/COEP headers enabled for full WebAssembly and SharedArrayBuffer testing.")
    sys.stdout.flush()
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nShutting down server.")
        httpd.server_close()
