# `projection.bqn` ownership audit — 2026-07-26

Status: completed ownership audit / P1 evidence updated
Owner: architecture / posting projection
Canonical: no; current runtime modules and current contracts remain authoritative
Exit: retain as the observation record for the bounded cleanup sequence; revise when a later slice changes the recorded ownership

## Finite question

> What does `src_next/projection.bqn` actually own, which responsibilities are semantic, compatibility-only, or presentation-only, and what is the smallest safe sequence for making the code more coherent without mechanically fragmenting it?

The initial audit was performed on main commit `2e073ff0300ab8241ad32816400db7674837ac38`. P1 was implemented by PR #395 without reading private ledger data or changing the production report path.

## Main finding

`projection.bqn` is not a generic projection engine. Before P1 it was a shared shelf containing seven concern groups:

```text
Layer constants and source mapping
Posting row vocabulary
Non-Actual TSV field / metadata / identity helpers
Date aliases and day-coordinate helpers
Arithmetic-currency proof authorization
Source-group balance validation
Diagnostic table rendering
```

The right cleanup is not to split this list into seven files. The right cleanup is to remove one clearly foreign responsibility, run the complete evidence gate, and then re-observe the remaining module.

## P1 result

P1 removed developer-only presentation from `projection.bqn`.

Moved beside the sole runtime consumer in `src_next/main.bqn`:

- `proj_cols`;
- the diagnostic-local `Sum0`;
- `BalanceBySourceOk`;
- `FormatBalanceCheck`;
- `FormatProjTable`.

`src_next/main.bqn` is now explicitly described as a developer inspection entrypoint. The production daily-use route remains:

```text
tools/report
  -> src_next/report.bqn
```

`projection.bqn` no longer defines or exports the diagnostic presentation names. Its header now points to current contracts rather than missing top-level `PROJECTION_CONTRACT.md` and `AXIS_CONTRACT.md` files.

### P1 evidence

- existing public-fixture `src_next/main.bqn` golden output remains unchanged;
- table header, projection rows, and `projection_balance_by_source` output remain covered;
- `checks/check-projection-diagnostic-presentation.sh` pins the new ownership boundary;
- production `src_next/report.bqn` does not depend on `src_next/main.bqn`;
- Posting IR shape, ordering, row status, and identity are unchanged;
- Layer, date, proof, Cube, TBDS, source formats, and currency policy are unchanged;
- full `tools/check.sh`, Coverage, and GitHub Actions pass on the corrected implementation.

The first implementation attempt also exposed a useful BQN-language constraint: a subject value such as the column array must retain a subject-role name (`proj_cols`), rather than an uppercase function-role name. The corrected implementation preserves the original role and output.

## Current ownership after P1

### Layer vocabulary and source mapping

Current exports:

- `layer_actual`;
- `layer_plan`;
- `layer_budget`;
- `layer_forecast`;
- `SourceLayer`;
- `LayerName`.

This is real shared semantic vocabulary. Numeric and name ownership remains duplicated across `projection.bqn`, Cube/report consumers, and the Journal adapter. Centralizing Layer would touch several production consumers, so it remains a later independent slice.

### Non-Actual Posting IR vocabulary

Current relevant exports:

- `InferKind`;
- `FieldOrEmpty`;
- `TxIdFromMeta`;
- `PostingId`.

These are used by the non-Actual TSV posting builder in `context.bqn`. They are accounting-adapter vocabulary, not generic projection algebra.

`kind` remains transaction-level classification. It must not be treated as posting-level account classification.

### Scalar and metadata compatibility helpers

Current exports:

- `MetaValue`;
- `IsDigits`;
- `IsIntegerText`.

Repository search found little or no runtime pressure on the exported forms. However, the repository is public, so internal code search cannot prove that no external clone imports them. Removal requires explicit compatibility characterization.

### Date and day-coordinate helpers

Current exports:

- `IsValidDateText`;
- `DaysFromEpoch`;
- `ResolveDay`;
- `ResolveDayFromCycle`.

`IsValidDateText` and `DaysFromEpoch` forward implementations owned by `date.bqn`. This makes `projection.bqn` a dependency magnet.

