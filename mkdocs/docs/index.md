# Introduction
A typical office or enthusiast LAN will have several web services hosted internally, with private domain names resolved by a private DNS server.  We'd like these services to use HTTPS, with SSL/TLS certificates which have valid chains of trust, but we don't want to get a real-world Certificate Authority (CA) involved in issuing our private service certificates.

The solution is to create our own CA.  This entity will represent a new root point of trust which our service clients can explicitly accept, and which can extend its trust to the various internal web service SSL/TLS certificates.

However, this plan has important implications for security and privacy.  Trusting any CA implies that any certificate signed by that CA is also trusted.  This broad trust could be exploited to issue fraudulent certificates for 3rd party domains if, say, the CA certificate and key were stolen, or if the agency which controls the CA chose to undermine the privacy and security of the clients who trusted it.

In order to mitigate this risk, we'd like to limit the CA such that its trust only extends to domains which match a given whitelist.  Clients can then verify this condition by inspecting the CA certificate before trusting it, and be assured that, at worst, their risk extends only to a limited set of internal domains.

In addition, we'd like to find a balance between convenience and security when it comes to handling the CA's confidential files.  To do so, while still enabling convenient signing of new service certificates, we'll create an intermediate certificate signed by the root CA certificate, which is then used for signing the various web service certificates.

This structuring of the CA into a root and an intermediate certificate will allow us to avoid frequent access to the root CA certificate's key.  It will also give us a trusted entity from which to revoke the intermediate CA certificate if it were compromised.  And finally, the intermediate certificate can have a relatively short expiration date, with a replacement intermediate certificate being rotated into usage near the existing one's end of life, without having to re-issue a trusted certificate for all the clients.

In summary, we want:

- A single long-lived root CA certificate, limited to just internal production domains with [X.509 Name Constraints](https://tools.ietf.org/html/rfc5280#section-4.2.1.10), which can be trusted by internal clients.

- An intermediate CA certificate, signed by the root CA certificate.

- Various SSL/TLS service certificates for each of the production services on the internal network, signed by the intermediate CA certificate.

The rest of this guide will go into detail on how to accomplish these goals, and some advice on maintaining it with a minimum of hassle.
