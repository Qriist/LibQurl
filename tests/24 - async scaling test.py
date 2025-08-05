import os
from http.server import ThreadingHTTPServer, BaseHTTPRequestHandler

# Path to the file you want to serve
FILE_PATH = 'testfile.bin'

# Chunk size to stream (bytes)
CHUNK_SIZE = 64 * 1024  # 64 KB


class FileServerHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path != '/file':
            self.send_error(404, "Only /file is available")
            return

        if not os.path.exists(FILE_PATH):
            self.send_error(500, f"{FILE_PATH} not found")
            return

        file_size = os.path.getsize(FILE_PATH)
        self.send_response(200)
        self.send_header('Content-Type', 'application/octet-stream')
        self.send_header('Content-Length', str(file_size))
        self.end_headers()

        with open(FILE_PATH, 'rb') as f:
            while True:
                chunk = f.read(CHUNK_SIZE)
                if not chunk:
                    break
                self.wfile.write(chunk)

    def log_message(self, format, *args):
        pass  # Silence logs


if __name__ == '__main__':
    from sys import argv

    # Generate dummy file if not present
    if not os.path.exists(FILE_PATH):
        print(f"Creating {FILE_PATH}...")
        with open(FILE_PATH, 'wb') as f:
            f.write(os.urandom(10 * 1024 * 1024))  # 10 MB

    port = int(argv[1]) if len(argv) > 1 else 8000
    server = ThreadingHTTPServer(('', port), FileServerHandler)
    print(f"Serving '{FILE_PATH}' on http://localhost:{port}/file")
    server.serve_forever()
