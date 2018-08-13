#!/usr/bin/env python
"""Simple HTTP Server that concentrates on providing easy control over response codes."""

from http.server import BaseHTTPRequestHandler

import argparse, os, ssl, sys

HOST_NAME = 'localhost'
PORT_NUMBER = 8080
STATUS_CONTENT = {
    '200': 'OK',
    '201': 'CREATED',
    '202': 'ACCEPTED',
    '204': 'NO_CONTENT',
    '400': 'BAD_REQUEST',
    '404': 'NOT_FOUND',
    '418': "I'm a Teapot",
    '501': 'NOT_IMPLEMENTED'
}


class Server(BaseHTTPRequestHandler):
    def do_HEAD(self):
        return

    def do_GET(self):
        self.respond()

    def do_POST(self):
        self.respond()

    def handle_http(self, status=200, content_type='text/html'):
        if status != 200:
            content_type = 'text/plain'
            content = bytes(STATUS_CONTENT[str(status)], "UTF-8")
        else:
            if self.command == 'POST':
                status = 202
            content = bytes(
                "Hello %s, I received:\n  %s" % (self.address_string(),
                                                 self.requestline), "UTF-8")
        self.send_response(status)
        self.send_header('Content-type', content_type)
        self.end_headers()
        return content

    def respond(self):
        content = self.handle_http(status=CONFIG['code'])
        self.wfile.write(content)


def main(args):
    server_address = (HOST_NAME, PORT_NUMBER)
    try:
        # needs Python 3.7+
        from http.server import ThreadingHTTPServer
        httpd = ThreadingHTTPServer(server_address, Server)
    except:
        from http.server import HTTPServer
        httpd = HTTPServer(server_address, Server)

    if CONFIG.get('tls') is not None:
        httpd.socket = ssl.wrap_socket(
            httpd.socket, keyfile=CONFIG['key'], certfile=CONFIG['cert'], server_side=True)
    httpd.serve_forever()


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "-r",
        "--responsecode",
        type=int,
        help='Default HTTP Response Code',
        default=200)
    parser.add_argument("-c", "--cert", help='path to TLS Certificate file')
    parser.add_argument("-k", "--keyfile", help='path to TLS Private Key file')
    args = parser.parse_args()
    global CONFIG
    CONFIG = {}
    CONFIG['key'] = args.keyfile
    CONFIG['cert'] = args.cert
    if args.cert is not None or args.keyfile is not None:
        try:
            CONFIG['tls'] = os.path.exists(CONFIG['cert']) and os.path.exists(CONFIG['key'])
            assert CONFIG['tls'] is not False
        except:
            raise RuntimeError('You must supply files for a key AND a certificate, if either')
    CONFIG['code'] = args.responsecode
    sys.exit(main(args))