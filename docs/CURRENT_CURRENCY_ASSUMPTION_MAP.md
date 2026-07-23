# Current Currency Assumption Map

Status: audit snapshot / docs-only current-state map
Owner: config
Canonical: no; canonical path: `docs/CURRENCY_AWARENESS_CAMPAIGN_MAP.md`
Exit: keep as Stage 0 evidence; selected Stage 1 semantics are now owned by `docs/CURRENCY_STAGE1_AMOUNT_SEMANTICS_DECISION.md`
Date: 2026-07-09

Stage 1 update: this map remains Stage 0 observation evidence. The selected amount/currency semantics are now owned by `docs/CURRENCY_STAGE1_AMOUNT_SEMANTICS_DECISION.md`; do not read this audit snapshot's Stage 1 candidate list as the current decision.

Source-model note (2026-07-24): references below to `journal.tsv` describe the pre-Journal-only evidence/model and are not current runtime instructions. Current Actual ingress is the configured native Journal; `plan.tsv` and `budget_alloc.tsv` remain TSV sources.

## 1. Purpose

This Stage 0 map answers the current-state question:

> Where does the current repository assume JPY, or otherwise assume that one numeric amount axis is sufficient?

The purpose is evidence, not design. This document exposes current assumptions so a later Stage 1 slice can choose the smallest amount/currency semantics decision to make next.

## 2. Scope and non-goals

Scope covered in this observation:

- source TSV shape and sandbox data;
- metadata schema and config defaults;
- loader and projection path;
- Posting IR contract and current implementation;
- AccountKey currency metadata behavior;
- Canonical Daily Cube and TBDS;
- report ViewModels, `FormatHuman`, compact output, and structured JSON;
- BQN editor validation and shell entrypoints;
- lint / strict checks, fixtures, golden outputs, and current docs.

Non-goals:

- no runtime implementation;
- no source TSV migration;
- no `currency=`, `base_amount=`, `BASE_CURRENCY`, FX rates, valuation, decimal amount, or currency-axis introduction;
- no decision that adding `currency=ILS` makes mixed-currency arithmetic safe;
- no Stage 1 semantics selection.

Semantic separations preserved here:

```text
amount != currency
original_amount != reporting_value
currency != exchange_rate
transaction_date != rate_observation_date
rate_observation_date != valuation_date
valuation_date != report_coordinate
```

## 3. Current amount flow overview

Current source amount flow is effectively:

```text
journal-like source TSV fifth column `amount`
  -> loader.SplitTsvKeepEmpty keeps fields aligned
  -> projection.MakeRow parses amount text as integer
  -> two Posting IR rows carry signed integer `delta`
  -> cube.Materialize stores naked numeric deltas at Day × AccountKey × Layer cells
  -> TBDS sums deltas into opening / movement / closing
  -> report ViewModels sum selected TBDS/cube/source values
  -> FormatHuman / compact / JSON emit naked numeric amount fields, usually with account_key strings that may include `/JPY` or another account metadata currency
```

Current account currency flow is separate and narrower:

```text
accounts.tsv optional metadata `currency=...`
  -> account_key.CurrencyFromMeta defaulting to `JPY`
  -> AccountKey string `account/currency`
  -> grouping/display labels and some TBDS row metadata
```

Important current limitation: the source transaction row has one amount and two accounts. If a source row moves between accounts with different account metadata currencies, current projection emits equal-and-opposite numeric deltas with each side's AccountKey, but it does not prove that the one source amount has a safe unit for both sides or that any FX valuation happened.

## 4. Repository-wide findings

