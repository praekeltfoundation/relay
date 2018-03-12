#!/bin/sh

# Generate a self-signed cert with no SAN extension.
openssl req -newkey rsa:2048 -nodes -keyout demo-nosan.pem \
        -new -x509 -days 3650 -out demo-nosan.pem \
        -subj "/CN=demo-nosan.example.com"

# Generate a self-signed cert with some SAN values.
openssl req -newkey rsa:2048 -nodes -keyout demo.pem \
        -new -x509 -days 3650 -out demo.pem \
        -config demo.conf -extensions 'v3_req'
