$urls = @(
    "https://github.com/google/fonts/raw/main/ofl/notosanssc/static/NotoSansSC-Bold.ttf",
    "https://github.com/google/fonts/raw/main/ofl/notosansjp/static/NotoSansJP-Bold.ttf",
    "https://github.com/google/fonts/raw/main/ofl/notosanskr/static/NotoSansKR-Bold.ttf",
    "https://github.com/google/fonts/raw/main/ofl/notosanstc/static/NotoSansTC-Bold.ttf"
)

$destDir = Join-Path $PSScriptRoot "..\..\assets\fonts"

if (-not (Test-Path $destDir)) {
    New-Item -ItemType Directory -Force -Path $destDir
}

foreach ($url in $urls) {
    $filename = [System.IO.Path]::GetFileName($url)
    $destPath = Join-Path $destDir $filename
    Write-Host "Downloading $url to $destPath..."
    curl.exe -L -o $destPath $url
}
Write-Host "All CJK font downloads completed successfully!"
