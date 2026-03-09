param(
    [string]$GhosttyRoot = "",
    [string]$BindgenRoot = "",
    [string]$ManifestPath = ""
)

$ErrorActionPreference = "Stop"

if (-not $GhosttyRoot) {
    $GhosttyRoot = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) "ghostty-win"
}
if (-not $BindgenRoot) {
    $BindgenRoot = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) "win-zig-bindgen"
}
if (-not $ManifestPath) {
    $ManifestPath = Join-Path $BindgenRoot "winui_native_exceptions.json"
}

$comNative = Join-Path $GhosttyRoot "src\apprt\winui3\com_native.zig"
$comGenerated = Join-Path $GhosttyRoot "src\apprt\winui3\com_generated.zig"

foreach ($p in @($comNative, $comGenerated, $ManifestPath)) {
    if (-not (Test-Path -LiteralPath $p)) {
        throw "Required file not found: $p"
    }
}

$manifest = Get-Content -Raw -Path $ManifestPath | ConvertFrom-Json
$pass = 0
$fail = 0

function Check {
    param([string]$Name, [bool]$Ok, [string]$Detail)
    if ($Ok) {
        Write-Host "[PASS] $Name - $Detail"
        $script:pass++
    } else {
        Write-Host "[FAIL] $Name - $Detail" -ForegroundColor Red
        $script:fail++
    }
}

# 1. com_generated.zig must import from winrt.zig (proof of --winrt-import)
$genContent = Get-Content -Raw -Path $comGenerated
$hasWinrtImport = $genContent -match 'const winrt = @import\("winrt\.zig"\)'
Check "winrt-import" $hasWinrtImport "com_generated.zig imports GUID/HRESULT from winrt.zig"

# 2. com_generated.zig must NOT define its own GUID struct
$hasOwnGuid = $genContent -match 'pub const GUID = extern struct \{[\s\S]*?data1'
$guidReexport = $genContent -match 'pub const GUID = winrt\.GUID'
Check "no-own-GUID" (-not $hasOwnGuid -and $guidReexport) "GUID is re-exported, not redefined"

# 3. com_native.zig types must all be in the exception manifest
$nativeContent = Get-Content -Raw -Path $comNative
# Match only top-level pub const (not indented VTable structs)
$nativeTypes = [regex]::Matches($nativeContent, '(?m)^pub const (\w+)\s*=\s*extern struct') |
    ForEach-Object { $_.Groups[1].Value }
# Also capture IID constants
$nativeIIDs = [regex]::Matches($nativeContent, 'pub const (IID_\w+)\s*=') |
    ForEach-Object { $_.Groups[1].Value }

$manifestNames = @{}
foreach ($t in $manifest.types) {
    $manifestNames[$t.name] = $t.category
}
# IID_CharacterReceivedHandler is implicitly allowed (pinterface computation)
$manifestNames["IID_CharacterReceivedHandler"] = "pinterface"

foreach ($typeName in $nativeTypes) {
    $inManifest = $manifestNames.ContainsKey($typeName)
    Check "native-type-$typeName" $inManifest "com_native.zig type '$typeName' is in exception manifest"
}

foreach ($iidName in $nativeIIDs) {
    $inManifest = $manifestNames.ContainsKey($iidName)
    Check "native-iid-$iidName" $inManifest "com_native.zig IID '$iidName' is in exception manifest"
}

# 4. No consumer_alias types in active manifest
$activeAliases = $manifest.types | Where-Object { $_.category -eq "consumer_alias" }
$noAliases = ($activeAliases | Measure-Object).Count -eq 0
Check "no-consumer-alias" $noAliases "No consumer_alias entries in active manifest types"

# 5. No stale rescue types in com_native.zig (types that ARE in com_generated.zig)
foreach ($typeName in $nativeTypes) {
    $inGenerated = $genContent -match "pub const $typeName\s*=\s*extern struct"
    $isOk = -not $inGenerated
    Check "not-duplicated-$typeName" $isOk "com_native.zig '$typeName' is not also in com_generated.zig"
}

Write-Host ""
Write-Host "OVERALL: pass=$pass fail=$fail"
if ($fail -gt 0) { exit 1 }
