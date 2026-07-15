# Daily capacity current consumer and input-evidence audit — 2026-07-15

Status: audit snapshot
Owner: report / config / envelope
Canonical: no; decision basis: `../completed-plans/POLICY_RISK_STYLE_DAILY_CAPACITY_DECISION-2026-07-15.md`
Exit: retain as current-main evidence for the next separately selected daily-capacity contract or migration slice

## Purpose

Map the current `POLICY_RISK_STYLE` behavior and the evidence already available for the target daily-capacity model:

```text
DailyCapacity
  asset_scope
  obligation_scope
  horizon
```

This is a docs-only audit. It changes no runtime behavior, configuration, fixture, source TSV, report field, machine output, or editor path.

## Scope and inspected surfaces

The audit inspected the current canonical report and evidence paths relevant to the decision:

- `src_next/config.bqn`;
- `src_next/outlook.bqn`;
- `src_next/report.bqn`;
- `src_next/summary.bqn`;
- `src_next/actual_snapshot.bqn`;
- `src_next/account_key.bqn`;
- `src_next/plan_evidence.bqn`;
- `src_next/plan_rows.bqn`;
- `src_next/planned_payments.bqn`;
- `src_next/cycle.bqn`;
- `src_next/envelope_computation.bqn`;
- `src_next/household_policy.bqn`;
- `src_next/context.bqn` and `src_next/issues.bqn`;
- current metadata, focused tests, checks, and representative policy fixtures.

Historical design prose was used only to explain origin. Current `main` code and checks own the findings below.

## Executive result

Within the current canonical runtime/report surfaces, `PolicyRiskStyle` has one direct behavioral consumer:

```text
src_next/outlook.bqn :: BuildCore
```

The current switch does **not** choose between two human-facing daily-amount formulas.

It controls whether one secondary machine ViewModel field is numeric:

```text
POLICY_RISK_STYLE=conservative
  -> liq_safe_daily is numeric

POLICY_RISK_STYLE=simple
  -> liq_safe_daily = unavailable/policy
```

The primary human Outlook amount remains `liq_daily` under both values. `FormatHuman` does not render `liq_safe_daily`.

Therefore the current key is narrower than its name and narrower than the historical profile description. It is a compatibility switch around one secondary Outlook field, not a complete household risk-style subsystem.

## 1. Current consumer map

### 1.1 Accessor owner

`src_next/config.bqn` owns parsing and validation:

```text
accepted: conservative | simple
missing: warning + conservative fallback
empty: error
unknown: error
```

The accessor itself performs no arithmetic.

### 1.2 Direct behavioral consumer

`src_next/outlook.bqn` reads:

```text
risk_style = cfg.PolicyRiskStyle
is_simple  = risk_style == simple
```

No direct `PolicyRiskStyle` read was found in the inspected envelope or household-policy calculation modules.

### 1.3 Transitive output surfaces

The behavior reaches:

- `outlook.Format`, which emits `src_next_outlook_liq_safe_daily`;
- `src_next/summary.bqn`, which calls compatibility `outlook.Build`;
- `src_next/report.bqn`, which calls explicit-observation `outlook.BuildAt` for the human Outlook section;
- `checks/check-src-next-stage4-fields.sh`, which requires the machine field to be present;
- focused config and Outlook tests.

These are output and compatibility surfaces. They are not independent policy owners.

## 2. Current arithmetic

At observation date `O` and cycle end `C`, current Outlook derives:

```text
liq_total
  = balance of every account with role=asset and type=liquid at O

future_planned_liquid_net
  = sum of remaining raw plan-row effects on type=liquid accounts
    inside [O, C)

future_planned_liquid_expenses
  = negative parts of those liquid deltas

liq_basis
  = liq_total + future_planned_liquid_net

liq_safe_basis
  = liq_total + future_planned_liquid_expenses

liq_daily
  = floor(liq_basis / days_left)

liq_safe_daily
  = conservative
      ? floor(liq_safe_basis / days_left)
      : unavailable/policy
```

Because `future_planned_liquid_expenses` is negative, `liq_safe_basis` subtracts future liquid outflows and ignores future liquid inflows.

### 2.1 What `liq_daily` means today

`liq_daily` includes both:

- future planned liquid income;
- future planned liquid outflow.

