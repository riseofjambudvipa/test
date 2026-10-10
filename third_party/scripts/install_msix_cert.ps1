# ============================================================
# CapStudio MSIX Certificate Installer
# Run ONCE (as Administrator) so Windows trusts the CapStudio
# self-signed MSIX package on this machine.
#
# Usage (in an elevated PowerShell):
#   .\third_party\scripts\install_msix_cert.ps1
#
# After running this script you can install CapStudio-Windows-x64.msix
# by double-clicking it — the publisher warning will be gone.
# ============================================================

param(
    [string]$PfxPath = "$PSScriptRoot\certificate\windows\capstudio_cert.pfx",
    [string]$Password = "capstudio-release-cert"
)

$PfxPath = (Resolve-Path $PfxPath -ErrorAction Stop).Path
Write-Host ""
Write-Host "CapStudio MSIX Certificate Installer" -ForegroundColor Cyan
Write-Host "  PFX : $PfxPath"
Write-Host ""

$secPwd = ConvertTo-SecureString -String $Password -AsPlainText -Force

try {
    # TrustedPeople = allows sideloaded MSIX packages
    Import-PfxCertificate -FilePath $PfxPath -Password $secPwd `
        -CertStoreLocation Cert:\LocalMachine\TrustedPeople | Out-Null

    # TrustedRoot = suppresses the "unknown publisher" chain warning
    Import-PfxCertificate -FilePath $PfxPath -Password $secPwd `
        -CertStoreLocation Cert:\LocalMachine\Root | Out-Null

    Write-Host "Certificate installed successfully." -ForegroundColor Green
    Write-Host "You can now install CapStudio-Windows-x64.msix by double-clicking it." -ForegroundColor Green
} catch {
    Write-Host "ERROR: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "This script must be run as Administrator." -ForegroundColor Yellow
    Write-Host "Right-click PowerShell > 'Run as Administrator', then run:" -ForegroundColor Yellow
    Write-Host "  .\third_party\scripts\install_msix_cert.ps1" -ForegroundColor White
    exit 1
}
Write-Host ""
