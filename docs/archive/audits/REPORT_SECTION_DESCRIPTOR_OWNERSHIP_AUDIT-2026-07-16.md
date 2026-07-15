# Report Section Descriptor Ownership Audit

Status: audit snapshot
Owner: report
Canonical: no; current paths: docs/REPORT_CONTRACTS.md, docs/STRUCTURED_UI_EXPORT_CONTRACT.md, src_next/report.bqn
Exit: retain as point-in-time evidence; do not implement directly; follow the selected active plan and TODO

## 1. Baseline

- Audit date: 2026-07-16
- Branch / target: current local `main` HEAD
- Baseline commit: `954d800 refactor: fold plan evidence into plan rows`
- Working tree at audit start: clean
- Previous plan-module consolidation: present in history and complete at this baseline
- Data boundary: repository source, docs, checks, and public fixture output only
- Private production data: not read or used

This is a point-in-time observation of the current tree. It is evidence, not a current contract and not implementation authority.

## 2. Scope

### Files inspected

Runtime and metadata implementation:

- `src_next/report.bqn`
- `src_next/report_section_metadata.bqn`
- `src_next/report_labels.bqn`
- `src_next/json.bqn`
- `tools/report`
- `tools/report-section-metadata`
- `tools/main-ui.sh`

Executable checks:

- `checks/check-report-section-metadata.sh`
- `checks/check-ui-smoke.sh`
- `checks/check-structured-ui-boundary.sh`
- `checks/check-src-next-report.sh`

Current contracts and routing:

- `docs/REPORT_CONTRACTS.md`
- `docs/REPORT_SECTION_CONTRACT_CHECKLIST.md`
- `docs/STRUCTURED_UI_EXPORT_CONTRACT.md`
- `docs/AI_CODEMAP.md`
- `docs/DOCS_LIFECYCLE_CONTRACT.md`
- `docs/archive/active-plans/README.md`
- `docs/README.md`
- `TODO.md`

Archive matches returned by searches were treated as historical evidence only, not current runtime instructions.

### Commands and observations

The audit used:

```sh
git status --short
git log -3 --oneline
rg -n \
  'report_section_metadata|report-section-metadata|BuildSectionEntries|--list-sections|section_key|structured_output|daily-flow|issues' \
  src_next tools checks docs TODO.md
tools/report fixtures/src-next-golden --list-sections --no-color
tools/report-section-metadata
tools/report-section-metadata --format json
bash checks/check-report-section-metadata.sh fixtures/src-next-golden
bash checks/check-structured-ui-boundary.sh
bash checks/check-ui-smoke.sh fixtures/src-next-golden
```

The focused checks passed during the pre-selection audit. They show current key/order parity and UI boundary health; they do not eliminate the ownership duplication described below.

## 3. Current ownership matrix

| Information | Runtime owner | Metadata owner | Docs/check duplication | Current source of truth | Drift detection |
|---|---|---|---|---|---|
| Section key | `report.bqn::BuildSectionEntries` keyed entries | `report_section_metadata.bqn::rows` column 0 | `REPORT_CONTRACTS.md`; partial `check-ui-smoke.sh` inventory; UI help | Runnable human contract: `tools/report --list-sections` / `report.bqn` | Yes for runtime-vs-metadata exact key list in `check-report-section-metadata.sh`; partial elsewhere |
| Section order | `BuildSectionEntries` row order; also full report/cache order | metadata `rows` order | `REPORT_CONTRACTS.md` list | Runtime order from `BuildSectionEntries` and `--list-sections` | Yes for runtime-vs-metadata exact order |
| Human label | Section `FormatHuman` implementations and `report_labels.bqn`; `report.bqn::FirstLine` observes rendered heading | metadata rows independently select label keys or literals, then normalize decoration | UI smoke has representative literal assertions | Human text: section formatter/config; menu label: metadata command | Partial; representative labels only, no complete formatter-to-metadata mapping check |
| Category | No runtime execution use | metadata row column 2 | Structured export docs describe category concept | `report_section_metadata.bqn::rows` | No exhaustive independent contract check |
| Implementation owner path | Actual imports and builder calls in `report.bqn` | metadata row column 3 as a string | AI code map and section checklist examples | Actual execution relation: `report.bqn`; exported owner string: metadata output | No owner-string-to-import/builder or path-existence check |
| Human output availability | Presence of a human builder and successful section execution | metadata row column 4, currently manual `yes` | Structured export docs | Runtime capability: `report.bqn`; public metadata value: metadata command | No direct capability-to-value check |
| Structured output value | Section-specific JSON dispatch in `report.bqn` for `planned`, `balances`, `snapshot`, `envelopes` | metadata row column 5, currently `metadata` for all rows | `STRUCTURED_UI_EXPORT_CONTRACT.md`; JSON section docs/checks | Public metadata value remains the metadata command; section JSON capability remains `report.bqn` | Ambiguous: current check preserves values but does not define which capability the column means |
| Human builder | Imports and expressions in `BuildSectionEntries` | No executable builder; only owner string and human metadata | Section checklist examples; report checks | `report.bqn` plus implementation module | Report checks cover output, but no descriptor-to-builder bijection exists |
| JSON builder | `report.bqn` dispatch plus four implementation `FormatJson` functions | No builder mapping; only `structured_output` text | Section JSON docs and `check-src-next-report.sh` | `report.bqn` dispatch | Section JSON behavior is checked; relation to metadata value is not |
| First-line marker | `report.bqn::FirstLine` over generated human section text | Metadata label is separate and presentation-normalized | UI smoke checks non-empty markers | `tools/report --list-sections` | Non-empty markers checked; no complete marker-to-label semantic parity check |

