# Long-term identity and external evidence observation

Status: observation only
Date: 2026-08-11
Scope: long-lived Household identity and external-evidence boundaries; no implementation roadmap
Related: PR #658 `docs: observe future commodity and value boundaries`

## Purpose

Record a second class of future-proofing pressure that is mostly independent from Currency / Commodity / valuation.

A Household ledger can remain numerically correct while becoming historically awkward if current names, external statements, imported rows, documents, or workflow objects are treated as though they were the same thing as canonical accounting facts.

The rule for this observation is:

> Do not prebuild future business or import systems. Preserve enough semantic separation that later evidence can be related to old accounting facts without silently rewriting them.

Missing capability is acceptable. A representation that forces later meaning to be encoded by overwriting old evidence is the risk.

## Current repository evidence

The canonical BQN Account owner is intentionally narrow:

```text
Account identity
accounting type
optional default Commodity
source order / source line
```

Household policy classification is already separate from Account facts.

Canonical Transaction Facts likewise distinguish source-qualified transaction identity, description, metadata, Plan/Actual relationships, Domain/Layer coordinates, and Posting evidence. Snapshot-local indices are explicitly not durable external identity.

Those are useful starting conditions. This observation does not request a replacement Account identity model or a wider Transaction schema now.

## Boundary 1: Account identity and lifecycle

Today the canonical Account key is the ledger identity. That is a practical Plain Text Accounting representation and does not need to change speculatively.

Long-lived records may eventually face:

```text
bank / card rename
account closure
card reissue
institution merger
human-facing hierarchy reorganisation
spelling or presentation changes
```

Future work should therefore preserve the conceptual separations:

```text
Account identity != current display label
Account identity != current institution name
closed != deleted
renamed != necessarily a new economic position
current Account policy != historical Posting evidence
```

This does **not** authorize a new opaque AccountId today.

If a concrete rename/lifecycle requirement appears, first decide whether explicit migration, aliases, lifecycle evidence, or a durable identifier is actually needed. Do not introduce an identity framework merely because names can theoretically change.

The immediate guardrail is narrower: do not make repository-wide rewriting of historical Journals the only possible way to represent a current naming change.

## Boundary 2: description is not counterparty identity

A Transaction description is admitted human/accounting source text. It is not necessarily a stable merchant, person, customer, vendor, or institution identity.

Examples such as:

```text
Amazon
AMZN MKTP JP
Amazon Marketplace
```

may or may not refer to one economic counterparty.

Preserve:

```text
description != counterparty identity
Account != counterparty
free text != durable external entity identity
```

No Payee / Counterparty registry is required now.

If later household sharing, lending, merchant analysis, or business activity creates a real counterparty requirement, add it as separate evidence rather than redefining historical descriptions.

## Boundary 3: calculated balance and observed balance

The current ledger correctly derives balances from admitted Postings.

A bank/card statement can provide different evidence:

```text
statement date
observed ending balance
institution/source
possibly statement identity
```

That evidence is not an accounting Transaction and should not become one merely to make the calculated balance agree.

Preserve:

```text
derived balance != observed/asserted balance
balance assertion failure != missing Transaction already identified
external statement evidence != canonical Posting
```

A future balance assertion capability may compare these two meanings and fail closed when they disagree. It should not automatically invent a balancing transaction unless a separate explicit correction operation authorizes one.

No balance-assertion syntax or report is requested now.

## Boundary 4: external/import observation and canonical event

A future bank/card/CSV/API importer may observe rows carrying:

```text
external transaction id
statement/import batch
raw description
posting date
amount
institution-specific fields
```

Those rows are candidates/evidence, not automatically canonical Household events.

Preserve:

```text
external observation != canonical transaction
external identity != ledger transaction identity
import batch provenance != accounting source identity
match decision != transaction meaning
replay of external evidence != new economic event
```

If import becomes concrete, stable external identity should be usable for duplicate/replay detection where available. Date + description + amount must not become the permanent identity law merely because it is convenient for an initial importer.

No importer or matching engine is requested now.

## Boundary 5: documentary evidence and financial fact

A long-lived Household may eventually retain evidence such as:

```text
receipt image
invoice PDF
bank statement
contract
email
tax document
```

These can support or explain accounting facts without being the accounting facts themselves.

Preserve:

```text
financial fact != documentary evidence
document filename/path != transaction identity
AI extraction != accepted canonical event
```

A future AI-assisted path should conceptually remain:

