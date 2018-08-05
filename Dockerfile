FROM ubuntu:bionic
MAINTAINER Jonathan Hanson "jonathan@jonathan-hanson.org"

# Install the tools we'll need
RUN apt-get update && apt-get install -y \
        openssl \
        tree \
        vim \
    && rm -rf /var/lib/apt/lists/*

# Prepare the CA certificate workspace
RUN mkdir -p -m 755 \
        /root/ca/certs \
        /root/ca/crl \
        /root/ca/newcerts \
    && mkdir -p -m 700 \
        /root/ca/private \
    && touch /root/ca/index.txt \
    && echo 1000 > /root/ca/serial

COPY ca_openssl.cnf /root/ca/ca_openssl.cnf

# Prepare the intermediate certificate workspace
RUN mkdir -p -m 755 \
        /root/ca/intermediate/certs \
        /root/ca/intermediate/crl \
        /root/ca/intermediate/csr \
        /root/ca/intermediate/newcerts \
    && mkdir -p -m 700 \
        /root/ca/intermediate/private \
    && touch /root/ca/intermediate/index.txt \
    && echo 1000 > /root/ca/intermediate/serial \
    && echo 1000 > /root/ca/intermediate/crlnumber

COPY int_openssl.cnf /root/ca/intermediate/int_openssl.cnf

# A quick helper script
COPY archive_ca /usr/local/bin/archive_ca
RUN chmod 755 /usr/local/bin/archive_ca

# For convenience, make sure the bash shell
# starts in the /root/ca directory
COPY entrypoint.sh /entrypoint.sh
RUN chmod 755 /entrypoint.sh

VOLUME /root/ca_persist

ENTRYPOINT ["/entrypoint.sh"]
CMD ["bash"]
