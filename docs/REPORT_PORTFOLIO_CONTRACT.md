# Destination report portfolio contract

Status: Portfolio Contract P1 selected implementation baseline
Date: 2026-07-28
Decision authority: `REPORT_PORTFOLIO_DECISION.md`
Current production: `tools/report` → strict `src/` composition

## 1. Static destination catalog

The destination catalog has these keys in this order:

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

| key | label | shape | human | compact | JSON |
|---|---|---|---:|---:|---:|
| `envelopes` | Envelope & Backing | bounded Statement: Cards + Matrix/List evidence | yes | yes | yes |
| `balances` | Account Balances | Account Matrix | yes | yes | yes |
| `balance-sheet` | Balance Sheet | classified position Statement | yes | no | no |
| `profit-and-loss` | Profit and Loss | classified period Statement | yes | no | no |
| `recent` | Recent Journal | Transaction List | yes | yes | no |
| `planned` | Planned Payments | Plan List + total Card | yes | yes | yes |
| `cycle-accounts` | Current-cycle Accounts | Account × measure Matrix | yes | no | no |
| `cycle-comparison` | Cycle Comparison | Account × comparison Matrix | yes | no | no |
| `monthly-accounts` | Monthly Accounts | Month × Account Matrix | yes | no | no |
| `daily-flow` | Daily Flow | Date × dynamic expense category Matrix | yes | no | no |
| `daily-target` | Daily Target | evidence-bearing Card/Projection | yes | yes | no |
| `issues` | Issues | source-ordered List | yes | no | no |

“No” means unsupported, not an empty renderer. Unsupported JSON is a nonzero CLI error. Compact output contains only registered compact owners; Matrix reports are not flattened into ad-hoc key floods.

The catalog is static and source-independent. Listing keys/metadata does not read household sources. Full and cache output iterate this catalog but build one requested result at a time.

Daily Flow answers one bounded question: for explicit Actual period `[start,end_exclusive)` and observation, what income, dynamic expense-category outflow, unmatched `other`, and signed net occurred on each observed date? Category identity comes from admitted Account budget metadata; values retain Posting contributors. Its production surface is human-only.

## 2. Shared result rules

All monetary report results obey:

- one explicit supported currency domain per result;
- exact coefficient/scale arithmetic;
- no FX conversion or cross-domain total;
- half-open periods `[start,end_exclusive)`;
- explicit observation/target coordinates at the use-case boundary;
- source-qualified Transaction/Posting contributors where money is derived;
- `unavailable` and `error` never become numeric zero or a valid-looking empty report;
- a valid admitted empty source may produce a normal empty/zero result where the report contract says so.

Human signs are presentation policy. Result coefficients remain canonical Posting signs unless a named measure explicitly projects consumption/income into a positive display measure.

## 3. Account Balances

### Question

What is the exact Actual-layer balance of every admitted Account in one selected domain at observation `O`?

### Coordinates

```text
row axis     = all Accounts in admitted Account order whose currency = selected domain
column axis  = closing
window       = all Actual Postings with date <= O
```

Zero-posting Accounts remain rows. `O` is explicit to the use case; the normal daily composition may choose the latest admitted Actual date, or period start for valid empty Actual, but the accounting builder does not choose it.

### Measure and provenance

```text
closing(account,O) = exact sum of selected Actual Posting coefficients through O
```

Each cell retains contributing Posting references. Result totals are separated by accounting role if supplied by the section; there is no cross-role sign reinterpretation in the accounting capability.

### Empty/error

A valid empty Actual source returns every selected-domain Account with exact zero closing and no contributors. Unknown domain, invalid observation, rejected Facts, or exact overflow returns no numeric table.

## 3A. Balance Sheet and Profit and Loss

Balance Sheet is an observation-bounded position statement over explicit `asset`, `liability`, and `equity` roles. Because current journals do not require closing entries, it exposes an exact `unclosed accumulated result` derived from Income/Expense closing balances and proves `assets = liabilities + equity`. A nonzero Actual balance in an unsupported role fails closed.

