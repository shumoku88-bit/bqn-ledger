# Safety / Docs Alignment Plan 2026-06-29

Status: active / small-batch plan
Date: 2026-06-29

## Purpose

Avoid ad-hoc cleanup while continuing the current `safety / docs hygiene` thread.

This plan batches only small consistency fixes that reduce false confidence or stale navigation.  It does not change report numbers, source TSVs, or the Go editor write boundary.

## Scope

Allowed:

- Fix broken current-doc links.
- Add small current stubs when active docs still reference an archived concept.
- Clarify whether a document is current policy, active plan, compatibility debt, or historical evidence.
- Update `TODO.md` with the current batch boundary.
- Run the standard checks after changes.

Not allowed in this batch:

- Editing real source TSVs (`journal.tsv`, `plan.tsv`, `budget_alloc.tsv`, `accounts.tsv`).
- Creating new configuration TSVs such as `report_sections.tsv`, `account_display.tsv`, or `envelope_targets.tsv`.
- Removing prefix fallback from multiple report modules at once.
- Changing report numbers without a fixture/golden explanation.
- Reviving old-engine contracts as current behavior.

## Work queue

### Batch A: current-doc link integrity ✅ done 2026-06-29

Problem: `docs/SAFETY_PROFILE.md` and active section-status policy docs still mention `docs/REPORT_CONTRACTS.md`, but the only existing file was archived under `docs/archive/completed-plans/REPORT_CONTRACTS.md`.

Result: added `docs/REPORT_CONTRACTS.md` as a current index/boundary note, and linked it from `docs/README.md`.

Action:

1. Add a small current `docs/REPORT_CONTRACTS.md` index/stub.
2. Make it point to current sources of truth:
   - `tools/report --list-sections`
   - `src_next/report.bqn`
   - `src_next/summary.bqn`
   - `docs/archive/active-plans/REPORT_SECTION_STATUS_POLICY.md`
   - historical `docs/archive/completed-plans/REPORT_CONTRACTS.md`
3. Do not copy old-engine contract text back as current spec.

Acceptance:

- `rg "docs/REPORT_CONTRACTS.md" docs README.md AGENTS.md TODO.md` points to an existing current file.
- The new file clearly says it is an index/current boundary note, not a full old-engine contract revival.

### Batch B: residual prefix fallback debt inventory ✅ done 2026-06-29

Problem: `REPORT_ASSUMPTION_AUDIT.md` identifies residual prefix fallback in report modules as compatibility debt, but removal should not be ad-hoc.

Result: added `docs/archive/audits/PREFIX_FALLBACK_DEBT_INVENTORY-2026-06-29.md`. First cleanup candidate was `src_next/balances.bqn` display grouping fallback.

Action:

1. List current `src_next` prefix compatibility sites by module.
2. Pick at most one module for a future code cleanup.
3. Before code changes, identify the fixture/check that proves no output drift.

Acceptance:

- A small table records: module, fallback type, current guard, safe next step.
- If no safe single-module cleanup is obvious, stop at inventory.

### Batch D: first single-module fallback cleanup ✅ done 2026-06-29

Problem: `src_next/balances.bqn` used account-name prefixes to group balances when `role=` metadata was missing.

Action:

1. Remove prefix-based role inference from `src_next/balances.bqn` only.
2. Missing role now stays `unknown` for balances grouping instead of being silently grouped by `assets:` / `income:` / `expenses:` / `budget:` prefix.
3. Update `tests/test_src_next_balances.bqn` to assert both explicit-role behavior and missing-role non-inference.

Acceptance:

- `bqn tests/test_src_next_balances.bqn` passes.
- `checks/check-src-next-balances.sh fixtures/src-next-golden` passes.
- `checks/check-missing-role-fallback.sh` remains the fallback detector and passes.
- Full `rtk bash ./tools/check.sh` passes before handoff.

### Batch C: safety invariant stale-reference cleanup ✅ done 2026-06-29

Problem: current safety docs may still mention non-current or missing guard names.

Result: refreshed current docs that pointed to missing or archived paths without clear status:

- `docs/PLAN_ID_LIFECYCLE.md`: old `report_engine.bqn` wording → current `src_next/planned_payments.bqn` / `src_next/plan_journal_overlap.bqn` boundary.
- `docs/TIME_AS_AXIS.md`: archived related-doc paths, removed missing `AS_OF_SECTION_AUDIT.md` current reference, and replaced old `report_engine.BuildAt` wording with current `src_next`/check boundary.
- `docs/SAFETY_PROFILE.md`: missing Go/safe workflow links → current `GO_EDITOR_USAGE.md` plus archive paths.
- `docs/JOURNAL_META.md`: removed stale `tools/txn.bqn` / `tools/add.bqn` references; documented `tools/edit --meta` path.
- `docs/CONVENTIONS.md`: stale `tools/lint.bqn`, `tools/summary.bqn`, and `core.InitAccounts` references → current `src_next` readiness/lint/summary boundaries.
- `docs/SAFETY_PROFILE_INVARIANT_MAP.md` and `TODO.md`: missing active Go/editor doc paths → archive/current paths.

Action:

1. Search current docs for missing current-doc paths and old-engine guard names.
2. Fix only direct stale current-path references.
3. Leave historical archive docs unchanged unless they are linked as current.

Acceptance:

- Current docs do not direct pit to missing files.
- Historical docs remain clearly historical.

## Completion check

Run:

```bash
rtk bash ./tools/check.sh
```

If new files are added and `devtools-check.sh` reports repo-index drift, run:

```bash
tools/repo-index --baseline
rtk bash ./tools/check.sh
```
