# Fintech engineering review backlog

Status: active backlog / docs-only
Created: 2026-07-01
Source: https://w.pitula.me/fintech-engineering-handbook/
Scope: slow review of fintech engineering patterns that may or may not fit `bqn-ledger`

This document is a discussion surface, not an implementation plan.

It exists so that fintech-oriented ideas can be reviewed slowly, one at a time, without forcing `bqn-ledger` to become a fintech SaaS, a banking integration product, or a multi-user accounting system.

## Current repository fit

`bqn-ledger` already has several strong money-system bones:

- source TSV files are the source of truth
- BQN derives views, validation, reports, and exports
- amounts are integer yen
- Posting IR models debit / credit deltas and balance invariants
- Canonical Daily Cube and TBDS are derived views, not source data
- BQN editor uses explicit safe-write paths
- report calculation aims to fail closed instead of producing pretty wrong output
- real household data stays outside the public repository

So the question is not "how do we add every fintech pattern?"

The useful question is:

```text
Which small patterns make this personal ledger safer, clearer, or easier to audit,
without changing the project boundary?
```

## Review rules

For every candidate below, decide one of:

| Decision | Meaning |
| --- | --- |
| `adopt-now` | Worth designing soon as a small docs-first PR. |
| `adopt-later` | Valuable, but only after a concrete need appears. |
| `observe` | Keep vocabulary in mind; no repo change yet. |
| `reject` | Does not fit the current project boundary. |

No candidate should go directly from this backlog to implementation.

Preferred flow:

```text
read candidate
  -> decide fit
  -> write tiny design note or reject note
  -> add fixture/check only if the design changes source contracts or report meaning
  -> implement in a separate PR, if still wanted
```

## Candidate map

| ID | Candidate | Current fit | Suggested first action |
| --- | --- | --- | --- |
| F1 | Multi-time transaction semantics | high | docs-only decision before adding metadata |
| F2 | Reversal / correction linkage | high | extend reversal metadata contract |
| F3 | Editor idempotency keys | medium-high | define command-level duplicate prevention scope |
| F4 | Read-only reconciliation imports | high, but later | design import/reconciliation boundary without auto-editing source TSV |
| F5 | Raw external evidence storage | medium | only if bank/card CSV import starts |
| F6 | Soft period close | medium-high | warning-only design for reviewed/report-exported periods |
| F7 | Negative balance / overdraft policy | medium | document when negative balances are allowed, warned, or errors |
| F8 | Controlled currency / rounding policy | medium, later | keep aligned with multi-currency roadmap |
| F9 | FX metadata | low until multi-currency is real | defer behind F8 |
| F10 | Redacted export surface | medium-high | connect to sanitized report / public sharing work |
| F11 | Funds reservation vocabulary | low-medium | compare with envelope budget; avoid distributed-system complexity |
| F12 | Full SaaS controls / webhooks / provider redundancy | reject for now | explicitly keep out of scope |

## F1. Multi-time transaction semantics

Status: adopt-later (2026-07-11)
Audit document: [FINTECH_F1_MULTI_TIME_FIT_REVIEW-2026-07-11.md](archive/audits/FINTECH_F1_MULTI_TIME_FIT_REVIEW-2026-07-11.md)

### Decision summary
Classified as `adopt-later`. The first journal date column is the current default Event/projection coordinate used by Posting IR, Cube, TBDS, and report period selection; the production contract does not unconditionally define it as an “economic occurrence date.” The card fixture uses separate Events in the repository's actual `from -> to` direction: card usage is `liabilities:card -> expenses:*` (expense and liability increase), and card payment is `assets:bank -> liabilities:card` (bank asset and liability decrease).

The existing cashflow-due design derives a default due date from liability account metadata (`due_day`, `due_month_offset`, `payment_account`) and permits row-level `due_on` overrides. The current tracked tree has no executable derivation/report/check consumer, so this is fixture-backed projection design rather than a current accounting calculation. Future metadata vocabulary such as `occurred_on`, `booked_on`, `paid_on`, or `settled_on` remains unadopted.

### Reopen conditions
Reopen F1 consideration only if:
- A specific consumer (reconciliation, tax export, credit card view, audit view) is designed and requires single-row multi-time metadata for correctness.
- A real data scenario is found where the current model produces incorrect results (e.g. wrong expense period, wrong balance).
- Bank statement import (F4) shows that settlement date matching requires per-row settlement metadata rather than separate entries.
- Tax reporting requires separating economic event date from payment date and cannot derive it from existing postings.

Current opportunity:

- keep the first five TSV columns stable
- avoid overloading `date` with too many meanings
- add optional metadata only when a real report needs it

Possible metadata vocabulary (illustrative, not adopted):

