# Report Assumption Audit

Status: current remainder audit
Date: 2026-06-29

This document tracks report / household-policy assumptions that are allowed to remain in code, already externalized, or still need a decision.  It is the Phase 0 artifact for `docs/archive/active-plans/REPORT_POLICY_EXTERNALIZATION_PLAN.md`.

Scope: current `src_next/`, `config/*.tsv`, shell UI report entrypoints, and checks.  This audit is docs-only; it does not change source TSVs or report numbers.

## Classification rule

| Kind | Owner | Rule |
|---|---|---|
| core invariant | BQN code | Keep in code. Do not make user-configurable. |
| data contract | source/config TSV + docs | Stable metadata keys and allowed enums; lint before expanding. |
| lifestyle policy | config TSV or account metadata | Values may change without changing arithmetic code. |
| presentation | `config/report_labels.tsv` or UI code | Externalize only when it reduces coupling; do not create a DSL. |
| compatibility shim | code + check/docs | Keep only with an explicit removal condition. |
| fixture example | fixtures/checks | Fixture names/labels are examples, not production policy. |

## Current table

| Location | Literal / concept | Kind | Current status | Next action |
|---|---|---|---|---|
| `src_next/cube.bqn`, `src_next/tbds.bqn`, `src_next/projection.bqn` | `actual / plan / budget / forecast`, cube shape, posting projection | core invariant | Keep in code. | Do not externalize. New meanings should be separate projections/views. |
| `config/report_labels.tsv`, `src_next/report_labels.bqn` | Human-readable section titles, table labels, legends | presentation | Externalized first pass complete. Runtime Japanese labels now go through the label table where practical. | Keep using this boundary. Add duplicate/missing-key checks before expanding semantics. |
| `src_next/report.bqn` `BuildSectionEntries` | Canonical section keys and dispatcher order | presentation / dispatcher contract | Keep in code for now. Section functions are code-level capabilities; `--list-sections` is the UI boundary. | Do not create `report_sections.tsv` until section enable/order/alias changes become a real need and lint is designed. |
| `tools/main-ui.sh` `section_list` | UI menu labels / aliases for daily launcher | presentation / shell UI | UI-only; not part of accounting semantics. | Optional later: derive more from `tools/report --list-sections`, but keep shell responsibility to display/selection only. |
| `config/default_config.tsv`, `config/meta_schema.tsv`, `src_next/config.bqn` | `HOUSEHOLD_GROUP_LIFE`, `HOUSEHOLD_GROUP_RESERVE`, `HOUSEHOLD_GROUP_ORDER` | lifestyle policy | Correct boundary: concrete values like `daily`, `flex`, `reserve` are config values, not arithmetic concepts. | Keep. If new group policy keys are added, add lint/fixture first. |
| `src_next/household_policy.bqn` machine keys containing `daily/flex/reserve` | Compatibility output slots | compatibility shim | Acceptable for stable machine-readable fields; compared values are loaded from `HOUSEHOLD_GROUP_*`. | Do not treat the field names as policy values. Consider neutral keys only if changing machine API is worth it. |
| `src_next/envelope_computation.bqn` `PolicyForBase` / `FixtureFoodLikeTarget` | Fixture-gated target `fixture_food_like`, selector `budget=食費` via labels | fixture example / prototype policy | Safe as fixture/prototype guard, not production policy. Production defaults remain disabled unless policy is available. | Before real target selection, design a small target policy contract + missing/duplicate lint. Do not infer food from account names. |
| `src_next/envelope_computation.bqn` status values `SAFE/WARN/SHORT/HELD/DONE/SAVED/DRAWN` | Household report status enum | data contract / presentation mix | Status enum is now behaviorally meaningful. Labels/explanations live in `report_labels.tsv`; thresholds remain code. | If thresholds become user policy, split enum contract and threshold config in a separate design. |
| `src_next/readiness_check.bqn` `valid_roles`, `valid_types`, `valid_classes` | allowed metadata values | data contract | Good lint/readiness boundary. | Expand only with `config/meta_schema.tsv`, docs, and fixture updates. |
| `src_next/balances.bqn`, `src_next/ytd_summary.bqn`, `src_next/actual_snapshot.bqn`, `src_next/daily_trend.bqn`, `src_next/envelope_computation.bqn`, `src_next/household_policy.bqn` | prefix compatibility such as `assets:`, `income:`, `expenses:`, `budget:` | compatibility shim | Residual view/report compatibility remains outside projection/readiness. It is not a new policy mechanism. | Later cleanup candidate: remove or confine fallback after fixtures prove explicit `role=` paths cover all active reports. |
| `src_next/planned_payments.bqn`, `src_next/actual_comparison.bqn`, `src_next/outlook.bqn` | short display names by stripping prefixes | presentation helper | Display-only convenience; still tied to account naming style. | Prefer account label metadata only if account display configuration becomes a real requirement. Do not add `account_display.tsv` yet. |
| `checks/check-src-next-envelope-production-guard.sh` | fallback markers for daily/food/flex/reserve in snapshot | safety guard | Good: prevents polished numeric claims where src_next intentionally delegates/falls back. | Keep until replacement report values have contracts and fixtures. |

## Decisions from this pass

1. **Do not create `report_sections.tsv` now.**  Section dispatch is still code-owned; `--list-sections` is enough for UI tools.
2. **Do not create `account_display.tsv` now.**  Account labels/order should first try `accounts.tsv` metadata if the need becomes concrete.
3. **Keep `HOUSEHOLD_GROUP_*` config.**  This is the right boundary for lifestyle group values; Canonical Daily Cube axes remain fixed.
4. **Treat residual prefix checks as compatibility debt, not policy.**  They are candidates for a later small cleanup, but not part of this docs-only pass.
5. **Real target policy is still not designed.**  The existing food-like target is fixture/prototype-gated; production policy needs a separate contract and lint before implementation.

## Next implementation candidates

Small, safe candidates after this audit:

1. Add a check that every `report_labels.tsv` key referenced by `L "..."` exists, and duplicate keys fail closed.
2. Add a docs-only target policy sketch for future envelope targets (`target_id`, `label`, `selector_key`, `selector_value`) before creating any TSV.
3. Remove one residual prefix fallback from a single report module only if fixtures prove no output drift.

Non-candidates for now:

- Configurable Daily Cube axes or Layer names.
- A generic report DSL.
- `report_sections.tsv` or `account_display.tsv` without lint/fixture design.
- Any source TSV migration without explicit moko approval.
