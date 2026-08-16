# Destination report portfolio contract

Status: current production contract  
Updated: 2026-08-16  
Current production: `tools/report` -> strict `src/` composition

## Static destination catalog

The destination catalog is source-independent and has these keys in this order:

```text
envelopes
balances
balance-sheet
profit-and-loss
recent
planned
cycle-accounts
cycle-comparison
monthly-accounts
daily-flow
daily-target
issues
```

| key | label | primary shape | human | compact | JSON |
|---|---|---|---:|---:|---:|
| `envelopes` | Envelope & Backing | Statement + evidence | yes | yes | yes |
| `balances` | Account Balances | Account Matrix | yes | yes | yes |
| `balance-sheet` | Balance Sheet | position Statement | yes | no | no |
| `profit-and-loss` | Profit and Loss | period Statement | yes | no | no |
| `recent` | Recent Journal | Transaction List | yes | yes | no |
| `planned` | Planned Payments | Plan List + totals | yes | yes | yes |
| `cycle-accounts` | Current-cycle Accounts | Account x measure Matrix | yes | no | no |
| `cycle-comparison` | Cycle Comparison | Account x comparison Matrix | yes | no | no |
| `monthly-accounts` | Monthly Accounts | Month x Account Matrix | yes | no | no |
| `daily-flow` | Daily Flow | Date x Account Matrix | yes | no | no |
| `daily-target` | Daily Target | evidence-bearing projection | yes | yes | no |
| `issues` | Issues | source-ordered List | yes | no | no |

Unsupported surfaces fail explicitly. Listing catalog metadata does not read Household sources.

## Shared laws

All monetary report results obey:

- one explicit supported Commodity domain per result;
- exact coefficient/scale arithmetic;
- no implicit FX conversion or cross-domain total;
- half-open periods `[start,end_exclusive)` where a period is required;
- explicit observation / target coordinates at the application boundary;
- source-qualified Transaction / Posting contributors for derived money;
- `unavailable` and `error` never become numeric zero or a valid-looking empty report;
- a valid admitted empty source may produce a normal empty or zero result where its report contract permits it.

Human signs are presentation policy. Semantic results keep canonical Posting signs unless a named measure explicitly projects another sign meaning.

## Account Balances

At observation `O`, Account Balances publishes the exact Actual closing of every admitted Account in the selected domain:

```text
closing(account,O) = exact sum of Actual Posting coefficients through O
```

Zero-posting Accounts remain rows. Every balance retains its Posting contributors.

## Balance Sheet and Profit and Loss

Balance Sheet is an observation-bounded position statement over explicit Asset, Liability, and Equity roles. Because current journals do not require closing entries, accumulated Income/Expense result is exposed explicitly rather than silently folded into another Account.

Profit and Loss is a half-open-period movement statement over explicit Income and Expense roles:

```text
net income = total income - total expenses
```

Both remain Actual-only, one-domain results with source-qualified evidence. Detailed statement laws are owned by `FINANCIAL_STATEMENTS.md`.

## Current-cycle Accounts

For resolved cycle `C=[S,E)` and `S <= O < E`:

```text
observed end = min(O + 1 day, E)
opening      = Actual Postings before S
period       = Actual Postings in [S, observed end)

movement = debit + credit
closing  = opening + movement
```

The row axis is the selected-domain Account axis in admitted order. Semantic credit stays signed; display normalization belongs to rendering.

## Cycle Comparison

Cycle Comparison consumes two already-resolved windows and never searches the source for a vaguely similar prior period.

```text
difference = current_movement - baseline_movement
```

Unavailable baseline evidence remains unavailable, not zero.

## Monthly Accounts

Monthly Accounts groups exact Actual movement by explicit calendar-month range. Semantic rows are ascending calendar months and columns are Accounts in admitted order. Zero months and zero Account cells remain representable without fabricating evidence.

## Daily Flow

Daily Flow answers how active non-Budget Accounts moved on each observed date in one explicit Actual period. The result keeps Account-level evidence rather than replacing Expense Accounts with Envelope display categories.

