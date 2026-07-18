# Minimal BQN Journal parser Stage 1

Status: completed test-only implementation
Owner: journal source migration
Canonical: no; current routing remains `TODO.md` and `NEXT_SESSION.md`
Exit: completed; production routing, writer work, parity expansion, and source cutover require separately selected slices
Date: 2026-07-18

## Purpose

Implement the smallest BQN parser that can read the public Minimal BQN Journal Profile Stage 0 evidence into a transaction-level representation without changing production source truth or routing.

The implementation is deliberately a test-only characterization surface. It proves that the Stage 0 journal shape can preserve native multi-posting events, identity, plan completion links, execution-envelope links, and signed accounting rows before any production adapter work.

## Implementation

Added:

- `src_next/journal_profile_stage1.bqn`
- `tests/test_src_next_journal_profile_stage1.bqn`

The parser consumes the public synthetic fixture:

- `fixtures/journal-profile-stage0/profile.journal`

It compares the normalized accounting result with:

- `fixtures/journal-profile-stage0/expected-posting-matrix.tsv`

## Supported subset

Stage 1 recognizes only the Stage 0 paper profile required by the public fixture:

- `commodity JPY` declaration;
- account declarations with comment metadata bodies;
- transaction headers with valid date, `*` or `!` status marker, and nonempty description;
- supported transaction metadata keys;
- explicit integer JPY posting amounts;
- actual, plan, and budget layers;
- durable and physical-fallback event identity;
- deterministic posting order and posting identity;
- plan completion and execution-envelope linkage.

It does not claim to parse arbitrary hledger syntax. Includes, aliases, automated postings, periodic transactions, balance assertions, inferred posting amounts, multiple commodities, and unrestricted metadata remain outside this supported subset.

## Transaction IR result

Each admitted transaction preserves:

- `source_event_id`;
- `identity_kind`;
- physical source start and end lines;
- date, status marker, and description;
- layer name;
- plan, allocation, and execution-envelope links;
- ordered metadata;
- ordered postings.

Each posting preserves:

- account key;
- signed delta;
- commodity and source amount text;
- debit or credit side;
- deterministic `posting_index`;
- deterministic `posting_id`;
- physical source line.

Ordinary actual events without explicit `event-id` receive a clearly labelled physical fallback identity. That fallback is not promoted as durable stable-edit identity.

## Fail-closed behavior

The parser emits error diagnostics and withholds invalid transaction records for covered failures including:

- unsupported Stage 0 transaction metadata;
- invalid declaration or transaction shapes;
- missing or unsupported commodity evidence;
- duplicate account, commodity, metadata, event, or plan identities where applicable;
- invalid dates or status markers;
- unknown accounts or commodities;
- missing explicit plan or budget identity;
- missing postings;
- zero, non-integer, or otherwise invalid explicit amounts;
- unbalanced event postings;
- actual completion that does not match exactly one plan;
- plan/completion execution-envelope mismatch.

The parser does not silently infer a missing amount, repair an unbalanced event, or turn rejected evidence into zero-valued success.

## Accounting matrix evidence

`BuildMatrix` projects admitted transactions into the Stage 0 signed `event x account` matrix.

The unit test verifies:

- the public fixture produces five transactions;
- actual, plan, and budget layers remain distinct;
- plan identity and execution-envelope links survive parsing;
- posting counts and order are deterministic;
- each event posting set sums to zero;
- the complete projected matrix equals `expected-posting-matrix.tsv`.

This matrix remains an analytical BQN projection. Transaction blocks are the source evidence and the transaction/posting IRs remain the normalization boundaries.

## Validation

Validation completed through the repository's normal check path:

- `tests/test_src_next_journal_profile_stage1.bqn` passes;
- `tools/check.sh` passes;
- coverage step passes;
- temporary debug workflow evidence was removed before completion.

The red-path test set covers:

- missing plan event identity;
- duplicate required metadata;
- unbalanced postings;
- unsupported transaction metadata.

## Non-change boundary

This Stage 1 does not change or select:

- current TSV source truth;
- current editor or safe-write path;
- `tools/to-hledger`;
- production loader or runtime routing;
- current Posting IR consumers;
- Cube or TBDS shape and behavior;
- reports;
- private-data reads or fixtures;
- journal writer design;
- production conversion;
- shadow-read activation;
- source cutover;
- reverse synchronization.

Draft PR #273 remains parked background evidence.

## Exit result

Minimal BQN Journal parser Stage 1 is complete as a test-only implementation.

The next coherent migration candidate is a separately selected Posting IR adapter parity slice. It would compare Stage 1 normalized postings with current TSV-adapter Posting IR for the subset representable by both, before any report or runtime routing.

A bookkeeping matrix study extension also remains available as an independent research direction. It should add one hand-checkable accounting topic at a time and must not be inferred as a broad engine rewrite.
