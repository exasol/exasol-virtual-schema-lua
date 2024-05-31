#!/bin/bash
# This script creates a disposable set of TLS certificates for integration tests.
#
#################################
# NEVER USE THIS IN PRODUCTION! #
#################################

set -o errexit
set -o nounset
set -o pipefail

readonly working_dir='/tmp/test-certificates'
readonly testpw='testpw'

mkdir -p "$working_dir"
cd "$working_dir"

# Create CA key:
openssl genrsa -aes256 -out ca.key --passout "pass:$testpw" 4096

# Create CA certificate:
openssl req -x509 -new -nodes -key ca.key -sha256 -days 365 -out ca.crt -subj '/CN=ITest CA/C=DE/O=ITest' --passin "pass:$testpw"

# Create server key:
openssl genrsa -out server.key 4096

# Create server certificate signing request:
openssl req -new -nodes -key server.key -sha256 -out server.csr -subj '/CN=ITest Exasol Server/C=DE/O=ITest'

# Create certificate extensions configuration:
cat > server_cert_extensions.cfg <<EOL
[extensions]
keyUsage = critical, nonRepudiation, digitalSignature, keyEncipherment, keyAgreement
basicConstraints = CA:false
subjectAltName = @alt_names

[alt_names]
DNS.1 = localhost
IP.1 = 127.0.0.1
EOL

# Sign the request:
openssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out server.crt -days 90 -sha256 -extfile server_cert_extensions.cfg -extensions extensions --passin "pass:$testpw"

# Install the certificates:
cp ca.crt /exa/etc/ssl/ssl.ca
cp ca.key /exa/etc/ssl/ssl.ca.key # Note that in a production environment you would not have the CA key on the server!
cp server.key /exa/etc/ssl/ssl.key
cp server.crt /exa/etc/ssl/ssl.crt

dwad_client stop DB1
# https://github.com/exasol/exasol-virtual-schema-lua/issues/36: find a better way than waiting a couple of minutes.
dwad_client start DB1

# This is a workaround for the fact that the change in /exa/etc/ssl does not take immediate effect:
cp ca.crt /exa/etc/dwad/db_DB1_ca.pem
cp server.crt /exa/etc/dwad/db_DB1_cert.pem