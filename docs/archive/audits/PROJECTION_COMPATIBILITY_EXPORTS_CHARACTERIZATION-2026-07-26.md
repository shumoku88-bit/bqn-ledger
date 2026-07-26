# `projection.bqn` compatibility-export characterization — 2026-07-26

Status: completed P2 characterization; P2a test-evidence correction recorded
Owner: architecture / posting projection
Canonical: no; current runtime modules and current contracts remain authoritative
Baseline main: `17d1d32f441c0ab7d121fd49995797bd7b45e839`
Exit: retain as the evidence record for the selected compatibility-export cleanup slices

## Finite question

> Which apparently dead exports of `src_next/projection.bqn` have repository callers, focused-test dependence, current documentation promises, or visible external-clone evidence, and what is the smallest safe removal sequence?

This slice changes no BQN runtime, report, source admission, valuation, Cube, TBDS, source data, or private household data.

## Candidates

The characterization covers exactly these exports:

- `ResolveDay`;
- `RequireArithmeticCurrencyProof`;
- `MetaValue`;
- `IsDigits`;
- `IsIntegerText`.

Live neighboring exports such as `ResolveDayFromCycle`, `AuthorizeArithmeticCurrencyProof`, and `ArithmeticCurrencyAuthorizationMessage` are evidence boundaries, not deletion candidates in this slice.

## Method

The audit inspected:

1. each definition and export in `src_next/projection.bqn`;
2. repository-wide exact-name and qualified-access searches;
3. all code hits whose names could be confused with a longer live name, especially `ResolveDay` versus `ResolveDayFromCycle`;
4. focused tests importing `projection.bqn`;
5. current contracts, active plans, TODO routing, and archived point-in-time records;
6. public GitHub code-search results for visible independent consumers.

Public code search cannot observe private repositories, unindexed forks, local clones, deleted branches, or dynamic/aliased access. Therefore external absence is evidence, not proof.

P2a correction: the first full repository gate exposed two legacy `proj.IsIntegerText` assertions in `tests/test_src_next_account_key.bqn`. They were test-only calls rather than runtime consumers, and the current parser contract is already exercised by `tests/test_src_next_exact_decimal.bqn`. The original zero-focused-caller statement was therefore inaccurate and is corrected below rather than hidden by merely deleting the assertions.

## Result summary

| Candidate | Repository runtime caller | Focused-test caller | Current documentation pressure | Remaining coherent owner | Selected treatment |
|---|---:|---:|---|---|---|
| `ResolveDay` | 0 | 0 | No current contract requires the hardcoded `2026-01-01` base | none | remove definition and export in P2a |
| `RequireArithmeticCurrencyProof` | 0 | 0 | Named by a stale current-contract implementation description; historical docs also record its former role | none; outer fatal behavior now lives in `context.AuthorizedRowsFromCheckedResult` | keep through P2a, then remove with contract correction and parity evidence in P2b |
| exported `MetaValue` | 0 | 0 | No current public promise found | private helper for `TxIdFromMeta` | remove export only in P2a; keep local definition |
| exported `IsDigits` | 0 | 0 | No current runtime contract; historical currency documents mention the old integer parser path | only used by dead `IsIntegerText` | remove definition and export in P2a |
| exported `IsIntegerText` | 0 | 2 legacy assertions in `test_src_next_account_key.bqn` | One active implementation-plan document still describes the pre-exact-decimal path as current | none; current amount parsing is owned by `exact_decimal.bqn` | remove obsolete assertions, definition, and export in P2a; correct the stale plan wording |

## Candidate evidence

### `ResolveDay`

Current definition:

```text
ResolveDay date
  -> ResolveDayFromCycle ⟨date, "2026-01-01"⟩
```

Repository search returned several files containing `ResolveDay`, but inspection showed their executable calls are to the live `ResolveDayFromCycle` export. Examples include:

- `src_next/plan_rows.bqn`;
- `src_next/context.bqn`;
- `src_next/journal_posting_ir_stage2a.bqn`;
- `src_next/plan_journal_overlap.bqn`;
- `src_next/journal_currency_proof_carrier_stage2a.bqn`;
- `src_next/envelope_computation.bqn`.

No exact repository call to `ResolveDay` was observed. No focused test calls it. Its hardcoded epoch is not a current accounting or time contract. `date.bqn` owns Gregorian date arithmetic, while `ResolveDayFromCycle` remains the active explicit-coordinate seam.

Conclusion: `ResolveDay` has no coherent remaining owner and is the clearest full-definition removal candidate.

### `RequireArithmeticCurrencyProof`

`RequireArithmeticCurrencyProof` is an effectful wrapper around the live pure predicate and message builder:

```text
AuthorizeArithmeticCurrencyProof
ArithmeticCurrencyAuthorizationMessage
```

No runtime or test caller was observed. Current `context.bqn` instead does this:

```text
BuildCheckedPostingProjectionFromPrepared
  -> ArithmeticCurrencyAuthorizationMessage
  -> AuthorizeArithmeticCurrencyProof
  -> structured result

BuildAuthorizedRowsFromSnapshot
  -> AuthorizedRowsFromCheckedResult
  -> existing ERROR output / exit 1 compatibility behavior
```

Focused currency tests call the pure predicate and message builder directly. They do not call the effectful wrapper.

Documentation is the only stronger compatibility surface:

- `docs/HEADLESS_KERNEL_EVOLUTION_MAP.md` correctly describes direct `RequireArithmeticCurrencyProof` use as the pre-Phase-C starting point;
- `docs/PURE_CHECKED_POSTING_PROJECTION_RESULT_CONTRACT.md` still contains stale implementation-state and old current-seam wording that names `RequireArithmeticCurrencyProof`;
- archived currency audits record the historical implementation.

