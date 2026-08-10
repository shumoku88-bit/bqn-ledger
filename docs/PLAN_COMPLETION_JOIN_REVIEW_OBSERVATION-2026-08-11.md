# Plan Completion Join review observation — 2026-08-11

## Baseline

Observed against `main` `5930d70fb8e81bc3fd6203338c9d288cf8bd3071` after PR #623 closed the Month Category Flow review and advanced the Phase 1 cursor to `src/accounting/plan_completion_join.bqn`.

The only other open PR observed at review start is Draft #550 for canonical Household recovery closeout. It is a separate documentation/migration closeout workstream and does not overlap this accounting owner.

This document is observation-only. It does not change production BQN, tests, public result shape, diagnostics, arithmetic, identity, provenance, writer authority, or the TODO checkbox/cursor.

## Owner boundary

`src/accounting/plan_completion_join.bqn` is the pure relation owner between explicit Plan and Actual selections.

Input:

```text
Plan Facts
Actual Facts
selected Plan Transaction indices
selected Actual Transaction indices
```

The owner deliberately does not choose a period, observation, cycle, report route, source path, parser, renderer, or writer.

Only nonempty durable `plan_id` is a relationship key. There is no five-field fallback, date/memo/amount inference, or source-local index comparison between Plan and Actual Facts.

## Current production consumer graph

Direct production consumers are:

- `src/sections/planned_payments.bqn`;
- `src/application/daily_scope_adapter.bqn`;
- `src/accounting/envelope_backing.bqn`.

This is therefore a live shared accounting capability, not a dead or qualification-only owner.

The consumers use different portions of the result:

- Planned Payments uses relationship status, Plan coordinates/evidence, and currency/direction match flags;
- Daily Scope uses Plan identity/date/amount/provenance and the completion state of obligations;
- Envelope Backing uses open/completion status, Plan destination/amount/evidence, and completion currency/direction agreement.

The breadth of current consumers is evidence against collapsing the Join into any one Section or Application adapter.

## Current semantic pipeline

The successful path is approximately:

```text
validate source families and selection coordinates
→ selected Plan plan_id axis
→ selected linked Actual plan_id/index axis
→ unmatched linked Actual references
→ for each selected Plan:
     build exact Plan Transaction evidence
     rescan linked Actual plan_id values for matches
     build matching Actual Transaction evidence
     classify open/completed/duplicate/ambiguous
     append one candidate row namespace
→ transpose candidate row namespaces back into aligned result columns
→ derive status counts
```

The semantic concepts are sound; the middle representation is more row-oriented than the public result.

## Protected relationship semantics

### KEEP explicit selection ownership

Selection is an input policy, not Join policy.

This matters in current consumers. Planned Payments explicitly sorts its Plan selection by date before calling the Join, while other consumers use different explicit horizons. The Join should preserve the caller's selected Plan order instead of inventing canonical date or source order.

### KEEP durable `plan_id` as the only relation key

The current strict identity boundary is central to the owner. Do not reintroduce fallback matching from date, memo, amount, Account coordinates, or source-local row/index values.

### KEEP relationship states

Each selected Plan publishes exactly one of:

```text
open
completed
duplicate
ambiguous
```

`duplicate` means multiple matching Actual transactions have the same date, currency, exact coefficient/scale, and debit/credit Account directions.

`ambiguous` means multiple matching Actual transactions disagree on at least one of those semantic coordinates.

Duplicate and ambiguous evidence must remain visible and must not be collapsed into `completed` or summed.

### KEEP source-local exact evidence

Plan and Actual coefficients/scales remain source-local. Separate Actual completions are not added together. Currency and direction comparison are published as evidence for consumers rather than silently rewriting one source to resemble the other.

### KEEP source-qualified provenance

Durable Transaction and Posting references remain the public identity/provenance language. The Join must not replace them with snapshot-local numeric coordinates.

### KEEP fail-closed publication

Invalid Fact families, invalid/duplicate selection coordinates, invalid selected Plan identity, invalid Plan direction evidence, or invalid matching Actual completion evidence produce an overall error with no partial rows, counts, or unmatched-reference publication.

## Ordering observations

Three order laws are currently implemented but not directly characterized by the focused test.

### Plan row order

The outer row axis follows `planTransactionIndices` exactly because `candidateRows` are appended while iterating that selection vector.

