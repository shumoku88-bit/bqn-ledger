# Journal native three-posting semantic-coordinate parity — test-only

Status: completed test-only implementation
Owner: journal source migration
Canonical: no; current routing remains `TODO.md` and `NEXT_SESSION.md`
Exit: completed; any later Journal or production work requires a separately selected finite slice
Date: 2026-07-19

## Purpose

This completed slice proves, through bounded test-only evidence, that semantic accounting coordinates agree between:

- exactly one native Journal actual transaction with exactly three ordered postings; and
- exactly two legacy TSV source rows representing the same accounting effect and expanding to exactly four Posting IR rows.

The comparison is about semantic accounting coordinates, not row topology. This slice provides finite evidence that native multi-posting reaches checked Posting IR and Cube without being flattened into TSV two-account rows.

## Exact fixture boundary

The implementation added one dedicated public synthetic fixture:

```text
fixtures/journal-native-three-posting-parity/
  accounts.tsv
  profile.journal
  journal.tsv
```

The focused test is:

```text
tests/test_journal_native_three_posting_semantic_parity.bqn
```

The fixture is an independent derivative of the Stage 0 split receipt. It does not directly reuse the complete Stage 0 fixture.

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

The fixed accounts are `assets:anonymous`, `expenses:anonymous-first`, and `expenses:anonymous-second`. No production account names are used.

## Existing paths only

The implementation uses only these existing paths:

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

## Completion evidence

The completed implementation records the following actual behavior:

- `profile.journal` parses as one ordinary actual transaction with no `event-id`, zero diagnostics, and three ordered postings: `+800`, `+300`, and `-1100`;
- Stage 2A preserves that posting order and emits three `ok` Posting IR rows;
- the two physical `journal.tsv` rows share `txn_id=txn-anonymous-split-001`, and the checked legacy projection emits four `ok` Posting IR rows carrying that metadata value;
- the Journal event, each legacy `source_row` group, and the complete legacy projection each balance to zero;
- the explicit `(date, account_key, layer_name)` axis reduces both paths to `⟨-1100, 800, 300⟩` for asset, first expense, and second expense coordinates;
- both paths materialize the same numeric Cube with shape `31 × 3 × 4`, account vector `⟨-1100, 800, 300⟩`, layer totals `⟨0, 0, 0, 0⟩`, and actual expense total `1100`;
- Cube admission remains intentionally asymmetric at three Journal valid rows versus four legacy valid rows, with zero skipped rows on both paths;
- the comparison carrier and coordinate reduction exist only in `tests/test_journal_native_three_posting_semantic_parity.bqn`;
- no `src_next` helper, production code, runtime route, source-data path, identity unification, or topology normalization was added;
- focused Stage 1, Stage 2A, Cube, and parity tests plus repository checks pass;
- repository routing returns to no next finite Journal slice selected, with no follow-up selected automatically.
