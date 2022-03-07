### Export environment variables to remove SSL downloading issue
```bash
# Should add following to ~/.profile

#CentOS/RHEL:
export SSL_CERT_DIR=/etc/pki/tls/certs
export SSL_CERT_FILE=/etc/pki/tls/cert.pem

#Ubuntu/Debian:
export SSL_CERT_DIR=/etc/ssl/certs
export SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt

# Run dev
foreman start -f Procfile.dev
```