This is semantically important because the caller owns selection order.

### Matching Actual evidence order

For one Plan, matching Actual indices are produced by filtering `linkedActualIndices`. Therefore every Actual evidence cell currently preserves the order of `actualTransactionIndices` after the nonempty-`plan_id` filter.

This affects aligned arrays such as references, dates, currencies, coefficients, scales, Account directions, contributors, and match flags.

### Unmatched Actual order

`unmatched_actual_references` also preserves selected Actual order after the linked-Actual filter.

### Evidence gap

The current focused test is strong on relationship states and exact evidence but is mostly a one-Plan characterization. Before changing the relation algorithm, add a multi-Plan/multi-Actual law that fixes all three order relations explicitly.

## Important unmatched-Actual boundary

A linked selected Actual whose `plan_id` does not occur in the selected Plan axis is published only as a durable Transaction reference in `unmatched_actual_references`.

Current code does **not** run `TransactionEvidence` on such an unmatched Actual.

This is a meaningful boundary. A future whole-array refactor must not eagerly validate every linked Actual completion before determining whether it belongs to a selected Plan, because doing so would strengthen admission accidentally and could turn legitimate omitted-Plan historical/period evidence into an error.

Safe direction:

```text
classify linked Actual plan_id against selected Plan plan_id axis first
→ unmatched: publish durable Transaction reference only
→ matched: build exact Actual completion evidence
```

## Array-visibility observations

### A. Repeated Plan × Actual relation scan

For every selected Plan, current code evaluates:

```bqn
matchingMask ← planId⊸≡¨linkedActualPlanIds
```

The semantic relation is naturally one coordinate transform:

```text
linked Actual plan_id
→ coordinate on selected Plan plan_id axis
→ matched Plan cells + unmatched lane
```

A BQN-native candidate is to classify the linked Actual `plan_id` vector against the selected Plan `plan_id` axis once, then group the matched Actual indices/evidence by that coordinate.

This would make the relationship axis visible instead of rediscovering it once per Plan.

No performance claim is made yet. The current topology is visibly repeated work, but a benchmark is required before calling it a material runtime bottleneck.

### B. Candidate row namespace followed by full reprojection

Current code appends one large record to `candidateRows` per selected Plan and, after all validation succeeds, reconstructs every public column with expressions such as:

```bqn
{𝕩.status}¨candidateRows
{𝕩.plan_id}¨candidateRows
{𝕩.actual_references}¨candidateRows
...
```

The public result is already columnar/aligned. The temporary row namespace therefore looks like structural plumbing rather than retained accounting meaning.

A coherent end-state could construct aligned Plan columns plus grouped Actual evidence cells directly, then derive status and counts over those arrays without the append/reprojection round trip.

### C. Transaction-to-Posting rescans

`TransactionEvidence` constructs posting/debit/credit masks by comparing one Transaction index against the complete Posting axis each time it is called.

Canonical Facts currently expose `postings.transaction_index` but no transaction posting offset/count table. The repeated masks therefore have a real data-model cause.

The Join could potentially classify selected Postings onto selected Transaction coordinates once, but that is a distinct relation layer from Plan-to-Actual matching. Do not add new Facts columns or a generic relation helper merely to make this review shorter.

Classification: **OBSERVE separately after A/B are proven**, unless a coherent measured or readability-driven end-state clearly requires all three together.

## Public surface triage

### Clearly live / retained

Current production consumers directly justify retaining, at minimum:

- `rows.index` and relationship `status`;
- Plan identity/date/currency/exact amount;
- Plan from/to Account direction;
- Plan Transaction/Posting provenance;
- `currency_matches` and `direction_matches`;
- relationship `counts` while Planned Payments consumes them.

### Documented relationship evidence

The active `docs/PLAN_COMPLETION_JOIN.md` deliberately contracts matching Actual:

- durable Transaction references and dates;
- currencies and exact coefficients/scales;
- debit/credit Account arrays and Posting contributors;
- per-completion match flags;
- unmatched Actual references.

Most of this rich Actual evidence is not read directly by current production consumers, but zero current reachability is not enough to remove an explicitly documented independent Join capability. Review these fields individually rather than deleting the Actual evidence family wholesale.

### Strong subtraction candidate: `actual_transaction_indices`

Repository search finds `rows.actual_transaction_indices` only inside `plan_completion_join.bqn` itself.

