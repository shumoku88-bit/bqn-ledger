# Journal metadata inventory

This document inventories the transaction metadata admitted by the current native Journal parser and separates four different questions:

1. What can be persisted?
2. Which path writes it?
3. Which runtime code gives it meaning?
4. Can it be regenerated or removed without losing information?

This is a code-surface inventory. It does not inspect private production data, so it does not claim how often each key appears in the user's Journal.

## Current boundary

`src/editor/journal_profile.bqn` admits 22 transaction metadata keys:

```text
action
receipt-id
event-id
layer
plan-id
execution-envelope
allocation-id
agreement-id
actual-event-id
tax
biz
invoice
note
due-on
receipt
txn-id
party
cashflow
currency
income-budget
recur
series
```

The parser preserves every admitted item in `transaction.metadata`, but only seven keys are promoted to dedicated transaction fields:

```text
event-id
layer
plan-id
allocation-id
execution-envelope
actual-event-id
txn-id
```

That distinction matters. Parser admission is not proof that a key currently participates in accounting, reports, or workflow behavior.

## Writer surface

The ordinary and durable native Journal append owner, `src_edit/journal_block_add_cmd.bqn`, accepts these metadata arguments:

```text
tax
biz
invoice
note
due_on -> due-on
receipt
txn_id -> txn-id
party
plan_id -> plan-id
cashflow
currency
recur
series
```

It writes `event-id` separately only for durable transactions. Ordinary actual transactions intentionally carry no explicit `event-id`.

`src_edit/plan_finish_cmd.bqn` creates a deterministic durable identity:

```text
completion-<plan-id>-<actual-date>
```

It uses the selected plan row's `currency=` token to resolve and validate the transaction domain, then leaves that token in `plan.tsv`. The completed Actual carries currency in its posting commodities and no longer duplicates it as `; currency: JPY` metadata.

The command still copies the remaining plan metadata broadly. This means plan-oriented metadata such as `recur` and `series` can be copied into an Actual transaction even though the Journal runtime gives them no recurrence semantics.

No current production writer was found for `action`, `receipt-id`, `layer`, `execution-envelope`, `allocation-id`, `agreement-id`, `actual-event-id`, or `income-budget`. Their current presence in the parser comes from historical migration compatibility, public synthetic characterization, or test-only event forms.

## Semantic tiers

### Tier A: structural or functional metadata

These keys currently affect identity, layer selection, cross-event validation, or Posting IR.

| Key | Generation source | Current readers | Regeneration | Removal assessment |
|---|---|---|---|---|
| `event-id` | Caller-supplied durable append; deterministic plan completion; historical migration and reverse paths | Parser identity, posting IDs, duplicate checks, cross-event references, identity inventory | Depends on family. Some historical migration and completion IDs are reproducible; externally supplied IDs may not be | Keep when referenced or externally meaningful. Ordinary Actuals already omit it. Reconstructibility alone is not deletion authority. |
| `layer` | Explicit historical/test plan and budget events; omitted by ordinary Actual writer | Parser chooses `actual`, `plan`, or `budget`; Posting IR layer index and transaction kind | `actual` is the parser default and is known from the production Actual source boundary. Other layers are not reliably derivable from postings | `layer: actual` is a strong cleanup candidate in an Actual-only Journal. Keep explicit non-Actual layers while those event forms exist. |
| `plan-id` | Plan editor and plan completion workflow; explicit metadata append | Parser completion links, plan completion validation, `actual_source.CompletionEvidence`, budget synchronization, identity inventory | Sometimes visible inside a completion `event-id`, but not universally and not safely for arbitrary imported data | Keep. It is a real external relationship between a plan row and an Actual transaction. |
| `execution-envelope` | Historical/test plan and completion events; no current general writer found | Parser checks equality between an internal plan and its completion; identity inventory treats it as a functional link | It may be proposed again from current policy, but that would not prove the historical accepted value | Keep where present until the plan/envelope model is deliberately simplified. Do not regenerate historical meaning from mutable defaults. |
| `allocation-id` | Historical/test budget-layer allocation events; no current production writer found | Parser requires it as one possible budget-event link; identity inventory treats it as functional | External identifier, not derivable from postings alone | Keep where used. Retire parser support only after confirming there are no production occurrences or consumers. |
| `actual-event-id` | Test-only persisted budget companion linked to a durable Actual event | Parser validates one companion target and uniqueness; identity reference inventory | Not derivable from companion postings because several Actual events could have the same date, accounts, and amount | Keep on linked companions. The companion design depends on this explicit link. |
| `txn-id` | Explicit metadata append or migrated legacy `txn_id` | Parser promotes it; Posting IR uses it as `tx_id`; source identity remains separate | Human/business grouping is not reliably derivable from transaction shape | Keep when present. It is the only generic metadata key projected into current Posting IR behavior. |

### Tier B: accounting-domain marker duplicated by stronger source evidence

| Key | Generation source | Current readers | Regeneration | Removal assessment |
|---|---|---|---|---|
| `currency` | Historical conversion, existing source, or explicitly supplied metadata; current ordinary and plan-completion writers omit it | Parser validates an existing marker; complete-source admission obtains the accounting domain from posting commodities and resolved account currencies | For a valid single-domain transaction, the posting commodity reconstructs the transaction currency exactly | Stop-writing is complete for current ordinary and plan-completion Actual paths. Existing markers remain accepted for compatibility and may later be removed through a previewed source cleanup. |

### Tier C: human or policy evidence preserved generically

These keys are admitted and carried in `transaction.metadata`, but the current parser, Posting IR, and complete-source admission do not give them dedicated runtime fields.