| Surface | Evidence | Current assumption | Class | Pressure |
|---|---|---|---|---|
| source TSV | `docs/JOURNAL_META.md` describes required five columns and says accounting uses the first five columns only; `data/journal.tsv`, `data/plan.tsv`, `data/budget_alloc.tsv` have naked integer fifth-column amounts | source `amount` has no row-level currency identity; existing sandbox data is effectively JPY/one-unit | A, G | Yes: Stage 1 must define what source `amount` means once non-JPY exists |
| metadata schema | `config/meta_schema.tsv` has no `currency` or `base_amount` key, while `src_next/account_key.bqn:30` parses account metadata `currency` with default `JPY` | account-level `currency=` exists as compatibility behavior without schema ownership; row-level currency is absent | A, B, F | Yes: decide whether currency is ledger-level, account-level, row-level, unresolved, or staged |
| AccountKey | `src_next/account_key.bqn:30`, `:60`, `:69`; `src_next/main.bqn:32-33` | missing account currency silently becomes `JPY`; AccountKey carries `account/currency` string; conversion is out of scope | A, D, E | Yes: missing currency semantics are immediate Stage 1 pressure |
| loader | `src_next/context.bqn:31-41`, `:47-57`; `src_next/loader.bqn` SplitKeepEmpty helpers | loader preserves source fields but does not interpret currency or amount unit | B | Stage 1 pressure only if source contract changes |
| projection / Posting IR | `src_next/projection.bqn:154-248`; `docs/POSTING_IR_CONTRACT.md:75` | amount is parsed as integer and becomes signed integer `delta`; no Posting IR currency/value fields | B, C, F | Yes: Posting IR `delta` cannot remain semantically naked if mixed currencies are allowed |
| cube | `src_next/cube.bqn:152-193`; `docs/CANONICAL_DAILY_CUBE.md:65` | cube cells contain naked numeric deltas at Day × AccountKey × Layer | C, D | Yes, for mixed-currency reports; maybe not for explicit single-currency operation |
| TBDS | `src_next/tbds.bqn:85-135`; `docs/TBDS_CONTRACT.md:73-75`, `:128` | TBDS row has `currency`, but opening/movement/closing are plain numbers and sums by account/layer; amount is not an axis | C, D | Yes: decide where currency identity must become non-optional before aggregation |
| ViewModels | `src_next/balances.bqn:25-35`, `:55-113`; `src_next/snapshot.bqn:96-123`; `src_next/trial_balance.bqn:89-97` | totals add amounts across selected account groups without partitioning by currency | C, D, E | Yes for balances/snapshot/trial-balance totals |
| FormatHuman | `src_next/format.bqn:64-76`; balance/snapshot/trial-balance formatters | integer, right-aligned yen-style/no-decimal display; unit generally inferred from account key or omitted | E | Yes: display must not define arithmetic semantics |
| structured JSON | `src_next/balances.bqn:119-164`; `src_next/planned_payments.bqn:198-238`; `src_next/envelope_computation.bqn:805-874`; `docs/REPORT_SECTION_CONTRACT_CHECKLIST.md` examples | JSON emits `amount`, totals, `delta`, `remaining`, etc. as naked numbers, usually no adjacent `currency` field | E, D | Yes for machine consumers; JSON could preserve wrong assumptions more strongly than human text |
| editor | `src_edit/validate.bqn:34-54`, `:114-130`; `tools/edit-bqn` usage says `--amount INT` | editor validates integer amount only; no currency prompt/validation; metadata syntax alone could accept `currency=...` if schema does not reject it elsewhere | F, A | Yes: source-writing boundary is where missing/unknown currency can become indistinguishable from JPY |
| lint / strict checks | `src_next/readiness_check.bqn` validates role/type/spend_class/envelope_role but not currency; `checks/check-src-next-minimal-summary.sh:160-174` expects account totals as `<account_key> <signed_integer>` | checks prove integer one-axis output shape, not currency-safe arithmetic | F | Yes: Stage 1 should add checks before implementation if semantics change |
| fixtures / goldens | `fixtures/src-next-currency-accountkey/*`; many expected summaries show `/JPY` account keys and one numeric total | fixtures prove AccountKey labeling/defaulting, not mixed-currency arithmetic safety | F, G | Yes: add Stage 1/2 fixture only after semantics selected |
| docs | `docs/ENGINEERING_ROADMAP.md:80-94`; `docs/CURRENCY_AWARENESS_CAMPAIGN_MAP.md` | broad multi-currency/FX ideas exist, but campaign map correctly separates currency awareness from FX valuation | G | No implementation authority; guides decision pressure |