## 4. Current section inventory

The current tree reports 15 sections. The observed order matches both `report.bqn` and the metadata command.

| Order | Key | Category | Implementation owner | Section-specific JSON ViewModel |
|---:|---|---|---|---|
| 1 | `snapshot` | `overview` | `src_next/snapshot.bqn` | yes |
| 2 | `issues` | `operations` | `src_next/issues.bqn` | no |
| 3 | `ytd` | `accounting` | `src_next/ytd_summary.bqn` | no |
| 4 | `balances` | `accounting` | `src_next/balances.bqn` | yes |
| 5 | `cycle` | `household` | `src_next/cycle_summary.bqn` | no |
| 6 | `trial-balance` | `accounting` | `src_next/trial_balance.bqn` | no |
| 7 | `envelopes` | `household` | `src_next/envelope_computation.bqn` | yes |
| 8 | `planned` | `operations` | `src_next/planned_payments.bqn` | yes |
| 9 | `recent` | `operations` | `src_next/recent_journal.bqn` | no |
| 10 | `check` | `diagnostics` | `src_next/readiness_check.bqn` | no |
| 11 | `outlook` | `household` | `src_next/outlook.bqn` | no |
| 12 | `daily-trend` | `household` | `src_next/daily_trend.bqn` | no |
| 13 | `daily-flow` | `household` | `src_next/daily_flow.bqn` | no |
| 14 | `actual-comparison` | `household` | `src_next/actual_comparison.bqn` | no |
| 15 | `debug` | `diagnostics` | `src_next/report.bqn` | no |

The four section-specific JSON ViewModels above are derived from current `report.bqn` dispatch, not from interpreting the metadata column.

## 5. Confirmed duplication

1. **Key and order:** the same 15 keys in the same order are manually listed in `report.bqn::BuildSectionEntries` and `report_section_metadata.bqn::rows`.
2. **Label spec:** metadata rows independently choose config label keys or literals that correspond to headings produced by implementation formatters. `daily-flow` uses a literal in both surfaces.
3. **Owner relation:** metadata stores an owner path string separately from the actual import and build expression in `report.bqn`.
4. **Human output value:** every metadata row manually stores `yes`; this is separate from the existence and behavior of a human builder.
5. **JSON capability versus metadata value:** the runtime JSON dispatch has four explicit keys, while every metadata row independently stores `structured_output=metadata`.
6. **Documentation inventory:** `docs/REPORT_CONTRACTS.md` manually lists section keys.
7. **UI/check inventory:** `checks/check-ui-smoke.sh` maintains a separate `required_keys` array rather than consuming an exact descriptor inventory.
8. **JSON serialization:** `report_section_metadata.bqn` implements local JSON string/object formatting while `src_next/json.bqn` owns shared fail-closed serialization and broader escaping semantics.

The existing parity check usefully catches key/order divergence between runtime and metadata. It is drift detection around two owners, not elimination of duplicate ownership.

## 6. Confirmed current drift

### 6.1 Current contract inventory omits `daily-flow`

`docs/REPORT_CONTRACTS.md` lists 14 keys and omits `daily-flow`. Current runtime and metadata output both contain `daily-flow` between `daily-trend` and `actual-comparison`.

