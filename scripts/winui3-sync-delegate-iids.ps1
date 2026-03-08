param(
    [string]$RepoRoot = "",
    [string]$WinmdPath = "",
    [switch]$Check
)

$ErrorActionPreference = "Stop"

if (-not $RepoRoot) {
    $RepoRoot = Split-Path -Parent $PSScriptRoot
}

function Find-Winmd {
    $base = Join-Path $env:USERPROFILE ".nuget\packages\microsoft.windowsappsdk"
    if (-not (Test-Path -LiteralPath $base)) {
        throw "WindowsAppSDK package directory not found: $base"
    }
    $candidates = @(Get-ChildItem -LiteralPath $base -Directory |
        Sort-Object Name -Descending |
        ForEach-Object {
            Join-Path $_.FullName "lib\uap10.0\Microsoft.UI.Xaml.winmd"
        } |
        Where-Object { Test-Path -LiteralPath $_ })
    if (-not $candidates -or $candidates.Count -eq 0) {
        throw "Microsoft.UI.Xaml.winmd not found under $base"
    }
    return ($candidates | Select-Object -First 1)
}

if (-not $WinmdPath) {
    $WinmdPath = Find-Winmd
}
if (-not (Test-Path -LiteralPath $WinmdPath)) {
    throw "WinMD not found: $WinmdPath"
}

$toolDir = Join-Path (Split-Path -Parent $RepoRoot) "win-zig-bindgen"
$comPath = Join-Path $RepoRoot "src\sample-host\winui3\com.zig"
if (-not (Test-Path -LiteralPath $toolDir)) {
    Write-Host "winui3-sync-delegate-iids: SKIP (bindgen repo not found at $toolDir)"
    exit 0
}
if (-not (Test-Path -LiteralPath $comPath)) {
    throw "com.zig not found: $comPath"
}

$generatedPath = Join-Path ([System.IO.Path]::GetTempPath()) ("core-sync-iids-" + [System.Guid]::NewGuid().ToString("N") + ".zig")
Push-Location $toolDir
try {
    & zig build run -- --winmd $WinmdPath --deploy $generatedPath --iface ITabView
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to generate delegate IID constants from winmd2zig"
    }
}
finally {
    Pop-Location
}
if (-not (Test-Path -LiteralPath $generatedPath)) {
    throw "Generated file not found: $generatedPath"
}
$generated = Get-Content -LiteralPath $generatedPath
Remove-Item -LiteralPath $generatedPath -ErrorAction SilentlyContinue

$text = Get-Content -Raw -LiteralPath $comPath

function Normalize-GuidLine([string]$line) {
    return $line.Replace(".data1", ".Data1").Replace(".data2", ".Data2").Replace(".data3", ".Data3").Replace(".data4", ".Data4")
}

$map = @{
    "IID_TypedEventHandler_AddTabButtonClick" = Normalize-GuidLine (($generated | Select-String "IID_TypedEventHandler_AddTabButtonClick").Line)
    "IID_SelectionChangedEventHandler" = Normalize-GuidLine (($generated | Select-String "IID_SelectionChangedEventHandler").Line)
    "IID_TypedEventHandler_TabCloseRequested" = Normalize-GuidLine (($generated | Select-String "IID_TypedEventHandler_TabCloseRequested").Line)
}

foreach ($k in $map.Keys) {
    if (-not $map[$k]) {
        throw "Generated output missing constant: $k"
    }
}

function Replace-Const([string]$src, [string]$constName, [string]$newLine) {
    $pattern = "pub const $constName = GUID\{[\s\S]*?\};"
    return [regex]::Replace($src, $pattern, $newLine, [System.Text.RegularExpressions.RegexOptions]::Singleline)
}

$updated = $text
$updated = Replace-Const $updated "IID_TypedEventHandler_AddTabButtonClick" $map["IID_TypedEventHandler_AddTabButtonClick"]
$updated = Replace-Const $updated "IID_SelectionChangedEventHandler" $map["IID_SelectionChangedEventHandler"]
$updated = Replace-Const $updated "IID_TypedEventHandler_TabCloseRequested" $map["IID_TypedEventHandler_TabCloseRequested"]

if ($Check) {
    if ($updated -ne $text) {
        Write-Host "winui3-sync-delegate-iids: OUT-OF-DATE"
        exit 2
    }
    Write-Host "winui3-sync-delegate-iids: OK"
    exit 0
}

if ($updated -ne $text) {
    Set-Content -LiteralPath $comPath -Value $updated -Encoding UTF8
    Write-Host "Updated: $comPath"
} else {
    Write-Host "No changes: $comPath"
}
