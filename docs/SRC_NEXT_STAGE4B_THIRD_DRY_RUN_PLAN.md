# src_next Stage 4b Third Dry Run Plan

Status: docs-only dry run plan / no Stage 4b start / no implementation change / no production replacement / no production advice
Branch: `docs-src-next-stage4b-third-dry-run-plan`
Date: 2026-06-25

This document defines the plan for a third manual comparison dry run before deciding whether to open `src_next` Stage 4b daily-use trial.

Important:

- This plan does **not** start Stage 4b.
- This plan does **not** change production default.
- Production default remains `bqn main.bqn`.
- `src_next` remains observation-only.
- This plan does **not** introduce production advice.

---

## 1. Status

| Item | Status |
|:---|:---|
| Plan type | docs-only dry run plan |
| Stage 4b | not started |
| Implementation change | none |
| Production replacement | none |
| Production advice | none |
| Production default | unchanged: `bqn main.bqn` |
| `src_next` role | observation-only |

---

## 2. Purpose

This plan exists to:

- Define how to perform a third manual comparison dry run.
- Confirm that known expected differences remain stable.
- Confirm there are no `bug/src_next`, `unclassified`, or `requires-contract` results.
- Confirm unsupported / unavailable areas remain excluded from life decisions.
- Produce a private comparison log only.

The dry run is a comparison exercise, not a trial start.

---

## 3. Non-goals

This plan does not:

- Start Stage 4b.
- Replace the current engine.
- Change `bqn main.bqn` as production default.
- Edit production data.
- Modify `data/*.tsv`.
- Implement missing fields.
- Implement `safe_remaining`, `daily_amount`, outlook, envelope advice, budget advice, or production advice.
- Modify BQN implementation.
- Modify fixtures.
- Modify check scripts.
- Create production advice.
- Publish production data amounts.
- Commit private comparison logs.

---

## 4. Inputs

Use the following inputs:

| Input | Purpose |
|:---|:---|
| Current production data under `data/` | Read-only comparison input. Do not edit. |
| Current engine output from `bqn main.bqn --base data` | Production reference report. |
| Machine-readable current engine output from `export-report-numbers.bqn --base data` | Field extraction for comparison. Use the repo's documented path in commands. |
| `src_next` observation output from `tools/report-next-summary data` | Observation-only comparison target. |
| `docs/SRC_NEXT_MANUAL_COMPARISON_PROCEDURE.md` | Existing comparison procedure. |
| `docs/SRC_NEXT_COMPARISON_RECORD_TEMPLATE.md` | Existing comparison record template. |

Production data may be read by these commands, but must not be edited. Public docs and PR text must not include production data amounts.

---

## 5. Commands

Run commands in this order:

```sh
rtk bash tools/check.sh
bqn main.bqn --base data
bqn src/reports/exporters/export-report-numbers.bqn --base data
tools/report-next-summary data
```

Notes:

- `rtk bash tools/check.sh` must pass before interpreting dry run results.
- The current engine report from `bqn main.bqn --base data` remains the production reference.
- The exporter command uses the repo's existing documented path for `export-report-numbers.bqn`; the intent is machine-readable current engine output.
- `tools/report-next-summary data` is observation-only and must not be used as production advice.

---

## 6. Private log location

Use this private log path for the third dry run:

```text
private/src-next-comparison/third-manual-comparison-dry-run.md
```

Requirements:

- The log must remain private.
- The log must not be committed.
- The log may contain production-specific observations.
- Public docs may contain only public-safe summaries and no production amounts.
- If the private log is accidentally staged, stop and unstage it before continuing.

This plan defines the path only. It does not create or commit the private log.

---

## 7. Comparison areas

Use the existing 14-area structure from the refined manual comparison procedure:

| Area | Name | Third dry run handling |
|:---|:---|:---|
| Area 0 | as_of | Record both observation dates. Differences may explain derived mismatches. |
| Area 1 | cycle boundary | Compare cycle start / end / day count. |
| Area 2 | actual totals | Compare cycle income / expense / net actual totals. |
| Area 3 | account balances | Compare nonzero actual account totals. |
| Area 4a | plan totals baseline / cycle-bounded | Compare the half-open cycle subset `[cycle_start, cycle_end_exclusive)`. |
| Area 4b | plan totals export semantics | Record export / observation scope differences. |
| Area 5 | budget totals | Expected to remain `unsupported/src_next` unless implemented separately. |
| Area 6 | skipped rows | Expected to remain `unsupported/src_next` unless row model support changes. |
| Area 7 | valid rows | Expected to remain `unsupported/src_next` unless row model support changes. |
| Area 8 | unknown accounts | Compare unknown account count / list when surfaced. |
| Area 9 | envelope production guard | Confirm production data remains guarded and not used for advice. |
| Area 10 | next income | Compare next income date when surfaced by both outputs. |
| Area 11 | unavailable production advice fields | Confirm unavailable / out-of-scope advice fields remain excluded. |
| Area 12 | remaining days | Differences may be expected if derived from `as_of`. |
| Area 13 | actual_comparison | Expected to remain `unsupported/src_next` unless implemented separately. |

---

## 8. Expected classifications

Record expected handling as follows:

