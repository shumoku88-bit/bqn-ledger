# Current report construction inventory

Status: Phase 0A current-production evidence; not the destination portfolio
Owner: ledger-facts report migration
Roadmap: `docs/LEDGER_REPORT_ENGINE_MIGRATION_ROADMAP.md`
Destination decision: `docs/REPORT_PORTFOLIO_DECISION.md`
Scope: current production report code at `6f5b68d`

## Purpose

Classify every current human section by result shape, required facts, selection, axes, measures, joins, time policy, currency policy, and output surfaces before designing the new array-oriented report-construction API.

This is a description of current behavior, not the destination module design. The 2026-07-28 portfolio reset explicitly permits rebuilding, merging, operationally relocating, or deleting these sections. This inventory remains useful for consumer removal and retained-semantic comparison. It deliberately separates:

- **result shape** — Matrix, List, Card, or Custom composite;
- **construction fit** — declarative Select/Group/Pivot, hybrid, or custom semantic Build;
- **source facts** — canonical evidence the destination must provide;
- **compatibility pressure** — current behavior that must be classified for deletion or source-data migration in Phase 0B.

## Output surface legend

- **H** — human direct/full/cache section
- **C** — compact machine summary
- **J** — section JSON
- **T** — additional TSV-style structured formatter
- **M** — static section metadata/catalog entry

The compact summary is not one-to-one with the human catalog. `issues`, `daily-flow`, and `debug` have no compact block; compact-only diagnostic blocks also exist outside the 15 human sections.

## Summary matrix

| key | primary result shape | construction fit | principal row axis | principal column/field axis | surfaces |
|---|---|---|---|---|---|
| `snapshot` | Card + small List | Hybrid/custom assembly | account for breakdown | named balances/status cards | H C J M |
| `issues` | List | Declarative List | open issue in source order | date/title/amount/memo | H M |
| `ytd` | Matrix + cards | Declarative aggregation with local sign policy | account, partitioned by role | YTD movement; fixed/variable totals | H C M |
| `balances` | Matrix | Declarative Period/Group | account | actual closing | H C J M |
| `cycle` | Card + Lists | Custom semantic Build | income account / expense entry | actual, plan, remaining, period status | H C M |
| `trial-balance` | Matrix | Declarative Period/Pivot | account | opening/debit/credit/closing | H C T M |
| `envelopes` | Custom composite | Custom Build over grouped facts | envelope / funding source / plan row | allocated/spent/remaining/pace/backing | H C J M |
| `planned` | List + total card | Hybrid Join/List | plan row | date/category/memo/planned/actual/status | H C J M |
| `recent` | List | Declarative transaction List | transaction, newest first | date/from/to/memo/amount | H C M |
| `check` | Card + diagnostic Lists | Custom validation summary | check/account/source row | count/status/message | H C M |
| `outlook` | Custom composite | Custom semantic Build | account/envelope/obligation | balances/reserves/daily capacity/frontier | H C M |
| `daily-trend` | Matrix + ranked List | Custom temporal Build | observation date D | liquid/fund/daily/delta/spend classes | H C M |
| `daily-flow` | Matrix | Declarative Pivot after explicit coordinate preparation | date | income/envelope/other/net | H M |
| `actual-comparison` | Matrix | Custom period/anchor Build | lane + account | current/baseline/diff/count/ratio/status | H C M |
| `debug` | Card/Text | Custom diagnostic formatter | verification check | status/message | H M |

## Detailed inventory

### `snapshot`

- Current owner: `src_next/snapshot.bqn`
- Shape: composite Card result with a nonzero-account List and liquid breakdown.
- Facts:
  - current TBDS rows;
  - account registry roles/types;
  - current cycle;
  - Cube valid/skipped counts.
- Filters:
  - Actual layer for account closing balances;
  - account role/type partitions for liquid, savings, investment, liability.
- Axes:
  - account for closing and liquid breakdown;
  - named scalar cards for liquid, savings, investments, assets, liabilities, net worth, cycle totals, readiness.
- Measures:
  - TBDS closing;
  - Actual income/expense/net;
  - Plan expense;
  - valid/skipped counts.
- Joins: account index → account key/role/type.
- Time policy: current cycle TBDS; displayed `as_of` is `cycle.end_exclusive`, not a current Actual observation.
- Currency policy: ordinary context arithmetic domain; human selected-domain parity is not owned here.
- Construction assessment: account balances are declarative Period/Group; status and mixed cards are custom assembly.
- Compatibility pressure:
  - `fallback/current-engine` source labels;
  - snapshot status combines availability and readiness conventions;
  - JSON currently rebuilds from context rather than accepting the VM.

