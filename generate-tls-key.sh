#!/bin/sh
set -ex

if [ "$(id -u)" != 0 ]; then
	echo >&2 "error: must be root to invoke $0"
	exit 1
fi

: ${CERTDIR:=/var/lib/wsl2-docker/tls}

# ca
mkdir -p ${CERTDIR}/ca
if [ ! -f "${CERTDIR}/ca/key.pem" ]; then
	openssl genrsa -out ${CERTDIR}/ca/key.pem 4096
	chmod 0600 ${CERTDIR}/ca/key.pem
fi
if [ ! -f "${CERTDIR}/ca/cert.pem" ]; then
	openssl req -new -key ${CERTDIR}/ca/key.pem -out ${CERTDIR}/ca/cert.pem \
		-subj "/CN=wsl2-docker CA" -x509 -days 366
fi

# server
mkdir -p ${CERTDIR}/server
if [ ! -f "${CERTDIR}/server/key.pem" ]; then
	openssl genrsa -out ${CERTDIR}/server/key.pem 4096
	chmod 0600 ${CERTDIR}/server/key.pem
fi
if [ ! -f "${CERTDIR}/server/cert.pem" ]; then
	openssl req -new -key ${CERTDIR}/server/key.pem -out ${CERTDIR}/server/csr.pem \
		-subj "/CN=wsl2-docker server"
	cat > ${CERTDIR}/server/openssl.cnf << EOF
[ x509_exts ]
subjectAltName = DNS:localhost,IP:127.0.0.1
EOF
	openssl x509 -req \
		-in ${CERTDIR}/server/csr.pem \
		-CA ${CERTDIR}/ca/cert.pem \
		-CAkey ${CERTDIR}/ca/key.pem \
		-CAcreateserial \
		-out ${CERTDIR}/server/cert.pem \
		-days 366 \
		-extfile ${CERTDIR}/server/openssl.cnf \
		-extensions x509_exts
fi

openssl verify -CAfile ${CERTDIR}/ca/cert.pem ${CERTDIR}/server/cert.pem

# client
mkdir -p ${CERTDIR}/client
if [ ! -f "${CERTDIR}/client/key.pem" ]; then
	openssl genrsa -out ${CERTDIR}/client/key.pem 4096
	chmod 0600 ${CERTDIR}/client/key.pem
fi
if [ ! -f "${CERTDIR}/client/cert.pem" ]; then
	openssl req -new -key ${CERTDIR}/client/key.pem -out ${CERTDIR}/client/csr.pem \
		-subj "/CN=wsl2-docker client"
	cat > ${CERTDIR}/client/openssl.cnf << EOF
[ x509_exts ]
extendedKeyUsage = clientAuth
EOF
	openssl x509 -req \
		-in ${CERTDIR}/client/csr.pem \
		-CA ${CERTDIR}/ca/cert.pem \
		-CAkey ${CERTDIR}/ca/key.pem \
		-CAcreateserial \
		-out ${CERTDIR}/client/cert.pem \
		-days 366 \
		-extfile ${CERTDIR}/client/openssl.cnf \
		-extensions x509_exts
fi

openssl verify -CAfile ${CERTDIR}/ca/cert.pem ${CERTDIR}/client/cert.pem

echo "generate OK"

if [ ! -d "${HOME}/.docker" ]; then
	mkdir -p ${HOME}/.docker
	chmod 0700 ${HOME}/.docker
	cp ca/cert.pem ${HOME}/.docker/ca.pem
	cp client/cert.pem ${HOME}/.docker/cert.pem
	cp client/key.pem ${HOME}/.docker/key.pem

	chmod 0644 ${HOME}/.docker/ca.pem
	chmod 0644 ${HOME}/.docker/cert.pem
	chmod 0600 ${HOME}/.docker/key.pem
fi

echo "DONE"
