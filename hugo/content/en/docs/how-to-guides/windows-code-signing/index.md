---
title: Replace the Windows signing certificate
description: Create a new certificate for signing the Windows release
weight: 40
---

The release workflow signs the Windows binaries with `sentinel/packaging/windows/sign.ps1`.
It reads the certificate from the repository secrets `WINDOWS_SIGNING_PFX` (base64 PFX) and `WINDOWS_SIGNING_PFX_PASSWORD`.
The public part is published at `hugo/static/certs/franklyn.crt`.

There is no backup of the private key, and GitHub secrets cannot be read back.
Replace the certificate before it expires (14 November 2031), or right away if the key leaks.

## Create the certificate and set the secrets

The key is created in RAM, the password is never shown, and both are deleted at the end:

```sh
cd "$(mktemp -d -p /dev/shm)"
openssl req -x509 -newkey rsa:3072 -sha256 -days 1826 -noenc \
  -keyout franklyn.key -out franklyn.crt -subj "/CN=Franklyn" \
  -addext "basicConstraints=critical,CA:FALSE" \
  -addext "keyUsage=critical,digitalSignature" \
  -addext "extendedKeyUsage=codeSigning"
export PW="$(openssl rand -base64 32)"
openssl pkcs12 -export -inkey franklyn.key -in franklyn.crt -out franklyn.pfx -passout env:PW
base64 -w0 franklyn.pfx | gh secret set WINDOWS_SIGNING_PFX -R 2526-4ahitm-itp/2526-4ahitm-franklyn
printf %s "$PW" | gh secret set WINDOWS_SIGNING_PFX_PASSWORD -R 2526-4ahitm-itp/2526-4ahitm-franklyn
cp franklyn.crt ~/franklyn.crt
shred -u franklyn.key franklyn.pfx; unset PW
```

## Publish the certificate

1. Copy `~/franklyn.crt` to `hugo/static/certs/franklyn.crt`.
2. Print the new thumbprint and replace the old one, and the expiry date, in `hugo/content/en/guide/self-host/windows-code-signing.md`:
   ```sh
   openssl x509 -in ~/franklyn.crt -noout -fingerprint -sha1 -enddate
   ```
3. Tell admins to install the new certificate. If the old key leaked, they should also move the old certificate to **Untrusted Certificates**.