### `issues`

- Current owner: `src_next/issues.bqn`
- Shape: List.
- Facts: issue records loaded from `issues.tsv`.
- Filters: `status = open`.
- Axes: source issue order; fields date/title/optional amount/memo.
- Measures: none; amount remains display text.
- Joins: none.
- Time policy: none.
- Currency policy: none; issue amount is not admitted accounting money.
- Construction assessment: straightforward declarative List.
- Compatibility pressure: renderer accepts broad context and performs filtering directly; there is no semantic Build or compact result.

### `ytd`

- Current owner: `src_next/ytd_summary.bqn`
- Shape: account Matrix plus total/breakdown cards.
- Facts:
  - ledger-wide Actual posting rows from the configured Actual source;
  - resolved account role and spend class;
  - cycle end coordinate.
- Filters:
  - range `[January 1 of cycle.end year, cycle.end_exclusive)`;
  - Actual layer;
  - income credit and expense debit semantics;
  - role partitions for income/expense/asset/liability;
  - fixed/variable expense partitions.
- Axes:
  - account rows grouped by role and sorted by absolute movement;
  - one YTD movement column;
  - fixed/variable account breakdown lists.
- Measures: exact debit, credit, signed net movement, income, expense, net, fixed total, variable total.
- Joins: account index → role/spend class/account key.
- Time policy: year start is derived from `cycle.end_exclusive`; the end is exclusive.
- Currency policy: ordinary context/Journalsource arithmetic path.
- Construction assessment: strong Select/Group candidate with a section-local display-sign projection.
- Compatibility pressure:
  - rebuilds a local Cube for the YTD range;
  - role prefix fallback remains in `GetRole`;
  - filters by current Actual source file identity.

### `balances`

- Current owner: `src_next/balances.bqn`
- Shape: account Matrix.
- Facts:
  - selected-domain TBDS for direct/default selected output;
  - ordinary-context TBDS for compatibility/JSON output;
  - account role/type metadata;
  - currency calculation and presentation scales.
- Filters: Actual layer, nonzero closing balances, selected arithmetic domain.
- Axes: account rows; amount/role/type fields.
- Measures: TBDS closing.
- Joins: account key/index → role/type; selected currency → precision policy.
- Time policy: selected cycle period, including pre-period opening in closing.
- Currency policy: explicit `--currency` or `DEFAULT_CURRENCY` selected-domain path; legacy full/JSON path may use ordinary context.
- Construction assessment: strongest initial Period/Group Matrix candidate after strict domain selection.
- Compatibility pressure:
  - dual selected and ordinary context routes;
  - missing-default legacy full-report body;
  - multiple human builders and a context-based JSON path.

### `cycle`

- Current owner: `src_next/cycle_summary.bqn`; human composition also receives `expense_breakdown` entries.
- Shape: Card result with income and expense Lists.
- Facts:
  - cycle TBDS Actual and Plan rows;
  - checked Plan posting pairs;
  - plan source identity and completion evidence;
  - account roles;
  - Actual date evidence;
  - expense breakdown result for human output.
- Filters:
  - cycle `[start,end_exclusive)`;
  - Actual income/expense;
  - Plan expense;
  - unfinished applicable Plan expense in `[as_of,end_exclusive)`.
- Axes: income account and expense category lists; named cycle total cards.
- Measures: Actual income/expense/net, Plan expense, unfinished Plan expense, days remaining.
- Joins:
  - plan source row → exactly one admitted debit/credit pair;
  - plan ID → completion;
  - account index → expense role.
- Time policy: `as_of` is latest Actual in explicit half-open cycle or cycle start; remaining plan uses `as_of <= D < end`.
- Currency policy: ordinary context arithmetic domain.
- Construction assessment: base totals are declarative; remaining-plan applicability and fail-closed join make the section custom.
- Compatibility pressure:
  - `no_base_compatibility` fallback substitutes total Plan expense;
  - `ForTest` exports;
  - broad context adapter and source-line evidence parser.

### `trial-balance`

- Current owner: `src_next/trial_balance.bqn`
- Shape: Matrix.
- Facts: TBDS rows, cycle coordinates, selected layer.
- Filters: selected layer; stable account-index ordering.
- Axes:
  - rows: account;
  - columns: opening, debit movement, credit movement, closing.
