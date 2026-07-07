# Daily Trend Explicit Empty Plan Identity Meaning Decision

Status: implemented product decision / repo-wide product meaning
Owner: report
Canonical: no; canonical temporal principle remains `docs/TIME_AS_AXIS.md`
Related map: `docs/DAILY_TREND_EXPLICIT_EMPTY_PLAN_IDENTITY_SEMANTICS.md`
Related characterization: PR #107 empty-id reserve frontier
Implemented by: PR #110
Exit: archive after docs synchronization; reopen only with new evidence

## 0. Decision

Selected candidate:

```text
B. no usable explicit identity; use existing five-field fallback
```

Repo-wide meaning of explicit empty syntax is:

```text
explicit syntax presence
!=
usable explicit identity
```

More concretely:

```text
metadata absent
  -> compatibility fallback identity

explicit plan_id=
  -> compatibility fallback identity

non-empty plan_id=value
  -> explicit identity value
```

This is a product meaning decision.
PR #110 implemented the report-side runtime alignment while preserving first matching token precedence.
It does **not** by itself decide duplicate metadata validity, TSV data, or editor behavior.

## 1. What this decision does and does not decide

This document decides the meaning of explicit empty `plan_id=` for the repo as a product.

It does **not** decide:

- malformed non-empty identity policy
- duplicate `plan_id` metadata validity / uniqueness
- a broad `PlanId` redesign
- deletion of the empty-id reserve branch
- direct `L -> D` rewrite
- source migration
- shared identity-kernel extraction
- any runtime repair in this PR

## 2. Why candidate B is selected

### 2.1 Candidate A is weak here

Candidate A says explicit empty syntax is a valid intentional empty identity.

That is weak for current repo evidence because:

- no normal producer intentionally emits empty identity as a business meaning
- PR #107 only proves reachability, not desirable product ownership
- editor and lifecycle tools already treat empty identity as “missing usable identity” rather than as a distinct positive identity value

So A would overstate the evidence.

### 2.2 Candidate B preserves compatibility without inventing a new regime

Candidate B says explicit empty syntax does not establish a usable explicit identity, so the existing five-field key remains the compatibility identity.

That fits the current repo better because:

- legacy / manual TSV rows without metadata already rely on five-field fallback
- explicit empty metadata is not a producer-owned intentional identity shape
- the report-side fallback rule already exists and is the smallest compatibility-preserving interpretation
- the repo can still distinguish explicit non-empty identity from fallback identity

This keeps the meaning narrow:

```text
absence of metadata
  -> fallback

explicit empty metadata
  -> fallback

explicit non-empty metadata
  -> explicit identity
```

### 2.3 Candidate C is stronger than needed and would break compatibility

Candidate C says explicit empty source input is invalid and should fail closed.

That is a stronger stance than the current evidence requires because:

- it would convert currently reachable legacy/manual data into a hard error
- it would break a currently observable report-side compatibility path
- it would implicitly turn PR #107 from a characterization into a source-policy condemnation, which this PR does not authorize

C may still be a future policy question, but not here.

### 2.4 Candidate D invents a special regime without clear ownership

Candidate D says empty identity should form a separate identity-less semantic regime.

That is not selected because:

- it creates a new semantic category without a clear producer or owner
- it does not simplify current layer behavior
- it would split editor/report behavior further instead of clarifying the contract

## 3. Layer-by-layer meaning under this decision

### 3.1 Report-side fallback semantics

