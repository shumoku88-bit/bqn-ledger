# Shellcheck Warning Inventory 2026-06-29

Status: inventory / audit-only
Date: 2026-06-29

## Purpose

This document provides a baseline inventory of `shellcheck` warnings across Bash helper scripts and checks in the repository.
In accordance with `PUBLIC_PRODUCTIZATION_REVIEW_FILTER.md`, we inventory current warnings before deciding which to fix, suppress, or ignore. We do not enforce `shellcheck` in CI yet to avoid mechanical rewrites that distract from canonical engine safety.

## Scope Checked

Scripts in `tools/` and `checks/` matched by `*.sh` and known executable files (`bl`, `report`, `query`, etc.).

Command used:
```bash
shellcheck ./tools/*.sh ./tools/bl ./tools/report ./tools/query ./tools/bqn-dump ./tools/bqn-eval ./tools/repo-index ./tools/lib/*.sh ./checks/*.sh
```

## Inventory

Total warnings found: 17 occurrences across 5 warning types.

| Warning Code | Type | Occurrences | Locations | Notes / Action Plan |
|---|---|---|---|---|
| **SC2034** | Unused variable | 3 | `tools/bl`, `tools/devtools-check.sh`, `tools/add-ui.sh` | Low priority. Can be safely removed or kept if intended for future use. |
| **SC2059** | Printf format string contains variables | 2 | `tools/bl` | Low priority. Fix: use `printf "%b" "${COLOR_OK}..."` or `printf "%s\n"`. |
| **SC1091** | Not following sourced file | 1 | `tools/lib/system-defaults.sh` (`source ".env"`) | False positive/Intended. Shellcheck cannot follow missing or dynamic `.env` files. Fix: add `# shellcheck disable=SC1091`. |
| **SC2016** | Expressions don't expand in single quotes | 1 | `checks/check-report-labels.sh` | False positive. The perl script uses `$ARGV` and `$1`. Bash variable expansion is correctly prevented. Fix: add `# shellcheck disable=SC2016`. |
| **SC2329** | Function never invoked | 10 | `checks/check-src-next-cycle-summary.sh`, `checks/check-src-next-ytd-summary.sh`, `checks/check-src-next-envelope-production-guard.sh`, `checks/check-src-next-budget-actual-zero.sh` | Low priority. Leftover boilerplate functions from other checks. Can be removed. |

## Next Steps

1. This is a read-only inventory (no files were changed).
2. In a future batch (e.g., a "Shellcheck Hygiene" task), apply targeted fixes and `# shellcheck disable` annotations.
3. Only after the codebase is intentionally warning-free, add a `shellcheck` pass to `tools/devtools-check.sh` or `tools/check.sh`.
