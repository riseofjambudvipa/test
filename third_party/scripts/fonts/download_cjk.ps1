$ErrorActionPreference = "Stop"

$urls = @(
    "https://github.com/google/fonts/raw/main/ofl/notosanssc/static/NotoSansSC-Bold.ttf",
    "https://github.com/google/fonts/raw/main/ofl/notosansjp/static/NotoSansJP-Bold.ttf",
    "https://github.com/google/fonts/raw/main/ofl/notosanskr/static/NotoSansKR-Bold.ttf",
    "https://github.com/google/fonts/raw/main/ofl/notosanstc/static/NotoSansTC-Bold.ttf"
)

$destDir = Join-Path $PSScriptRoot "..\..\..\assets\fonts"

if (-not (Test-Path $destDir)) {
    New-Item -ItemType Directory -Force -Path $destDir
}

foreach ($url in $urls) {
    $filename = [System.IO.Path]::GetFileName($url)
    $destPath = Join-Path $destDir $filename
    Write-Host "Downloading $url to $destPath..."
    curl.exe -L -o $destPath $url
    if ($LASTEXITCODE -ne 0) {
        Write-Error "curl failed with exit code $LASTEXITCODE downloading $url"
    }
    if (Test-Path $destPath) {
        $size = (Get-Item $destPath).Length
        Write-Host "File size: $($size) bytes"
        if ($size -lt 1024) {
            Write-Error "Download failed or file too small: $destPath"
        }
    } else {
        Write-Error "File not found after download: $destPath"
    }
}
Write-Host "All CJK font downloads completed successfully!"
