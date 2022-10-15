## Certificates generating

Self-Signed certificates procedure

1. Root Key and Certificate generating

```
openssl genrsa -out rootCA.key 4096
openssl req -x509 -new -nodes -key rootCA.key -sha256 -days 1024 -out rootCA.crt
```

2. Certificate Key, CSR and Certificate generating

```
openssl genrsa -out ru-central1.internal.key 2048
openssl req -new -sha256 \
    -key ru-central1.internal.key \
    -subj "/CN=ru-central1.internal" \
    -reqexts SAN \
    -config <(cat /etc/ssl/openssl.cnf \
        <(printf "\n[SAN]\nsubjectAltName=DNS:*.ru-central1.internal")) \
    -out ru-central1.internal.csr
openssl x509 -req \
-extfile <(printf "subjectAltName=DNS:*.ru-central1.internal") \
-days 720 \
-in ru-central1.internal.csr \
-CA rootCA.crt \
-CAkey rootCA.key \
-CAcreateserial \
-out ru-central1.internal.crt
```