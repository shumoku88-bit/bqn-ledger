# Headless Kernel Phase D: Read-only 6D Feasibility Evidence

Status: audit snapshot
Owner: other
Canonical: no; current path: docs/HEADLESS_KERNEL_EVOLUTION_MAP.md
Exit: retain as Phase D point-in-time evidence after the phase closes; do not treat this document as runtime or source-schema authority

Point-in-time runtime: `main` at merge commit `0d2ae4b77e0b73ac0a1441cd68a52c04492bfe1c`.

## 1. Question

Can the provisional six-dimension view be derived read-only from current row evidence and raw journal-like source fields without introducing a new shared event carrier?

The provisional dimensions are:

```text
when
party / place
what
where-to / account destination
amount
what-happened / action
```

## 2. Overall conclusion

**A. Existing evidence is sufficient.**

This conclusion has a narrow meaning:

- the current checked-result boundary preserves enough source evidence to construct a read-only inspection view;
- each dimension can report whether its meaning is direct, derived, ambiguous, or absent;
- missing or ambiguous semantics must remain visible rather than being guessed;
- the view should consume `row_evidence` plus the checked arithmetic result, not Posting IR alone.

This conclusion does **not** mean:

- every source row contains six definite normalized business facts;
- `memo` is automatically both a party and an item description;
- a precise verb such as paid, received, borrowed, or lent is already selected;
- a 6D runtime view, report, export, or source contract is authorized;
- a new event carrier, `CanonicalEvent`, `Project(events, spec)`, or strict event sourcing is justified.

## 3. Current evidence chain

Current `main` preserves the following chain:

```text
journal.tsv / plan.tsv / budget_alloc.tsv
  -> LoadPostingSourceSnapshot
  -> SplitTsvKeepEmpty
  -> BuildRowEvidenceForLine
       source_file
       source_row
       flds              # every source field, including metadata tokens
       currency
       provenance
       parsed
       state
       message
  -> BuildCheckedPostingProjectionFromSnapshot
       row_evidence
       arithmetic_evidence
       arithmetic_currency_proof
       posting_rows
       diagnostics
```

Important observations:

1. `loader.SplitTsvKeepEmpty` preserves empty source fields, so an empty memo does not shift `from`, `to`, or `amount`.
2. `BuildRowEvidenceForLine` stores the complete `flds` array rather than retaining only the five accounting fields.
3. The checked result returns `row_evidence` directly on both success and error paths.
4. Arbitrary metadata tokens after column five therefore remain available for read-only interpretation even when the accounting projection does not parse them.
5. Posting IR intentionally keeps accounting-normalized fields and does not preserve all descriptive source meaning.

## 4. Dimension-by-dimension classification

| Dimension | Current source owner | Current evidence | Meaning state | Posting IR relation | Phase D finding |
|---|---|---|---|---|---|
| `when` | field 0, `date` | exact source text in `row_evidence.flds`; date validity and derived `day_index` are available downstream | direct when valid; invalid remains visible | preserves `date` and `day_index` | sufficient |
| `party / place` | optional metadata such as `party=...`; sometimes humans place a merchant or place in `memo` | all metadata tokens and memo survive in `flds` | direct only when explicit metadata exists; otherwise ambiguous or absent | memo and arbitrary metadata are not preserved | sufficient for an optional, state-bearing read-only dimension; no safe universal memo fallback |
| `what` | field 1, `memo`, as raw descriptive text | exact memo survives in `flds` | direct as source description, but semantic role may be merchant, item, purpose, or mixed | current `source_id` is sourced from field 1 in the runtime path, but that does not make memo a normalized `what` value | sufficient as raw descriptive evidence with an ambiguity state |
| `where-to / account destination` | field 3, `to`; field 2, `from`, supplies movement origin | both exact account strings survive in `flds`; resolved account keys and roles are available | direct for account destination; invalid or unknown account remains visible | split into debit and credit posting sides; the original pair is easier and safer to read from row evidence | sufficient |
| `amount` | field 4 plus optional `currency=...` | raw amount text, parsed exact decimal result, normalized coefficient, currency provenance, and arithmetic-currency proof are available in the checked result | direct when admitted; malformed or mixed-domain input remains fail-closed | preserves signed `delta`, but raw text and full proof context live outside an individual posting row | sufficient |
| `what-happened / action` | source file, `from`, `to`, account roles, and their direction | exact source direction survives; layer and coarse `kind` are derived | derived at coarse level as actual/plan/budget and income/expense/transfer; precise verbs remain ambiguous unless separately specified | preserves layer, side, and coarse `kind`, but not a selected fine-grained action vocabulary | sufficient for coarse action evidence with an explicit ambiguity state |

