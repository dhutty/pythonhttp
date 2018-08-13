FROM python:3.7
LABEL maintainer="Duncan Hutty <dhutty@allgoodbits.org>"

ADD . /code
WORKDIR /code

EXPOSE 8080
CMD ["python", "/code/pythonhttpserver.py"]
