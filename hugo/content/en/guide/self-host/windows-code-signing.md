---
title: Windows Code Signing
description: Trust the Franklyn signing certificate on Windows
weight: 20
---

The Franklyn Windows binaries (`franklyn.exe`, its DLLs, the setup and the uninstaller) are signed with Franklyn's own self-signed certificate.
Once you install the certificate, Windows reports the signatures as valid, with the publisher `Franklyn`.

{{< callout type="warning" >}}
The certificate does not remove the "Windows protected your PC" (SmartScreen) prompt for downloaded installers.
{{< /callout >}}

## Install the certificate

Download [`franklyn.crt`](/certs/franklyn.crt) and add it to the **Trusted Root Certification Authorities** store of the computer.

- **Single machine:** in PowerShell as Administrator:
  ```powershell
  Import-Certificate -FilePath .\franklyn.crt -CertStoreLocation Cert:\LocalMachine\Root
  ```
- **Group Policy:** Computer Configuration → Policies → Windows Settings → Security Settings → Public Key Policies → Trusted Root Certification Authorities → Import.
- **Intune:** create a **Trusted certificate** profile with the destination store **Computer certificate store - Root**.

Check that the thumbprint is `C592E0BA31885A3CC32213BF632C45E7326DB4A3`.

## Check

After installing Franklyn, open a new terminal and run:

```powershell
Get-AuthenticodeSignature (Get-Command franklyn).Source
```

`Status` must be `Valid`.

The certificate expires on 14 November 2031. Binaries signed before that date stay valid after it expires.
