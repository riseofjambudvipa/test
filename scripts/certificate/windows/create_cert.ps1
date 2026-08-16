# ============================================================
# CapStudio Code Signing Certificate Generator
# Run this script ONCE as Administrator in PowerShell.
# Right-click PowerShell -> "Run as Administrator"
# Then: cd "A:\Projects\Local AI Caption Studio\CapStudio"
#        $env:CAPSTUDIO_CERT_PASSWORD = "<choose a password>"
#        .\create_cert.ps1
# ============================================================
#
# FIX (Issue #10, CapStudio 1.0 audit): the password was previously
# hardcoded here in plaintext (and separately, identically, hardcoded in
# pubspec.yaml's msix_config.certificate_password). This cert is
# self-signed (not CA-issued) so the practical exposure was limited, and
# .pfx output was already correctly gitignored — but a plaintext password
# committed to a tracked script is still avoidable. Now read from an
# environment variable; the build step should pass the same value via
# `flutter pub run msix:create --password <value>`, which the msix package
# supports as an override for pubspec.yaml's certificate_password field.

if (-not $env:CAPSTUDIO_CERT_PASSWORD) {
    Write-Host "ERROR: Set the CAPSTUDIO_CERT_PASSWORD environment variable first." -ForegroundColor Red
    Write-Host '  Example: $env:CAPSTUDIO_CERT_PASSWORD = "your-chosen-password"' -ForegroundColor Yellow
    exit 1
}

$certSubject = "CN=CapStudio, O=Local AI, C=IN"
$pfxPassword  = ConvertTo-SecureString -String $env:CAPSTUDIO_CERT_PASSWORD -Force -AsPlainText
$pfxPath      = "$PSScriptRoot\capstudio_cert.pfx"

Write-Host ""
Write-Host "Generating self-signed code signing certificate..." -ForegroundColor Cyan
Write-Host "  Subject : $certSubject"
Write-Host "  Output  : $pfxPath"
Write-Host ""

# Step 1: Create the self-signed certificate in LocalMachine\My
$cert = New-SelfSignedCertificate `
    -Type Custom `
    -Subject $certSubject `
    -KeyUsage DigitalSignature `
    -FriendlyName "CapStudio Code Signing" `
    -CertStoreLocation "Cert:\LocalMachine\My" `
    -TextExtension @("2.5.29.37={text}1.3.6.1.5.5.7.3.3", "2.5.29.19={text}")

Write-Host "Certificate created. Thumbprint: $($cert.Thumbprint)" -ForegroundColor Green

# Step 2: Export to PFX file at the project root
Export-PfxCertificate `
    -Cert "Cert:\LocalMachine\My\$($cert.Thumbprint)" `
    -FilePath $pfxPath `
    -Password $pfxPassword | Out-Null

Write-Host "Certificate exported to: $pfxPath" -ForegroundColor Green

# Step 3: Install to Trusted Root so Windows trusts the installer
Import-PfxCertificate `
    -FilePath $pfxPath `
    -Password $pfxPassword `
    -CertStoreLocation Cert:\LocalMachine\Root | Out-Null

Write-Host "Certificate installed to Trusted Root." -ForegroundColor Green
Write-Host ""
Write-Host "Done! You can now run:  dart run msix:create" -ForegroundColor Yellow
Write-Host "The installer will show:  Publisher: CapStudio" -ForegroundColor Cyan
Write-Host ""