Its lower accounting capability may also expose dynamic Expense categories for other consumers. That category meaning comes only from explicit `ExpenseRoutingHistory`; current `budget.toml`, Account names, prefixes, and labels are not historical routing authority. Detailed ownership is in `DATE_CATEGORY_FLOW_CAPABILITY.md`.

## Envelope & Backing

Envelope & Backing composes owners with deliberately different lifetimes:

- `budget.journal`: ordered Entitlement movement evidence;
- `household.toml [budget]`: explicit opening / unassigned Budget Account coordinates;
- `household.toml [[budget.envelopes]]`: stable allocation Account -> Envelope identity coordinates;
- `household.toml [envelope-history]`: stable Envelope identities and explicit Expense / Fulfillment routing history;
- Actual and Plan Journals: accounting, Plan, and completion evidence;
- `budget.toml`: current Envelope definition / presentation and current Backing topology only.

No Account-name inference, destination-Account inference, current Expense assignment, `spent`, or `execution` compatibility participates.

A clean Envelope epoch may start with an empty canonical `budget.journal`. Before the first explicit Entitlement-source movement, no stock origin or initial money is inferred from Actual balances.

Live stock terms use the Entitlement-source origin through observation rather than resetting at the report Period:

```text
stock horizon = Entitlement-source origin .. O

Remaining(e)
  = Entitlement(e)
  - Consumption(e)
  + Refunds(e)
  - Fulfillment(e)

Headroom(e)
  = Remaining(e)
  - Commitment(e)
```

Consumption comes from Actual Expense evidence plus historical Expense routing. Fulfillment comes from completed Plan/Actual evidence plus historical PlanId routing. Commitment is the current open Plan claim and is published directly as `commitment`; there is no reserve compatibility alias.

Negative Remaining and Headroom remain visible evidence and are not clamped.

Backing is orthogonal to Envelope capacity:

```text
funding_balance       = exact Actual closing at O of current Backing Asset Accounts
signed_envelope_total = sum Remaining across current Envelopes
backing_required      = sum max(Remaining,0)
backing_surplus       = funding_balance - backing_required

ledger_unassigned
reconciliation_delta  = backing_surplus - ledger_unassigned
```

`reconciliation_delta = 0` is informative, not an invariant equating Budget evidence with Asset balances. Detailed current laws are in `ENVELOPE_BACKING_CAPABILITY.md`.

## Planned Payments

Planned Payments publishes open Plans only. Stable PlanId plus Actual completion evidence decides completion; Account similarity does not. It retains temporal classification, exact single-domain totals, and source evidence. The detailed contract is in `PLANNED_PAYMENTS_SECTION.md`.

## Recent Journal

Recent Journal returns the latest positive bounded count of admitted Actual Transactions in physical source order, newest first. Multi-Posting lanes remain arrays rather than fabricated single from/to Accounts. A valid empty Actual source returns an empty List.

## Issues

Issues is a source-ordered List over admitted Issue rows. It is a Household notebook surface, not an accounting Fact, Envelope claim, or monetary obligation. Editor Issue commands and report admission share the same source meaning rather than parsing rendered report text.

## Daily Target

Daily Target projects safe daily capacity from explicit observation `O` through exclusive target date `T` using owner-admitted Asset and unsettled-obligation evidence.

```text
eligible_assets
  = sum included Asset balances

gross_obligations
  = sum included open obligations

obligation_deduction
  = gross_obligations - proven already-excluded amounts

capacity_balance
  = eligible_assets - obligation_deduction
```

Only explicit reservation provenance may reduce obligation deduction. Aggregate equality with an Envelope or Plan is not sufficient proof.

## Time and composition

Application composition captures or resolves time and passes explicit coordinates inward. Accounting and section modules do not read the clock.

Canonical report composition reads admitted owners from one Household root. A report must not re-read legacy source names, reinterpret current configuration as historical evidence, or build a parallel report-specific Household model.

## Evolution law

When a report changes:

- preserve exactness, identity, provenance, and source order;
- establish the semantic owner before adding a field or route;
- do not keep completed migration aliases in current result shapes;
- do not turn presentation names into domain authority;
- do not infer missing historical evidence from current policy;
- keep completed implementation sequences and retired compatibility history in Git rather than this current contract.