```text
document / external evidence
  -> interpretation candidate
  -> human or policy admission
  -> canonical Household fact
```

Do not embed binary documents into current Journal syntax merely to reserve this future.

## Boundary 6: accounting transaction and workflow object

Household accounting can already represent many economically relevant business-like events through ordinary Accounts and multi-Posting Transactions:

```text
income / expense
accounts receivable / payable positions
fees
taxes
gross and net components
```

The existence of those accounting meanings does not imply that invoice/customer/vendor workflow objects are required.

Preserve:

```text
accounting transaction != invoice
Account != customer/vendor
receivable/payable balance != workflow status
```

Only introduce invoice/customer/vendor owners if a concrete workflow requires due dates, document numbering, payment matching, reminders, or lifecycle state that cannot be expressed as accounting evidence alone.

This observation explicitly rejects speculative business-suite expansion.

## Gross, net, fees, and taxes are not a new core-money problem

The current multi-Posting model is already capable of representing components such as:

```text
gross amount
withholding tax
service fee
net bank movement
```

as separate Account movements inside one balanced Transaction.

Therefore this observation does not request GrossAmount, NetAmount, Fee, or Tax fields on Transaction Facts.

If a future UI/report wants named presentation for those meanings, derive it from explicit Account/policy evidence or introduce a narrow domain owner at that time. Do not collapse several economic components into one bank-net amount as source authority.

## Time coordinates: add meanings by name, not generic slots

PR #658 already protects `transaction date != settlement date` and related valuation-time distinctions.

This observation adds one guardrail for external evidence: do not reserve a generic `date2` field.

If a concrete capability later needs another date, prefer the named meaning:

```text
BankPostingDate
StatementDate
SettlementDate
DocumentDate
```

rather than a permanently ambiguous secondary date whose meaning changes by caller.

Current Transaction date meaning should remain stable for old data.

## Current configuration and historical evidence

Long-lived identity/evidence interacts with the existing Household history rule:

```text
current configuration / current labels
!= historical evidence
```

Examples:

- closing an Account must not erase its old Postings;
- changing a current label must not silently reinterpret old external evidence;
- changing import rules must not change which historical external row was accepted as which canonical event;
- moving or renaming a document must not change the accounting event it once supported.

When historical meaning genuinely changes, prefer explicit attributable correction/migration evidence.

## BQN-specific guardrails

For bqn-ledger specifically:

- keep canonical Account admission narrow until a concrete lifecycle requirement proves a new coordinate;
- do not widen `facts.bqn` with payee, document, statement, invoice, or reconciliation columns merely to reserve them;
- keep source-qualified durable transaction identity distinct from external/import identity;
- preserve source order and provenance when future matching relates outside evidence to canonical Facts;
- represent future comparison/matching as explicit aligned evidence/relations rather than mutating canonical numeric Facts;
- let multi-Posting Transactions continue to represent fee/tax/gross-net accounting before inventing dedicated monetary fields;
- do not make a generic business/import framework a prerequisite for ordinary Household use.

## Useful future characterization witnesses

If a concrete capability reaches one of these boundaries, a small witness is preferable to broad implementation:

```text
closed Account with historical Postings still reportable
renamed display label without changing historical transaction evidence
same description text referring to two distinct counterparties
statement balance equal to derived balance
statement balance disagreeing with derived balance without auto-correction
same external row replayed twice with one stable external identity
one document linked to an existing event without becoming its identity
one gross/net/fee/tax Transaction represented only by multiple Postings
one later named posting/statement date distinct from the canonical transaction date
```

None is required by this observation.

## Explicit non-goals

This observation does not authorize:

- opaque AccountId migration;
- Account rename/alias/closure syntax;
- counterparty/payee registry;
- bank/card importer;
- reconciliation engine;
- balance-assertion syntax;
- document store;
- receipt OCR/AI ingestion;
- invoice/customer/vendor system;
- business accounting suite;
- generic second date;
- new Transaction/Posting Fact columns;
- source migration;
- writer changes;
- private Household data changes.

## Decision

The repository does not currently show a critical identity/evidence dead end.

The correct future-proofing action is preservation rather than expansion:

```text
identity != current label
canonical fact != external observation
derived balance != asserted external balance
description != counterparty
a financial fact != its document evidence
accounting event != workflow object
```

Only when a real Household need reaches one of these boundaries should the repository add the smallest named owner/evidence required by that need.
