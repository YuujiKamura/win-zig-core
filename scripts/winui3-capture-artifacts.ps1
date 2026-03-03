param(
    [Parameter(Mandatory = $true)]
    [string]$Root,
    [Parameter(Mandatory = $true)]
    [string]$OutFile
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $Root)) {
    throw "Root not found: $Root"
}

$rootFull = (Resolve-Path -LiteralPath $Root).Path
$outDir = Split-Path -Parent $OutFile
if ($outDir -and -not (Test-Path -LiteralPath $outDir)) {
    New-Item -ItemType Directory -Path $outDir -Force | Out-Null
}

# WinUI bootstrap artifacts and generated XAML/runtime assets.
$include = @(
    "*.pri",
    "*.xbf",
    "*.xaml",
    "*.dll",
    "*.winmd",
    "*.exe",
    "*.manifest",
    "*.json"
)

$all = @()
foreach ($pattern in $include) {
    $all += Get-ChildItem -Path $rootFull -Recurse -File -Filter $pattern -ErrorAction SilentlyContinue
}

$rows = $all | Sort-Object FullName -Unique | ForEach-Object {
    $rel = $_.FullName.Substring($rootFull.Length).TrimStart('\')
    [pscustomobject]@{
        RelativePath   = $rel
        Extension      = $_.Extension.ToLowerInvariant()
        Size           = $_.Length
        LastWriteTime  = $_.LastWriteTimeUtc.ToString("o")
    }
}

$rows | ConvertTo-Json -Depth 4 | Set-Content -Path $OutFile -Encoding UTF8
Write-Host "Captured $($rows.Count) artifacts from $rootFull"
Write-Host "Output: $OutFile"
