# Household Policy Layer Plan

Status: **active design / policy layer boundary**
Date: 2026-06-26

## 1. Vision

`bqn-ledger` は、ledger / hledger 系より簡単に記帳できるが、内部は accounting-grade で、生活管理にはより役に立つ道具を目指す。

この文書は、そのうち **生活スタイル・家計管理スタイルの差し替え可能性** を担当する。

合言葉:

```text
記帳は簡単。
会計事実は厳密。
生活ルールは policy。
判断材料は view。
```

## 2. 背景

現状の repo には、年金の隔月支給、固定費の収入日連動、封筒予算、日割り金額など、moko の生活に強く効くルールがある。

ただし、`bqn-ledger` を会計ソフトとして育てるなら、特定の生活スタイルを core に埋め込んではいけない。

年金生活、月給、週給、不定期収入、フリーランス、同居家計、封筒派、口座残高派、ゼロベース予算派など、さまざまな管理スタイルに対応できる構造にする。

## 3. Layer model

```text
Source TSV
  -> Posting IR
  -> Ledger-wide validated postings
  -> TBDS(period, as_of)
  -> Accounting reports
  -> Household policy layer
  -> Household views / warnings / advice
```

### Accounting core

Accounting core は生活ルールを知らない。

Allowed:

- account
- posting
- layer
- period
- opening / movement / closing
- Trial Balance
- Balance Sheet
- Income Statement
- validation / provenance

Not allowed:

- 年金支給日
- 給料日
- 食費らしさ
- daily / flex / reserve の生活意味
- 安全日割り
- おすすめ配分
- 家族構成や生活流派

### Household policy layer

Household policy layer は、accounting core の出力を生活判断用 view に変換する。

Allowed:

- income cadence / income anchor
- cycle resolver
- fixed obligation policy
- envelope group semantics
- budget style
- reserve style
- target selectors
- alert thresholds
- daily allowance formula
- missing-data readiness policy

The policy layer may read stable metadata keys and policy config, but must not mutate source TSV.

## 4. Product goal

ledger / hledger を単に再実装しない。

目標:

```text
ledger / hledger より簡単に記帳できる。
ledger / hledger より生活判断に役立つ。
ledger / hledger より household policy の拡張性が高い。
それでも accounting core は ledger / hledger に負けない。
```

## 5. Supported household style axes

最初から全実装するのではなく、設計上対応できる軸として固定する。

| Axis | Examples | Core ownership |
|---|---|---|
| income cadence | monthly salary, weekly pay, pension bimonthly, irregular freelance | policy |
| period style | calendar month, payday cycle, income-anchor cycle, custom fixed period | policy / period resolver |
| budget style | envelope, zero-based, account-balance-first, minimal tracking | policy / household views |
| obligation style | rent/utilities before spending, debt repayment, subscription reserve | policy |
| household structure | single, couple, shared expenses, dependent support | policy |
| business mix | personal-only, business-mixed, tax export | metadata / accounting reports / export |
| risk style | conservative safe daily, cash-only, credit-card aware, reserve-first | policy |

## 6. Policy profile concept

将来、policy profile を導入できるようにする。

Example profile labels:

```text
monthly_salary
weekly_income
pension_bimonthly
freelance_irregular
zero_based_budget
envelope_budget
account_balance_first
minimal_tracking
business_mixed
```

Profile は calculation engine を差し替えるものではない。

Profile は、次のような policy choices の束である。

```text
period_resolver = income_anchor | calendar_month | fixed | rolling
income_cadence = monthly | weekly | bimonthly | irregular
budget_style = envelope | zero_based | balance_first | minimal
reserve_policy = preserve_until_period_end | target_amount | none
fixed_obligation_policy = before_daily_allowance | separate_warning | ignore
alert_style = conservative | normal | quiet
```

## 7. Stable selector model

Household policy は account 名に直接依存しない。

Prefer stable metadata selectors:

```text
role=expense
budget=...
budget_group=...
spend_class=...
type=liquid|savings|invest
cashflow=fixed_obligation
anchor=income:<label>
```

Policy target example:

```tsv
target_id	label	selector_key	selector_value
food_like	食費	budget	食費
life_envelopes	生活封筒	budget_group	life
reserve_envelopes	仮確保	budget_group	reserve
```

Concrete labels are policy data, not engine concepts.

## 8. Invariants

### 8.1 Core isolation

Policy must not change Posting IR, ledger-wide postings, or TBDS accounting facts.

Same source TSV + same accounting period must produce the same accounting reports regardless of household policy profile.

### 8.2 Policy explicitness

Policy defaults may exist, but must be documented and visible.

Do not silently infer a household style from account names if metadata/config is required.

### 8.3 Fail visible