Human Outlook labels and renders this primary amount. It is not selected by `POLICY_RISK_STYLE`.

### 2.2 What `liq_safe_daily` means today

`liq_safe_daily` excludes future planned liquid income while subtracting future planned liquid outflow.

It is emitted by the compact machine formatter but not rendered by current `FormatHuman`.

### 2.3 The reserve input is broader than fixed obligations

The current reserve arithmetic is based on **all negative liquid deltas** admitted by the raw remaining-plan scan.

It does not currently require:

- `cashflow=fixed_obligation`;
- destination `role=expense`;
- destination `spend_class=fixed`;
- an unpaid completion state from shared plan evidence;
- an explicit owner obligation policy.

A transfer from a liquid account to a non-liquid account can therefore participate in the same negative-liquid bucket even when it is not a payment obligation.

The historical word `fixed_reserve` is a compatibility name, not proof that the input is limited to fixed obligations.

## 3. Current plan-row admission

Outlook currently reads raw `plan.tsv` lines directly for daily arithmetic.

Its remaining-plan scan applies:

- source date inside `[O, C)`;
- current anchor logic;
- account `type=liquid` effects.

It does not reuse the shared plan completion path in:

```text
plan_evidence.bqn
  -> plan_id identity
  -> journal plan_id completion evidence

plan_rows.bqn
  -> completed_mask
  -> temporal status
```

Consequences for a future contract:

1. a plan row and its completed journal row are distinguishable elsewhere in the repository, but current Outlook daily arithmetic does not consume that distinction;
2. raw plan presence is not sufficient evidence that an obligation remains unpaid;
3. the existing anchor behavior must be characterized before it is reused as an obligation-admission rule;
4. plan date is usable horizon evidence, but plan classification and settlement evidence must remain separate.

## 4. Asset-scope evidence

### 4.1 Reusable current evidence

`actual_snapshot.bqn` already exposes:

- per-account balance vector;
- non-zero entries with account keys;
- `liq_breakdown`;
- explicit account role and type resolution;
- observation-bounded journal evidence.

`account_key.bqn` resolves parallel metadata arrays including:

- account;
- account key and currency;
- role;
- type;
- budget and budget group;
- spend class;
- kind;
- envelope role.

This is enough to build an evidence-bearing asset candidate set without reading account names as policy.

### 4.2 Missing target ownership

Current Outlook admits every account satisfying:

```text
role=asset AND type=liquid
```

There is no current owner-specific daily-capacity admission field or named set.

`type=liquid` is useful classification evidence, but it cannot express all intended owner choices, such as:

- include ordinary checking;
- exclude an emergency account that is technically liquid;
- include or exclude cash;
- exclude externally managed or restricted balances.

`envelope_role` is not a substitute. It classifies budget accounts as dynamic, execution, or unassigned and is validated only in that envelope domain.

### 4.3 Audit classification

```text
role/type/account balance evidence: reusable
owner-selected asset_scope storage: missing / design required
```

The next slice must not silently redefine all `type=liquid` balances as owner-approved spending capacity.

## 5. Obligation-scope evidence

### 5.1 Strongest reusable evidence

The strongest current base is the shared plan evidence path:

```text
plan source row
  + source date
  + account endpoints
  + amount
  + plan_id
  + journal plan_id completion evidence
  -> open/completed distinction
```

`planned_payments.bqn` already presents open and completed rows from this shared source.

This is stronger than Outlook's current raw plan scan because it can prove that a planned row has or has not been matched to actual evidence.

### 5.2 Existing metadata signals

Current metadata includes possible supporting signals:

- `cashflow=fixed_obligation` on plan-like rows;
- account `spend_class=fixed|variable`;
- `due_on` as a general date metadata key;
- `plan_id` for completion linkage;
- account role/type and transaction endpoints.

These signals do not yet form one canonical obligation contract.

In particular:

- account `spend_class=fixed` classifies an expense account, not one specific unpaid payment;
- `cashflow=fixed_obligation` is explicit but currently narrow and not consumed by Outlook daily arithmetic;
- a plan row can be optional, tentative, income, transfer, saving movement, or payment;
- date and amount alone do not establish obligation ownership.

### 5.3 Issues are not payment authority

Current `issues.tsv` context exposes only:

