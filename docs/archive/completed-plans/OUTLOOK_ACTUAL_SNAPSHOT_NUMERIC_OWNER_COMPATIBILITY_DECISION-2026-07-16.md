# Outlook / Actual Snapshot Numeric-Owner Compatibility Decision

Status: completed decision record / docs-only
Owner: report
Canonical: no; current paths: `docs/archive/active-plans/REPORT_PROJECTION_ALIGNMENT_PLAN-2026-07-15.md`, `docs/OUTLOOK_TEMPORAL_CURRENT.md`, `docs/REPORT_CONTRACTS.md`, and future runtime checks
Exit: retain as the approved preimplementation compatibility decision; runtime slices may implement only the independently selected boundaries recorded here

## Decision scope

This record decides the compatibility contract required before Outlook and `actual_snapshot` move eligible monetary calculations away from their current raw `journal.tsv` / `plan.tsv` parsers. It follows the public pre-migration evidence in:

- `OUTLOOK_ACTUAL_SNAPSHOT_CHARACTERIZATION-2026-07-16.md`;
- `fixtures/outlook-actual-snapshot-characterization/`;
- `tests/test_src_next_outlook_actual_snapshot_characterization.bqn`;
- the existing anchor fixture `fixtures/src-next-anchor-unmet/`.

This slice changes no BQN runtime, report output, fixture expectation, source/config schema, metadata key, editor behavior, Daily Capacity connection, or private production data. No runtime migration is selected by this record.

## 1. Migration is split into two independent runtime slices

The migration order is approved as:

```text
Slice A: actual_snapshot actual-balance numeric owner
Slice B: Outlook remaining-plan monetary owner and anchor policy
```

Slice A may proceed without Slice B. Slice B must not be folded automatically into Slice A.

Reasons:

- actual balances and remaining plans have different source layers, rejection rules, time windows, and evidence needs;
- `actual_snapshot` already has an explicit `O` boundary that can be migrated independently;
- plan completion, anchor metadata, conditional income, and conservative expense reservation require source identity evidence that the accounting aggregate intentionally does not carry;
- combining both would make a numeric-owner migration also become an anchor-policy rewrite and would obscure compatibility review.

## 2. Slice A preserves the cumulative inclusive-O actual snapshot

The future checked boundary remains:

```text
actual_snapshot.BuildAt ⟨ctx, O⟩
```

`O` is caller-owned and must be a valid date. The accepted actual set is:

```text
source_file = journal.tsv
layer = actual
status = ok
D <= O
```

The snapshot remains ledger-cumulative, not cycle-bounded movement.

- Actual rows before `C.start` remain part of opening balance history.
- A row at `D = O` is included.
- A row with `D > O` is excluded.
- `C.end_exclusive` does not cap the snapshot when `O` is later.
- Moving `O` after cycle end may therefore admit end-exclusive and later out-of-cycle actual rows, as characterized.
- Account balances, liquid/savings/invest totals, liabilities, net worth, entries, and liquid breakdown retain their current meanings and ordering unless a focused compatibility fixture approves a difference.

Numeric ownership moves to the checked ledger-wide Posting IR and a local O-bounded TBDS-family accounting view. The runtime must not reread and reparse `journal.tsv` amounts inside `actual_snapshot`.

This decision does not require using the existing cycle Cube. The Canonical Cube remains `Day × Account × Layer` and cycle-bounded.

## 3. Slice A rejected actual evidence fails closed

A migrated snapshot must expose at least:

```text
state = ok | error
reason
diagnostics
as_of = O
```

A valid empty actual history is `ok` with real zero balances. `unavailable` is not used merely because no admitted journal rows exist.

### Valid-coordinate rejected rows

A rejected `journal.tsv` source row with a valid event coordinate `D` is applicable to the cumulative snapshot exactly when:

```text
D <= O
```

An applicable rejected actual source row makes the snapshot `error`.

- Do not silently exclude it and continue.
- Do not coerce it to zero.
- Do not preserve a partial normal-looking balance.
- Deduplicate diagnostics by stable source identity, at minimum `source_file + source_row`, so the debit/credit posting pair does not create duplicate source errors.

A valid-date rejected actual row with `D > O` does not by itself fail this O-bounded snapshot. Ledger-wide readiness may still expose it independently.

### Invalid-date evidence

A rejected actual row with an invalid date has no trustworthy coordinate and cannot be proved later than O. It is applicability-unknown and fails the snapshot closed as `error`.

### Amount and currency authorization precedence

Current context construction authorizes amount/currency arithmetic for the full posting-source snapshot before sections receive `ctx.posting_rows`.

- Invalid amount, unsupported currency, duplicate currency metadata, or equivalent arithmetic authorization failure may stop upstream before `actual_snapshot.BuildAt` is reached.
- That upstream fatal/error is stronger fail-closed behavior and is accepted by this decision.
- Slice A does not add a new nonfatal checked-result carrier through context/report.
- A future partial-report carrier would be a separate architecture decision.

