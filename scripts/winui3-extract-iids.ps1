param(
    [string]$LogPath = "",
    [string]$OutJson = ""
)

$ErrorActionPreference = "Stop"
if (-not $LogPath) {
    $repo = Split-Path -Parent $PSScriptRoot
    $LogPath = Join-Path $repo "debug.log"
}
if (-not $OutJson) {
    $repo = Split-Path -Parent $PSScriptRoot
    $OutJson = Join-Path $repo "tmp\winui3-iids.json"
}

if (-not (Test-Path -LiteralPath $LogPath)) {
    throw "Log not found: $LogPath"
}

$content = Get-Content -Path $LogPath

$unknown = @{}
$outer = @{}

foreach ($line in $content) {
    if ($line -match "eventHandler QI: unknown iid=\{([0-9a-fA-F\-]+)\}") {
        $id = $matches[1].ToLowerInvariant()
        if (-not $unknown.ContainsKey($id)) { $unknown[$id] = 0 }
        $unknown[$id]++
    }
    if ($line -match "outerQI: iid=\{([0-9a-fA-F\-]+)\}") {
        $id = $matches[1].ToLowerInvariant()
        if (-not $outer.ContainsKey($id)) { $outer[$id] = 0 }
        $outer[$id]++
    }
}

$result = [pscustomobject]@{
    source_log = $LogPath
    unknown_iids = $unknown.GetEnumerator() | Sort-Object Name | ForEach-Object {
        [pscustomobject]@{ iid = $_.Name; count = $_.Value }
    }
    outer_qi_iids = $outer.GetEnumerator() | Sort-Object Name | ForEach-Object {
        [pscustomobject]@{ iid = $_.Name; count = $_.Value }
    }
}

$outDir = Split-Path -Parent $OutJson
if ($outDir -and -not (Test-Path -LiteralPath $outDir)) {
    New-Item -ItemType Directory -Path $outDir -Force | Out-Null
}

$result | ConvertTo-Json -Depth 5 | Set-Content -Path $OutJson -Encoding UTF8
Write-Host "Extracted IID summary: $OutJson"