```text
date, status, title, amount, memo
```

An open issue may describe a possible expense or decision, but it lacks canonical posting endpoints, settlement identity, and obligation semantics.

Therefore:

```text
open issue amount != admitted payment obligation
```

Issues may later reference an obligation, but must not be summed automatically.

### 5.4 Current next-cycle liability display

Outlook separately selects plan rows exactly on `C` whose destination account name starts with `liabilities:` and reports them as next-cycle obligations.

That path:

- does not reduce current `liq_daily` or `liq_safe_daily`;
- uses an account-name prefix heuristic;
- is limited to one boundary date;
- is not a general obligation-scope owner.

### 5.5 Audit classification

```text
plan source + plan_id completion evidence: reusable
explicit obligation admission policy: missing / design required
issues amount as obligation source: reject
current liability-prefix display: compatibility evidence only
```

## 6. Horizon evidence

### 6.1 Current human Outlook path

`src_next/report.bqn` supplies an explicit Outlook observation date `O`:

- `--outlook-as-of YYYY-MM-DD`, when provided;
- otherwise report `Today`.

Outlook uses current cycle `end_exclusive` as `C` and computes:

```text
days_left = max(0, C - O)
```

The focused observation check proves that Outlook's `O` flag does not redefine snapshot or Daily Trend output.

### 6.2 Current compact summary compatibility path

`src_next/summary.bqn` calls `outlook.Build`, whose compatibility default selects the latest recorded actual frontier as `as_of`.

Therefore current human and compact machine entrypoints do not necessarily use the same observation source:

```text
human report Outlook: explicit O / Today
compact summary Outlook: local recorded frontier L
```

That distinction must remain visible during migration.

### 6.3 Current cycle evidence

`cycle.bqn` provides:

- `start`;
- `end_exclusive`;
- `day_count`;
- `mode`;
- fixed, income-anchor, and calendar-month resolution paths.

This makes current cycle end `C` a concrete first horizon candidate without assuming a universal calendar month.

It does not prove that all future daily-capacity products must use `C` forever.

### 6.4 Edge states not yet designed

Current arithmetic returns zero when `days_left` is zero rather than an explicit unavailable result.

A future contract still needs named behavior for:

- `O < cycle start`;
- `O == C`;
- `O > C`;
- unavailable cycle;
- invalid or empty admitted scopes;
- historical and future observation frames.

### 6.5 Audit classification

```text
explicit O and cycle end C: reusable first-consumer evidence
owner-selectable horizon vocabulary: missing / later design
human versus compact observation-source parity: migration concern
```

## 7. Envelope overlap and duplicate reservation

### 7.1 Parallel current products

Outlook currently produces two separate shapes:

```text
whole-liquid daily amount
  = projected liquid balance / days_left

envelope daily amount
  = each selected life-envelope remaining / days_left
```

The envelope values are displayed in parallel. Outlook does not currently subtract envelope balances from `liq_daily`.

### 7.2 Backing evidence

`envelope_computation.bqn` separately computes:

```text
envelope funding_base
  = all role=asset, type=liquid actual closing balances

allocated_total
  = remaining balances of active dynamic/execution envelopes

cash_backed_unassigned
  = funding_base - allocated_total
```

This gives useful evidence that envelope balances are claims on the same liquid funding base used by Outlook.

### 7.3 Execution coverage evidence

The optional execution-envelope diagnostic compares:

```text
one configured execution envelope remaining
against
aggregate unfinished planned-payment total
```

It correctly reuses shared `plan_id` completion evidence.

However, it is aggregate-only. It does not establish a per-obligation identity link proving which exact plan amount is already represented by which envelope balance.

### 7.4 Duplicate-reservation hazard

A future daily-capacity calculation would double reserve money if it:

1. starts from a pool whose remaining amount already excludes or holds an obligation; and
2. subtracts the same obligation again from that pool.

The inverse hazard also exists: starting from whole liquid assets and assuming an envelope alone proves a bank balance is unavailable without a defined backing/admission contract.

Required future evidence is therefore not merely:

```text
envelope exists
```

It is:

```text
obligation X is already represented in admitted pool Y
with inspectable provenance
```

### 7.5 Audit classification

