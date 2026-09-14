"""Static file server for Onwards.

Takes its port from the PORT environment variable so the harness can assign
one, falling back to 8830 when run by hand.
"""
import http.server
import os
import socketserver

PORT = int(os.environ.get("PORT") or 8830)


class Handler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        # always serve the freshest edit
        self.send_header("Cache-Control", "no-store")
        super().end_headers()


socketserver.TCPServer.allow_reuse_address = True

with socketserver.TCPServer(("127.0.0.1", PORT), Handler) as httpd:
    print("Onwards serving on http://127.0.0.1:%d" % PORT, flush=True)
    httpd.serve_forever()
