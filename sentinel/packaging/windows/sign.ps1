param([string[]]$Path)
$ErrorActionPreference = 'Stop'
$cert = [Security.Cryptography.X509Certificates.X509Certificate2]::new([Convert]::FromBase64String($env:SIGNING_PFX), $env:SIGNING_PFX_PASSWORD)
Set-AuthenticodeSignature -LiteralPath $Path -Certificate $cert -HashAlgorithm SHA256 -TimestampServer http://timestamp.digicert.com |
    Where-Object { $_.SignerCertificate.Thumbprint -ne $cert.Thumbprint -or -not $_.TimeStamperCertificate } |
    ForEach-Object { throw "$($_.Path): $($_.StatusMessage)" }
