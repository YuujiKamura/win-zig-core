# AGENTS.md

## Project Scope

`win-zig-core` is the WinRT/COM runtime and cross-repo acceptance orchestrator for the WinUI3 stack.

Read [NON-NEGOTIABLES.md](C:\Users\yuuji\win-zig-core\NON-NEGOTIABLES.md) first.

## Primary Commands

- Runtime tests: `zig build test`
- Full acceptance: `pwsh -File .\scripts\winui3-verify-all.ps1`
- Contract run only: `pwsh -File .\scripts\winui3-contract-run.ps1 -SkipReference -SkipExtractIids`

## Role In The Stack

- `win-zig-metadata`: parser truth
- `win-zig-bindgen`: generator truth
- `ghostty-win`: consumer/build truth
- `win-zig-core`: cross-repo acceptance truth

`winui3-verify-all.ps1` is the SSOT acceptance command for the workspace.

## Workstreams

| Area | Owner | Typical Files |
|------|-------|---------------|
| Runtime | one agent | `src/runtime/` |
| Sample host | one agent | `src/sample-host/winui3/` |
| Acceptance scripts | one agent | `scripts/winui3-*.ps1`, `README.md` |

## Operating Rules

1. Do not patch around downstream breakage in this repo if the source of truth belongs in `win-zig-bindgen` or `ghostty-win`.
2. Keep `winui3-verify-all.ps1` aligned with current repo layout and current CLI contracts.
3. If a check is deprecated, remove it from the orchestrator instead of leaving a dead step in the documented flow.

## GitHub Policy

- Create issues/PRs on fork repos only unless the user explicitly says otherwise.