Current report-side `PlanId` implementation (post-#110) preserves first matching token precedence:

- metadata absent -> five-field fallback
- first matching `plan_id=` token empty -> five-field fallback
- first matching `plan_id=` token non-empty -> explicit identity value

Historical pre-#110 report behavior was narrower:

- metadata absent -> five-field fallback
- explicit `plan_id=` -> extracted empty string

PR #110 changed only the empty-value selection rule.
It did not add duplicate-key validation or a new metadata policy.

### 3.2 Editor-side extraction behavior

Current editor-side extraction already collapses both of these to empty extracted identity:

- metadata absent
- explicit empty metadata

That is compatible with the decision because the editor surface is already treating the empty case as “missing usable identity,” not as a positive semantic identity.

The editor extraction shape is therefore consistent with the decision’s product meaning, and PR #110 now aligns the report-side extractor as well.

### 3.3 Plan list behavior

`plan list` currently renders empty extracted identity through the `MISSING-ID` path.

This decision keeps that interpretation:

- empty syntax does not become a new usable plan identity
- list output continues to treat it as lacking a usable identity
- the UI remains compatible with manual TSV rows that do not carry a usable `plan_id`

### 3.4 Plan finish behavior

`plan finish` currently refuses missing identity.

This decision supports that boundary:

- explicit empty syntax is not a usable finish identity
- it should not become a finish target unless a future product decision says otherwise
- completion remains anchored on a usable non-empty identity

### 3.5 Canonical plan add behavior

Canonical `plan add` already generates or validates a non-empty ID and rejects `plan_id=...` through generic metadata input.

This decision does not change that.

It only says that, if explicit empty syntax appears in existing or manual TSV, it should not be treated as a usable explicit identity.

### 3.6 Shared completion / actual matching

Shared completion and actual matching currently consume exact identity equality.

This decision means:

- empty explicit syntax should not create a new matching regime
- actual aggregation should continue to rely on usable identity equality
- empty syntax should remain outside the normal completion key space

That keeps exact matching intact while preserving compatibility fallback for rows that do not carry usable explicit identity.

### 3.7 Actual amount aggregation

Actual aggregation is not being redesigned here.

Under this decision:

- non-empty explicit identities can continue to participate in exact aggregation / matching flows
- explicit empty syntax should not introduce a distinct aggregation key
- legacy rows remain aggregatable through the fallback identity path

This is intentionally narrow: aggregation semantics are left as current-exact-match behavior, with empty syntax treated as lacking usable explicit identity.

### 3.8 Overlap diagnostics

Overlap diagnostics can still observe what is present in source TSV.

This decision does not erase that observation layer.

But product meaning becomes:

- explicit empty syntax is not a usable explicit identity
- diagnostics may still show the raw shape, but that shape should be interpreted as compatibility fallback rather than as a positive identity regime
- overlap checks remain exact-equality diagnostics, not a product endorsement of empty identity as meaningful input

### 3.9 Daily Trend reserve behavior

PR #107 proved the empty-id reserve edge is reachable and that raw frontier `L` can move reserve at a fixed historical row.

PR #110 implemented the report-side alignment that treats explicit empty `plan_id=` like an absent usable identity.
The Daily Trend reserve formula was not rewritten and the empty-id branch code remains.

Current consequence:

- explicit empty syntax no longer selects the empty-id reserve regime
- the historical PR #107 result remains historical evidence only

### 3.10 Legacy / manual TSV compatibility

This is one of the strongest reasons for candidate B.

Manual or legacy TSV rows may exist without an explicit usable identity field.

The decision preserves that compatibility by saying:

- missing metadata is still readable
- explicit empty metadata is not promoted to a special meaning
- both collapse to compatibility fallback identity

That is the least disruptive interpretation that still keeps explicit non-empty identity meaningful.

## 4. Why the split matters

The repo now has three separate observations:

1. explicit empty syntax is reachable
2. the Daily Trend empty-id reserve branch is reachable and L-sensitive
3. the repo needs a product meaning for explicit empty identity

This decision answers only the third question.

It does **not** say the runtime branch was wrong.
It does **not** say the branch should be deleted.
It does **not** authorize `L -> D`.
It does **not** broaden ordinary reserve semantics.

## 5. Boundary with malformed non-empty identity

This PR intentionally does **not** decide malformed non-empty identity policy.

For example:

```text
plan_id=abc
```

may be invalid under editor validation rules, but that is a separate question.

This decision only covers the meaning split between:

- absent metadata
- explicit empty metadata
- non-empty explicit metadata

## 6. Consequences for the surrounding layers

### 6.1 Report compatibility identity

Selected meaning:

```text
plan_id=
  -> compatibility fallback identity
```

### 6.2 Editor extraction

Selected meaning:

```text
absence / explicit empty
  -> empty extracted identity
```

### 6.3 Plan list

Selected meaning:

```text
empty extracted identity
  -> MISSING-ID
```

### 6.4 Plan finish

Selected meaning:

```text
missing usable identity
  -> refuse finish
```

### 6.5 Completion / actual matching

Selected meaning:

```text
usable identity equality
  -> exact match
empty syntax only
  -> not a usable key
```

### 6.6 Overlap diagnostics

Selected meaning:

```text
raw data observation
  !=
product endorsement of empty identity
```

### 6.7 Daily Trend reserve

Selected meaning:

```text
explicit empty syntax presence
  !=
usable explicit identity
```

## 7. Runtime alignment implemented by PR #110

The smallest behavior change is now live:

- explicit empty `plan_id=` falls back to the existing five-field compatibility identity
- non-empty explicit `plan_id=value` remains explicit identity
- ordinary five-field fallback is preserved
- first matching token precedence is preserved
- reserve formula is unchanged
- empty-id branch code is unchanged

## 8. Decision summary

Selected and implemented meaning:

```text
explicit empty syntax presence
!=
usable explicit identity
```

Operationally:

```text
metadata absent
  -> fallback identity

explicit plan_id=
  -> fallback identity

non-empty plan_id=value
  -> explicit identity value
```

This is the product decision for PR #109, implemented by PR #110.
