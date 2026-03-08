# Non-Negotiables

These rules are mandatory for `win-zig-core`.

## Acceptance

- `pwsh -File .\scripts\winui3-verify-all.ps1` is the acceptance SSOT.
- Do not mark cross-repo work complete unless `winui3-verify-all.ps1` passes.

## Script Discipline

- Keep script commands synchronized with current CLI flags and file paths.
- Remove stale steps instead of documenting them as optional if they are no longer valid.
- Do not hide failing downstream checks behind `exit 0` or no-op placeholders.

## Ownership

- `scripts/winui3-verify-all.ps1` has a single driver during a task.
- If a fix belongs in another repo, fix that repo instead of normalizing the failure away here.

## Hygiene

- Fork-only GitHub operations.
- No stale README verification order.
