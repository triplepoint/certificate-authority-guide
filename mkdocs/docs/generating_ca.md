# A Note on the OpenSSL Config Files
Our skeleton working directory contains copy of the openssl config file in both the `/root/ca` and `/root/ca/intermediate` directory.  These files are identical, but they're duplicated to ensure that the intermediate CA archive has its own copy when it's used on its own (for example, when signing a service certificate).

In the `openssl` commands below, we'll be careful to explicitly set the openssl `-config` and `-name` flags appropriately for each scenario, but just be aware these two files are (or at least should be) identical.

# Generating a Root CA Certificate
The Certificate Authority's core documents are its root certificate and the associated private key.  This is the certificate which all clients will directly trust, and its the root of the chain of trust that ultimately extends down to the individual service certificates.

You'll likely only need to generate this root certificate and its key once.  We'll set the expiration for 20 years (7300 days), and as long as the certificate isn't compromised you can rely on it to function for that long.

## Generate a New Key and Certificate Signing Request for the CA Certificate
Here we'll generate a new RSA key for the CA certificate, and also a Certificate Signing Request (CSR) which will define the details of the CA certificate, and which will be used to self-sign the new certificate.

The key will be encrypted with a passphrase, which you'll be prompted to supply.  You'll want to use a real non-empty password for this key and store it in a safe place.

When you are prompted for the CA Certificate Distinguished Name details, take care to get them right.  You won't want to have to regenerate the certificate after its been distributed.

``` shell
openssl req \
    -config /root/ca/ca_openssl.cnf \
    -new \
    -newkey rsa:4096 \
    -keyout /root/ca/private/ca.key.pem \
    -out /root/ca/ca.req.pem
```

This generates the new CA certificate key at `/root/ca/private/ca.key.pem` and  generates the new CSR for the root certificate at `/root/ca/ca.req.pem`.

## Self-Sign the Root Certificate
Now that we have a signing request, we can act on it to self-sign the root certificate:

``` shell
openssl ca \
    -config /root/ca/ca_openssl.cnf \
    -name CA_root \
    -in /root/ca/ca.req.pem \
    -create_serial \
    -out /root/ca/certs/ca.cert.pem \
    -days 7300 \
    -keyfile /root/ca/private/ca.key.pem \
    -selfsign \
    -extensions v3_ca
```
This generates the new CA root certificate at `/root/ca/certs/ca.cert.pem`.

## Verifying the Root Certificate
Now that the root CA certificate and key are generated, you can verify them with:
``` shell
openssl x509 -noout -text -in /root/ca/certs/ca.cert.pem
```

TODO - what are we looking at?

## Generate a New Key for the Intermediate Certificate
Just like we did for the CA root certificate above, we need to generate a signing key for the CA intermediate certificate:
``` shell
openssl genrsa \
    -aes256 \
    -out /root/ca/intermediate/private/intermediate.key.pem \
    4096 && \
chmod 400 /root/ca/intermediate/private/intermediate.key.pem
```
This generates the new intermediate certificate key at: `/root/ca/intermediate/private/intermediate.key.pem`.


# Generating an Intermediate CA Certificate
## Generate a Certificate Signing Request (CSR) for the Intermediate Certificate
This document represents a request to the root CA to generate the intermediate certificate.

Note that the `Country Name`, `State or Province Name`, and `Organization Name` all have to match the values of the CA certificate.

Also note that the Common Name used in this CSR _must_ be distinct from the CA certificate's Common Name, used above.

``` shell
openssl req \
    -config /root/ca/intermediate/int_openssl.cnf \
    -key /root/ca/intermediate/private/intermediate.key.pem \
    -new \
    -sha256 \
    -out /root/ca/intermediate/csr/intermediate.csr.pem
```

## Sign the Intermediate Certificate with the CA Certificate
Answer `y` to any prompts about "commiting", this is about the database of signed certificates that OpenSSL is keeping for us (see below).
``` shell
openssl ca \
    -config /root/ca/ca_openssl.cnf \
    -extensions v3_intermediate_ca \
    -days 3650 \
    -notext \
    -md sha256 \
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


# Creating a Chain File
It's often convenient to have a combined "chain file" for a given service certificate's chain of trust back to a trusted root certificate.  Many SSL/TLS configurations expect to have these files.

These chain files are simply the concatenated set of all the certificates in the chain of trust which lead back to the trusted CA root certificate:
``` shell
cat /root/ca/intermediate/certs/intermediate.cert.pem \
    /root/ca/certs/ca.cert.pem > \
    /root/ca/intermediate/certs/ca-chain.cert.pem && \
chmod 444 /root/ca/intermediate/certs/ca-chain.cert.pem
```


# Safe Storage
The above work has generated several files which so far only exist on this Docker container, and which now need to be preserved:

- The CA certificate and its key file
- The intermediate certificate and its keyfile
- A chainfile combining both certs
- A set of `index.txt*` and `serial*` files, one for each of the two CA certificates, which track what certificates have been signed with which CA certificates
- The `*openssl.cnf` files, one for each CA certificate, which configured OpenSSL during the various operations

These files need to be packaged and prepared for storage.

We'll package the entire set up into one archive at `/root/ca_authority.tar.gz` which can represent the CA root certificate, and which can be stored in a seldom-accessed, higher-security site.

We'll also package the intermediate authority's files into a separate archive at `/root/intermediate_authority.tar.gz`, which can be stored in the more-convenient, less-secure site.

Be sure to store both keys' passwords somewhere safe as well:
``` shell
tar -czvf /root/ca_authority.tar.gz -C /root/ca/ .
cp /root/ca_authority.tar.gz /root/ca_persist

tar -czvf /root/intermediate_authority.tar.gz -C /root/ca/intermediate/ .
cp /root/intermediate_authority.tar.gz /root/ca_persist
```

Because this "export" behavior is critical, the above shell commands are also provided on the Docker image as ascript named [`archive_ca`](https://github.com/triplepoint/certificate-authority-guide/blob/master/src/scripts/archive_ca):
``` shell
archive_ca
```
