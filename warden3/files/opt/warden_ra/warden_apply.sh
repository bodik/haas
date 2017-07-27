#!/bin/bash

url="$1"
key=key.pem
csr=csr.pem
cert=cert.pem
result=${TMPDIR:-${TMP:-/tmp}}/cert.$$.$RANDOM
config=${TMPDIR:-${TMP:-/tmp}}/conf.$$.$RANDOM
client="$2"
password="$3"
incert="$3"
inkey="$4"

trap 'rm -f "$config $result"' INT TERM HUP EXIT

function flee { echo -e "$1"; exit $2; }

[ -z "$client" -o -z "$password" ] && flee "Usage: ${0%.*} client.name password\n       ${0%.*} client.name cert_file key_file" 255

for n in openssl curl; do
    command -v "$n" 2>&1 >/dev/null || flee "Haven't found $n binary." 251
done
for n in "$csr" "$key" "$cert"; do
    [ -e "$n" ] && flee "$n already exists, I won't overwrite, move them away first, please." 254
done
for n in "$result" "$config"; do
    touch "$n" || flee "Error creating temporary file ($n)." 253
done

echo -e "default_bits=2048\ndistinguished_name=rdn\nprompt=no\n[rdn]\ncommonName=dummy" > "$config"

openssl req -new -nodes -batch -keyout "$key" -out "$csr" -config "$config" || flee "Error generating key/certificate request." 252

if [ -z "$inkey" ]; then
	curl --progress-bar --request POST --data-binary '@-' "$url?name=$client&password=$password" < "$csr" > "$result"
else
	curl --progress-bar --request POST --data-binary '@-' --cert "$incert" --key "$inkey" "$url?name=$client" < "$csr" > "$result"
fi

case $(<$result) in '-----BEGIN CERTIFICATE-----'*)
    mv "$result" "$cert"
    flee "Succesfully generated key ($key) and obtained certificate ($cert)." 0
esac

flee "$(<$result)\n\nCertificate request failed. Please save all error messages for communication with registration authority representative." 252