- `as_of` difference may be `expected/current-engine-difference`.
- `remaining_days` difference may be `expected/current-engine-difference` if derived from `as_of`.
- Plan boundary / export semantics difference may be `expected/current-engine-difference`.
- `cycle_end_exclusive` plan rows are excluded from `src_next` current cycle by half-open interval semantics.
- Budget totals should remain `unsupported/src_next` unless implemented separately.
- Skipped rows should remain `unsupported/src_next` unless row model support changes.
- Valid rows should remain `unsupported/src_next` unless row model support changes.
- `actual_comparison` should remain `unsupported/src_next` unless implemented separately.
- `net_worth`, `daily_remaining`, envelopes, `daily_amount`, `safe_remaining`, and outlook should remain unavailable or out of scope.
- No unsupported or unavailable field may be used for household decisions.

Do not force a mismatch into `expected/current-engine-difference` if the reason no longer matches the known classification.

---

## 9. Pass conditions

The third dry run passes if all of the following are true:

- `rtk bash tools/check.sh` passes.
- `bug/src_next = 0`.
- `bug/current-engine = 0`.
- `unclassified = 0`.
- `requires-contract = 0`.
- Known expected differences remain classified.
- Unsupported / unavailable areas remain excluded.
- No production data amounts are committed.
- Private log remains uncommitted.
- Working tree is clean after the public docs commit.

A passing third dry run still does not start Stage 4b. A separate explicit start decision is required.

---

## 10. Pause / fail conditions

Pause progress if any of the following occur:

- `bug/src_next` appears.
- `unclassified` difference appears.
- `requires-contract` appears.
- Any expected difference no longer fits its classification.
- Unsupported / unavailable output is used or nearly used for life decisions.
- `src_next` output is treated as production advice.
- `src_next` edits or appears to edit `data/*.tsv`.
- Private log is accidentally staged.
- Production data amounts appear in public docs.

If progress pauses, keep using the current engine (`bqn main.bqn`) as the production reference and resolve or reclassify the issue before considering Stage 4b.

---

## 11. Public-safe result summary template

After the third dry run is executed privately, a future public-safe summary may use this template.
Do not include production amounts.

```markdown
## Third dry run public-safe summary

Date:
Check result:
Private log:
Stage 4b started: no

| Classification | Count |
|:---|---:|
| match | |
| expected/current-engine-difference | |
| unsupported/src_next | |
| unavailable | |
| bug/src_next | 0 |
| bug/current-engine | 0 |
| unclassified | 0 |
| requires-contract | 0 |
| policy/not-engine | |

Notes:
- No production amounts are included.
- Private log remains uncommitted.
- Stage 4b remains deferred unless a separate start decision is created.
```

---

## 12. Relationship to pretrial backlog

This plan clarifies:

| Backlog item | Clarification |
|:---|:---|
| P1-2: Additional dry runs | A third manual comparison dry run is planned by this document. |
| P1-3: Third dry run procedure | The third dry run procedure is defined by this document and uses the existing manual comparison procedure and template. |

This plan does not by itself satisfy:

| Backlog item | Reason |
|:---|:---|
| P0-4: explicit start decision | This plan keeps the current decision as defer. |
| P0-5: trial log location for actual daily-use trial | The private dry run log path is not the Stage 4b daily-use trial log location. The future daily-use trial log path is defined separately in `docs/SRC_NEXT_STAGE4B_DAILY_USE_TRIAL_LOG_POLICY.md`. |
| P0-6: observation-only terms at trial start | Those terms must be restated in a separate start decision if Stage 4b is opened. |

---

## 13. Current decision

Current decision remains: **defer Stage 4b**.

- This plan does not start Stage 4b.
- A third dry run may be executed privately after this plan is merged.
- Any public result summary must be production-data-free.
- Stage 4b can only start through a separate explicit start decision.

---

## 14. Related documents

- [SRC_NEXT_STAGE4B_PRETRIAL_BACKLOG.md](SRC_NEXT_STAGE4B_PRETRIAL_BACKLOG.md)
- [SRC_NEXT_STAGE4B_DAILY_USE_TRIAL_LOG_POLICY.md](SRC_NEXT_STAGE4B_DAILY_USE_TRIAL_LOG_POLICY.md)
- [SRC_NEXT_STAGE4B_THIRD_DRY_RUN_SUMMARY.md](SRC_NEXT_STAGE4B_THIRD_DRY_RUN_SUMMARY.md)
- [SRC_NEXT_STAGE4B_ENTRY_DECISION_RECORD.md](SRC_NEXT_STAGE4B_ENTRY_DECISION_RECORD.md)
- [SRC_NEXT_STAGE4B_TRIAL_SCOPE.md](SRC_NEXT_STAGE4B_TRIAL_SCOPE.md)
- [SRC_NEXT_STAGE4B_READINESS_GATE.md](SRC_NEXT_STAGE4B_READINESS_GATE.md)
- [SRC_NEXT_MANUAL_COMPARISON_PROCEDURE.md](SRC_NEXT_MANUAL_COMPARISON_PROCEDURE.md)
- [SRC_NEXT_COMPARISON_RECORD_TEMPLATE.md](SRC_NEXT_COMPARISON_RECORD_TEMPLATE.md)
- [SRC_NEXT_SNAPSHOT_EQUIVALENCE_CRITERIA.md](SRC_NEXT_SNAPSHOT_EQUIVALENCE_CRITERIA.md)
