# Report code reduction plan

Status: current implementation plan
Owner: report / context boundaries
Canonical queue: `TODO.md`
Updated: 2026-07-27
Exit: archive or shorten after the retained report path is smaller, compatibility callers are resolved, and the remaining boundaries are documented as current architecture

## Purpose

Preserve the report behavior used in daily operation while reducing the amount of code and the number of temporary paths required to maintain it.

This is not a campaign to make every section look alike. Clean boundaries are useful only when they make later deletion possible.

```text
preserve observable behavior
  -> expose one small prepared boundary
  -> migrate real callers
  -> remove obsolete adapters, checks, and duplicate preparation
  -> measure the retained result
```

## Baseline

Point-in-time repository measurement on 2026-07-27:

| Area | Files | Physical lines |
|---|---:|---:|
| `src_next/**/*.bqn` | 75 | 13,056 |
| `src_edit/**/*.bqn` | 37 | 3,736 |
| `tests/**/*.bqn` | 121 | 12,377 |
| `checks/*.{sh,bqn}` | 82 | 9,475 |

For `src_next`, 1,551 lines are blank and 1,098 are comment-only, leaving approximately 10,407 nonblank, non-comment lines. These values are characterization, not CI thresholds. Shorter code is not an improvement if it hides accounting meaning, weakens diagnostics, or compresses BQN beyond reviewability.

The current size includes more than report formulas: Journal parsing, Posting IR construction, exact-decimal and currency admission, Cube/TBDS construction, household policy, rendering, compatibility entrypoints, and failure diagnostics. A comparison with hledger must compare equivalent scope rather than raw repository lines.

## Required outcome

The track is successful only if all of the following are true:

- daily report output and machine/JSON contracts used by callers remain stable unless an explicit contract change is approved;
- invalid, unavailable, and empty evidence remain distinguishable;
- source loading and semantic interpretation no longer coexist merely for compatibility after their callers have migrated;
- source-shape grep checks are not used where a prepared behavioral test can prove the contract more directly;
- compatibility wrappers have an identified caller and deletion decision rather than becoming permanent by default;
- after the temporary migration peak, retained `src_next` code and public compatibility surface are smaller than this baseline;
- no generic section-pipeline framework is introduced without multiple real consumers proving the same abstraction.

## Working rules

- Work on one finite section slice at a time.
- Name the code expected to become removable before adding a new boundary.
- A renderer layer is optional. Do not create one for a module that only produces a semantic value for another consumer.
- Keep consumer-specific temporal policy local unless exact parity is demonstrated by fixtures.
- Prefer a narrow prepared argument record or tuple over a broad `ctx`, but do not mechanically copy every `ctx` field into a new record.
- Replace a structural grep with behavioral evidence in the same slice when the grep would prevent a valid refactor.
- Record source-line and exported-API deltas after each completed slice. Temporary growth is acceptable only with a named deletion checkpoint.
- Do not reduce tests merely to improve the line count. Remove duplicated checks only after stronger behavioral coverage exists.
- Do not minify BQN or merge distinct accounting meanings to meet a numeric target.

## First completed finite slice: Actual Snapshot

The former `actual_snapshot.BuildAt` core was I/O-free but still received broad `ctx`. This smallest production seam established the reduction workflow before larger Daily Flow/Trend work; `TODO.md` now owns selection of the next finite slice.

### Behavior that must remain fixed

- `as_of` is an inclusive cumulative cutoff.
- Pre-cycle history remains opening-balance evidence.
- Valid Actual rows after `as_of` do not affect the snapshot.
- Rejected Actual evidence at or before `as_of` fails closed.
- Invalid-date Actual evidence has unknown applicability and fails closed.
- A valid empty Actual source is a zero snapshot, not unavailable.
- The existing Outlook failure propagation remains unchanged.
- Default `Build(ctx)` retains Actual Snapshot's local invalid-date and in-cycle observation policy; it is not moved into `actual_observation.bqn`.

### TODO

- [x] Add an I/O-free `BuildFromPrepared` boundary receiving only the posting/cube/resolution evidence and explicit `as_of` needed by the calculation.
- [x] Keep `BuildAt(ctx, as_of)` as a compatibility adapter while Outlook and focused callers still use it.
- [x] Keep `Build(ctx)` as the default-observation adapter without changing its temporal policy.
- [x] Add a focused prepared-core test whose input has no `base`, source path, or broad report context.
- [x] Preserve cumulative TBDS, rejected-row applicability, empty-source, and Outlook propagation tests.
- [x] Replace the `BuildAt` source-shape assertions in `checks/check-src-next-actual-snapshot.sh` with behavioral prepared-boundary evidence.
- [x] Search all `Build` / `BuildAt` callers and record whether each wrapper is retained, migrated, or removable.
- [x] Review exported names and avoid adding test-only aliases when the real prepared boundary can be tested directly.
- [x] Run focused checks, `tools/check.sh`, coverage, and diff review.
- [x] Record physical-line and export-count deltas in `TODO.md`; explain any temporary increase and name the deletion that will repay it.