Profit and Loss is a half-open-period movement statement over explicit `income` and `expense` roles. It publishes positive-normalized income and expense measures plus `net income = total income - total expenses`; abnormal debits/credits remain negative rather than being inferred into another class.

Both are Actual-only, one-domain, human-only results with source-qualified Posting contributors. The current semantics and the decisions deliberately left open—closing policy, reporting year, classification depth, comparative policy, formal adjustments, and structured surfaces—are in [`FINANCIAL_STATEMENTS.md`](FINANCIAL_STATEMENTS.md).

## 4. Current-cycle Accounts

### Question

How has every Account moved from resolved cycle start through observation `O`?

### Period

For resolved cycle `C=[S,E)` and `S <= O < E`:

```text
observed end = min(O + 1 day, E)
opening      = Actual Postings before S
period       = Actual Postings in [S, observed end)
```

### Matrix

```text
row axis    = all Accounts in selected domain, admitted order
column axis = opening | debit | credit | movement | closing
```

Canonical measures:

```text
debit    = signed exact sum of debit Postings in period
credit   = signed exact sum of credit Postings in period
movement = debit + credit
closing  = opening + movement
```

Credit remains negative in the semantic result. Renderers may label it clearly but do not silently absolute-value the stored measure. Every cell retains Posting contributors; closing contributors are opening plus period contributors.

This replaces the daily-report need previously split across Cycle and Trial Balance. A full-cycle developer Trial Balance is a preset/tool over the same capability, not a required portfolio route.

## 5. Cycle Comparison

### Question

How does per-Account movement in one explicit current window compare with one explicit baseline window?

### Input windows

The report accepts two already-resolved windows:

```text
current  = [current_start,current_end_exclusive)
baseline = [baseline_start,baseline_end_exclusive)
comparison_policy = aligned_elapsed | complete_cycles
```

- `aligned_elapsed` requires equal day counts and is the normal active-cycle comparison;
- `complete_cycles` requires two complete resolved cycles but not equal calendar labels;
- the report never searches source rows for a “similar” prior period;
- unavailable previous income-anchor evidence produces `unavailable`, not a zero baseline.

### Matrix

```text
row axis    = all Accounts in selected domain, admitted order
column axis = current_movement | baseline_movement | difference

difference = current_movement - baseline_movement
```

Each measure retains its own window contributors. Difference contributors are source-qualified union evidence, while its arithmetic keeps current and baseline coefficients distinguishable in the result.

Counts, ratios, and increased/decreased labels are not part of P1. They may be added only for a demonstrated retained question; the old Actual Comparison lanes/statuses are not inherited automatically.

## 6. Monthly Accounts

### Question

What was each Account’s net movement in each calendar month of one explicit month range?

### Matrix

```text
semantic row axis    = calendar month YYYY-MM, ascending
semantic column axis = all Accounts in selected domain, admitted order
human row axis       = Accounts in admitted order
human column axis    = calendar months, ascending
measure              = signed exact Actual movement in that calendar month
```

Input month range is `[first_month,last_month_exclusive)` and is not inferred from “today”. Months with no selected Postings remain explicit zero rows/cells with no contributors. The semantic Matrix includes zero-posting Accounts. Human rendering transposes only presentation; it does not transpose or rebuild the accounting result or contributor coordinates.

P1 intentionally selects movement only. Monthly closing, debit/credit submatrices, role summaries, and YTD cards are not silently bundled. A later concrete consumer may add a separate bounded result after its semantics are reviewed.

## 7. Envelope & Backing

### Question

What does each envelope currently claim, what has consumed it, what open Plans depend on it, and is the positive claim backed by admitted funding assets?

The result is one bounded Statement, not an import of the old Envelope ViewModel.

### Coordinates

Inputs include selected domain, resolved envelope horizon `H=[S,E)`, explicit observation `O`, strict Budget/Actual/Plan Facts, completion Join, Account metadata, and an owner-resolved funding scope.