### 6.2 UI smoke required-key inventory omits two runtime sections

`checks/check-ui-smoke.sh::required_keys` omits:

- `issues`
- `daily-flow`

The check still observes a total of 15 sections and succeeds, but removal of either omitted key would not fail its explicit per-key loop.

### 6.3 `structured_output` is a contract ambiguity

The column name, surrounding docs, and current value vocabulary do not distinguish two different statements:

1. the metadata command itself can return each descriptor row in a structured TSV/JSON representation;
2. an individual report section has its own section-specific JSON ViewModel through `tools/report --section <key> --format json`.

Current rows all carry `metadata`, while current runtime has four section-specific JSON ViewModels. This audit does **not** conclude that the current value is simply wrong. It records that the two meanings are not separately defined and that a consumer could misunderstand the field.

Changing the column name, values, or meaning is a separate future contract decision. It is not part of descriptor centralization.

## 7. Risk classification

| Risk area | Current assessment | Reason |
|---|---|---|
| Household calculation correctness | Low/directly unaffected | The duplication concerns section identity and metadata, not accounting arithmetic or source admission. |
| Human report section availability | Medium maintenance risk | A runtime builder can be added/removed without all static inventories being updated; the runtime path itself is currently healthy. |
| UI menu drift | Medium | `main-ui.sh` consumes metadata key/label/order, so metadata/runtime divergence can expose missing, stale, or non-runnable menu entries. |
| Metadata consumer misunderstanding | Medium, already plausible | `structured_output` does not distinguish metadata representation from section-specific JSON capability. |
| Section add/remove maintenance | High relative to this small surface | Key, order, label spec, owner string, values, docs, and checks require coordinated manual edits. |
| AI architecture misunderstanding | Medium | Current docs can make either `report.bqn` or metadata rows appear to own the full section map, while actual ownership is split. |
| Serializer divergence | Low current impact / medium future risk | Current output parses, but the local serializer has narrower escaping behavior than `json.bqn`. |

## 8. Options considered

### A. Fold metadata into `report.bqn` — not selected

This reduces a file but couples the source-independent metadata command to the report entrypoint and its broad implementation import graph. Co-location alone does not guarantee one descriptor owner and increases future import-side-effect risk.

### B. Add one pure static descriptor module — recommended

A small module can own static identity/order/metadata fields while remaining free of source reads, clock reads, CLI execution, and implementation imports. Runtime builders and CLI behavior stay with their current owners. This adds one file but reduces semantic ownership duplication.

### C. Make one existing module importable as the owner — not selected

`report.bqn` and `report_section_metadata.bqn` are both executable entrypoints ending in `Main •args`. Making either simultaneously act as a side-effect-free library requires import guards or mixed CLI/library responsibility. That is less clear than one pure data module.

### D. Keep current structure and strengthen checks only — not selected

This is the smallest code change and existing parity checks already provide value, but it leaves the duplicated owner model in place. It detects some drift after manual duplication rather than removing the duplicated static identity.

## 9. Recommendation

Create one small pure data module, expected at:

```text
src_next/report_sections.bqn
```

It should own static descriptors only. It must:

- own canonical static section identity and order;
- contain metadata label specs, categories, owner paths, and current public metadata values;
- contain no builder functions and construct no ViewModels;
- read no source TSV;
- read no config;
- read no wall clock;
- execute no CLI and read no `•args`;
- import no report implementation module;
- have no import-time output or mutation;
- avoid dynamic loading and generic plugin architecture.

`report.bqn` should continue to own executable human builders, JSON dispatch, first-line marker generation, report/cache orchestration, and CLI behavior. `report_section_metadata.bqn` should continue to own label resolution and metadata formatting.

## 10. Non-authorization

This audit snapshot does not by itself authorize:

- BQN, shell, test, or check changes;
- changing metadata column names, values, or meaning;
- adding section-specific JSON output;
- adding, removing, renaming, or reordering sections;
- changing human labels or report output;
- changing UI behavior;
- starting Outlook / `actual_snapshot` or another projection-alignment slice;
- broad report, context, plugin, or registry redesign.

Implementation authority is limited to the finite slice explicitly selected in `TODO.md` and specified by `docs/archive/active-plans/REPORT_SECTION_DESCRIPTOR_CENTRALIZATION_PLAN-2026-07-16.md`.