```text
occurred_on=YYYY-MM-DD   # when the event happened economically
booked_on=YYYY-MM-DD     # when it was recorded into this ledger
settled_on=YYYY-MM-DD    # when cash/bank/card settlement actually materialized
value_on=YYYY-MM-DD      # optional synonym only if chosen; avoid both occurred_on and value_on together
```

Questions before adoption:

- Is existing `date` always the default coordinate date?
- Should `booked_on` be generated by the editor, or left out until needed?
- Which report would change first: tax export, reconciliation, card-payment view, or audit display?
- What should happen if `occurred_on` and `date` disagree?

Suggested first PR, if adopted:

- update `docs/TIME_AS_AXIS.md`
- update `docs/JOURNAL_META.md`
- add no runtime code
- add examples only

## F2. Reversal / correction linkage

Status: candidate

`bqn-ledger` already has `journal reverse`. The next audit-oriented improvement is to link the reversal or correction to the original record explicitly, not only by memo text.

Possible metadata vocabulary:

```text
reversal_of=<source_id-or-txn_id>
correction_of=<source_id-or-txn_id>
correction_kind=reversal|adjustment|repost
```

Questions before adoption:

- Should the link target be `source_id`, `tx_id`, `txn_id`, or a new stable `entry_id`?
- Can source-row-derived IDs survive TSV line reordering?
- Should `journal reverse` require explicit `txn_id` before it can create a strong link?
- Should linked corrections appear in normal spending reports, audit reports, or both?

Suggested first PR, if adopted:

- define the metadata contract only
- do not change report behavior yet
- add a future fixture note for reversal linkage

## F3. Editor idempotency keys

Status: candidate

The handbook emphasizes explicit idempotency keys for operations that may be retried. `bqn-ledger` is local and personal, not distributed, but duplicate writes can still happen through repeated UI/editor operations.

Possible scope:

- `plan finish --apply`
- journal add from UI
- budget allocation add
- reversal command

Possible metadata vocabulary:

```text
entry_id=<stable-entry-id>
command_id=<editor-operation-id>
idempotency_key=<operation-scope-id>
```

Questions before adoption:

- Is `plan_id` already enough for plan finishing?
- Should duplicate prevention be a lint warning, an editor hard stop, or a report diagnostic?
- Does the key live in source TSV metadata or only in editor logs?
- Is this useful without an editor operation log?

Suggested first PR, if adopted:

- write `docs/EDITOR_IDEMPOTENCY_DESIGN.md`
- cover only one command first, likely `plan finish`
- no broad framework

## F4. Read-only reconciliation imports

Status: candidate / later

Reconciliation means comparing this ledger with an external statement, such as a bank CSV or card CSV, and surfacing mismatches without blindly overwriting either side.

This fits `bqn-ledger` only if it stays read-only at first.

Possible boundary:

```text
imports/raw/<source>/<file>
imports/normalized/<source>.tsv
reconciliation_breaks.tsv or generated report only
```

Rules:

- never auto-edit `journal.tsv`
- preserve raw external file
- normalize external rows into a separate derived/import area
- expose unmatched or suspicious rows as a report/check
- require human decision for journal changes

Questions before adoption:

- Which external source matters first: bank, credit card, manual CSV, or exported report?
- Should imported files live inside repo, outside repo, or under `LEDGER_DATA_DIR`?
- What is a match: exact amount/date/party, `txn_id`, or heuristic?
- How long should card settlement timing differences remain non-alerting?

Suggested first PR, if adopted:

- docs-only import boundary
- one tiny sample CSV fixture with fake data
- no write path

## F5. Raw external evidence storage

Status: candidate / only if F4 starts

If `bqn-ledger` ever consumes bank/card CSV exports, keeping only normalized rows loses evidence. The raw file is useful when the provider format changes, a parser bug appears, or a mismatch needs investigation.

Possible rule:

```text
Store raw import input unchanged.
Every normalized row keeps import_id and external_row reference.
```

Questions before adoption:

- Is this overkill for manual personal finance?
- Can raw files contain private data that should never enter the public repo?
- Should this belong to real data outside the repository only?

Suggested decision:

- probably `adopt-later`
- tie it to reconciliation only

## F6. Soft period close

Status: candidate

The current roadmap says full period locks / audit trails are not needed for personal use. That still seems right.

A lighter option is a warning-only close marker for periods already reviewed, exported, or publicly shared.

Possible file:

```text
closed_periods.tsv
start	end_exclusive	reason	closed_on
2026-06-01	2026-07-01	monthly_review	2026-07-02
```

Possible behavior:

- no hard lock
- warn if a source row in a closed period changes or is newly added
- stronger warning for tax/export/public-sharing periods

Questions before adoption:

- Is this useful before tax export exists?
- Would it add anxiety or actual safety?
- Should the editor warn only, or should `tools/check.sh` warn too?

Suggested first PR, if adopted:

