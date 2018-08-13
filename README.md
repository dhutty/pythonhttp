A little demo code that shows how easy it is to create a simple, but useful custom webserver in Python.

I wrote this originally for someone in a chat who wanted to return a specific HTTP response code to every request and am
publishing only because I've written code that looks much like this at least once before, so this will make it faster if
I need something like it again.

* Subclasses BaseHTTPRequestHandler
* Threaded, if python3.7+
* Hand it an SSL cert and a private key, you have SSL support
* Containerized

        docker build -t pythonhttp .
        docker run --rm -P pythonhttp -- --responsecode 204

Note that I do not consider this to be production quality code or suitable for purposes in any way serious. This is for demonstration purposes only.
