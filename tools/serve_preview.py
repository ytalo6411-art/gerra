#!/usr/bin/env python3
"""Serve only the built Web export; works for nested preview hosts without CORS."""
from argparse import ArgumentParser
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
import os
from urllib.parse import urlsplit


class PreviewHandler(SimpleHTTPRequestHandler):
    extensions_map = {**SimpleHTTPRequestHandler.extensions_map, ".wasm": "application/wasm"}

    def send_head(self):
        path = Path(self.translate_path(urlsplit(self.path).path))
        compressed = path.with_suffix(".wasm.gz")
        if path.suffix == ".wasm" and "gzip" in self.headers.get("Accept-Encoding", "") and compressed.is_file():
            file = compressed.open("rb")
            self.send_response(200)
            self.send_header("Content-Type", "application/wasm")
            self.send_header("Content-Encoding", "gzip")
            self.send_header("Content-Length", str(os.fstat(file.fileno()).st_size))
            self.send_header("Vary", "Accept-Encoding")
            self.end_headers()
            return file
        return super().send_head()


def main():
    root = Path(__file__).resolve().parents[1]
    parser = ArgumentParser(description=__doc__)
    parser.add_argument("--port", type=int, default=4173)
    parser.add_argument("--directory", type=Path, default=root / "build/web")
    args = parser.parse_args()
    if not (args.directory / "index.html").is_file():
        parser.error("Exporte o preset Web para build/web/index.html antes de servir.")
    handler = partial(PreviewHandler, directory=str(args.directory))
    with ThreadingHTTPServer(("0.0.0.0", args.port), handler) as server:
        print(f"Vale do Cedro · HTTP :{args.port}", flush=True)
        server.serve_forever()


if __name__ == "__main__":
    main()
