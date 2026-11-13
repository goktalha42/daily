param(
    [Parameter(Mandatory = $true)]
    [string]$Version,

    [Parameter(Mandatory = $true)]
    [int]$BuildNumber,

    [Parameter(Mandatory = $false)]
    [string]$Title = "Zühtü v$Version Güncellemesi",

    [Parameter(Mandatory = $true)]
    [string]$Changelog,

    [Parameter(Mandatory = $false)]
    [bool]$ForceUpdate = $false
)

$ErrorActionPreference = "Stop"
$apkFile = "Zuhtu_v${Version}_b${BuildNumber}.apk"

Write-Host "1/5 pubspec.yaml ve version.json güncelleniyor (v$Version+$BuildNumber)..." -ForegroundColor Cyan
(Get-Content pubspec.yaml) -replace '^version:\s*.*$', "version: $Version+$BuildNumber" | Set-Content pubspec.yaml -Encoding UTF8

$versionJson = [ordered]@{
    version      = $Version
    build_number = $BuildNumber
    title        = $Title
    changelog    = $Changelog
    apk_url      = "https://raw.githubusercontent.com/goktalha42/daily/main/releases/$apkFile"
    release_url  = "https://github.com/goktalha42/daily/releases/tag/v$Version"
    force_update = $ForceUpdate
}
$jsonStr = $versionJson | ConvertTo-Json -Depth 4
[System.IO.File]::WriteAllText("$PSScriptRoot\version.json", $jsonStr, [System.Text.UTF8Encoding]::new($false))

Write-Host "2/5 İmzalı mobil ARM APK derleniyor (ortak zuhtu_keystore.jks)..." -ForegroundColor Cyan
flutter build apk --release --target-platform android-arm,android-arm64 --build-name=$Version --build-number=$BuildNumber

Write-Host "3/5 Eski release APK dosyaları temizlenip yeni sürüm kopyalanıyor..." -ForegroundColor Cyan
New-Item -ItemType Directory -Force -Path releases | Out-Null
Get-ChildItem -Path releases -Filter "*.apk" -ErrorAction SilentlyContinue | Remove-Item -Force
Copy-Item "build\app\outputs\flutter-apk\app-release.apk" "Zuhtu_v$Version.apk" -Force
Copy-Item "build\app\outputs\flutter-apk\app-release.apk" "releases\$apkFile" -Force

Write-Host "4/5 Graphify bilgi grafiği güncelleniyor..." -ForegroundColor Cyan
graphify update .

Write-Host "5/5 GitHub'a gönderiliyor (anlık uygulama içi OTA aktifleşiyor)..." -ForegroundColor Cyan
git add -A
git commit -m "release(v$Version): publish OTA build $Version+$BuildNumber"
git tag -f "v$Version"
git push origin main
git push origin "refs/tags/v$Version" --force

Write-Host "Tamamlandı! Zühtü v$Version+$BuildNumber uygulama içinden doğrudan çekilebilir." -ForegroundColor Green
