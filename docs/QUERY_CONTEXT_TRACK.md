# Query / Context Track

Status: **planning note only / no implementation approved yet**  
Date: 2026-06-28

This note defines a future track for small query tools and AI consultation context packets.
It is inspired by the useful separation seen in tools such as mail search/index tools and command-line data filters, but it does not commit `bqn-ledger` to any specific external tool or UI.

The immediate goal is not to add a life log, not to replace the ledger model, and not to create another source of truth.
The goal is to reserve a clean design lane for:

- finding ledger facts quickly
- exporting small machine-readable slices
- building reviewable context packets for later AI consultation
- eventually relating money records to optional non-money life records without mixing their source files

---

## Motivation

`bqn-ledger` already has a stable direction:

```text
source TSV
  -> BQN validation / derived model
  -> report / summary / export / UI
```

Daily reports answer the ordinary question:

```text
What is my current household accounting state?
```

A query/context track would answer smaller questions:

```text
Which rows explain this number?
Which planned payments are due?
Which expenses are food-related in the current cycle?
Which facts should be shown to an AI before asking for advice?
```

This should make the system more searchable without turning the core into a general diary app or an advice engine.

---

## Boundary

```text
BQN core       = validation, accounting meaning, derived data
query tools    = small read-only slices over derived output
context tools  = reviewable packets assembled from explicit slices
AI             = outside interpreter / consultation layer
source TSV     = protected ground
```

Allowed responsibilities:

- read source-derived machine output
- filter rows or summary fields
- expose explicit status words such as `OK`, `WARN`, `ERROR`, `UNAVAILABLE`, `EXPERIMENTAL`
- produce human-reviewable context before AI use
- call existing report / summary / export tools

Forbidden responsibilities:

- edit source TSV files
- delete or rewrite source rows
- merge ledger files into a single `events.tsv`
- infer account roles from names
- hide invalid data behind pretty output
- turn AI advice into canonical numeric output
- create `life.tsv` as part of this track without a later explicit design approval

---

## Relationship to existing source files

Current source-of-truth files remain separate:

```text
journal.tsv
plan.tsv
budget_alloc.tsv
accounts.tsv
cycle.tsv
config.tsv
```

This track must not collapse them into one event log.
It may present an event-like view to humans, but that view is derived and disposable.

A future non-money life log, if approved later, should also stay separate from money source files.
For example, a later design might discuss something like:

```text
life.tsv        optional non-money observations
journal.tsv     money facts
```

That future design is outside the current implementation scope.

---

## Possible command shape

Names are placeholders only.

```sh
tools/find food --cycle current
tools/find plan --status due
tools/find account expenses:food --cycle current

tools/context food --cycle current
tools/context current-cycle --with plans --with envelopes

tools/export summary-json
tools/export summary-ndjson
```

If a command hub exists later, it may route to these tools:

```sh
<hub> find food
<hub> context current-cycle
<hub> export summary-json
```

The hub should route only. It should not implement query logic itself.

---

## Context packet contract

A context packet is not advice.
It is a small, reviewable bundle of facts prepared for a human or AI conversation.

Candidate packet shape:

```text
packet_id
created_at
base_dir_label
as_of
cycle_range
included_sections
source_files_read
warnings
facts
omitted
```

Rules:

1. The packet must say what it included.
2. The packet must say what it omitted when relevant.
3. The packet must preserve status words and warnings.
4. The packet must be reproducible from source TSV and derived outputs.
5. The packet must not become a new source of truth.

---

## Future life-log relationship

A future life-log track could make AI consultation more useful by relating money facts to non-money observations such as fatigue, outings, cooking, reading, project work, or social load.

This document only reserves the boundary.
It does not approve `life.tsv` or any implementation.

Possible later questions:

```text
Did food spending rise after high-fatigue days?
Did book purchases cluster around outings?
Did planned payments collide with hospital / errand days?
What context should be shown before asking an AI about next cycle budget?
```

Important rule:

```text
money facts and life observations may be related by date/ref,
but they should not be forced into one canonical source file.
```

---

## Phases

### Phase 0: docs-only boundary

- Define this track.
- Do not implement query tools.
- Do not create life-log files.
- Do not change source TSV.

### Phase 1: money-only query prototype

Possible later approval:

```text
Approve a read-only money query prototype.
Use existing report / summary / export outputs.
No source TSV mutation.
No life-log implementation.
```

### Phase 2: context packet prototype

Possible later approval:

```text
Approve a read-only context packet prototype for current-cycle money facts.
Packet must be human-reviewable before AI use.
No AI advice is written back to source TSV.
```

### Phase 3: life-log design only

Possible later approval:

```text
Approve a docs-only optional life-log design.
Keep money source files separate.
Do not implement until the money query/context boundary is stable.
```

---

## First safe next step

The safe next step is documentation only:

1. Keep this document linked from `docs/README.md`.
2. Add `TODO.md` linkage later only if this track becomes active work.
3. Keep command hub design separate from query logic.
4. Finish current ledger hardening work before implementing this track.

This keeps the idea alive without letting it swallow the accounting engine.