- Measures: exact TBDS values and column totals; zero-sum check.
- Joins: account index → account key; layer index → layer name.
- Time policy: current cycle period; displayed `as_of = end_exclusive`.
- Currency policy: inherited from the supplied TBDS/domain proof.
- Construction assessment: best first MatrixResult/Period/Pivot proof.
- Compatibility pressure: Build accepts broad context and Cube layer aliases; otherwise relatively isolated.

### `envelopes`

- Current owner: `src_next/envelope_computation.bqn`
- Shape: custom composite containing envelope Matrix, source Lists, execution-plan List, and status Cards.
- Facts:
  - Actual, Plan, and Budget posting facts;
  - Actual TBDS closing;
  - account role/type/kind/budget/group/envelope-role metadata;
  - completion evidence;
  - policy/config values;
  - Actual dates and cycle.
- Filters:
  - envelope/unassigned budget accounts;
  - expense accounts mapped by budget label;
  - Actual expense debit and refund credit;
  - future Plan debit after section observation;
  - liquid Actual closing for backing;
  - open execution plans.
- Axes:
  - envelope rows;
  - funding/active/unassigned source rows;
  - Budget movement provenance;
  - execution-plan rows.
- Measures: allocated, spent, drawn, remaining, average spend, target pace, days until empty, funding base, backing delta, planned open total.
- Joins:
  - budget label → expense accounts;
  - plan identity → completion;
  - envelope group/role → presentation and policy;
  - source row → provenance.
- Time policy: current cycle; `as_of` is the last in-cycle Actual date in source order; future Plan is `D > as_of`.
- Currency policy: ordinary context arithmetic domain; config/account evidence participates.
- Construction assessment: several internal Group operations are reusable, but overall status/backing/execution semantics require custom Build.
- Compatibility pressure:
  - raw `budget_alloc.tsv` parsing remains in target calculation;
  - config/source loading in adapters;
  - compatibility fields retained for tests;
  - broad Build and test-oriented prepared APIs;
  - projection/date compatibility dependency.

### `planned`

- Current owner: `src_next/planned_payments.bqn` plus `src_next/plan_rows.bqn`.
- Shape: ordered List with open-total Card.
- Facts:
  - Plan source/admitted rows;
  - completion evidence from Actual transactions;
  - cycle and observation;
  - account/category source fields.
- Filters: Plan rows in cycle; open/completed partition.
- Axes: Plan row sorted by date; fields date/category/memo/planned amount/actual amount/status/plan ID.
- Measures: planned amount, matched Actual amount, open total.
- Joins: Plan identity → completion transactions and actual amount.
- Time policy: observation is latest Actual in explicit half-open cycle or cycle start; status is future/due/overdue/completed.
- Currency policy: current Plan/Actual compatibility amount shape.
- Construction assessment: List construction is generic; identity, completion, and temporal status are custom prepared joins.
- Compatibility pressure:
  - five-field fallback Plan identity;
  - source amount parsing;
  - context-format entrypoints;
  - compact and human use different prepared VMs;
  - multiple `ForTest` aliases and compatibility `PlanId` export.

### `recent`

- Current owner: `src_next/recent_journal.bqn`
- Shape: transaction List.
- Facts: Actual transactions with postings and description.
- Filters: final `N` source transactions.
- Axes: transaction rows, reversed to newest first; fields date/from accounts/to accounts/memo/amount.
- Measures: sum of positive debit postings per transaction.
- Joins: transaction → debit/credit posting account lists.
- Time policy: source order only; not cycle-bounded.
- Currency policy: current compatibility Actual transaction shape assumes one displayable amount/domain.
- Construction assessment: strong declarative transaction List after canonical transaction/posting join.
- Compatibility pressure: consumes historical `delta` postings through `actual_source.Transactions`; Build is hidden inside renderers.

### `check`

- Current owner: `src_next/readiness_check.bqn`; human output also invokes `plan_journal_overlap.bqn`.
- Shape: status/count Cards and diagnostic Lists.
- Facts:
  - account registry and raw metadata;
  - admitted/skipped posting evidence;
  - cycle;
  - Actual transaction count and Plan source row count;
  - Plan/Actual overlap evidence.
- Filters: unknown/duplicate/missing/inconsistent account metadata; stale Plan rows; future Actual rows; overlap classes.
- Axes: check category, account/source row.
- Measures: counts and statuses; source diagnostics.
- Joins: skipped rows → source type; account index → metadata; plan identity → Actual identity.
- Time policy: stale/future classification relative to current cycle.
- Currency policy: reports admission/projection state rather than independently aggregating money.
- Construction assessment: custom validation summary; generic List/Card presentation should be reusable.
- Compatibility pressure:
  - human renderer performs source reads and dynamic import;
  - broad context/Cube shape;
  - projection compatibility dependency;
  - source counts and semantic checks are split across Build/FormatHuman.

