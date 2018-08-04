FROM ubuntu:bionic
MAINTAINER Jonathan Hanson "jonathan@jonathan-hanson.org"

RUN apt-get update && apt-get install -y \
    openssl \
 && rm -rf /var/lib/apt/lists/*

CMD ["bash"]
