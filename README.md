# Generating an Internal CA Certificate
We'd like to have internal web services protected with TLS, and we'd like to have an internal CA certificate sign those service certificates.  Specifically, we want:
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

# Procedure
## Get a Docker Execution Environment
Setting up the Docker host environment is beyond the scope of this document, but a good place to start is the [Docker Community Edition website](https://www.docker.com/community-edition).

Clone this repository to a working directory:
``` shell
git clone https://github.com/triplepoint/ca-certificate-guide
cd ca-certificate-guide
```

Then build the [`Dockerfile`](Dockerfile) into an image and create a Docker instance from the image with the usual Docker commands:
``` shell
docker build -t "ca-certificate-tools:latest" .
docker run -it --rm ca-certificate-tools:latest
```

Unless specified otherwise, the commands in the rest of this guide are executed inside the context of this Docker image.

## Establish a Customized `openssl.cnf` File


## Generate the New CA Certificate
While all of the steps in this process are sensitive, this step is the really security-relevant part and should be done on as secure an environment as possible.  Be paranoid.

### Generate a New Private Key for the CA Certificate



# References
- https://jamielinux.com/docs/openssl-certificate-authority/create-the-root-pair.html
- https://fabianlee.org/2018/02/17/ubuntu-creating-a-trusted-ca-and-san-certificate-using-openssl-on-ubuntu/
- https://www.marcanoonline.com/post/2016/09/restrict-certificate-authority-to-a-domain/