An envelope is selected only by explicit Account metadata/policy. Account-name prefixes and display labels do not establish envelope or funding membership.

### Per-envelope terms

For envelope `e`:

```text
entitlement(e)          = signed exact Budget allocation movement mapped to e in the full horizon [S,E)
actual_consumption(e)   = positive projection of mapped Actual expense-debit evidence in [S,O+1)
actual_refunds(e)       = positive projection of mapped Actual expense-credit evidence in [S,O+1)
ledger_remaining(e)     = entitlement - actual_consumption + actual_refunds
open_plan_reserve(e)    = exact open Plan outflows mapped to e with O <= due < E
post_plan_headroom(e)   = ledger_remaining - open_plan_reserve
```

P1 includes a same-day Plan when it remains open after completion evidence through O. A same-day completed Plan is excluded by the durable completion Join, so it is not reserved twice.

P1 entitlement deliberately uses the full admitted horizon allocation while consumption is observation-bounded. Budget evidence before `S` is not silently carried into this horizon; a future carry-forward policy requires explicit source semantics. Negative `ledger_remaining` remains visible as overspent and is not clamped to zero.

P1 uses `refunds` as the display name for the exact expense-credit projection. It does not yet claim that every credit is an externally sourced cash refund: an expense reclassification can also credit an expense Account. Posting and Transaction provenance is retained so a later concrete question can split `external_refund / reclassification / other_credit` without reparsing source text. That split requires an explicit transaction-counterpart or admitted classification contract; it must not be inferred from Account names. Until such a consumer is selected, the accounting definition above remains deterministic and the renderer must not describe the coordinate more strongly than “expense credits / refunds”.

### Backing terms

```text
funding_balance         = exact Actual closing at O of owner-admitted funding Accounts
signed_envelope_total   = sum ledger_remaining across active envelopes
backing_required        = sum max(ledger_remaining,0) across active envelopes
backing_surplus         = funding_balance - backing_required
```

Status:

```text
backed       when backing_surplus >= 0
under_backed when backing_surplus < 0
unavailable  when funding/envelope ownership or required evidence is absent/ambiguous
error        when supplied evidence is contradictory, mixed-domain, duplicated, or invalid
```

Budget-ledger unassigned is a separate reconciliation coordinate:

```text
ledger_unassigned
reconciliation_delta = backing_surplus - ledger_unassigned
```

`reconciliation_delta=0` is informative but not required for `backed`; the Budget ledger and funding assets are different evidence systems. They must never be labeled as one number.

Open Plan reserve is shown per envelope and in totals. It is not deducted a second time from `funding_balance`; Daily Target owns obligation deduction and reservation provenance.

### Evidence

The result retains funding Account contributors, Budget entitlement contributors, Actual consumption/refund contributors, open Plan/Actual completion references, and any reconciliation Account contributors. Invalid evidence publishes no partial backing amount.

## 8. Planned Payments

The implemented contract in `PLANNED_PAYMENTS_SECTION.md` remains selected:

- strict cycle selection and explicit latest-or-start observation;
- durable `plan_id` only;
- `future / due / overdue / completed`;
- duplicate/ambiguous completion refusal;
- exact single-domain open total;
- human/compact/JSON from one result.

Its final key remains `planned`; destination compact prefix remains `ledger_planned_payment`.

## 9. Recent Journal

### Question and List

What are the latest `N` admitted Actual Transactions in physical source order?

```text
selection = final N Transactions, then newest first
fields    = date, description, credit Account keys, debit Account keys,
            exact debit total, currency, transaction reference, Posting contributors
```

`N` is an explicit positive bounded input. Multi-posting lanes remain arrays; they are not collapsed into a fabricated single from/to Account. Each Transaction must stay one domain. A valid empty Actual source returns an empty List, not an unavailable report.

Final key is `recent`. Compact payload is explicitly tab-delimited:

