# Managing an Internal CA Certificate
We'd like to have internal web services protected with TLS, and we'd like to have an internal Certificate Authority (CA) certificate sign those service certificates.  Specifically, we want:

- A single master CA certificate for all internal production domains  
    - This is the certificate that gets distributed to clients as a trusted internal CA
- The CA certificate to be limited to just the internal production domains, with [X.509 Name Constraints](https://tools.ietf.org/html/rfc5280#section-4.2.1.10)
    - This is intended to contain the risk to issuing certificates for non-internal domains, if the CA certificate should be compromised (as part of a man-in-the-middle attack)
- An intermediate certificate, signed by the CA certificate, which in turn signs the service certificates.
    - Reducing access frequency to the CA certificate's credentials is intended to reduce risk
    - Being able to revoke the intermediate certificate and issue a replacement is also intended to reduce risk
- Various service certificates, signed by the intermediate certificate, for each of the production services on the internal network.

With this scenario, the CA certificate's keys can be put in long-term secure storage, while the intermediate certificate's keys can be stored in a more accessible (but still secure) location.

In order to contain the infrastructure for provisioning these certificates, we'll build a Docker container in which we'll execute the various commands.


# Getting a Docker Execution Environment
Setting up the Docker host environment is beyond the scope of this document, but a good place to start is the [Docker Community Edition website](https://www.docker.com/community-edition).

Clone this repository to a working directory:
``` shell
git clone https://github.com/triplepoint/ca-certificate-guide
cd ca-certificate-guide
```

Then build the [`Dockerfile`](https://github.com/triplepoint/ca-certificate-guide/blob/master/Dockerfile) into an image and create a Docker instance from the image with the usual Docker commands:
``` shell
docker build -t "ca-certificate-tools:latest" .
docker run -it --rm ca-certificate-tools:latest
```
Be sure not to omit the `--rm` flag; this container will generate confidential files, and we want to destroy it once we've moved the generated certificates and keys to secure locations.

Unless specified otherwise, the commands in the rest of this guide are executed inside the context of this Docker image.


# Generating a CA Certificate and an Intermediate Certificate
## Build a Custom `openssl.cnf` File
TODO?

## Generate a New Key Pair for the CA Certificate
TODO

## Generate the CA Certificate
TODO

## Generate a New Key Pair for the Intermediate Certificate
TODO

## Generate a Certificate Signing Request (CSR) for the Intermediate Certificate
TODO

## Sign the Intermediate Certificate with the CA Certificate
TODO

## Remember Security
Now that you've built the CA certificate and the Intermediate certificate, you can safely store the CA certificate's private key and a copy of its public key somewhere secure and out of the way.  You will rarely need access to this key.

The key pair for the Intermediate certificate should also be stored some place secure, ideally some place _else_ from the CA certificate's, to reduce frequent access exposure to the CA certificate's keys.  Remember that we'll need access to this private key whenever a new service key is signed.


# Distributing the CA Certificate to Clients
TODO - chainfiles, etc


# Generating a Signed Service Certificate
TODO


# Revoking a Service Certificate
TODO


# Revoking the Intermediate Certificate
TODO


# References
- https://jamielinux.com/docs/openssl-certificate-authority/create-the-root-pair.html
- https://fabianlee.org/2018/02/17/ubuntu-creating-a-trusted-ca-and-san-certificate-using-openssl-on-ubuntu/
- https://www.marcanoonline.com/post/2016/09/restrict-certificate-authority-to-a-domain/
