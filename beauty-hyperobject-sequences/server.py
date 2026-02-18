#!/usr/bin/env python3
"""Beauty Hyperobject Sequences - Server

A minimal HTTP server that serves the web app and proxies OEIS API requests
to avoid CORS issues. Run with: python3 server.py

No external dependencies required.
"""

import http.server
import json
import os
import re
import urllib.request
import urllib.parse
import urllib.error
import hashlib
import time
import mimetypes
from pathlib import Path

PORT = 8071
CACHE_DIR = Path(__file__).parent / '.cache'
OEIS_BASE = 'https://oeis.org'

# Ensure JS modules get correct MIME type
mimetypes.add_type('application/javascript', '.js')
mimetypes.add_type('text/css', '.css')


class BeautyHandler(http.server.SimpleHTTPRequestHandler):

    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(Path(__file__).parent), **kwargs)

    def do_GET(self):
        parsed = urllib.parse.urlparse(self.path)
        path = parsed.path
        query = urllib.parse.parse_qs(parsed.query)

        if path == '/api/search':
            self.handle_search(query)
        elif path.startswith('/api/sequence/'):
            seq_id = path.split('/')[-1].upper()
            self.handle_sequence(seq_id)
        elif path.startswith('/api/bfile/'):
            seq_id = path.split('/')[-1].upper()
            self.handle_bfile(seq_id, query)
        else:
            super().do_GET()

    def handle_search(self, query):
        q = query.get('q', [''])[0]
        start = query.get('start', ['0'])[0]
        if not q:
            self.send_json({'error': 'Missing query parameter q'}, 400)
            return

        url = f'{OEIS_BASE}/search?fmt=json&q={urllib.parse.quote(q)}&start={start}'
        data = self.cached_fetch(url)
        if data is None:
            self.send_json({'error': 'Failed to fetch from OEIS'}, 502)
            return
        try:
            parsed = json.loads(data)
            # OEIS returns literal null for no-result searches; normalize it
            if parsed is None:
                parsed = {'results': [], 'count': 0}
            self.send_json(parsed)
        except json.JSONDecodeError:
            self.send_json({'error': 'Invalid JSON from OEIS', 'raw': data[:500]}, 502)

    def handle_sequence(self, seq_id):
        if not re.match(r'^A\d{6}$', seq_id):
            self.send_json({'error': f'Invalid sequence ID: {seq_id}'}, 400)
            return

        url = f'{OEIS_BASE}/search?fmt=json&q=id:{seq_id}'
        data = self.cached_fetch(url)
        if data is None:
            self.send_json({'error': 'Failed to fetch from OEIS'}, 502)
            return
        try:
            parsed = json.loads(data)
            if parsed is None:
                parsed = {'results': [], 'count': 0}
            self.send_json(parsed)
        except json.JSONDecodeError:
            self.send_json({'error': 'Invalid JSON from OEIS'}, 502)

    def handle_bfile(self, seq_id, query):
        if not re.match(r'^A\d{6}$', seq_id):
            self.send_json({'error': f'Invalid sequence ID: {seq_id}'}, 400)
            return

        n = min(int(query.get('n', ['1000'])[0]), 10000)
        digits = seq_id[1:]
        url = f'{OEIS_BASE}/{seq_id}/b{digits}.txt'
        data = self.cached_fetch(url, max_age=86400)  # cache b-files for 24h
        if data is None:
            self.send_json({'error': 'Failed to fetch b-file'}, 502)
            return

        terms = []
        indices = []
        for line in data.split('\n'):
            line = line.strip()
            if not line or line.startswith('#'):
                continue
            parts = line.split()
            if len(parts) >= 2:
                try:
                    indices.append(int(parts[0]))
                    terms.append(int(parts[1]))
                except ValueError:
                    continue
            if len(terms) >= n:
                break

        self.send_json({
            'id': seq_id,
            'terms': terms[:n],
            'offset': indices[0] if indices else 0,
            'count': len(terms[:n])
        })

    def cached_fetch(self, url, max_age=3600):
        CACHE_DIR.mkdir(exist_ok=True)
        key = hashlib.md5(url.encode()).hexdigest()
        cache_file = CACHE_DIR / f'{key}.dat'

        if cache_file.exists():
            age = time.time() - cache_file.stat().st_mtime
            if age < max_age:
                return cache_file.read_text(encoding='utf-8', errors='replace')

        for attempt in range(3):
            try:
                req = urllib.request.Request(url, headers={
                    'User-Agent': 'BeautyHyperobjectSequences/1.0 (mathematical-beauty-research)'
                })
                with urllib.request.urlopen(req, timeout=30) as resp:
                    data = resp.read().decode('utf-8', errors='replace')
                    cache_file.write_text(data, encoding='utf-8')
                    return data
            except Exception as e:
                print(f'  Fetch attempt {attempt+1} failed for {url}: {e}')
                if attempt < 2:
                    time.sleep(2 ** attempt)

        # Return stale cache if available
        if cache_file.exists():
            return cache_file.read_text(encoding='utf-8', errors='replace')
        return None

    def send_json(self, data, status=200):
        body = json.dumps(data, ensure_ascii=False).encode('utf-8')
        self.send_response(status)
        self.send_header('Content-Type', 'application/json; charset=utf-8')
        self.send_header('Content-Length', len(body))
        self.send_header('Access-Control-Allow-Origin', '*')
        self.end_headers()
        self.wfile.write(body)

    def end_headers(self):
        self.send_header('Cache-Control', 'no-cache')
        super().end_headers()

    def log_message(self, format, *args):
        if '/api/' in str(args[0]) if args else False:
            super().log_message(format, *args)


if __name__ == '__main__':
    os.chdir(str(Path(__file__).parent))
    print()
    print('  ' + '=' * 48)
    print('  |  Beauty Hyperobject Sequences              |')
    print('  |  mathematical beauty as living interface    |')
    print('  ' + '=' * 48)
    print(f'  Listening on http://localhost:{PORT}')
    print('  Press Ctrl+C to stop')
    print()

    with http.server.HTTPServer(('', PORT), BeautyHandler) as httpd:
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print('\n  Shutting down gracefully...')