If a policy view cannot be computed because metadata or config is missing, show `UNAVAILABLE` / `WARN` / `ERROR` rather than `0`.

### 8.4 No hard-coded lifestyle

No permanent BQN logic may assume:

- pension is the only income style
- cycle is always income-anchor
- daily/flex/reserve are universal group names
- food is a built-in account concept
- every household wants envelope budgeting

### 8.5 Source TSV safety

Adding or switching a policy profile must not rewrite source TSV automatically.

If a migration is needed, produce a human-reviewed plan first.

## 9. First implementation direction

Do not start by implementing many profiles.

First, make the boundary real:

1. Accounting core produces TBDS / Trial Balance / Balance Sheet / Income Statement.
2. Household policy layer consumes accounting outputs and account metadata.
3. Existing moko-style pension / envelope behavior becomes one policy profile candidate, not hard-coded core.
4. Add one contrasting public fixture, e.g. monthly salary + calendar month, to prove the engine is not pension-only.

## 10. Work phases

### Phase 0 — Document boundary ✅ Done (2026-06-27)

- [x] Create this plan.
- [x] Link this plan from active docs and TODO.
- [x] Record that `pension_bimonthly` is a policy profile candidate, not a core invariant.
  - Explicit in Section 6 (Policy profile concept) and Section 8.4 (No hard-coded lifestyle).
  - `pension_bimonthly` is a profile label, never a core invariant.

### Phase 1 — Policy assumption audit ✅ Done (2026-06-27)

- [x] Audit `src_next` and current report code for hard-coded lifestyle labels.
- [x] Classify assumptions as core / metadata / policy / presentation / fixture.
- [x] Update `docs/REPORT_ASSUMPTION_AUDIT.md` or create a focused household policy audit table.

Audit findings:

| File | Finding | Classification | Action |
|------|---------|----------------|--------|
| `config.bqn` | Missing POLICY_* values → silent default | Policy | Fixed: added CONFIG WARNING on default fallback |
| `envelope_computation.bqn` | `GetPri` hard-coded `⟨"daily","flex","reserve"⟩` | Policy | Fixed: now reads `cfg.HouseholdGroupOrderLabels` |
| `envelope_computation.bqn` | `FixtureFoodLikeTarget` hard-codes `"食費"` | Fixture | Acceptable (test-only, not production path) |
| `envelope_computation.bqn` | FormatHuman status strings ("reserve 確保中" etc.) | Presentation | Acceptable for now (presentation layer) |
| `config/meta_schema.tsv` | POLICY_* keys not defined in schema | Metadata | Fixed: added policy key definitions |
| `household_policy.bqn` | Uses cfg for group labels | Policy-driven | ✅ Already correct |
| `cycle.bqn` | Reads mode/income_account from config | Config-driven | ✅ Already correct |
| `readiness_check.bqn` | Validates spend_class against known values | Metadata | ✅ Already correct |

### Phase 2 — Minimal policy schema design

- [x] Decide where policy lives initially: `data/config.tsv`, separate `policy/*.tsv`, or fixture-local config.
- [x] Define minimal keys for period resolver, income cadence, budget style, and group semantics.
- [x] Add unknown / missing / duplicate policy checks before using policy in reports.

### Phase 3 — Two-style fixture proof

- [x] Keep moko-like bimonthly income / income-anchor fixture.
- [x] Add monthly salary / calendar-month fixture.
- [x] Ensure accounting core outputs are policy-independent.
- [x] Ensure household views differ only through explicit policy.

### Phase 4 — Household views on top

- [x] Cycle view from selected period resolver.
- [x] Envelope view from target selectors.
- [x] Daily allowance view from explicit risk style.
- [x] Fixed obligation reserve from explicit cashflow policy.

## 11. Relationship to current docs

- `docs/ACCOUNTING_ENGINE_QUALITY_PLAN.md`
  - Accounting core quality gate. This policy layer must sit above it.
- `docs/TBDS_CONTRACT.md`
  - Provides accounting state consumed by household views.
- `docs/SRC_NEXT_HOUSEHOLD_REPORT_POLICY_CONTRACT.md`
  - Existing contract for household report selectors; this plan generalizes it to lifestyle/profile level.
- `docs/REPORT_POLICY_EXTERNALIZATION_PLAN.md`
  - Broader externalization plan. This document narrows the focus to household lifestyle policy.
- `docs/GENERALIZATION_TODO.md`
  - Historical background; current active work belongs in `TODO.md` and this plan.

## 12. Immediate next task

After TBDS accounting gate:

```text
1. Audit hard-coded lifestyle assumptions.
2. Define minimal policy profile schema.
3. Add one non-pension monthly-salary fixture.
4. Prove accounting core is unchanged and household view changes by policy only.
```