The active Join document specifies durable Actual references and semantic evidence but does not name snapshot-local Actual numeric indices as part of the result contract.

The owner already publishes `actual_references`, which are source-qualified durable identity. This makes `actual_transaction_indices` look like an implementation coordinate leaking beside the durable authority.

Classification: **SUBTRACT candidate, strong evidence**, but apply only after ordering/evidence laws are strengthened and the full consumer graph is rechecked on the implementation baseline.

### Private subtraction candidate: `TransactionEvidence.transaction_index`

The private `TransactionEvidence` record publishes `transaction_index`, but current Join code does not consume that field when building either Plan or Actual result evidence.

Classification: **SUBTRACT candidate, local and low-risk**. It should not drive the main architecture slice by itself.

## Historical evidence

The Join was introduced in commit `46e7766fb2a7df3d0b9959149ebd9f071048be6c` with the durable Plan completion boundary already substantially in its current form.

PR #472 later removed the custom mutable `Unique` helper and replaced selection/Plan-ID uniqueness checks with BQN major-cell Deduplicate `⍷`. Do not reopen that completed subtraction.

Later canonical-source work changed the Plan source family from legacy `plan.tsv` to canonical `plan.journal`, and Fact Reference ownership moved to `src/ledger/`, without changing the relation algorithm.

Therefore the Plan-per-Actual scan plus candidate-row/reprojection shape is largely original Phase 3H implementation topology rather than a recently justified architecture decision.

## Laws to add before relation refactor

A focused test should construct at least two selected Plans and an interleaved selected Actual order and prove:

1. result Plan rows exactly preserve explicit Plan selection order;
2. matching Actual references/evidence within each Plan cell preserve explicit Actual selection order;
3. all Actual evidence arrays stay aligned with those references;
4. unmatched Actual references preserve explicit Actual selection order;
5. open/completed/duplicate/ambiguous classification is unchanged in a multi-Plan result;
6. counts remain the reduction of the final status vector;
7. unmatched linked Actual evidence does not affect a selected Plan relationship.

If feasible without manufacturing invalid canonical Facts, also characterize that an unmatched linked Actual is not subjected to matching-completion `TransactionEvidence` validation.

## Candidate array-native end-state

The likely A/B end-state is:

```text
explicit Plan selection
→ selected Plan plan_id axis

explicit Actual selection
→ linked Actual index + plan_id axis
→ classify once against selected Plan plan_id axis
→ unmatched durable references
→ matched Actual indices + Plan coordinates

selected Plan Transaction evidence
matched Actual Transaction evidence
→ group Actual evidence cells by Plan coordinate
→ classify relationship status per Plan cell
→ publish aligned result columns directly
→ reduce status counts
```

This is not authorization to implement that exact syntax. The important architectural idea is one visible relation coordinate and one aligned publication path, while preserving the current semantic laws.

## KEEP / OBSERVE / SUBTRACT summary

### KEEP

- explicit caller-owned selections and their order;
- durable `plan_id` only relation;
- source-family qualification;
- Plan one-debit/one-credit completion projection boundary;
- Actual exact debit/credit evidence, including multi-posting arrays;
- source-local exact scale and no cross-source summation;
- open/completed/duplicate/ambiguous states and current signature meaning;
- durable Transaction/Posting provenance;
- currency/direction comparison evidence;
- unmatched Actual reference semantics;
- fail-closed publication;
- live `counts` surface for now.

### OBSERVE / likely refactor

- Plan-per-Actual repeated matching scan;
- `candidateRows` append followed by field-by-field reprojection;
- Transaction-per-Posting full-axis masks as a separate deeper relation concern;
- broad documented Actual evidence surface field-by-field rather than by current reachability alone.

### SUBTRACT candidates

- public `actual_transaction_indices` snapshot-local coordinate;
- private unused `TransactionEvidence.transaction_index`.

### DEFER

- adding transaction posting offsets/counts to canonical Facts;
- a generic relation/group helper;
- deleting documented Actual relationship evidence merely because current consumers do not read every field;
- any Section/Application redesign while the Join owner is under review.

## Next review step

Do not implement the classification refactor first.

The next evidence slice should be a focused **selection/evidence ordering law** over multiple Plans and interleaved Actuals. Once that is green on current `main`, the relation classification and direct aligned publication can be evaluated against explicit preserved laws rather than incidental row topology.