## 5. Findings classified by A-G

### A. Source meaning

**Explicit fact:** `journal.tsv`, `plan.tsv`, and `budget_alloc.tsv` are journal-like five-column rows, with amount in column 5. `docs/JOURNAL_META.md` states the first five columns are fixed and that accounting/balance calculation uses only those five columns.

**Evidence:**

- `docs/JOURNAL_META.md` basic format and extension-column sections.
- `data/journal.tsv`, `data/plan.tsv`, `data/budget_alloc.tsv` contain naked integer amounts with no currency column.
- `config/meta_schema.tsv` defines metadata keys but does not define `currency` or `base_amount`.

**Assumption:** a row's `amount` is sufficient source value for accounting. Current data is safe because it is effectively one-currency. Future pressure: source `amount` needs an explicit meaning if non-JPY rows exist.

### B. Parsing

**Explicit fact:** source rows are split preserving empty fields, then `projection.MakeRow` extracts field 4 as `amountText` and validates it as integer text.

**Evidence:**

- `src_next/context.bqn:31-41` and `:47-57` call `loader.SplitTsvKeepEmpty` before `proj.MakeRow`.
- `src_next/projection.bqn:154-180` extracts `amountText` from field 4, checks `IsIntegerText`, and parses with `•BQN`.
- `src_edit/validate.bqn:34-54` validates editor amount input as integer.

**Assumption:** amount parsing has one numeric text grammar and no currency-dependent grammar. This is compatible with current integer JPY-like data, but pressures Stage 1 precision/source representation decisions.

### C. Arithmetic

**Explicit fact:** Posting IR and downstream calculations use signed integer `delta` and ordinary addition.

**Evidence:**

- `docs/POSTING_IR_CONTRACT.md:75` defines `delta` as signed integer delta.
- `src_next/projection.bqn:240-248` creates debit `+amount` and credit `-amount`.
- `src_next/projection.bqn:259-260`, `src_next/cube.bqn:37`, and `src_next/tbds.bqn:32-38` sum deltas.

**Assumption:** all deltas being summed are mutually addable. Current repository evidence does not show conversion or currency-safe partitioning before arithmetic.

### D. Aggregation

**Explicit fact:** AccountKey includes currency metadata, but major totals aggregate plain numbers over selected account groups.

**Evidence:**

- `src_next/account_key.bqn:69` builds `account/currency` AccountKeys.
- `src_next/balances.bqn:55-63` filters entries by role/type and `SumAmount`s the numeric values.
- `src_next/snapshot.bqn:113-118` sums liquid/savings/investment/liability closing vectors into totals.
- `src_next/trial_balance.bqn:89-97` sums openings/debits/credits/closings into a `Total` row.
- `fixtures/src-next-currency-accountkey/expected/src_next_summary.txt` shows `assets:usd_cash/USD` and `expenses:food/JPY` coexisting, while `src_next_actual_expense_total: 150` includes all food debits as one number.

**Assumption:** grouping by account role/type is sufficient for totals. AccountKey currency labels reduce some account-balance collision risk, but current totals are not currency-partitioned.

### E. Display

**Explicit fact:** human display uses integer formatting and usually does not print a separate currency field except when account key includes `/JPY` or another suffix.

**Evidence:**

- `src_next/format.bqn:64-76` right-aligns and formats integer amounts.
- `src_next/trial_balance.bqn:83-97` prints numeric columns plus AccountKey strings and a zero-sum check.
- `src_next/balances.bqn:67-113` prints balances/totals as numbers.
- `docs/report-mocks/TRIAL_BALANCE.mock.txt` includes account names suffixed `/JPY` and numeric totals.

**Assumption:** yen-style integer display is adequate. Current display does not decide machine arithmetic, and future currency work must keep that separation.

