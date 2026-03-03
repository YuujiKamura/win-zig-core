# win-zig-core

`win-zig-core` is the WinRT/COM runtime wiring layer for Zig.

## Current Scope (snapshot)

- Delegate runtime ABI (`src/winui3/delegate_runtime.zig`)
- COM runtime helpers (`src/winui3/com_runtime.zig`)
- Marshaler runtime (`src/winui3/marshaler_runtime.zig`)
- WinUI3 host integration snapshot (`src/winui3/App.zig`, related files)
- Contract/smoke scripts (`scripts/winui3-*.ps1`)

## Validation

- `scripts/winui3-test.ps1`
- `scripts/winui3-contract-run.ps1`

## Migration note

Source snapshot copied from `ghostty-win` commit `fe9218c`.
