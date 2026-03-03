param(
    [string]$RepoRoot = "",
    [string]$BuildRoot = "",
    [switch]$Build,
    [switch]$Fix
)

$ErrorActionPreference = "Stop"
$repo = if ($RepoRoot) { $RepoRoot } else { Split-Path -Parent $PSScriptRoot }
if (-not $BuildRoot) { $BuildRoot = $repo }

if ($Build) {
    Push-Location $BuildRoot
    try {
        zig build -Dapp-runtime=winui3 -Drenderer=d3d11 | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw "Build failed (exit code $LASTEXITCODE) at BuildRoot=$BuildRoot"
        }
    }
    finally {
        Pop-Location
    }
}

$fixExit = 0
if ($Fix) {
    pwsh -File "$repo\scripts\winui3-contract-fix.ps1"
    $fixExit = $LASTEXITCODE
    if ($fixExit -ne 0) { exit $fixExit }
}

$checkArgs = @()
if ($Build) { $checkArgs += "-Build" }
if ($BuildRoot) { $checkArgs += @("-BuildRoot", $BuildRoot) }
pwsh -File "$repo\scripts\winui3-contract-check.ps1" @checkArgs
$checkExit = $LASTEXITCODE
pwsh -File "$repo\scripts\winui3-delegate-iid-check.ps1" -RepoRoot $repo
$iidExit = $LASTEXITCODE
pwsh -File "$repo\scripts\winui3-extract-iids.ps1" 2>$null
if ($checkExit -ne 0) { exit $checkExit }
if ($iidExit -ne 0) { exit $iidExit }
