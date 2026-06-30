#!/usr/bin/env python3

from http.server import BaseHTTPRequestHandler, HTTPServer
import os


HOST = "0.0.0.0"
PORT = int(os.environ.get("PORT", "443"))
MESSAGE = os.environ.get("MESSAGE", "XPTO Server funcionando!")


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        body = f"{MESSAGE}\nPath: {self.path}\n"

        self.send_response(200)
        self.send_header("Content-Type", "text/plain; charset=utf-8")
        self.send_header("Content-Length", str(len(body.encode("utf-8"))))
        self.end_headers()
        self.wfile.write(body.encode("utf-8"))

    def log_message(self, fmt, *args):
        print(f"[http] {self.address_string()} - {fmt % args}", flush=True)


if __name__ == "__main__":
    print(f"[xpto-server] ouvindo em {HOST}:{PORT}", flush=True)
    HTTPServer((HOST, PORT), Handler).serve_forever()