```text
envelope remaining/backing/aggregate coverage: reusable diagnostics
per-obligation reservation provenance: missing / design required
automatic subtraction of both envelope and obligation: prohibited
```

## 8. Current fixture and check evidence

### 8.1 Existing useful coverage

Current repository evidence includes:

- explicit `conservative` and `simple` profile configurations;
- an envelope+bimonthly fixture using `conservative`;
- a no-envelope+monthly fixture using `simple`;
- config tests for missing/default/explicit and explicit-empty behavior;
- focused Outlook arithmetic assertions on the conservative/default path;
- a focused test proving the human Outlook does not render the old safe/conservative label;
- explicit Outlook observation-source and isolation checks;
- a Stage 4 machine-field presence check for `src_next_outlook_liq_safe_daily`;
- plan completion evidence tests and execution-envelope coverage checks.

### 8.2 Coverage gaps before migration

The contrasting monthly-salary fixture has an empty plan, so its explicit `simple` value does not prove a meaningful obligation contrast.

Before any runtime migration, focused synthetic coverage is needed for at least:

1. same assets and plans under current `simple` and `conservative` compatibility values;
2. open versus completed `plan_id` rows;
3. explicit fixed obligation versus optional planned purchase;
4. liquid-to-non-liquid transfer versus real payment obligation;
5. included and excluded liquid accounts;
6. envelope and non-envelope paths;
7. one obligation already represented by an execution envelope;
8. prevention of duplicate reservation;
9. cycle-end, zero-day, unavailable-cycle, and negative-capacity states;
10. human, compact machine, and future structured output vocabulary;
11. current-output compatibility mapping or an explicit intentional break.

No production or private fixture is needed for this design proof.

## 9. Migration implications

A direct rename such as:

```text
POLICY_RISK_STYLE -> DAILY_CAPACITY_STYLE
```

would preserve the wrong abstraction.

A direct reinterpretation of `simple` and `conservative` as owner scopes would also be unsafe because current values do not carry:

- account admission identity;
- obligation admission identity;
- settlement evidence;
- reservation provenance;
- explicit horizon ownership.

The safe sequence remains:

```text
current audit
  -> docs-only minimal input/result contract
  -> synthetic characterization
  -> separately selected runtime seam
  -> compatibility decision
  -> migration only after gates pass
```

## 10. Recommended next eligible finite slice

The smallest next candidate is a docs-only **Daily Capacity minimal input/result contract** for the current Outlook consumer only.

It should define, without adding source fields or runtime code:

```text
input
  observation O
  horizon C for the first consumer
  admitted asset evidence rows
  admitted obligation evidence rows
  reservation provenance

result
  state
  eligible_assets
  admitted_obligations
  capacity_balance
  remaining_days
  daily_capacity
  diagnostics
  source evidence
```

That contract should also decide:

- whether negative capacity remains numeric or becomes a named state;
- how zero remaining days is represented;
- how one obligation proves it is already represented by an envelope/pool;
- which compatibility fields remain during migration;
- whether the compact summary must keep its local-`L` observation path temporarily.

It should **not** yet choose:

- a new config key;
- an account metadata key;
- a plan metadata expansion;
- a JSON section;
- a report rewrite;
- a migration date;
- private-data changes.

This candidate remains unselected after this audit.

## Non-goals

- no runtime or arithmetic change;
- no config fallback removal;
- no rename or deletion of `simple`, `conservative`, `liq_daily`, or `liq_safe_daily`;
- no source TSV or fixture mutation;
- no automatic classification of all liquid assets as spendable;
- no automatic promotion of all plans or issues to obligations;
- no envelope redesign;
- no broad Outlook temporal campaign;
- no selection of unrelated configurable-ledger, AI context-bundle, Israel, strict-source, M4, or Observatory work.

## Result

Current `POLICY_RISK_STYLE` is a single-consumer compatibility switch around the secondary Outlook field `liq_safe_daily`.

The repository already has strong reusable evidence for:

- observation-bounded balances;
- explicit account role/type classification;
- plan identity and completion;
- cycle boundaries;
- envelope balances, backing, and aggregate execution coverage.

It does not yet have explicit owner-selected asset admission, canonical obligation admission, or per-obligation reservation provenance.

The next safe step is a docs-only minimal input/result contract, not a runtime rename or a new metadata field.
