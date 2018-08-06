# Managing a Private Certificate Authority
A typical office or enthusiast LAN will have several web services hosted on private domain names which only resolve on the LAN.  We'd like these services to use HTTPS, with SSL/TLS certificates which have valid chains of trust, but we don't want to get a real-world Certificate Authority (CA) involved in issuing our service certificates.

The solution is to create our own CA.  This entity represents a new root point of trust which our client hosts can explicitly trust, and which can extend a valid chain of trust to the various internal web service SSL/TLS certificates.

However, this plan has important implications for security and privacy.  Trusting any CA implies that any certificate signed by that CA is also trusted.  This broad trust could be exploited to issue fraudulent certificates for 3rd party domains if, say, the CA certificate and key were stolen, or if the agency which controls the CA chose to undermine the privacy and security of the clients who trusted it.

In order to mitigate this risk, we'd like to limit the CA such that its trust only extends to domains which match a given whitelist.  Clients can then verify this condition by inspecting the CA certificate before trusting it, and be assured that, at worst, their attack surface extends only to a small set of internal domains.

In addition, as a matter of security best practices, we'd like to recognize the tradeoff between convenience and security when it comes to storing the CA certificate's key, and optimize for security.  In order to do so, while still enabling convenient signing of new service certificates, we'd like to have an intermediate certificate signed by the CA certificate, which is then used for signing the various web service certificates.  This allows us to avoid the need for frequent access to the CA certificate's key, and also enables us to revoke the intermediate certificate if it were compromised, while allowing for a more convenient (though still secure) storage strategy for the intermediate certificate's key.

Specifically, we want:
- A single master CA certificate, limited to just internal production domains with [X.509 Name Constraints](https://tools.ietf.org/html/rfc5280#section-4.2.1.10), which can be trusted by internal clients
- An intermediate certificate, signed by the CA certificate, which in turn signs the various internal service certificates.
- Various SSL/TLS service certificates, signed by the intermediate certificate, for each of the production services on the internal network.


# Getting a Docker Execution Environment
In order to contain the infrastructure for provisioning these certificates, we'll build a Docker container in which we'll execute the various commands.

Setting up the Docker host environment is beyond the scope of this document, but a good place to start is the [Docker Community Edition website](https://www.docker.com/community-edition).

Clone this repository to a working directory:
``` shell
git clone https://github.com/triplepoint/ca-certificate-guide
cd ca-certificate-guide
```

Then build the [`Dockerfile`](https://github.com/triplepoint/ca-certificate-guide/blob/master/Dockerfile) into an image and create a Docker instance from the image with the usual Docker commands:
``` shell
docker build -t "ca-certificate-tools:latest" .

mkdir -p ./archives
docker run -it --rm  \
    --mount type=bind,source="$(pwd)/archives",target="/root/ca_persist" \
    ca-certificate-tools:latest
```
Here we're creating and mounting a `./archives` directory as a Docker volume.  This will be used for persisting archives of the generated files between Docker containers.  You might instead choose to directly mount a USB drive.

Be sure not to omit the `--rm` flag; this container will generate confidential files, and we want to destroy it once we've moved the generated confidential files to secure locations.

Unless specified otherwise, the commands in the rest of this guide are executed inside the context of this Docker image.


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

# Distributing the CA Certificate to Clients
TODO


# Generating a Signed SSL/TLS Service Certificate
The above instructions for generating the root CA certificate and the intermediate certificate were complex, but since they are seldom performed that should be acceptable.

In contrast, the procedure for requesting a new service certificate from the internal CA could happen frequently.  We'll need to provide some automation in order to avoid mistakes and reduce labor.

We'll go through this process once manually, for explanation's sake, and then we'll introduce a script that does the same thing, but quicker and easier.

TODO
- SANs


# Revoking a SSL/TLS Service Certificate
TODO


# Revoking the Intermediate Certificate
TODO


# References
- [Jamie Nguyen's _OpenSSL Certificate Authority_](https://jamielinux.com/docs/openssl-certificate-authority/create-the-root-pair.html)
- [Robert Marcano's _Restrict Certificate Authority to a Domain_](https://www.marcanoonline.com/post/2016/09/restrict-certificate-authority-to-a-domain/)
- [OpenSSL documentation on Certificate Authorities](https://www.openssl.org/docs/manmaster/man1/ca.html)
- [OpenSSL documentation on Certificate Requests](https://www.openssl.org/docs/manmaster/man1/req.html)
- https://fabianlee.org/2018/02/17/ubuntu-creating-a-trusted-ca-and-san-certificate-using-openssl-on-ubuntu/
