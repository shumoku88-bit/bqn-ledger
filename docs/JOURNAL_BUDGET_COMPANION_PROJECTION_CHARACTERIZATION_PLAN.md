# Journal budget companion projection characterization — finite plan

Status: selected finite characterization plan
Owner: journal source migration
Canonical: no; canonical routing remains TODO.md
Exit: focused public-synthetic implementation, review, completion record, and return to no selected finite Journal slice
Date: 2026-07-22

## Purpose

Define a test-only characterization plan to project persisted Journal actual purchase events and their associated balanced budget companion events through Stage 1 Transaction IR and Stage 2A Posting IR into TBDS period views (`context.BuildPeriodView`).

This characterization proves that budget-layer virtual account movements can be observed separately from actual-layer money movements without altering actual-layer amounts, mutating production routing, or changing TBDS/Cube shapes.

## Finite question

> 保存済みのbalanced budget-layer companion eventを、既存のJournal parser、Posting IR、CubeまたはTBDSの境界へtest-onlyで投影し、actual-layerの金額を変えずにbudget-layerの仮想口座移動だけを観察できるか。

## Current evidence

This plan builds directly on PR #311 evidence:

- `fixtures/journal-resolved-envelope-assignment-persistence/` (`defaults-v1.journal`, `defaults-v2.journal`, `persisted-events.journal`)
- `tests/test_journal_resolved_envelope_assignment_persistence.bqn`
- `src_next/journal_profile_stage1.bqn`
- `src_next/journal_posting_ir_stage2a.bqn`
- `src_next/journal_read_only_source_carrier.bqn`
- `docs/archive/completed-plans/JOURNAL_RESOLVED_ENVELOPE_ASSIGNMENT_PERSISTENCE_PLAN-2026-07-22.md`

## Selected projection path

```text
persisted Journal events
  -> Stage 1 Transaction IR
  -> Stage 2A checked Posting IR (via journal_read_only_source_carrier)
  -> BuildPeriodView (src_next/context.bqn)
  -> TBDS layer-filtered views (src_next/tbds.bqn)
  -> separately observable actual and budget layers
```

## Why TBDS was selected

TBDS (Trial Balance Data Set) was selected over raw Cube coordinates for the focused characterization based on the following evaluation:

1. **Direct API reuse**: `context.BuildPeriodView` produces `tbds` (via `tbds.Build ⟨postingRows, cubeResult, resolved, cy⟩`) using existing pure modules without modification.
2. **Built-in layer separation**: `tbds.bqn` natively maintains 4 layer slots (`actual=0`, `plan=1`, `budget=2`, `forecast=3`) and exposes `tbds.RowsForLayer ⟨layerIdx, tbdsRows⟩`.
3. **No shape or per-posting layer changes**: Both `actual` and `budget` layers use standard 16-field Posting IR rows and standard TBDS tuples `(period_id, account_key, layer_name, opening, debit_movement, credit_movement, movement, closing)`.
4. **Independent hand-verifiable totals**: Actual-layer movements and budget-layer movements can be inspected independently. `actual` layer shows asset/expense movements; `budget` layer shows virtual envelope movements (`budget:spent:*` / `budget:*`).
5. **No production routing impact**: Rehearsal will run in a test-only BQN script reusing public synthetic fixtures.

## Required assertions

The future focused implementation MUST verify all of the following assertions:

### Source and identity
- Actual purchase event and budget companion event remain distinct durable events in Transaction IR.
- The `actual-event-id` metadata link on the budget companion is preserved without loss.
- Postings within each event maintain their exact original source sequence.
- Each event (actual purchase and budget companion) balances independently to zero (`+´ delta = 0`).

### Layer separation
- Actual purchase asset and expense amounts appear exclusively in the `actual` layer (`layer_index = 0`).
- Budget companion virtual account movements appear exclusively in the `budget` layer (`layer_index = 2`).
- The budget event causes zero double-counting of bank payment (`assets:bank`) or expense accounts (`expenses:*`).
- Actual-layer projection remains completely identical before and after introducing or projecting the companion event.

### Budget coordinates
For the PR #311 public synthetic example, the `budget` layer TBDS rows MUST reflect:
```text
budget:spent:daily   +2300
budget:daily         -2300
budget:spent:flex     +500
budget:flex          -500
```
The sum of all movements across the `budget` layer MUST equal 0.

### Historical stability
- Re-evaluating default resolution against V2 account declarations does NOT alter the projected coordinates of the already-persisted V1 budget companion.
- Historical envelope coordinates are derived strictly from persisted event postings, not regenerated from current declaration metadata.
- Future default resolution (candidate proposal) and historical projection (persisted fact) are maintained as separate authorities.

### Fail closed
The future implementation MUST fail visibly (returning an error state with structured diagnostics) for:

- Unknown budget account in postings or declaration defaults.
- Unsupported layer coordinate (e.g. unknown or non-standard layer name).
- Missing, invalid, or mismatched `actual-event-id` link.
- Unbalanced budget companion event (`+´ delta ≠ 0`).
- Partial admission during Posting IR conversion (all-or-nothing requirement).
- Layer index confusion or blending between `actual` and `budget` layers.

## Expected changed-file boundary for implementation

Future test-only implementation will be strictly confined to:

```text
tests/test_journal_budget_companion_projection_characterization.bqn
```

If necessary, minor pure test-only helpers may be added within existing test-only files (`src_next/journal_read_only_source_carrier.bqn` or `src_next/journal_posting_ir_stage2a.bqn`). No production routing or source loading files will be modified.

## Production boundary

This plan explicitly excludes and does not authorize:

- Production Journal loading, parser routing, or default switch.
- Writers, editors, preview UI, or serializers.
- Production envelope calculation or report runtime migration.
- Current TSV or private ledger data modifications.
- Cube or TBDS shape or axis modifications.
- Per-posting layer structures.
- Source conversion, shadow reads, cutover, or reverse synchronization.
- Correction-event syntax or general event-store infrastructure.

## Non-goals

- Adding metadata axes to Cube or TBDS.
- Mutating production loader (`loader.bqn` / `context.BuildContext`).
- Changing `budget_alloc.tsv` or `plan.tsv` production behavior.
- Combining actual and budget layers into a single aggregate figure.

## Validation required before completion

When the future implementation is created, validation must include:

```bash
git diff --check
bash checks/check-docs-lifecycle.sh
bash checks/check-absolute-links.sh
bash checks/check-repo-index.sh
bash tools/check.sh
```

## Completion routing

Upon successful completion of the future focused implementation:
1. Record results in `docs/archive/completed-plans/JOURNAL_BUDGET_COMPANION_PROJECTION_CHARACTERIZATION_PLAN-2026-07-22.md`.
2. Update `TODO.md` to return `Journal source migration` to no selected finite slice.
3. Update `NEXT_SESSION.md` and `docs/README.md`.
