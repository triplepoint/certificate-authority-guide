---
title: Generating a new Certificate Authority
layout: default
---

# Generating a CA Certificate and an Intermediate Certificate
A pre-configured `ca_openssl.cnf` file is provided, but it's worth reviewing it and the associated man pages (see the References section below), to understand the details of what's happening.

## Generate a New Key for the CA Certificate
You'll want to use a real non-empty password for this certificate and store it in a safe place, just in case the key file itself is ever compromised.
``` shell
openssl genrsa -aes256 -out /root/ca/private/ca.key.pem 4096 && \
chmod 400 /root/ca/private/ca.key.pem
```
This generates the new CA certificate key at `/root/ca/private/ca.key.pem`.

## Generate the CA Certificate
``` shell
openssl req -config /root/ca/ca_openssl.cnf \
    -key /root/ca/private/ca.key.pem \
    -new -x509 -days 7300 -sha256 -extensions v3_ca \
    -out /root/ca/certs/ca.cert.pem && \
chmod 444 certs/ca.cert.pem
```
This generates the new CA certificate at `/root/ca/certs/ca.cert.pem`.

When you are prompted for the CA Certificate Distinguished Name details, take care to get them right.  You won't want to regenerate this CA cert later.

Once complete, you can verify the certificate's configuration with:
``` shell
openssl x509 -noout -text -in /root/ca/certs/ca.cert.pem
```

## Generate a New Key for the Intermediate Certificate
Just like we did for the CA certificate above:
``` shell
openssl genrsa -aes256 -out /root/ca/intermediate/private/intermediate.key.pem 4096 && \
chmod 400 /root/ca/intermediate/private/intermediate.key.pem
```
This generates the new intermediate certificate key at: `/root/ca/intermediate/private/intermediate.key.pem`.

## Generate a Certificate Signing Request (CSR) for the Intermediate Certificate
This document represents a request to the root CA to generate the intermediate certificate.

Note that the `Country Name`, `State or Province Name`, and `Organization Name` all have to match the values of the CA certificate.

Also note that the Common Name used in this CSR _must_ be distinct from the CA certificate's Common Name, used above.

``` shell
openssl req -config /root/ca/intermediate/int_openssl.cnf \
    -key /root/ca/intermediate/private/intermediate.key.pem \
    -new -sha256 \
    -out /root/ca/intermediate/csr/intermediate.csr.pem
```

## Sign the Intermediate Certificate with the CA Certificate
Answer `y` to any prompts about "commiting", this is about the database of signed certificates that OpenSSL is keeping for us (see below).
``` shell
openssl ca -config /root/ca/ca_openssl.cnf \
    -extensions v3_intermediate_ca \
    -days 3650 -notext -md sha256 \
    -in /root/ca/intermediate/csr/intermediate.csr.pem \
    -out /root/ca/intermediate/certs/intermediate.cert.pem && \
chmod 444 /root/ca/intermediate/certs/intermediate.cert.pem
```
This generates the new Intermdiate certificate at: `/root/ca/intermediate/certs/intermediate.cert.pem`.

Once generated, you can verify the certificate's values with:
``` shell
openssl x509 -noout -text -in /root/ca/intermediate/certs/intermediate.cert.pem
```

And you can verify the intermediate certificate's chain of trust against the CA certificate is valid with:
``` shell
openssl verify -CAfile /root/ca/certs/ca.cert.pem \
    /root/ca/intermediate/certs/intermediate.cert.pem
```

## Creating a Chain File
It's often convenient to have a combined "chain file" for a given service certificate's chain of trust back to a trusted root certificate.  Many SSL/TLS configurations expect to have these files.

These chain files are simply the concatenated set of all the certificates in the chain of trust which lead back to the trusted CA root certificate:
``` shell
cat /root/ca/intermediate/certs/intermediate.cert.pem \
    /root/ca/certs/ca.cert.pem > \
    /root/ca/intermediate/certs/ca-chain.cert.pem && \
chmod 444 /root/ca/intermediate/certs/ca-chain.cert.pem
```

## Safe Storage
The above work has generated several files which need to be preserved:
- The CA certificate and its key file
- The intermediate certificate and its keyfile
- A chainfile combining both certs
- A set of `index.txt*` and `serial*` files, one for each of the two CA certificates, which track what certificates have been signed with which CA certificates
- The `*openssl.cnf` files, one for each CA certificate, which configured OpenSSL during the various operations

These files need to be packaged and prepared for storage.

We'll package the entire set up into one archive at `/root/ca_authority.tar` which can represent the CA certificate, and which can be stored in a seldom-accessed, higher-security site.  

We'll also package the intermediate authority's files into a separate archive at `/root/intermediate_authority.tar`, which can be stored in the more-convenient, less-secure site.

Be sure to store both key's passwords somewhere safe as well:
``` shell
tar -czvf /root/ca_authority.tar.gz -C /root/ca/ .
cp /root/ca_authority.tar.gz /root/ca_persist

tar -czvf /root/intermediate_authority.tar.gz -C /root/ca/intermediate/ .
cp /root/intermediate_authority.tar.gz /root/ca_persist
```

Because this "export" behavior is critical, the above shell commands are also provided on the Docker image as ascript named `archive_ca`:
``` shell
archive_ca
```