- docs-only soft close contract
- no editor behavior yet

## F7. Negative balance / overdraft policy

Status: candidate

Negative balances should be representable even when they are undesirable. Clamping negative values to zero would invent money.

Possible account metadata:

```text
allow_negative=true|false
negative_policy=allowed|warn|error
```

Questions before adoption:

- Which accounts may be negative: liabilities, credit card, cash, bank, budget accounts?
- Is a negative asset account always a data problem, or sometimes a timing problem?
- Should household views treat negative balances differently from accounting views?

Suggested first PR, if adopted:

- add a small policy note to `docs/SAFETY_PROFILE.md` or a separate negative-balance contract
- no runtime enforcement until account cases are clear

## F8. Controlled currency / rounding policy

Status: deferred candidate

The roadmap already holds multi-currency for later. If it becomes real, currency cannot be just a free string.

Possible config concepts:

```text
BASE_CURRENCY=JPY
allowed_currency=JPY,USD,EUR
rounding_mode=floor|half_even|manual
rounding_account=expenses:rounding
```

Questions before adoption:

- Is any non-JPY transaction actually needed?
- Is this for card charges, investment, foreign services, or tax export?
- Will `base_amount` be required, or can non-JPY rows stay unavailable in JPY reports?

Suggested decision:

- keep deferred
- use this backlog to avoid designing multi-currency too casually

## F9. FX metadata

Status: defer behind F8

FX rates have direction, source, and time. This should not be added until controlled currency handling exists.

Possible metadata if needed later:

```text
currency=USD
base_currency=JPY
base_amount=180000
fx_rate=150
fx_direction=USDJPY
fx_rate_kind=transactional|reference
fx_rate_on=YYYY-MM-DD
fx_source=card_statement|manual|reference
```

Suggested decision:

- do nothing now
- revisit only after a real non-JPY use case appears

## F10. Redacted export surface

Status: candidate

This fits public sharing and sanitized mock work. It should not alter source TSV; it should be a derived export/view.

Possible output goals:

- keep report shape
- hide or bucket sensitive memo/party/receipt values
- optionally coarsen dates
- preserve enough structure to discuss the system publicly

Questions before adoption:

- Is the target YouTube/public report, fixture generation, or debugging with AI?
- Which fields are sensitive: memo, party, receipt, account names, dates, amounts?
- Should redaction be deterministic so diffs remain stable?

Suggested first PR, if adopted:

- docs-only redaction contract or extension of existing sanitized report mock docs
- no source TSV changes

## F11. Funds reservation vocabulary vs envelope budget

Status: observe

The handbook's funds reservation pattern resembles envelope budgeting only superficially. Reservation is about preventing double-spend during external money flows. Envelopes are a household planning and observation layer.

Useful vocabulary:

```text
total balance
reserved amount
available amount
```

Risk:

- importing reservation machinery could overcomplicate a personal ledger
- envelopes should not become distributed transaction locks

Suggested decision:

- observe only
- maybe use `available` language carefully in envelope reports

## F12. Full SaaS controls and external-provider machinery

Status: reject for now

Do not import these unless the project boundary changes:

- webhooks
- outbox / CDC
- provider redundancy
- multi-user access control
- four-eyes approval
- durable execution engines
- production canary money flows
- database-first locking / transaction design

Reason:

`bqn-ledger` is a personal plain-text ledger and report engine. These patterns are valuable in fintech systems, but they would add steel scaffolding around a small hand-built instrument.

## Suggested review order

Recommended slow path:

```text
1. F1 Multi-time transaction semantics
2. F2 Reversal / correction linkage
3. F7 Negative balance policy
4. F10 Redacted export surface
5. F6 Soft period close
6. F3 Editor idempotency keys
7. F4 Read-only reconciliation imports
8. F8/F9 Multi-currency and FX only if a real use case appears
```

This order starts with vocabulary and contracts, not machinery.

## Non-goals

- Do not make `bqn-ledger` a bank-sync product.
- Do not make source TSV unreadable for the sake of audit theory.
- Do not add database requirements.
- Do not make every fintech pattern a TODO.
- Do not change the first five journal-like TSV columns casually.
- Do not put AI advice or lifestyle judgments into canonical accounting output.

## Related repository documents

- `docs/ARCHITECTURE.md`
- `docs/TIME_AS_AXIS.md`
- `docs/JOURNAL_META.md`
- `docs/POSTING_IR_CONTRACT.md`
- `docs/TBDS_CONTRACT.md`
- `docs/SAFETY_PROFILE.md`
- `docs/ENGINEERING_ROADMAP.md`
- `docs/AUDIT_IMPROVEMENT_BACKLOG.md`
- `docs/PUBLIC_PRODUCTIZATION_REVIEW_FILTER.md`
- `docs/REAL_DATA_TRIAL_SAFETY.md`
