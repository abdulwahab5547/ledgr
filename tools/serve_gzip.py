#!/usr/bin/env python3
"""Static-file server with on-the-fly gzip compression.

Drop-in replacement for `python3 -m http.server`. Serves text-y assets
(`.js`, `.html`, `.css`, `.json`, `.wasm`, `.svg`, `.map`) gzipped when the
client's `Accept-Encoding` header includes `gzip`. Cuts Flutter web's
~3.5 MB `main.dart.js` to roughly 1 MB on the wire.

Usage:
    cd build/web && python3 ../../tools/serve_gzip.py 8765
"""

from __future__ import annotations

import gzip
import http.server
import io
import os
import socketserver
import sys

GZIP_TYPES = {
    '.js',
    '.mjs',
    '.html',
    '.css',
    '.json',
    '.svg',
    '.wasm',
    '.map',
    '.ttf',
    '.otf',
}


class GzipHandler(http.server.SimpleHTTPRequestHandler):
    def send_head(self):  # noqa: D401 — overriding stdlib API
        path = self.translate_path(self.path)

        # Directory? Defer to the parent (which generates a listing).
        if os.path.isdir(path):
            return super().send_head()

        if not os.path.exists(path):
            self.send_error(404, 'Not found')
            return None

        try:
            with open(path, 'rb') as f:
                content = f.read()
        except OSError:
            self.send_error(404, 'Not found')
            return None

        ext = os.path.splitext(path)[1].lower()
        accept_enc = self.headers.get('Accept-Encoding', '')
        gzip_ok = ext in GZIP_TYPES and 'gzip' in accept_enc

        if gzip_ok:
            content = gzip.compress(content, compresslevel=6)

        self.send_response(200)
        self.send_header('Content-Type', self.guess_type(path))
        self.send_header('Content-Length', str(len(content)))
        if gzip_ok:
            self.send_header('Content-Encoding', 'gzip')
            self.send_header('Vary', 'Accept-Encoding')
        # During development we want hot rebuilds to land immediately.
        self.send_header('Cache-Control', 'no-store')
        self.end_headers()
        return io.BytesIO(content)


class _Server(socketserver.ThreadingTCPServer):
    # Set BEFORE bind() so SO_REUSEADDR takes effect on the listening socket.
    allow_reuse_address = True
    daemon_threads = True


def main(argv: list[str]) -> int:
    port = int(argv[1]) if len(argv) > 1 else 8765
    bind = '0.0.0.0'
    with _Server((bind, port), GzipHandler) as httpd:
        print(f'serve_gzip.py listening on http://{bind}:{port}')
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            pass
    return 0


if __name__ == '__main__':
    raise SystemExit(main(sys.argv))