### F. Validation

**Explicit fact:** current validation rejects invalid dates, unknown accounts, and non-integer amounts, but not unknown/missing/incompatible currency states.

**Evidence:**

- `src_next/projection.bqn:198-210` reports `invalid_amount`, `invalid_date`, or `unknown_account`.
- `src_edit/validate.bqn:114-130` validates date/memo/from/to/amount/meta for journal-like additions.
- `src_next/readiness_check.bqn` validates metadata vocabularies for role/type/spend_class/envelope_role, not currency.
- `checks/check-src-next-minimal-summary.sh:160-174` validates integer shape of `src_next_actual_account_total`, not currency semantics.

**Assumption:** if account and integer amount are valid, amount semantics are valid enough. This is currently safe because the repository is effectively one-currency, but not safe if mixed currency can enter source rows.

### G. Documentation only

**Explicit fact:** current docs already contain multi-currency design material, but it is not current runtime truth.

**Evidence:**

- `docs/ENGINEERING_ROADMAP.md:80-94` proposes `currency`, `base_amount`, `BASE_CURRENCY`, and TBDS changes.
- `docs/CURRENCY_AWARENESS_CAMPAIGN_MAP.md` explicitly inserts Stages 0-5 before FX valuation and warns not to treat `currency=ILS` as safe mixed-currency arithmetic.
- `docs/TBDS_CONTRACT.md:88-117` explains amount as scalar value at a coordinate, not an axis.

**Assumption:** docs contain later-stage options, not selected contracts. This map must not promote them into implementation.

## 6. Explicit JPY assumptions

1. **Default account currency is JPY.**
   - Evidence: `src_next/account_key.bqn:30` uses `CurrencyFromMeta ← { MetaValue ⟨"currency", "JPY", 𝕩⟩ }`; `src_next/main.bqn:32` prints `Default currency: JPY`.
   - Classification: A, B, E.
   - Pressure: yes. Missing currency currently means JPY at account resolution.

2. **Goldens and mocks encode JPY AccountKeys.**
   - Evidence: expected summaries and report mocks contain `assets:bank/JPY`, `income:salary/JPY`, etc.; `docs/report-mocks/TRIAL_BALANCE.mock.txt` shows `/JPY` rows.
   - Classification: E, F, G.
   - Pressure: moderate. These are fixture/display evidence, not runtime proof by themselves.

3. **Current broad roadmap assumes base currency JPY in later FX design.**
   - Evidence: `docs/ENGINEERING_ROADMAP.md:89` proposes `BASE_CURRENCY=JPY`.
   - Classification: G.
   - Pressure: later-stage only. It should not be imported into Stage 1 automatically.

## 7. Implicit single-currency / single-numeric-axis assumptions

1. **Source row has one amount for both sides.**
   - Evidence: `projection.MakeRow` emits debit and credit rows from one `amount`; no per-side amount/currency.
   - Inference: a transfer between different AccountKey currencies can produce balanced numeric deltas without proving semantic convertibility.
   - Pressure: high.

2. **Posting IR `delta` is naked.**
   - Evidence: `docs/POSTING_IR_CONTRACT.md:75`; `src_next/projection.bqn` row shape lacks currency/value fields.
   - Pressure: high if mixed source currencies are allowed.

3. **Cube and TBDS store one numeric value per coordinate.**
   - Evidence: `docs/CANONICAL_DAILY_CUBE.md` describes Day × Account × Layer projection rows with `delta`; `docs/TBDS_CONTRACT.md` keeps amount as scalar, not axis.
   - Pressure: medium/high. Single-currency awareness may not require axis changes; mixed-currency aggregation probably requires non-optional currency identity before totals.

4. **Report totals add across account groups.**
   - Evidence: balances, snapshot, trial balance, cycle summary, envelopes, outlook, daily trend all sum numeric amounts according to role/type/layer/status.
   - Pressure: high for any report that might see mixed currency.