### Invalid observation

An invalid `O` is `error` with reason `invalid_observation`. It must not produce zero balances that resemble a valid empty ledger.

## 4. Outlook must propagate actual snapshot failure

Outlook must not consume unavailable numeric fields from an errored snapshot.

When Slice A is implemented, Outlook gains section-local status evidence sufficient to distinguish at least:

```text
ok
error
```

On actual snapshot error:

- Outlook is `error`;
- its reason identifies invalid observation or rejected actual evidence;
- source diagnostics are retained once per source row;
- actual-dependent and derived monetary values are not rendered as trustworthy numbers;
- `liq_total`, asset totals, net worth, `liq_daily`, and `liq_safe_daily` must not be normal numeric output;
- plan-only amounts must not be combined with an invalid actual balance to create a daily allowance.

This is a narrow Outlook status slice required by fail-closed actual ownership. It is not authorization for a repository-wide uniform status framework.

The normal empty-journal case remains `ok`: actual balances are zero, frontier evidence may remain `unavailable`, and the distinction between balance validity and record-frontier absence is preserved.

## 5. O, L, and C remain separate

The migrated actual balance must not change the current temporal roles:

```text
O = explicit Outlook observation and actual snapshot cutoff
L = admitted recorded-actual coordinate frontier evidence
C = selected cycle boundary
```

- `O` owns the actual balance cutoff.
- `L` may be before, at, or after O.
- `L` may lie after `C.end_exclusive` under the current Outlook producer scope.
- `L` does not enter the O-bounded balance merely because it is the latest record.
- `C` owns the remaining-plan horizon and days-left denominator, not the cumulative actual opening history.
- No report-wide `--as-of` or historical-knowledge replay is introduced.

## 6. The two latest-date helpers remain compatibility surfaces

The characterization fixed two different contracts:

```text
actual_snapshot.LatestActualDateInCycle
  [C.start, C.end_exclusive)

outlook.LatestActualDateInCycle
  D >= C.start, no upper cycle bound, fallback to C.start
```

Slice A must preserve both current exports and their current behavior. It must not merge them merely because their names overlap.

The Outlook helper name is acknowledged as misleading because it has no upper cycle bound. A later independently selected cleanup may:

1. introduce a truthful owner such as `LatestRecordedDateFromCycleStart` or keep `RecordedFrontierInfo` as the only primary name;
2. retain `outlook.LatestActualDateInCycle` temporarily as a compatibility alias;
3. update callers and remove the alias only with focused tests.

No helper rename or compatibility-alias campaign is selected here, and it must not be folded into Slice A.

## 7. Slice B uses checked plan amounts plus existing completion evidence

The later plan-side migration must use:

| Meaning | Owner |
|---|---|
| plan amount and liquid-account delta | admitted `plan.tsv` Posting IR |
| plan source identity and metadata | source evidence joined by `source_file + source_row` or an equally stable identity |
| completed / unfinished identity | existing `plan_rows` plan-ID completion evidence, not a new amount parser |
| observation and horizon | explicit O and C |
| anchor account validity | resolved account identity and role |
| anchor activation | admitted actual income-credit evidence in the observed current-cycle window |

`plan_rows.WithValues` must not become the numeric owner because it reparses source amounts. Its completion/source identity evidence may be reused or factored into a pure evidence seam.

Only unfinished plan rows are eligible for remaining-plan monetary aggregates.

The remaining horizon is:

```text
O <= plan date < C.end_exclusive
```

The inclusive O behavior is preserved. A plan row at `C.end_exclusive` remains outside the current remaining aggregate and may continue to belong to next-cycle obligation evidence.

## 8. Approved anchor policy is asymmetric for safety

`anchor=<account>` is an income-account condition. When present, the anchor value must resolve to exactly one known account with `role=income`.

Anchor activation is proved only by an admitted actual journal income-credit event for that account in:

```text
[C.start, min(O + 1 day, C.end_exclusive))
```

A planned income row, a later actual row after O, a prefix match, or account-name text alone does not activate the anchor.

### Unanchored rows

An unfinished in-horizon plan row without `anchor=` is admitted normally according to its checked liquid delta.

### Outflows are reserved even when a valid anchor is unmet

For an unfinished in-horizon plan row whose checked liquid delta is negative:

- include the outflow in `fixed_reserve` / future planned liquid expense even when its valid income anchor has not yet occurred;
- do not allow an unmet anchor to make a known obligation disappear;
- this preserves the conservative intent recorded by `fixtures/src-next-anchor-unmet/README.md`, where unmet anchored rent remains reserved.

The anchor still must be syntactically and semantically valid when supplied. Invalid metadata is not a permission to guess.

### Inflows require an active anchor when anchored

For an unfinished in-horizon plan row whose checked liquid delta is positive:

