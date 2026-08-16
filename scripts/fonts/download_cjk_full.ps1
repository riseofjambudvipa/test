$downloads = @(
    @{
        url = "https://github.com/notofonts/noto-cjk/raw/main/Sans/OTF/SimplifiedChinese/NotoSansCJKsc-Bold.otf"
        dest = "NotoSansSC-Bold.ttf"
    },
    @{
        url = "https://github.com/notofonts/noto-cjk/raw/main/Sans/OTF/Japanese/NotoSansCJKjp-Bold.otf"
        dest = "NotoSansJP-Bold.ttf"
    },
    @{
        url = "https://github.com/notofonts/noto-cjk/raw/main/Sans/OTF/Korean/NotoSansCJKkr-Bold.otf"
        dest = "NotoSansKR-Bold.ttf"
    },
    @{
        url = "https://github.com/notofonts/noto-cjk/raw/main/Sans/OTF/TraditionalChinese/NotoSansCJKtc-Bold.otf"
        dest = "NotoSansTC-Bold.ttf"
    }
)

$destDir = Join-Path $PSScriptRoot "..\..\assets\fonts"

if (-not (Test-Path $destDir)) {
    New-Item -ItemType Directory -Force -Path $destDir
}

# Clean up any previously failed/incorrect files first
foreach ($item in $downloads) {
    $filePath = Join-Path $destDir $item.dest
    if (Test-Path $filePath) {
        Remove-Item $filePath -Force
    }
}

# Download full CJK fonts
foreach ($item in $downloads) {
    $destPath = Join-Path $destDir $item.dest
    Write-Host "Downloading $($item.url) to $destPath..."
    curl.exe -L -o $destPath $item.url
    
    # Check downloaded size to ensure it's not a tiny HTML 404 page
    if (Test-Path $destPath) {
        $size = (Get-Item $destPath).Length
        Write-Host "File size: $($size) bytes"
        if ($size -lt 500000) {
            Write-Error "Download failed or file too small: $destPath"
        }
    } else {
        Write-Error "File not found after download: $destPath"
    }
}

Write-Host "All full CJK fonts downloaded successfully!"