| Key | Typical origin | Current semantic consumer | Regeneration | Removal assessment |
|---|---|---|---|---|
| `tax` | User or migrated TSV | None in current Journal runtime | Not derivable safely | Preserve if the information matters; it is source evidence rather than computed data. |
| `biz` | User or migrated TSV | None in current Journal runtime | Not derivable safely | Preserve unless the project intentionally abandons this classification. |
| `invoice` | User or migrated TSV | None in current Journal runtime | Not derivable safely | Preserve as documentary evidence. |
| `note` | User or migrated TSV | None in current Journal runtime | No | Preserve when useful. The transaction description may overlap but is not necessarily equivalent. |
| `due-on` | User exception or migrated TSV | None in current Journal runtime | A default date may be computable, but an exception value is not safely reconstructible | Preserve existing values. Reconsider whether new Actual transactions should carry a planned due date after payment. |
| `receipt` | User or migrated TSV | None in current Journal runtime | No | Preserve as an external evidence reference. Prefer this spelling over the separate parser-only `receipt-id`. |
| `party` | User or migrated TSV | None in current Journal runtime | Sometimes resembles the description, but not reliably | Preserve where it adds information. A future design may move party into a first-class event field. |
| `cashflow` | User or migrated TSV | None in current Journal runtime | Account roles may suggest a category but cannot prove the user's intended liquidity treatment | Preserve unless replaced by an explicit derived and reviewed rule. |
| `income-budget` | Historical conversion/profile compatibility | No current runtime consumer found | Policy meaning is not recoverable from postings | Existing values should be preserved. Current writer support can remain absent unless a real use returns. |

### Tier D: opaque plan metadata copied into Actuals

| Key | Generation source | Current readers | Regeneration | Removal assessment |
|---|---|---|---|---|
| `recur` | Plan row, historical conversion, explicit append | Generic metadata only; no recurrence semantics in Journal runtime | Often recoverable from the linked plan row while it still exists | Stop-copying candidate for future plan completions. Existing Actual copies are likely removable only after confirming the plan source and retention policy. |
| `series` | Plan row, historical conversion, explicit append | Generic metadata only; identity inventory currently treats presence as a functional link, but no calculation consumes it | Often recoverable from the linked plan row while it still exists | Stop-copying candidate. Prefer `plan-id` as the durable Actual-to-plan link rather than duplicating plan series metadata. |

### Tier E: parser-only historical or synthetic vocabulary

| Key | Observed source | Current readers | Regeneration | Removal assessment |
|---|---|---|---|---|
| `action` | Stage 0 synthetic and historical profile examples | Generic metadata only | May be guessed from postings but cannot be reproduced as the original wording | Candidate to retire from the supported profile after checking production occurrence counts. |
| `receipt-id` | Stage 0 synthetic profile | Generic metadata only | No | Candidate to retire in favor of the writer-supported `receipt` spelling, after occurrence checks. |
| `agreement-id` | Stage 0 and bookkeeping-matrix synthetic fixtures | Generic metadata only | No | Keep only if an active receivable/payable agreement model uses it. Otherwise retire from the production profile while fixtures may keep their own test vocabulary. |

## Important observations

### 1. The allowlist is broader than the current writer

The parser admits 22 keys, while the ordinary native append path accepts 13 metadata arguments plus optional durable `event-id`. This means the supported read surface contains historical and test-only vocabulary that current users cannot normally create through the editor.

### 2. Generic preservation has been mistaken for runtime meaning

Most metadata survives because migration work chose lossless preservation. That was valuable during TSV-to-Journal conversion, but it does not make every preserved key a permanent Journal concept.

### 3. `currency` stop-writing is complete for current Actual writers

Public fixtures already proved that a minimal Actual without `currency: JPY` has the same accounting, Cube, and TBDS results as a metadata-bearing form. A focused durable-completion fixture now keeps `event-id` and `plan-id` fixed while removing only `currency: JPY`; parser and Stage 2A outputs remain equal. Ordinary add and plan finish both leave the marker out, while posting commodities remain explicit.

### 4. Plan metadata still leaks into completed Actuals

The plan finish command still copies plan metadata broadly. `plan-id` is the durable relationship that the Actual needs. `recur` and `series` describe the plan source and currently have no Actual-runtime meaning. The writer should select metadata intentionally rather than copy almost everything.

### 5. Human evidence and computed metadata require different cleanup rules

A field being unused by reports does not make it disposable. `receipt`, `party`, `note`, tax markers, and similar values may be the only surviving human evidence. In contrast, `layer: actual` and legacy `currency: JPY` markers duplicate structural facts and are better cleanup candidates.

## Open experiments

These are independent, reversible experiments rather than a fixed queue.

1. Add a read-only metadata occurrence command that reports key counts and example-free structural statistics for the selected Journal. This would reveal which parser-only keys actually exist in production without exposing values.
2. Change plan completion rendering in a public fixture so it copies `plan-id` and explicitly selected Actual evidence, while leaving `recur` and `series` in `plan.tsv`.
3. Prove that removing explicit `layer: actual` from an Actual-only Journal leaves behavior unchanged, then stop writing it wherever a current writer still does.
4. After occurrence evidence, shrink the parser allowlist by retiring unused parser-only keys or move them to a separate compatibility profile.
5. Add a previewed cleanup for existing reconstructible metadata markers after occurrence counts and source-level parity are available.

## Current conclusion

The Journal metadata surface is not one coherent schema. It currently combines:

- structural identity and cross-event links;
- duplicated structural markers;
- human documentary evidence;
- plan-source metadata copied into Actuals;
- historical and synthetic compatibility vocabulary.

The safest cleanup strategy is therefore not a mass deletion. It is to separate these categories, stop writing reconstructible or misplaced metadata first, and only then consider rewriting existing Journal blocks with public-fixture parity and private read-only occurrence evidence.