- an unanchored inflow is included normally;
- an anchored inflow is included only when its valid anchor is active by the actual-evidence rule above;
- an anchored inflow with a valid but unmet anchor is excluded from `planned_future_income` without making the section unavailable or error;
- this prevents conditional income from increasing spendable capacity before its stated condition has actually occurred.

### Zero liquid delta

A checked plan row with zero liquid delta does not affect `planned_future_income`, `fixed_reserve`, `liq_daily`, or `liq_safe_daily`. Its identity may remain relevant to another report or obligation view.

## 9. Invalid anchor and rejected plan evidence fail Outlook closed

For Slice B, an in-horizon unfinished plan row is applicable evidence.

Outlook is `error` with no trustworthy monetary output when applicable plan evidence has:

- an unknown from/to account;
- an invalid or unplaceable date;
- an invalid amount/currency that is not already stopped by upstream authorization;
- duplicate or empty `anchor=` metadata where a unique nonempty value is required;
- an anchor account that is unknown or whose resolved role is not `income`;
- a structural source/Posting-IR join failure.

A valid-date rejected plan row outside `[O,C.end_exclusive)` does not by itself fail the current remaining-plan aggregate. An invalid-date plan row is applicability-unknown and fails closed.

This follows the report status policy: invalid future plan inputs are `ERROR`, not a warning and not zero.

## 10. Intentional compatibility changes

A future Slice A runtime PR intentionally changes these current behaviors:

1. `actual_snapshot` no longer reparses journal amounts locally.
2. Unknown-account or invalid-date actual evidence applicable to O no longer disappears silently; the snapshot and Outlook fail closed.
3. Invalid O no longer resembles a valid zero snapshot.
4. Outlook gains explicit error evidence for actual snapshot failure and suppresses derived monetary output.

A future Slice B runtime PR intentionally changes these current behaviors:

1. The characterized all-included anchor behavior is not preserved as target policy.
2. A nonexistent anchor in `fixtures/outlook-actual-snapshot-characterization/plan.tsv` becomes invalid applicable plan evidence and therefore `error`, rather than contributing `70` to `fixed_reserve`.
3. Unanchored rows remain eligible.
4. Valid anchored outflows remain reserved even when the anchor is unmet.
5. Valid anchored inflows are admitted only after an actual matching income event at or before O within C.
6. Completed plan rows no longer contribute to remaining-plan monetary aggregates.
7. Plan amounts come from admitted Posting IR, not `•BQN` / local source amount parsing in Outlook.

The characterization fixture remains unchanged as historical evidence. Target-contract runtime fixtures must be separate or must update expectations with an explicit citation to both the characterization and this decision.

## 11. Required runtime fixture matrix

Slice A must add focused synthetic evidence for at least:

| case | target result |
|---|---|
| pre-cycle actual + O-day actual | `ok`, both included |
| valid actual after O | excluded, snapshot remains `ok` |
| valid unknown-account actual at/before O | `error`, no numeric snapshot |
| valid unknown-account actual after O | does not fail this snapshot |
| invalid-date actual | `error`, no numeric snapshot |
| empty journal | `ok`, zero balances |
| O after cycle end | cumulative rows through O remain included |

Slice B must later add separate evidence for at least:

| case | target result |
|---|---|
| unanchored outflow | reserved |
| valid anchored outflow, anchor met | reserved |
| valid anchored outflow, anchor unmet | reserved |
| unanchored inflow | included |
| valid anchored inflow, anchor met by actual event at/before O | included |
| valid anchored inflow, anchor unmet | excluded, section remains `ok` |
| anchor occurs after O | anchored inflow excluded |
| unknown/non-income/duplicate/empty anchor | `error`, no monetary output |
| completed plan | excluded |
| valid plan after C.end_exclusive | outside current remaining aggregate |

## 12. Next selectable runtime slice

The next independently selectable Report Projection Alignment slice is **Slice A: `actual_snapshot` checked numeric-owner runtime migration**.

It may implement only:

- cumulative inclusive-O actual balances from checked ledger-wide Posting IR / a local TBDS-family view;
- snapshot `ok / error` evidence;
- section-local rejected-actual applicability and diagnostics;
- narrow Outlook propagation of snapshot failure;
- focused fixtures/checks and current report-contract updates required by the visible status change.

It must not implement:

- plan monetary migration;
- anchor-policy runtime changes;
- helper renaming;
- a generic temporal kernel;
- a report-wide `--as-of`;
- Daily Capacity wiring;
- Cube shape changes;
- source/config/metadata migration;
- automatic advice or writes.

Slice A is next selectable but remains unselected until explicitly started.

## Non-goals

- no `src_next/*.bqn` changes;
- no test, fixture, or check expectation changes;
- no runtime status/output changes in this docs-only slice;
- no plan or actual source TSV edits;
- no generic checked-result carrier through every report section;
- no latest-date helper rename;
- no plan editor or plan-completion workflow redesign;
- no Daily Capacity policy or adapter decision;
- no private production-data access.
