FROM python:3.7-alpine3.8
LABEL maintainer="Duncan Hutty <dhutty@allgoodbits.org>"

ADD . /code
WORKDIR /code

EXPOSE 8080
ENTRYPOINT ["python", "/code/pythonhttpserver.py", "--host", "0.0.0.0"]
