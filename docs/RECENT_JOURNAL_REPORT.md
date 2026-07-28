# Retained Recent Journal report

Status: Portfolio P3 destination proof

Owners:

- `src/accounting/recent_transactions.bqn` — bounded newest-first Fact Join;
- `src/sections/recent_journal.bqn` — retained List result and human/compact rendering;
- `src/report/text.bqn` — plain table rendering shared after two List consumers agreed.

## Accounting boundary

Input is canonical `actual.journal` Facts and an explicit positive integer limit `N`.

```text
selection = final N Transaction Facts in physical source order
result    = selected Transactions reversed to newest first
```

For each Transaction the capability preserves:

- strict date and description;
- currency domain;
- debit and credit Account arrays in transaction posting order;
- exact debit total coefficient/scale;
- source-qualified durable Transaction reference;
- separate debit/credit Posting contributors.

Multi-posting lanes remain arrays. The capability never fabricates one from/to Account. Amount derives through checked exact debit summation; the corresponding credit evidence remains available for zero-sum provenance.

Wrong source Facts, nonpositive/noninteger limit, non-Actual layer, missing lanes, scale mismatch, or exact overflow fails closed with no rows. Valid empty Actual returns an empty List.

## Output

Human output uses a plain List table and includes explicit currency. Compact output is deterministic TSV payload after the key:

```text
ledger_recent_journal: DATE<TAB>CURRENCY<TAB>AMOUNT<TAB>CREDIT_ACCOUNTS<TAB>DEBIT_ACCOUNTS<TAB>DESCRIPTION
```

Account arrays are comma-joined only at rendering. The semantic result retains arrays. JSON is unsupported in Portfolio P1.

The destination heading/key contains no generation name and never dual-emits `src_next_recent_journal`.

## Intentional differences

- explicit currency is present;
- compact payload is tab-delimited rather than space-position parsing;
- multi-posting directions are first-class arrays;
- only canonical complete Facts are accepted;
- no context, source reload, historical delta rows, or one-lane fallback.

Current production remains unchanged until atomic cutover.

## Proof

Public strict evidence proves:

- three newest-first Transactions;
- explicit limit truncation;
- split debit destinations on the newest Transaction;
- exact totals `15`, `20`, and `1000`;
- Transaction and Posting provenance;
- empty Actual;
- wrong source and invalid limit fail-closed;
- deterministic human/compact goldens;
- Planned Payments table bytes remain stable after extracting shared plain table rendering.