Completion result: `src_next` increased by 9 physical lines and the module added one real export. The structural `BuildAt` awk/grep check was removed. Outlook remains the production `BuildAt` caller, so its later migration is the named deletion checkpoint for the temporary adapter cost.

## Later slices

These are ordered directions, not authorization to implement all of them in one change.

### Daily Flow

- [x] Move date acquisition and compatibility fallback to the context adapter.
- [x] Give calculation a prepared boundary over required cube evidence, resolved metadata, cycle coordinates, and Actual dates.
- [x] Keep Daily Flow's explicit `as_of` anchor behavior distinct from Daily Trend assembly.
- [x] Remove unused imports and dead helpers discovered by the slice.
- [x] Test the core without `base` or filesystem access.
- [x] Reassess compact/human rendering duplication after behavior is fixed; retain the two renderers because they serve distinct machine and human contracts.

Completion result: the module removed five unused imports, one unused label binding, and a dead source-loading helper. `src_next` increased by 10 physical lines and the module added one real export. The production report still uses the context adapter; the later `actual_source.DatesFromContext` fallback deletion is the compatibility checkpoint, while final track completion still requires a net reduction from the original baseline.

### Daily Trend

- [x] Characterize `BuildAt(ctx, header_O)`: `header_O` changes presentation coordinates rather than replay calculation.
- [x] Prepare `daily_trend_plan` reserve evidence outside the numeric core while preserving fail-closed behavior.
- [x] Pass row-local plan income and reserve evidence explicitly.
- [x] Preserve current-source coordinate replay and the empty-cycle-start anchor.
- [x] Retain `BuildAt` while the production human caller needs its distinct header coordinate; defer rename/removal to the report observation checkpoint.

Completion result: `BuildFromPrepared` receives existing Cube/resolution evidence, explicit coordinates, and a checked plan result. The dead source-loading latest-date helper and the structural helper-connection grep were removed. `src_next` increased by 19 physical lines and the module added one real export. Report `BuildAt`, summary `Build`, and plan-evidence preparation remain explicit adapters rather than being pushed into the numeric core.

### Outlook

- [ ] Inventory the existing `BuildCore`, Actual Snapshot, remaining-plan, frontier, and Daily Capacity seams before adding another layer.
- [ ] Preserve open-ended frontier and explicit unavailable semantics.
- [ ] Remove duplicate assembly only where the same observation contract is proven.
- [ ] Decide whether `daily_capacity.bqn` becomes a real consumer seam or remains removable experimental surface.

### Envelope computation

- [ ] Do not refactor the 914-line module as one change.
- [ ] Characterize independent responsibilities: envelope balances, unassigned pool, backing diagnostics, and planned-payment coverage.
- [ ] Extract only a responsibility with a behavioral fixture and a named caller.
- [ ] Delete superseded local joins or render assembly in the same or immediately following slice.

### Actual source and compatibility reduction

- [ ] Inventory every `actual_source.bqn` export and repository caller.
- [ ] Classify exports as production prepared path, source-loading compatibility path, or removable test seam.
- [ ] Remove `LoadDates`, completion, and plan-ID source wrappers after the final non-context callers migrate.
- [ ] Separate source loading from pure evidence interpretation only when the remaining caller graph demonstrates a stable module boundary.
- [ ] Recheck whether historical parser fallback is still required by a real supported entrypoint.

## hledger comparison checkpoint

Before considering a rewrite or dependency switch:

- [ ] Compare equivalent capabilities: parsing, multi-posting preservation, exact amount policy, validation, cycle/envelope household policy, report output, editor safety, and diagnostics.
- [ ] Separate code hledger could replace from code that expresses household-specific behavior.
- [ ] Build one read-only synthetic experiment if the replacement boundary is still unclear.
- [ ] Record operational dependency and migration costs, not only source lines.
- [ ] Make an explicit keep-BQN, hybrid, or migration decision; do not let the code-reduction track silently become a rewrite.

## Per-slice completion record

For each completed slice, add a short entry to `TODO.md` while it is current, then rely on Git history after completion:

```text
slice:
behavior preserved:
prepared boundary:
removed code/API/check:
src_next line delta:
remaining compatibility caller:
checks:
```

The objective is not maximum layering. The objective is a smaller truthful implementation whose safety contracts remain visible.
