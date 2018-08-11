FROM ubuntu:bionic
MAINTAINER Jonathan Hanson "jonathan@jonathan-hanson.org"

# The path on the container where CA archives are written and read
ENV CA_ARCHIVE_DIR /root/ca_persist

# Establish the mount point for the CA archive directory
VOLUME ["$CA_ARCHIVE_DIR"]

# Install the tools we'll need
RUN apt-get update && apt-get install -y \
        openssl \
        tree \
        vim \
    && rm -rf /var/lib/apt/lists/*

# Copy over the stock prepared OpenSSL config files
# Note that these will only be used if the archives don't have their own copies
COPY conf/ca_root_openssl.cnf /opt/ca/ca_openssl.cnf
COPY conf/ca_intermediate_openssl.cnf /opt/ca/int_openssl.cnf

# A quick helper script for generating archives
COPY scripts/archive_ca /usr/local/bin/archive_ca
RUN chmod 755 /usr/local/bin/archive_ca

# The script to execute as soon as the container is created
COPY scripts/entrypoint.sh /entrypoint.sh
RUN chmod 755 /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["bash"]
