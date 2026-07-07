# Outlook Record Frontier Relation Decision

Status: current decision / pre-runtime freshness relation contract
Owner: report
Canonical: no; canonical temporal principle remains `docs/TIME_AS_AXIS.md`
Consumer question: `docs/OUTLOOK_HOUSEHOLD_QUESTION_DECISION.md`
Transport boundary: `docs/OUTLOOK_OBSERVATION_TRANSPORT_BOUNDARY.md`
Current paired characterization: `tests/test_src_next_outlook_observation_sensitivity.bqn`
Exit: revise or archive after explicit Outlook observation runtime work consumes this relation contract

## 0. Purpose

The selected Outlook direction separates:

```text
O = caller-selected observation date
L = last recorded actual-coordinate frontier
C = cycle boundary
```

PR #91 characterized a concrete case where:

```text
O = 2026-01-03
L = 2026-01-06
```

Current Outlook cannot express that distinction because it approximately returns:

```text
as_of        = local L
last_journal = local L
journal_lag  = 0
```

PR #92 selected an explicit consumer boundary for future Outlook observation transport, conceptually:

```text
outlook.BuildAt(ctx, O)
```

Before that mechanism can be implemented safely, Outlook needs a contract for the relative position of `L` and `O`.

This document selects that relation.

## 1. Decision

Canonical Outlook record-frontier relation uses four states:

```text
before_observation
a t_observation
after_observation
unavailable
```

The intended spelling is:

```text
before_observation
at_observation
after_observation
unavailable
```

The relation is determined only from named temporal meanings:

```text
L < O  -> before_observation
L = O  -> at_observation
L > O  -> after_observation
no trustworthy L -> unavailable
```

When both `O` and `L` are available, Outlook may also expose a nonnegative distance magnitude:

```text
record_frontier_distance_days = abs(O - L)
```

The relation gives direction.

The distance gives magnitude.

Neither field claims that records are complete, reconciled, or authoritative through `L`.

## 2. Correction of the vocabulary typo above

The only valid relation values selected by this document are exactly:

```text
before_observation
at_observation
after_observation
unavailable
```

No value containing whitespace is part of the contract.

## 3. Why relation + distance is selected

A single scalar called `journal_lag` cannot faithfully represent all characterized states without an additional convention.

### Signed scalar only

Candidate:

```text
O - L
```

Possible values:

```text
positive
zero
negative
```

Not selected as the primary representation.

Reason:

```text
negative lag
```

is semantically opaque in a household report and easy to misread.

A sign convention also hides the named meanings behind arithmetic.

### Nonnegative lag only

Candidate:

```text
max(0, O - L)
```

Not sufficient as the primary representation.

It collapses:

```text
L = O
```

and:

```text
L > O
```

into the same value:

```text
0
```

PR #91 already proves that `L > O` is a real reachable state under current inputs and explicit context observation.

### Relation only

Candidate:

```text
before / at / after / unavailable
```

Useful but incomplete for user-facing staleness magnitude.

### Relation + distance

Selected.

It preserves:

```text
direction
magnitude
unavailable state
```

without overloading sign or inventing one universal cutoff meaning.

## 4. Exact meanings

### `before_observation`

Condition:

```text
L < O
```

Meaning:

```text
the maximum admitted recorded actual coordinate lies before the selected observation date
```

Example:

```text
O = 2026-07-07
L = 2026-07-05
relation = before_observation
distance_days = 2
```

This does not prove:

```text
all records through 2026-07-05 are complete
```

It proves only the relative position of the selected frontier value.

### `at_observation`

Condition:

```text
L = O
```

Meaning:

```text
the maximum admitted recorded actual coordinate equals the selected observation date
```

Example:

```text
O = 2026-07-07
L = 2026-07-07
relation = at_observation
distance_days = 0
```

Do not label this automatically as:

```text
complete
fully current
reconciled
```

Coordinate equality is weaker than completeness.

### `after_observation`

Condition:

```text
L > O
```

Meaning:

```text
the admitted recorded actual frontier extends beyond the selected observation date
```

Example from the paired characterization shape:

```text
O = 2026-01-03
L = 2026-01-06
relation = after_observation
distance_days = 3
```

This state is important for:

```text
historical observation
replay
later-known records
future-dated journal anomalies
period-leak evidence
```

The relation alone does not decide which explanation applies.

It prevents the explanation from being hidden by a clamped lag of zero.

### `unavailable`

Condition:

```text
no trustworthy L can be derived under the selected frontier producer contract
```

Examples may include:

```text
no admitted actual rows
invalid source state
frontier producer explicitly unavailable
```

This decision rejects inventing a freshness frontier from an unrelated fallback date merely to avoid absence.

In particular:

```text
cycle.start
```

is not automatically evidence that an actual record exists on that date.

## 5. Important limitation: L is not K

This relation compares:

```text
last recorded frontier L
```

with:

```text
observation O
```

It does not introduce or replace:

```text
data / knowledge cutoff K
```

A dataset can have:

```text
L = 2026-07-05
```

without proving that the adopted input set is complete through that date.

Therefore the selected field names should avoid claims such as:

```text
data_complete_through
knowledge_current_through
fully_recorded_through
```

unless a separate K or completeness contract is introduced later.

## 6. Selected conceptual output shape

For a future explicit Outlook observation path, the preferred conceptual fields are:

