<#
.SYNOPSIS
    Generates an Android Release Keystore for CapStudio and formats it for GitHub Actions CI secrets.
.DESCRIPTION
    Creates an RSA 2048-bit keystore with 10,000 days validity, outputs its Base64 representation,
    and displays the exact configuration required for GitHub Secrets and android/key.properties.
#>

param(
    [string]$KeystorePath = "android/app/capstudio-release.jks",
    [string]$Alias = "capstudio",
    [string]$Password = ""
)

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "   CapStudio Android Production Keystore Generator        " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# Check if keytool is available
$keytool = Get-Command keytool -ErrorAction SilentlyContinue
if (-not $keytool) {
    Write-Error "keytool was not found on PATH. Please ensure the Java Development Kit (JDK) is installed."
    exit 1
}

if (-not $Password) {
    $securePass = Read-Host -Prompt "Enter password for the keystore and alias" -AsSecureString
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePass)
    $Password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
}

if ($Password.Length -lt 6) {
    Write-Error "Password must be at least 6 characters long."
    exit 1
}

$directory = Split-Path -Path $KeystorePath -Parent
if ($directory -and -not (Test-Path $directory)) {
    New-Item -ItemType Directory -Path $directory -Force | Out-Null
}

Write-Host "`nGenerating keystore at: $KeystorePath..." -ForegroundColor Yellow

$dname = "CN=CapStudio, OU=Engineering, O=CapStudio, L=Global, ST=Global, C=US"

& keytool -genkeypair -v `
    -keystore $KeystorePath `
    -alias $Alias `
    -keyalg RSA `
    -keysize 2048 `
    -validity 10000 `
    -storepass $Password `
    -keypass $Password `
    -dname $dname

if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to generate keystore."
    exit 1
}

Write-Host "`nKeystore generated successfully!" -ForegroundColor Green

# Generate Base64 string for CI
$keystoreBytes = [System.IO.File]::ReadAllBytes((Resolve-Path $KeystorePath))
$base64 = [System.Convert]::ToBase64String($keystoreBytes)
$base64Path = "$KeystorePath.base64.txt"
Set-Content -Path $base64Path -Value $base64

Write-Host "`n----------------------------------------------------------" -ForegroundColor Yellow
Write-Host "  GITHUB ACTIONS CI SECRETS CONFIGURATION                 " -ForegroundColor Yellow
Write-Host "----------------------------------------------------------" -ForegroundColor Yellow
Write-Host "Add the following 4 secrets to your GitHub repository (Settings -> Secrets -> Actions):"
Write-Host ""
Write-Host "  KEYSTORE_BASE64   : (Copied to $base64Path)" -ForegroundColor White
Write-Host "  KEYSTORE_PASSWORD : $Password" -ForegroundColor White
Write-Host "  KEY_ALIAS         : $Alias" -ForegroundColor White
Write-Host "  KEY_PASSWORD      : $Password" -ForegroundColor White
Write-Host "----------------------------------------------------------`n" -ForegroundColor Yellow

# Generate local key.properties template
$keyPropsPath = "android/key.properties"
$keyPropsContent = @"
storePassword=$Password
keyPassword=$Password
keyAlias=$Alias
storeFile=../app/capstudio-release.jks
"@

Set-Content -Path $keyPropsPath -Value $keyPropsContent
Write-Host "Wrote local properties template to: $keyPropsPath" -ForegroundColor Green
Write-Host "IMPORTANT: Keep your keystore safe. Never commit .jks, .base64.txt, or key.properties to git." -ForegroundColor Red
