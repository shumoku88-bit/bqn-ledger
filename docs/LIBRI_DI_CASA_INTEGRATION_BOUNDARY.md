# libri-di-casa integration boundary

Status: durable future-integration constraint; no integration is active

## Purpose

`bqn-ledger` may later integrate with or converge with `libri-di-casa`. That possibility affects boundaries now, but it does not justify a speculative shared domain model.

The selected long-term division is:

```text
libri-di-casa / Haskell
  authoritative confirmation, accounting validation, identity, provenance,
  correction, idempotent persistence, and deterministic book transfer

bqn-ledger / BQN
  admission of confirmed accounting evidence into canonical Facts,
  grouping, exact calculation, comparison, Matrix construction,
  and presentation-neutral report results
```

A conversational client, terminal UI, JSON/API adapter, or authenticated HTML presenter remains outside both accounting meanings. Repository layout and process topology may change later; this ownership split must remain explicit.

## Intended data path

```text
human words, observations, or retained evidence
  -> Memoriale / Inventario / Ricordanze interpretation
  -> human confirmation or correction
  -> authoritative libri-di-casa books
  -> versioned confirmed-accounting boundary
  -> bqn-ledger input adapter
  -> canonical Transaction / Posting Facts
  -> narrow accounting capability
  -> neutral report result
  -> terminal, conversation, JSON/API, or HTML presenter
```

The boundary may be an ordinary file, a library value, or a process protocol. Its transport is replaceable. Its accounting meaning, identity, exactness, and provenance are not.

## Constraints on current development

### One authoritative writer

Current `bqn-ledger` editors remain authoritative for the current standalone ledger. A future integration must select one write owner before cutover. Haskell and BQN must not independently mutate two supposedly authoritative copies of the same confirmed event.

Do not turn the current Shell/BQN editor into a universal persistence framework merely to anticipate integration. Preserve its safety while it is in use, and keep it replaceable at the application edge.

### Source role is not source format

Current Facts identify strict sources such as `actual.journal`, `plan.tsv`, and `budget_alloc.tsv`. Several accounting capabilities use those identities as admission guards. This is safe for the current runtime but must not become a permanent claim that confirmed Actual evidence can only have one physical encoding.

A future admitted source boundary must distinguish at least:

```text
semantic role    confirmed Actual, Plan, Budget, or another reviewed role
physical format  Native Journal, libri-di-casa export, or another adapter format
source identity  versioned file/export/store identity
record identity  durable event, Transaction, and Posting identifiers
provenance       source observation, interpretation, confirmation, and correction links
```

Accounting capabilities should depend on an admitted semantic role and canonical Fact invariants. Format parsing and physical source discovery belong to an outer adapter. Until that boundary is implemented and proven, Native Journal remains the sole production Actual source; no fallback or alternate discovery is permitted.

### Neutral report results

Accounting and section results must remain usable without terminal formatting. New calculations should produce bounded values, coordinates, diagnostics, and contributors before selecting a human, compact, JSON, conversational, or HTML presentation.

The current co-location of some semantic section builders and renderers is not a future API contract. Shared terminal/JSON text helpers and report dispatch must not force an external consumer to parse human output.

### Identity, exactness, and provenance survive transfer

An integration may not flatten multi-posting Transactions, infer Account identity from display labels, convert exact coefficients through floating point, or replace source-qualified contributors with aggregate-only values.

A future boundary must explicitly define:

- schema and protocol version;
- deterministic ordering;
- currency/commodity domain and exact coefficient/scale representation;
- durable Account, event, Transaction, and Posting identity;
- correction, supersession, and deletion semantics;
- source and confirmation provenance;
- fail-closed diagnostics and partial-publication behavior.

### No premature book mapping

Current Plan, Budget, Issues, and Daily Target scope must not be silently equated with `Ricordanze`, `Inventario`, or another historically named book. Each mapping requires a concrete record question and an explicit ownership decision. Similar labels do not prove identical lifecycle or authority.

## Known seams to improve before integration

The following are current design seams, not authorization for a broad rewrite:

1. replace physical-name checks such as `SourceIs ⟨facts,"actual.journal"⟩` with an admitted semantic source-role contract when a second real adapter exists;
2. separate neutral section results from terminal/JSON presentation where an external consumer needs the result;
3. remove package-level presentation coupling in which report dispatch imports sections while sections import `src/report` text helpers;
4. decide the standalone editor's retirement or adapter path before another project becomes the authoritative writer;
5. prove any new boundary with public synthetic fixtures covering multi-posting identity, exact mixed-scale amounts, provenance, malformed input, and deterministic output.

Do not add a universal household context, shared mutable store, compatibility alias, or fallback parser to solve these seams.

## Integration gate

A future integration is ready only when one finite slice can answer all of these questions:

1. Which project owns the authoritative write?
2. What exact confirmed record crosses the boundary?
3. How are semantic role and physical format distinguished?
4. Which identities and provenance references survive?
5. How are corrections and replay made idempotent?
6. Can BQN build the same canonical Facts deterministically?
7. Can report consumers use a neutral result without parsing terminal text?
8. Do malformed or incomplete transfers fail closed without partial publication?
9. Can both projects still run their core tests independently?

Until then, preserve a narrow replaceable adapter seam and continue standalone operation.
