#!/bin/bash

set -o nounset \
  -o errexit \
  -o verbose \
  -o xtrace

# Generate CA key
openssl req -new -x509 -keyout ca.key -out ca.crt -days 9999 -subj '/CN=ca.test.localhost/OU=TEST/O=LOCAL/L=Paris/S=Ca/C=FR' -passin pass:ssl-secret -passout pass:ssl-secret

# kafkactl
openssl genrsa -out kafkactl.client.key 2048
openssl req -passin "pass:ssl-secret" -passout "pass:ssl-secret" -key kafkactl.client.key -new -out kafkactl.client.req -subj '/CN=kafkactl.test.localhost/OU=TEST/O=LOCAL/L=Paris/S=Ca/C=FR'
openssl x509 -req -CA ca.crt -CAkey ca.key -in kafkactl.client.req -out kafkactl-ca-signed.pem -days 9999 -CAcreateserial -passin "pass:ssl-secret"

for i in kafka producer consumer
do
  echo $i
  # Create keystores
  keytool -genkey -noprompt \
    -alias $i \
    -dname "CN=$i.test.localhost, OU=TEST, O=LOCAL, L=Paris, S=Ca, C=FR" \
    -keystore $i.keystore.jks \
    -keyalg RSA \
    -storepass ssl-secret \
    -keypass ssl-secret

  # Create CSR, sign the key and import back into keystore
  keytool -keystore $i.keystore.jks -alias $i -certreq -file $i.csr -storepass ssl-secret -keypass ssl-secret

  openssl x509 -req -CA ca.crt -CAkey ca.key -in $i.csr -out $i-ca-signed.crt -days 9999 -CAcreateserial -passin pass:ssl-secret

  keytool -keystore $i.keystore.jks -alias CARoot -import -file ca.crt -storepass ssl-secret -keypass ssl-secret -noprompt

  keytool -keystore $i.keystore.jks -alias $i -import -file $i-ca-signed.crt -storepass ssl-secret -keypass ssl-secret -noprompt

  # Create truststore and import the CA cert.
  keytool -keystore $i.truststore.jks -alias CARoot -import -file ca.crt -storepass ssl-secret -keypass ssl-secret -noprompt

  echo "ssl-secret" > ${i}_sslkey_creds
  echo "ssl-secret" > ${i}_keystore_creds
  echo "ssl-secret" > ${i}_truststore_creds
done