5. **Structured JSON emits naked numbers.**
   - Evidence: balances JSON `amount` and totals; planned JSON `amount` / `actual_amount`; envelope JSON `remaining`, `delta`, etc.
   - Pressure: high for downstream machine consumers.

6. **Integer amount is the only accepted amount grammar.**
   - Evidence: projection and editor validation.
   - Pressure: high if Stage 1 considers human-readable decimal source amounts or minor-unit normalization.

## 8. Safe current behavior versus future pressure points

Safe enough today:

- Existing JPY source rows remain valid.
- AccountKey defaulting to `/JPY` prevents account key strings from being empty and gives current reports stable labels.
- Integer-only amount validation prevents malformed decimal/garbage amounts from entering the current engine.
- Current reports are coherent when the ledger is effectively one-currency and integer-denominated.

Future pressure points:

- Missing account currency silently becomes JPY; this is compatibility behavior, not proof of source currency truth.
- `currency=` account metadata is parsed even though `config/meta_schema.tsv` does not define it; that is an ownership gap.
- Mixed account currencies can coexist in AccountKey output, but gross expense totals and other reports still add naked amounts.
- JSON numeric fields could be consumed as if they were universally addable.
- Editor/write path has no way to require, default, reject, or preview currency semantics.
- Checks currently validate output shape and integer-ness, not currency compatibility.

## 9. Evidence gaps / unresolved questions

- Whether production `accounts.tsv` uses any `currency=` metadata was not inspected here because real source TSV must not be modified and Stage 0 does not need private-data disclosure.
- The exact current strict-lint behavior for unknown metadata keys should be verified before Stage 1 changes metadata schema. Current observed BQN readiness checks do not validate currency.
- It is not yet decided whether account-level currency defaulting is a deliberate current contract or an early prototype compatibility path that should be tightened.
- The repository has a `fixtures/src-next-currency-accountkey` proof that AccountKey labels can carry USD, but no fixture proving mixed-currency report arithmetic is safe. This is a finding, not a defect fix request.

## 10. Smallest justified Stage 1 decision candidates

Evidence supports these Stage 1 question shapes. No answer is selected here.

1. **What does source `amount` mean once non-JPY currency exists?**
   - Triggered by: source column 5, integer parser, editor `--amount INT`, Posting IR `delta`.

2. **What does missing currency mean for existing rows and accounts?**
   - Triggered by: `CurrencyFromMeta` defaulting missing account currency to JPY.

3. **Where must currency identity first become non-optional: source row, account metadata, ledger config, Posting IR, or report boundary?**
   - Triggered by: account-level `currency=` exists but row-level amount is naked.

4. **Can Posting IR continue to carry naked `delta`, or must `delta` be paired with currency/amount-kind before any cross-account aggregation?**
   - Triggered by: cube/TBDS/report sums.

5. **Which current reports are explicitly one-currency-only until currency partitioning exists?**
   - Triggered by: balances/snapshot/trial-balance/envelope/JSON totals.

6. **Should current `currency=` account metadata be documented/schema-owned, rejected until Stage 1, or treated as compatibility-only?**
   - Triggered by: `account_key.bqn` parses it while `config/meta_schema.tsv` does not define it.

## 11. Recommended next finite slice

Recommended next finite slice:

```text
Stage 1 decision slice: choose the source amount + missing currency contract.
```

Suggested boundary for that slice:

- docs-only first;
- decide source `amount` semantics and missing/unknown currency behavior;
- decide whether current account-level `currency=` default-to-JPY is compatibility-only or current contract;
- explicitly state whether Posting IR `delta` may remain naked for the next implementation slice;
- do not introduce FX valuation, `base_amount`, live rates, or automatic conversion.

## 12. No Stage 1 semantics selected

This document intentionally selects no Stage 1 answer. It does not authorize implementation of currency metadata, FX valuation, decimal amounts, currency axes, or report changes. It only maps the current semantic terrain and records the smallest next decisions supported by repository evidence.