Conclusion: the function is dead in repository code, but deleting it should be a separate P2b slice that corrects the current contract and re-proves outer fatal-output parity. It should not be bundled with proof-ownership relocation.

### exported `MetaValue`

`MetaValue` still has one local use inside `projection.bqn`:

```text
TxIdFromMeta
  -> MetaValue
```

No qualified repository caller of the exported field was observed. Other modules containing a function named `MetaValue` own separate local implementations and do not consume `projection.MetaValue`.

Conclusion: keep the local helper while `TxIdFromMeta` remains here, but remove it from the public namespace in P2a.

### exported `IsDigits` and `IsIntegerText`

The only runtime relationship in `projection.bqn` is:

```text
IsIntegerText
  -> IsDigits
```

No current runtime calls either export. The first characterization pass overlooked two direct assertions in the broad account-key test:

```text
proj.IsIntegerText "1200"
proj.IsIntegerText "12x"
```

Those assertions preserve no account-key, Posting IR, or current exact-decimal ownership boundary. The active amount path and its focused parser tests now use:

```text
context.BuildRowEvidenceForLine
  -> exact_decimal.Parse
  -> currency_arithmetic.Build
```

The current active document `docs/CURRENCY_STAGE2_EXPLICIT_SINGLE_CURRENCY_EXACT_DECIMAL_IMPLEMENTATION_PLAN.md` still describes `projection.IsIntegerText` as the current amount flow. That is pre-B1 baseline wording, not current runtime truth. The older `docs/CURRENT_CURRENCY_ASSUMPTION_MAP.md` is explicitly a non-canonical Stage 0 snapshot and may retain its historical observation.

Conclusion: remove the two obsolete assertions and both definitions/exports together in P2a, preserve the focused `exact_decimal.bqn` contract tests, and correct the active plan's implementation-state wording in that same slice.

## Focused-test dependence

The focused proof tests establish live pressure on:

- `AuthorizeArithmeticCurrencyProof`;
- `ArithmeticCurrencyAuthorizationMessage`;
- `context.BuildAuthorizedRowsFromSnapshot`;
- the pure checked-result and compatibility-wrapper paths.

The first full P2a gate additionally found two legacy `IsIntegerText` assertions in `tests/test_src_next_account_key.bqn`. They test the superseded parser surface rather than a current account-key or amount contract, so P2a removes them instead of retaining a wrapper. No focused test calls the other four candidates. Candidate removal must preserve neighboring live names and existing proof/result/fatal-wrapper behavior.

## External-clone compatibility

The repository is public, so a user could import fields from `projection.bqn` without leaving evidence in this repository.

Public GitHub searches found no visible independent consumer attributable to another repository for these exact `projection.bqn` compatibility names. Results for the unique `RequireArithmeticCurrencyProof` name were confined to this repository's source and documents. Combined searches using `projection.bqn` and the scalar helper names likewise did not identify an independent consumer.

This does not prove that no private, local, unindexed, or aliased consumer exists. The practical compatibility conclusion is narrower:

- no permanent wrapper is justified by visible evidence;
- removal should be recorded in the PR description and Git history;
- the proof wrapper deserves a separate contract-aware slice because its name appears in current documentation;
- the four P2a candidates do not justify a deprecation cycle by themselves.

## Selected cleanup sequence

### P2a — low-pressure compatibility exports

Remove in one bounded implementation slice:

- `ResolveDay` definition and export;
- `IsDigits` definition and export;
- the two obsolete `test_src_next_account_key.bqn` assertions plus the `IsIntegerText` definition and export;
- `MetaValue` export only.

Preserve:

- local `MetaValue` behavior used by `TxIdFromMeta`;
- `ResolveDayFromCycle`;
- `IsValidDateText` and `DaysFromEpoch` until the separate direct-date-ownership slice;
- focused `exact_decimal.bqn` parser evidence;
- all live proof predicate/message behavior;
- Posting IR, source admission, report, Cube, and TBDS contracts.

P2a should add a focused static boundary check and run the complete repository gate. It should also correct the active exact-decimal plan's stale `projection.IsIntegerText` current-runtime wording.

### P2b — effectful proof wrapper

After P2a, separately:

- correct the current implementation-state wording in `docs/PURE_CHECKED_POSTING_PROJECTION_RESULT_CONTRACT.md`;
- remove `RequireArithmeticCurrencyProof` from `projection.bqn`;
- preserve `AuthorizeArithmeticCurrencyProof` and `ArithmeticCurrencyAuthorizationMessage`;
- prove that `context.AuthorizedRowsFromCheckedResult` still owns the same `ERROR: ` prefix, exit code, failure ordering, and no-partial-row behavior.

P2b is not the proof-ownership move. Reassessing where the live predicate and message builder belong remains the later proof-contract slice.

## Non-goals

This characterization does not authorize:

- removing `ResolveDayFromCycle`;
- moving date ownership;
- moving proof authorization into `context.bqn`;
- changing proof basis/domain/scale policy;
- centralizing Layer vocabulary;
- renaming `projection.bqn`;
- introducing a generic utility or query framework;
- changing Posting IR, public reports, source formats, valuation, Cube, TBDS, or private data.

## Next finite slice

> P2a: remove `ResolveDay`, `IsDigits`, and `IsIntegerText`; remove the two obsolete `IsIntegerText` assertions; stop exporting `MetaValue`; correct the stale exact-decimal-plan runtime note; add a focused boundary check; and preserve every live accounting contract.
