param(
    [string]$ExePath = "C:\Users\yuuji\ghostty-win\zig-out\bin\ghostty.exe",
    [int]$WaitSeconds = 8
)

$ErrorActionPreference = "Stop"

function Run-Case {
    param(
        [string]$Name,
        [hashtable]$Env
    )

    Write-Host "=== CASE: $Name ==="
    $proc = Start-Process -FilePath $ExePath -PassThru -WindowStyle Hidden -Environment $Env
    Start-Sleep -Seconds $WaitSeconds

    $result = [ordered]@{
        case = $Name
        pid = $proc.Id
        alive_after_wait = -not $proc.HasExited
        exit_code = if ($proc.HasExited) { $proc.ExitCode } else { $null }
    }

    if (-not $proc.HasExited) {
        Stop-Process -Id $proc.Id -Force
    }

    [pscustomobject]$result
}

$baseEnv = @{
    "GHOSTTY_WINUI3_ENABLE_TABVIEW" = "1"
    "GHOSTTY_WINUI3_ENABLE_XAML_RESOURCES" = "1"
    "GHOSTTY_WINUI3_ENABLE_TABVIEW_HANDLERS" = "1"
    "GHOSTTY_WINUI3_TABVIEW_EMPTY" = "0"
    "GHOSTTY_WINUI3_TABVIEW_ITEM_NO_CONTENT" = "0"
    "GHOSTTY_WINUI3_TABVIEW_APPEND_ITEM" = "1"
    "GHOSTTY_WINUI3_TABVIEW_SELECT_FIRST" = "1"
}

$cases = @(
    @{ name = "baseline"; env = $baseEnv },
    @{ name = "tabview_off"; env = $baseEnv.Clone(); patch = @{ "GHOSTTY_WINUI3_ENABLE_TABVIEW" = "0" } },
    @{ name = "handlers_off"; env = $baseEnv.Clone(); patch = @{ "GHOSTTY_WINUI3_ENABLE_TABVIEW_HANDLERS" = "0" } },
    @{ name = "empty_tabview"; env = $baseEnv.Clone(); patch = @{ "GHOSTTY_WINUI3_TABVIEW_EMPTY" = "1" } },
    @{ name = "item_no_content"; env = $baseEnv.Clone(); patch = @{ "GHOSTTY_WINUI3_TABVIEW_ITEM_NO_CONTENT" = "1" } },
    @{ name = "no_append"; env = $baseEnv.Clone(); patch = @{ "GHOSTTY_WINUI3_TABVIEW_APPEND_ITEM" = "0" } },
    @{ name = "no_select"; env = $baseEnv.Clone(); patch = @{ "GHOSTTY_WINUI3_TABVIEW_SELECT_FIRST" = "0" } }
)

$rows = @()
foreach ($case in $cases) {
    if ($case.patch) {
        foreach ($k in $case.patch.Keys) {
            $case.env[$k] = $case.patch[$k]
        }
    }
    $rows += Run-Case -Name $case.name -Env $case.env
}

$rows | Format-Table -AutoSize
