#!/bin/sh

init() {
	mkdir certs clients crl csr newcerts private
	chmod 700 private
	touch index.txt
	echo 1000 > serial
	
	openssl genrsa -aes256 -passout pass:xxxxxx -out private/ca.key.pem 4096
	chmod 400 private/ca.key.pem
	
	openssl req -config openssl.cnf -passin pass:xxxxxx -key private/ca.key.pem -new -x509 -days 7300 -sha256 -extensions v3_ca -out certs/ca.cert.pem -subj "/C=CZ/ST=Czech Republic/L=Pilsen/O=FLAB/CN=warden-ra.flab.cesnet.cz"
	
	openssl rsa -in private/ca.key.pem -out private/ca.key2.pem -passin pass:xxxxxx
	mv private/ca.key2.pem private/ca.key.pem
	
	chmod 444 certs/ca.cert.pem
}

mkdir -p ca
cd ca || exit 1

case "$1" in
	init) init ;;
esac