```text
ledger_recent_journal: DATE<TAB>CURRENCY<TAB>AMOUNT<TAB>CREDIT_ACCOUNTS<TAB>DEBIT_ACCOUNTS<TAB>DESCRIPTION
```

## 10. Issues

Issues is a source-ordered List over admitted issue rows. It does not become an accounting Fact or monetary obligation.

Destination admission uses the exact header and field order:

```text
issue_id | status | date | category | title | amount | currency | details
```

(tab-separated in the source). Required evidence is durable unique issue identity, source row/reference, `open | resolved | dropped` status, optional strict date, required category/title, optional exact amount paired with explicit currency, and optional details. Default human selection is open issues only. Absent/header-only source is valid empty evidence. Invalid issue admission is `error`; no valid-looking partial List is returned.

Editor issue list/close/add workflows remain separate source commands and must share admission semantics rather than parse report text.

## 11. Daily Target

### Question

At explicit observation `O`, through exclusive target date `T`, what daily amount is supported by owner-admitted assets after admitted unsettled obligations are deducted exactly once?

P1 adopts the evidence model and safety ordering from `DAILY_CAPACITY_MINIMAL_INPUT_RESULT_CONTRACT.md`, generalized from cycle end to explicit `T`.

### Horizon and evidence

```text
horizon = [O,T)
O < T
remaining_days = T - O
```

Inputs are one proven arithmetic domain, owner-resolved asset scope, owner-resolved obligation scope, and reservation provenance. Included obligations are open and due before `T`; overdue open obligations remain included.

A virtual envelope claim held inside selected asset balances does not prove an obligation is outside the asset basis. `excluded_from_asset_basis` reduces obligation deduction only with exact per-obligation reservation provenance. Aggregate Envelope/Plan equality is diagnostic, not sufficient provenance.

Expected future income may be displayed as separate evidence but does not increase P1 safe capacity. A later income-inclusive projection requires its own admission and uncertainty contract.

### Arithmetic

```text
eligible_assets
  = sum included asset balances

gross_obligations
  = sum included open obligation amounts

already_excluded
  = sum proven excluded_from_asset_basis

obligation_deduction
  = gross_obligations - already_excluded

capacity_balance
  = eligible_assets - obligation_deduction
```

When `capacity_balance >= 0`:

```text
state = ok
daily_target = floor(capacity_balance / remaining_days)
daily_shortfall = 0
```

When `capacity_balance < 0`:

```text
state = deficit
daily_target = 0
daily_shortfall = ceiling((-capacity_balance) / remaining_days)
```

`unavailable/error` has no calculation. Result retains normalized asset, obligation, exclusion, and reservation references. Compact prefix is `ledger_daily_target`.

## 12. CLI time coordinates

Destination report composition exposes explicit options rather than Outlook-specific names:

```text
--as-of YYYY-MM-DD
--target-date YYYY-MM-DD
```

- `--as-of` applies only to retained reports with observation semantics;
- if omitted in an interactive daily command, composition captures system date once and passes it explicitly;
- deterministic tests/cache generation supply it explicitly;
- `--target-date` applies only to `daily-target`; if omitted, the resolved cycle end is the composition default and is still passed explicitly;
- accounting/section modules never read the clock.

Old `--outlook-as-of` is removed atomically with `outlook`; it is not aliased.

## 13. Implementation order

Selected dependency order:

1. Account Balances — direct Actual Facts and Account table;
2. Recent Journal — direct Transaction/Posting List;
3. Current-cycle Accounts — existing Account-period capability;
4. Monthly Accounts — bounded calendar grouping;
5. Cycle Comparison — two explicit period results;
6. Envelope & Backing — Budget/Actual/Plan composition;
7. Daily Target — funding/obligation evidence and reservation provenance;
8. Issues — strict issue admission/List, independently schedulable;
9. composition/routing cutover after all retained surfaces and removal actions are ready.

Planned Payments is already a destination proof and remains in the catalog. This order may be sliced reversibly, but no old report ViewModel becomes a dependency of a retained report.