## 5. Information-loss boundary

### Row evidence

No source-field provenance extension is required for the feasibility view because `row_evidence.flds` already preserves:

- date;
- memo;
- from account;
- to account;
- raw amount text;
- every metadata token after the fifth field.

The missing precision in `party / place`, `what`, and fine-grained `action` is primarily missing or overlapping **source semantics**, not lost provenance inside the checked-result boundary.

### Posting IR

Posting IR is not sufficient by itself for the full read-only inspection view because it intentionally drops or transforms some descriptive source information:

- memo is not retained as a dedicated descriptive field;
- arbitrary metadata such as `party=` is not retained;
- one source movement becomes separate debit and credit rows;
- amount becomes signed `delta` per side;
- action is reduced to coarse `kind` plus layer and side.

This is not a Posting IR defect. Posting IR remains the accounting normalization boundary. A 6D inspection view should sit beside accounting projections and read the checked evidence from the same snapshot.

## 6. Why conclusion A, not B or C

### Why not B: small provenance extension

A provenance extension is unnecessary for feasibility because the full raw field vector is already present in every row-evidence record and is returned by the pure checked-result boundary.

A future decision might introduce dedicated source metadata such as a more formal party, item, place, or action vocabulary. That would be a source-semantics decision, not a repair for provenance loss in the current checked result.

### Why not C: independent intermediate representation

A separate intermediate representation is unnecessary for a read-only evidence view because:

- the current row evidence already carries the raw source coordinates;
- the checked result already carries admitted amount and currency evidence;
- account resolution and Posting IR provide accounting-derived coordinates when needed;
- no second independent consumer has demonstrated a shared normalized event-carrier requirement.

An independent carrier may be reconsidered only if at least two concrete consumers require the same normalized non-accounting semantics and cannot safely consume current evidence.

## 7. Safe interpretation rule

A future read-only 6D view, if separately authorized, must preserve semantic state per dimension:

```text
direct
  exact source field or explicit metadata

derived
  deterministic current rule with named evidence

ambiguous
  source text exists but does not select one meaning

absent
  the source snapshot contains no supporting value
```

It must not convert `ambiguous` or `absent` into a confident value merely to fill six columns.

## 8. Evidence inspected

- `src_next/loader.bqn`
  - read-only loading and `SplitTsvKeepEmpty`
- `src_next/context.bqn`
  - `LoadPostingSourceSnapshot`
  - `BuildRowEvidenceForLine`
  - `BuildRowEvidenceFromSnapshot`
  - `BuildProjectionRowsForEvidence`
  - `BuildCheckedPostingProjectionFromSnapshot`
- `src_next/projection.bqn`
  - source-field helpers, layer mapping, `InferKind`, and Posting IR shape
- `src_next/account_key.bqn`
  - resolved account roles, currencies, kinds, and raw metadata
- `docs/CONVENTIONS.md`
  - five fixed journal-like fields and optional metadata columns
- `docs/JOURNAL_META.md`
  - optional `party=`, `txn_id=`, `receipt=`, `plan_id=`, and other metadata examples
- `docs/POSTING_IR_CONTRACT.md`
  - accounting-normalized boundary and optional provenance rule
- `tests/test_src_next_checked_posting_projection.bqn`
  - checked-result access to row evidence, exact arithmetic evidence, and fail-visible row statuses

## 9. Scope boundary retained

This investigation does not authorize:

- a 6D runtime implementation;
- a report, JSON export, or CLI command;
- source TSV or metadata schema changes;
- changing Posting IR fields;
- treating 6D as the primary ledger model;
- `CanonicalEvent`;
- `Project(events, spec)`;
- strict event sourcing;
- Phase E;
- a broad `context.bqn` split or a new numbered Stage.

Phase D closure and any later selection remain separate docs-only decisions.
