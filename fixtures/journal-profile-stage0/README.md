# Minimal BQN Journal Profile Stage 0 fixture

Status: public synthetic characterization evidence only

This directory contains the paper fixture used by the completed Stage 0 characterization:

- `profile.journal` - declarations and five synthetic accounting situations represented by six journal event blocks;
- `expected-posting-matrix.tsv` - the expected signed `event x account` matrix after transaction normalization.

The fixture is deliberately not wired into a parser, runtime, editor, report, or production conversion path.

## Sign convention

The expected matrix follows the current Posting IR convention:

- debit delta: positive;
- credit delta: negative.

Every event row therefore sums to zero.

## Identity note

`event_key` in the TSV is a fixture label for discussion and comparison. It is not a substitute for the future `source_event_id` contract.

Ordinary actual transactions in the paper profile may omit explicit `event-id`. Plans, budget allocations, externally referenced events, and events requiring stable automated editing use an explicit durable `event-id`.

## Current boundary

Current TSV source truth, `tools/to-hledger`, the existing editor, Posting IR runtime, Cube, TBDS, reports, and production data remain unchanged.
