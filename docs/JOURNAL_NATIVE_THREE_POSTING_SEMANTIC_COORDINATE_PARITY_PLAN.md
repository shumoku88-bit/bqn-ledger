# Journal native three-posting semantic-coordinate parity — test-only

Status: current contract / selected test-only implementation plan
Owner: journal source migration
Canonical: yes
Exit: archive as completed after the dedicated fixture and focused test land, or replace with a new decision if existing pure boundaries cannot support the selected comparison without production normalization
Date: 2026-07-19

## Purpose

Prove, through bounded test-only evidence, that semantic accounting coordinates agree between:

- exactly one native Journal actual transaction with exactly three ordered postings; and
- exactly two legacy TSV source rows representing the same accounting effect and expanding to exactly four Posting IR rows.

The comparison is about semantic accounting coordinates, not row topology. This slice provides finite evidence that native multi-posting reaches checked Posting IR and Cube without being flattened into TSV two-account rows.

## Exact fixture boundary

The implementation will add one dedicated public synthetic fixture:

```text
fixtures/journal-native-three-posting-parity/
  accounts.tsv
  profile.journal
  journal.tsv
```

The focused test will be:

```text
tests/test_journal_native_three_posting_semantic_parity.bqn
```

The fixture will be an independent derivative of the Stage 0 split receipt. It will not directly reuse the complete Stage 0 fixture.

The fixture is fixed to:

- anonymous accounts only;
- integer JPY only;
- exactly one actual transaction;
- exactly three Journal postings;
- exactly two legacy TSV source rows;
- the same date, account, layer, and amount semantics on both paths;
- one shared nonempty `txn_id` on the two legacy rows;
- no `event-id` on the ordinary actual Journal transaction;
- no private data;
- no loan repayment case.

The accounting effect is:

- asset account: `-1100`;
- first expense account: `+800`;
- second expense account: `+300`.

Exact anonymous account names will be fixed in the fixture during implementation. Production account names must not be used.

## Existing paths only

The implementation must use only these existing paths:

```text
Journal:
Parse
-> Stage 2A Build
-> cube.Materialize

Legacy:
BuildCheckedPostingProjectionFromSnapshot
-> cube.Materialize
```

No new `src_next` helper, production normalizer, or runtime route may be added. Any comparison carrier or coordinate reduction needed by the slice must remain inside the focused test.

## Primary parity boundary

The primary comparison boundary is:

```text
(date, account_key, layer_name) -> sum(delta)
```

Both source paths must reduce deltas over the same explicitly fixed coordinate axis. Each result must exactly equal both the expected vector and the cross-source result.

Account totals alone, TBDS totals alone, and transaction balance alone are insufficient as parity proof.

## Secondary Cube assertion

The test must use the same resolved account axis, cycle start, day count, and layer axis for both paths and compare:

- numeric Cube payload;
- Cube shape;
- coordinate-axis interpretation;
- selected numeric projections, including account and layer totals where applicable.

The complete `Materialize` result carriers must not be asserted equal. Journal and legacy have different valid-row counts by design.

Expected observations:

- Journal valid rows: `3`;
- legacy valid rows: `4`;
- skipped rows: `0` on both paths;
- numeric Cube coordinates: identical.

## Local invariants

The focused test must assert all of the following.

### 1. Journal parser

- exactly one admitted transaction;
- exactly three ordered postings;
- zero diagnostics.

### 2. Stage 2A

- exactly three Posting IR rows;
- every row has `status = ok`;
- Posting IR order preserves Journal source posting order.

### 3. Legacy TSV

- exactly two physical source rows;
- exactly four Posting IR rows;
- every row has `status = ok`;
- all four rows retain the same nonempty `txn_id`.

### 4. Balance

- the Journal event delta sum is zero;
- each legacy physical `source_row` group has a zero delta sum independently;
- the complete legacy delta sum is zero.

### 5. Semantic reduction

- both paths equal the three expected coordinate values;
- both paths equal each other.

### 6. Cube

- numeric Cube payload and selected numeric projections agree;
- Journal valid count is three;
- legacy valid count is four;
- skipped count is zero on both paths.

### 7. Topology difference

- Journal retains three rows;
- legacy retains four rows;
- the test explicitly preserves this asymmetry rather than normalizing it away.

## Explicit cross-source non-equality

Cross-source equality must not be required for:

- Posting IR row count;
- complete Posting IR row sequence;
- `source_file`;
- `source_row`;
- `source_id`;
- `tx_id` strings;
- `posting_id`;
- Journal `source_event_id` and legacy `txn_id`;
- `identity_kind`;
- physical provenance;
- transaction-level `kind`;
- side sequence.

The shared legacy `txn_id` is a legacy-side local invariant only. It must not be identified with Journal event identity.

## Non-goals

This slice does not implement or select:

- broader rejection or red-path parity;
- Stage 1 parser or Stage 2A adapter specification expansion;
- a production helper or normalizer;
- production Journal loading or routing;
- a `BuildContext` connection;
- TBDS or report connection;
- `source_row` consumer migration;
- identity/provenance contract changes;
- writer or editor work;
- shadow read;
- conversion;
- cutover;
- a source-of-truth switch;
- TSV cleanup;
- private-data access;
- a numbered follow-up label or automatic selection of any later stage.

## Stop conditions

Stop implementation without adding a workaround if any of these becomes necessary:

- a production normalizer;
- conversion that makes legacy TSV appear to be one Journal transaction;
- a Posting IR contract change;
- a Cube or context production-route change;
- cross-source unification of source identity;
- a Stage 1 parser or Stage 2A adapter specification change;
- private-data access.

Record the mismatch and request a separate design decision.

## Completion conditions

This slice is complete only when:

- only the dedicated public fixture is used;
- the comparison/reduction carrier exists only in the focused test;
- all selected assertions pass;
- production source and runtime behavior remain unchanged;
- focused checks and `tools/check.sh` pass;
- this plan is archived as completed;
- repository routing returns to “no next finite slice selected”;
- no follow-up work is selected automatically.
