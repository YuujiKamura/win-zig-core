param(
    [string]$CoreRoot = "",
    [string]$GhosttyRoot = "",
    [string]$BindgenRoot = "",
    [string]$MetadataRoot = "",
    [switch]$BuildGhostty,
    [switch]$WithReference
)

$ErrorActionPreference = "Stop"

if (-not $CoreRoot) {
    $CoreRoot = Split-Path -Parent $PSScriptRoot
}

$workspaceRoot = Split-Path -Parent $CoreRoot
if (-not $GhosttyRoot) { $GhosttyRoot = Join-Path $workspaceRoot "ghostty-win" }
if (-not $BindgenRoot) { $BindgenRoot = Join-Path $workspaceRoot "win-zig-bindgen" }
if (-not $MetadataRoot) { $MetadataRoot = Join-Path $workspaceRoot "win-zig-metadata" }

foreach ($p in @($CoreRoot, $GhosttyRoot, $BindgenRoot, $MetadataRoot)) {
    if (-not (Test-Path -LiteralPath $p)) {
        throw "Required path not found: $p"
    }
}

function Run-ZigTest([string]$repoPath) {
    Push-Location $repoPath
    try {
        Write-Host "[TEST] zig build test @ $repoPath"
        zig build test
        if ($LASTEXITCODE -ne 0) {
            throw "zig build test failed at: $repoPath"
        }
    }
    finally {
        Pop-Location
    }
}

Run-ZigTest $MetadataRoot
Run-ZigTest $BindgenRoot
Run-ZigTest $CoreRoot

$ghosttyCom = Join-Path $GhosttyRoot "src\apprt\winui3\com.zig"

Write-Host "[CHECK] win-zig-bindgen delegate IID sync (ghostty target)"
pwsh -File (Join-Path $BindgenRoot "scripts\winui3-sync-delegate-iids.ps1") `
    -Check `
    -RepoRoot $GhosttyRoot `
    -ToolDir $BindgenRoot `
    -ComPath $ghosttyCom
if ($LASTEXITCODE -ne 0) {
    throw "bindgen sync check failed"
}

Write-Host "[CHECK] ghostty delegate IID check"
pwsh -File (Join-Path $GhosttyRoot "scripts\winui3-delegate-iid-check.ps1") -RepoRoot $GhosttyRoot
if ($LASTEXITCODE -ne 0) {
    throw "ghostty delegate IID check failed"
}

Write-Host "[CHECK] ghostty inspect-event-params smoke"
pwsh -File (Join-Path $GhosttyRoot "scripts\winui3-inspect-event-params.ps1") `
    -RepoRoot $GhosttyRoot `
    -ToolDir $BindgenRoot
if ($LASTEXITCODE -ne 0) {
    throw "ghostty inspect-event-params failed"
}

$contractArgs = @("-RepoRoot", $CoreRoot, "-BuildRoot", $GhosttyRoot, "-SkipExtractIids")
if ($BuildGhostty) { $contractArgs += "-Build" }
if (-not $WithReference) { $contractArgs += "-SkipReference" }

Write-Host "[CHECK] win-zig-core contract-run"
pwsh -File (Join-Path $CoreRoot "scripts\winui3-contract-run.ps1") @contractArgs
if ($LASTEXITCODE -ne 0) {
    throw "win-zig-core contract-run failed"
}

Write-Host "[DONE] winui3-verify-all succeeded"
