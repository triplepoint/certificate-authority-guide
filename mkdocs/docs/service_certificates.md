# Generating a Signed SSL/TLS Service Certificate
The instructions introduced so far for generating the root CA certificate and the intermediate certificate were complex, but since they are seldom performed that should be acceptable.

In contrast, the procedure for requesting a new service certificate from your CA could happen frequently.  We'll need to provide some automation in order to avoid mistakes and reduce labor.

We'll go through this process once manually, for explanation's sake, and then we'll introduce a script that does the same thing, but quicker and easier.

TODO
- SANs