`ResolveDayFromCycle` is a real posting-coordinate helper. `ResolveDay` hardcodes `2026-01-01`, and no non-self repository caller was observed, but it remains an external-compatibility candidate rather than an automatic deletion.

### Arithmetic-currency proof authorization

Current exports:

- `AuthorizeArithmeticCurrencyProof`;
- `ArithmeticCurrencyAuthorizationMessage`;
- `RequireArithmeticCurrencyProof`.

`context.BuildCheckedPostingProjectionFromPrepared` constructs and authorizes the proof and returns structured diagnostics. Focused tests use the pure predicate and message builder. No runtime or test caller of the effectful `RequireArithmeticCurrencyProof` was observed outside its definition.

Current evidence favors ownership near the checked projection admission in `context.bqn`, but that move belongs to a separate proof-contract slice. A thin new module should not be created merely to shorten `projection.bqn`.

## Dependency-shape observation

Some modules import `projection.bqn` only to reach a forwarded date helper. For example, `cycle.bqn` already imports `date.bqn` but historically called `proj.IsValidDateText` and `proj.DaysFromEpoch`.

Direct owner imports would make the dependency graph more truthful. They should be restored in small coherent groups after dead-export characterization, not bundled into P1.

## Cleanup sequence

### P1 — Diagnostic presentation

Status: **completed by PR #395**.

Result:

```text
projection.bqn
  -> no diagnostic table or source-balance presentation

main.bqn
  -> local developer-only presentation

report.bqn
  -> unchanged production report owner
```

### P2 — Characterize apparently dead compatibility exports

Next selected finite slice.

Candidates:

- `ResolveDay`;
- `RequireArithmeticCurrencyProof`;
- exported `MetaValue`;
- exported `IsDigits`;
- exported `IsIntegerText`.

Before removal, record:

- exact repository callers;
- focused-test dependence;
- current documentation promises;
- whether a deprecation note is preferable for external clone users;
- whether the name has a coherent remaining owner.

P2 is a characterization slice. It must not assume that every candidate will be deleted.

### P3 — Restore direct date ownership

Replace forwarding use of:

- `projection.IsValidDateText`;
- `projection.DaysFromEpoch`;

with direct `date.bqn` ownership in small groups. Keep `ResolveDayFromCycle` until a better coordinate owner is selected.

### P4 — Reassess arithmetic-proof ownership

Possible direction:

```text
context proof construction
  -> context-local authorization predicate and message
  -> checked projection result
```

Synchronize `docs/PURE_CHECKED_POSTING_PROJECTION_RESULT_CONTRACT.md` in this slice. Its stale implementation-state wording is a documentation defect, but P1 did not change proof ownership or behavior.

### P5 — Reassess Layer ownership

Inventory the complete consumer contract for:

- duplicated layer constants;
- source-to-layer mapping;
- Journal transaction layer mapping;
- report modules importing numeric layer constants.

A small `layer.bqn` may be justified only after this inventory.

### P6 — Reassess the remaining adapter vocabulary

If the file then mostly contains:

- `FieldOrEmpty`;
- `TxIdFromMeta`;
- `PostingId`;
- `InferKind`;
- `SourceLayer`;
- `LayerName`;
- `ResolveDayFromCycle`;

its actual meaning is a non-Actual Posting IR adapter vocabulary. At that point choose among:

1. keep the smaller file;
2. move one-owner helpers into `context.bqn`;
3. extract a coherent `nonactual_posting_adapter.bqn`;
4. rename only with an explicit compatibility plan.

No choice is selected yet.

## Things not recommended

This audit does not support:

- splitting every helper into a separate file;
- creating a generic utility module for unrelated short functions;
- renaming `projection.bqn` before reducing and characterizing its responsibilities;
- moving date, proof, and Layer ownership in one PR;
- replacing transaction-level `kind` with posting-level account classification;
- introducing a generic projection DSL;
- changing Posting IR shape, Cube, TBDS, report output, source formats, currency policy, or private data.

## Current next finite slice

> P2: characterize the apparently dead compatibility exports of `projection.bqn`, including external-clone compatibility limits, before selecting any deletion or deprecation.

The purpose is truthful ownership, not maximum file count or minimum line count.