### `outlook`

- Current owner: `src_next/outlook.bqn` with Actual Snapshot, remaining-plan, Envelope, config, and obligation helpers.
- Shape: custom composite Card/Lists/Matrices.
- Facts:
  - ledger-cumulative Actual posting facts through observation O;
  - Plan posting facts, source metadata, completion and anchor evidence;
  - Envelope result;
  - next-cycle obligation Plan rows;
  - account roles/types and household group policy;
  - cycle and Actual record frontier.
- Filters:
  - Actual snapshot `D <= O`;
  - remaining Plan `O <= D < cycle.end_exclusive`;
  - anchor activation at or before O;
  - obligation rows at cycle end;
  - life/reserve Envelope groups.
- Axes: liquid account breakdown, daily-use Envelope rows, reserve rows, obligation rows, named capacity/status cards.
- Measures: liquid/savings/investment/net worth, planned inflow/outflow, reserve, daily capacity, obligation totals, frontier lag/distance.
- Joins: account metadata, Plan identity/completion, income anchor, Envelope group policy.
- Time policy: explicit O for human route; record frontier is open-ended after cycle start; Actual snapshot is cumulative through O; Plan horizon ends at cycle end.
- Currency policy: ordinary context arithmetic domain; no cross-domain total.
- Construction assessment: custom semantic Build composed from narrow capabilities; not a Pivot-spec target as a whole.
- Compatibility pressure:
  - `Build` and `BuildAt` have different no-frontier semantics;
  - `legacy_default` and compatibility fields;
  - next obligations still parse source Plan lines;
  - imports Envelope report implementation rather than a lower-level capability.

### `daily-trend`

- Current owner: `src_next/daily_trend.bqn` and `src_next/daily_trend_plan.bqn`.
- Shape: date Matrix plus ranked drop List.
- Facts:
  - Actual and Plan posting facts;
  - account role/type/spend class;
  - completion evidence and row-local fixed reserve;
  - cycle and Actual dates.
- Filters:
  - Actual cumulative values at each rendered D;
  - future income `plan date > D` and before cycle end;
  - unfinished fixed plans at D;
  - liquid/savings/variable/fixed/income account partitions.
- Axes:
  - rows: selected observation dates D;
  - columns: liquid, reserve, fund, days left, daily, delta-daily, variable, savings, fixed;
  - secondary rows: ten largest daily drops.
- Measures: cumulative and daily exact sums, planned future income, reserve, integer daily capacity, differences.
- Joins: Plan source row → admitted posting pair; Plan identity → completion at each D; account index → metadata class.
- Time policy: current-source coordinate replay; row calculation observation is D; empty accepted frontier anchors one row at cycle start; human header O is separate.
- Currency policy: ordinary context arithmetic domain.
- Construction assessment: output is matrix-shaped, but row-local plan state and observation semantics require custom Build over reusable Select/Period/Join capabilities.
- Compatibility pressure:
  - broad `Build`/`BuildAt` pair;
  - separate header and calculation observations;
  - source/context plan evidence adapters;
  - `ForTest` aliases in helper modules.

### `daily-flow`

- Current owner: `src_next/daily_flow.bqn`
- Shape: Matrix.
- Facts:
  - cycle Actual posting facts by day/account;
  - account role/kind/budget metadata;
  - Actual dates and cycle.
- Filters:
  - Actual layer;
  - income accounts;
  - expense accounts grouped by Envelope budget mapping;
  - other expense accounts;
  - observed coordinates inside cycle.
- Axes:
  - rows: sorted unique Actual dates plus section observation when applicable;
  - columns: income, one column per Envelope label, other expense, net.
- Measures: exact daily income, expense, and net sums.
- Joins: expense account budget label → Envelope budget account/column.
- Time policy: dates are cycle-bounded; `as_of` is latest Actual in the day-count window or cycle start.
- Currency policy: ordinary context/Cube arithmetic domain.
- Construction assessment: best second real Pivot proof after coordinate preparation; materially different from Trial Balance (`date × dynamic category`).
- Compatibility pressure: broad context adapter and base fallback through Actual dates; presentation helpers are local rather than shared.

### `actual-comparison`

- Current owner: `src_next/actual_comparison.bqn`
- Shape: comparison Matrix.
- Facts:
  - ledger-wide checked Actual posting facts;
  - Plan income-credit coordinates for future anchor evidence;
  - cycle config income account;
  - account role/spend class;
  - source transaction identity for counts.
