{
  python3,
  writeScriptBin,
}:
writeScriptBin "bad-python-server" ''
  #!${python3}/bin/python

  # Python 3 server example
  from http.server import BaseHTTPRequestHandler, HTTPServer
  import time

  hostName = "localhost"
  serverPort = 8080

  class MyServer(BaseHTTPRequestHandler):
      def do_GET(self):
          self.send_response(200)
          self.send_header("Content-type", "text/html")
          self.end_headers()
          self.wfile.write(bytes("<p>Request: %s</p>" % self.path, "utf-8"))

          if self.path == "/hang":
            while True:
              print("Thinking very hard ...")
              time.sleep(10)

  if __name__ == "__main__":
      webServer = HTTPServer((hostName, serverPort), MyServer)
      print("Server started http://%s:%s" % (hostName, serverPort))

      try:
          webServer.serve_forever()
      except KeyboardInterrupt:
          pass

      webServer.server_close()
      print("Server stopped.")
''
