#!/usr/bin/env python
"""Simple HTTP Server that concentrates on providing easy control over response codes."""

import argparse, json, os, random, ssl, sys, time
from http.server import BaseHTTPRequestHandler

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
            content = bytes(STATUS_CONTENT.get(str(status), "NOT_IMPLEMENTED"), "UTF-8")
        else:
            if self.command == 'POST':
                status = 202
            if self.requestline.startswith('GET /healthcheck'):
                content_type = 'application/json'
                content = bytes(json.dumps("alive"), "UTF-8")
            else:
                content = bytes(
                    "Hello %s, at %s I received:\n\n  %s" % (self.address_string(),
                                                     time.strftime("%c"),
                                                     self.requestline), "UTF-8")
        self.send_response(status)
        self.send_header('Content-type', content_type)
        self.end_headers()
        return content

    def respond(self):
        status = CONFIG['responsecode']
        if CONFIG['success'] < 100:
            if CONFIG['success'] < random.uniform(1, 100):
                status = random.choice([400, 404, 418, 501])
        content = self.handle_http(status=status)
        if CONFIG['delay'] != 0:
            delay = random.uniform(0, CONFIG['delay'])
            print('Delaying %d ms' % delay)
            time.sleep(delay * 0.001)
        self.wfile.write(content)


def main():
    server_address = (CONFIG.get('host'), CONFIG.get('port'))
    if sys.version_info >= (3,7):
        # needs Python 3.7+
        from http.server import ThreadingHTTPServer
        httpd = ThreadingHTTPServer(server_address, Server)
    else:
        from http.server import HTTPServer
        httpd = HTTPServer(server_address, Server)

    if CONFIG.get('tls') is not None:
        httpd.socket = ssl.wrap_socket(
            httpd.socket,
            keyfile=CONFIG['key'],
            certfile=CONFIG['cert'],
            server_side=True)
    try:
        print('Server started at %s:%s' % server_address)
        httpd.serve_forever()
    except KeyboardInterrupt:
        print('KeyboardInterrupt, shutting down.')
        httpd.server_close()


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--host", help='Interface', default=HOST_NAME)
    parser.add_argument(
        "--port", type=int, help='TCP port', default=PORT_NUMBER)
    parser.add_argument(
        "--delay", type=int, help='random delay, milliseconds', default=0)
    parser.add_argument(
        "-s",
        "--success",
        type=int,
        help='Desired chance of a successful response as a percentage',
        default=100)
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
    CONFIG['responsecode'] = args.responsecode
    CONFIG['success'] = args.success
    CONFIG['delay'] = args.delay
    CONFIG['key'] = args.keyfile
    CONFIG['cert'] = args.cert
    CONFIG['host'] = args.host
    CONFIG['port'] = args.port
    if args.cert is not None or args.keyfile is not None:
        try:
            CONFIG['tls'] = os.path.exists(CONFIG['cert']) and os.path.exists(
                CONFIG['key'])
            assert CONFIG['tls'] is not False
        except Exception as e:
            raise RuntimeError(
                'You must supply files for a key AND a certificate, if either')
    CONFIG['code'] = args.responsecode
    sys.exit(main())