- Filters:
  - current `[cycle.start, min(O+1,cycle.end_exclusive))`;
  - baseline interval of equal elapsed length from previous comparable income anchor;
  - semantic positive income-credit and expense-debit contribution rows;
  - applicable rejected Actual evidence in either interval.
- Axes:
  - rows: lane (`income`, `recurring_fixed`, `variable`) + account;
  - columns: current amount, baseline amount, difference, current/baseline/difference counts, ratio, status.
- Measures: TBDS period movements and deduplicated transaction/source counts.
- Joins: source row identity for counts; account index → role/spend class; income account → previous Actual/Plan anchor.
- Time policy: explicit O hard cutoff; equal-length baseline from previous anchor.
- Currency policy: ordinary context arithmetic domain.
- Construction assessment: Matrix result, but anchor resolution, applicability, amount/count dual evidence, and status policy require custom Build.
- Compatibility pressure: reads `cycle.tsv` for anchor identity, relies on broad context and source-file identity, and constructs local TBDS views.

### `debug`

- Current owner: inline builder in `src_next/report.bqn` using `cube.VerifyNumeric`.
- Shape: Card/Text diagnostic.
- Facts: current Cube and resolved account keys.
- Filters: none beyond the materialized current Cube.
- Axes: verification checks/messages.
- Measures: numeric consistency diagnostics.
- Joins: Cube account axis → account keys.
- Time policy: inherited current cycle Cube.
- Currency policy: inherited current context.
- Construction assessment: custom diagnostic capability with generic Card/Text rendering.
- Compatibility pressure: implementation lives in the composition root and labels itself `partial/src_next`.

## Construction candidates

### Strong declarative candidates

These should be expressible primarily through Select/Join/Group/Pivot/List vocabulary:

1. `trial-balance` — `account × {opening,debit,credit,closing}`
2. `daily-flow` — `date × {income,envelope labels,other,net}` after explicit coordinate preparation
3. `balances` — account × closing
4. `ytd` — account × movement with role/sign projection
5. `issues` — filtered issue List
6. `recent` — transaction/posting joined List

### Hybrid candidates

- `snapshot` — declarative balances plus custom cards/status
- `planned` — generic List after custom completion/temporal join
- `cycle` — declarative TBDS totals plus custom remaining-plan state
- `check` — custom checks rendered as generic Card/List results

### Custom semantic reports

- `envelopes`
- `outlook`
- `daily-trend`
- `actual-comparison`
- `debug`

Their output may still use Matrix/List/Card presentation-neutral shapes, but their semantic Builds must remain explicit.

## Recommended report-construction proof

### First real Matrix proof: `trial-balance`

Why:

- requires exact selected-domain arithmetic;
- proves Period opening/movement/closing;
- has stable account ordering and a zero-sum invariant;
- needs no Plan, Budget, completion, or external clock;
- maps directly to MatrixResult.

Expected axes:

```text
rows    = account index/key
columns = opening | debit | credit | closing
measure = exact coefficient in one proven domain/scale
```

### Second real Pivot proof: `daily-flow`

Why:

- uses a date row axis rather than account rows;
- has dynamic Envelope columns derived through account metadata;
- proves composable masks and derived net columns;
- exercises zero days and explicit observation coordinates without Plan completion.

Expected axes:

```text
rows    = observed date
columns = income | envelope labels... | other expense | net
measure = exact daily movement in one proven domain/scale
```

### Novel extensibility gate: monthly expense matrix

This report is not one of the current 15 and is not added to production during the proof.

```text
rows    = calendar month
columns = explicit expense category/account partition
filter  = Actual layer + expense debit + selected domain
measure = exact sum
sidecar = contributor posting IDs per cell
```

Success means it can be added and removed as one report definition and focused test without changing source admission, canonical fact shape, Period/Group/Pivot kernels, or current section modules.

## Phase 0A conclusions

1. A columnar posting/transaction fact model can serve every section, but not every section is reducible to one Pivot spec.
2. Trial Balance and Daily Flow are the best materially different real consumers for proving Matrix/Pivot vocabulary.
3. Outlook, Envelope, Daily Trend, and Actual Comparison must remain explicit semantic compositions over narrow capabilities.
4. Transaction facts are first-class: Recent and completion/anchor reports cannot be reconstructed safely from a dense Cube alone.
5. Contributor posting/source indices belong in generic result sidecars because readiness, comparison, backing, and future inspection require provenance.
6. The next Phase 0 slice is the compatibility deletion inventory. No destination `src/` module or Pivot API is justified before that inventory and the strict-source decisions are reviewed.