```text
as_of                         = O
last_recorded_on               = L, when available
record_frontier_relation       = before_observation | at_observation | after_observation | unavailable
record_frontier_distance_days  = abs(O - L), when available
```

Current field:

```text
last_journal
```

may remain as a compatibility alias during migration if it truly carries the selected L producer value.

This document does not require an immediate rename.

## 7. Decision for current `journal_lag`

Current:

```text
journal_lag = 0
```

is classified as a legacy field from collapsed O/L semantics.

It is not selected as the canonical representation of frontier relation.

A future runtime slice must not silently reinterpret `journal_lag` as a signed offset.

If compatibility requires retaining it, the preferred compatibility meaning is narrow:

```text
journal_lag = max(0, O - L)
```

that is:

```text
days the recorded frontier lies behind observation
```

Under that compatibility meaning:

```text
before_observation -> positive lag
at_observation     -> 0
after_observation  -> 0
```

Therefore `journal_lag` is insufficient by itself and must not replace the selected relation field.

For:

```text
unavailable
```

this document does not authorize fabricating `0`.

A runtime slice must choose an explicit unavailable representation compatible with its output surface.

## 8. Why `current` / `stale` / `future` are not selected values

These labels were considered informally but are not selected.

### `current`

Rejected because:

```text
L = O
```

does not prove completeness.

### `stale`

Rejected as the canonical relation name because it adds a quality judgment.

`L < O` is a positional fact.

Whether that delay is operationally stale may depend on workflow expectations.

### `future`

Rejected because:

```text
L > O
```

may arise from historical replay against later-known actual records, not necessarily an invalid future-dated Event relative to system today.

The selected vocabulary stays geometric:

```text
before
at
after
```

relative to observation.

## 9. Producer scope remains separate

This decision does not standardize how `L` is produced.

Open producer questions remain:

```text
ledger-wide maximum actual coordinate?
period-contained maximum?
selected-domain maximum?
subject to K?
what rows are admitted?
```

Those questions affect which L value is compared.

They do not change the relation algebra once a trustworthy O and available L are supplied.

Therefore:

```text
frontier producer policy
```

and:

```text
O/L relation classification
```

remain separate responsibilities.

## 10. Current helper fallback warning

Current local helpers may return a cycle boundary fallback when no qualifying journal row exists.

Such a fallback can be useful for calculation continuity.

It is not automatically valid record-frontier evidence.

For the selected canonical relation:

```text
no actual frontier evidence
```

should map to:

```text
unavailable
```

rather than silently pretending:

```text
L = cycle.start
```

This is a future runtime requirement, not a change in this docs-only slice.

## 11. Relationship to the selected household question

Canonical Outlook asks at `O` about spending room through `C`, while separately showing recorded frontier `L`.

The selected relation supports that question directly:

```text
O-relative spending calculation
+
L-relative record-frontier context
```

Example:

```text
Observation: 2026-07-07
Last recorded coordinate: 2026-07-05
Relation: before_observation
Distance: 2 days
```

Another valid example:

```text
Observation: 2026-01-03
Last recorded coordinate: 2026-01-06
Relation: after_observation
Distance: 3 days
```

The second case must not be flattened to:

```text
lag = 0
```

with no further explanation.

## 12. Consequence for explicit `Outlook.BuildAt`

The freshness blocker identified in PR #92 is now resolved at the relation-contract level.

A later runtime slice may add an explicit observation path conceptually shaped as:

```text
outlook.BuildAt(ctx, O)
```

provided it can:

```text
1. derive or receive trustworthy L separately
2. classify L relative to O
3. expose relation + distance without completeness claims
4. apply O to O-relative calculations
5. preserve current Build(ctx) behavior unless a separate migration decision changes it
```

This decision does not itself authorize runtime changes.

## 13. Recommended next finite runtime slice

The next runtime slice should remain narrow:

```text
add explicit Outlook observation mechanism
without changing production default wiring
```

Conceptual target:

```text
BuildAt(ctx, O)
```

Protected property:

```text
observation consistency
```

Expected behavior under the existing PR #91 fixture pair:

```text
O moves, L fixed
  -> O-relative terms follow O
  -> L relation updates only as a consequence of O/L comparison

O fixed, L moves
  -> O-relative terms stay tied to O
  -> last-recorded relation follows L
```

The runtime slice should not bundle:

- report CLI `--as-of`,
- production report switchover,
- summary switchover,
- Daily Trend changes,
- cycle-resolution changes,
- L producer unification,
- universal TemporalFrame,
- source TSV changes.

## 14. Runtime gate

A runtime slice may proceed only after it can state:

1. O is caller-owned and explicit,
2. L is independently derived or supplied,
3. relation values are exactly the four selected states,
4. distance is nonnegative magnitude only,
5. equality does not imply completeness,
6. unavailable does not fake cycle.start as evidence,
7. any retained `journal_lag` is compatibility-only and cannot replace relation,
8. current production Build(ctx) behavior remains separately controlled.

## 15. Decision summary

```text
Selected relation:
  L < O  -> before_observation
  L = O  -> at_observation
  L > O  -> after_observation
  no trustworthy L -> unavailable

Selected magnitude:
  abs(O - L)

Not claimed:
  completeness through L
  data cutoff K
  reconciliation status

Current journal_lag:
  legacy from collapsed O/L semantics
  not canonical by itself

Next runtime target:
  explicit consumer-specific Outlook observation path
  production default unchanged
```

The relation is intentionally simple.

It names geometry before policy judgment.
