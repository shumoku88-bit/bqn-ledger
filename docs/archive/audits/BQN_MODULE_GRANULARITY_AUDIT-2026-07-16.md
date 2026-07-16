# BQN Module Granularity Audit

Status: audit snapshot
Owner: architecture
Canonical: no; current runtime ownership remains in `src_next/`, `src_edit/`, and their current routing docs
Exit: retain as point-in-time evidence; do not implement directly; select at most one finite follow-up through current TODO/plan routing

## 1. Baseline

- Audit date: 2026-07-16
- Branch / target: current `origin/main`
- Baseline commit: `310f318 docs: complete report section descriptor centralization`
- Report section descriptor centralization: complete and excluded from re-selection
- Data boundary: repository source, current docs, checks, and public fixture references only
- Private production data: not read or used

This is a read-only point-in-time observation of the current BQN module boundaries. It is evidence, not a current contract and not implementation authority.

## 2. Question and decision rule

The audit asks whether the current BQN tree is split into modules more finely than its semantic ownership requires.

File count and line count are not sufficient reasons to merge. A small module is retained when it owns at least one of the following:

- a stable semantic vocabulary or taxonomy;
- a pure calculation or validation seam with independent tests;
- an I/O, clock, CLI, or mutation boundary;
- a public output or editor protocol contract;
- a lifecycle stage reused by a different subsystem;
- a safety boundary whose co-location would broaden write authority or import-time effects.

A consolidation candidate requires stronger evidence:

- duplicated semantic ownership or identical implementation;
- consumers that always require the same combined responsibility;
- no useful independent contract, test, lifecycle, or side-effect boundary;
- a finite migration with an explicit equivalence surface.

## 3. Scope and inventory

Current code search at the baseline returned:

- 55 BQN files under `src_next/`;
- 23 BQN files under `src_edit/`;
- 1 supporting BQN file under `tools/` (`tools/bqn-dump.bqn`).

Tests, fixtures, archived implementation history, and non-BQN wrappers were inspected only where needed to understand current ownership. Test modules are not counted as production granularity.

### 3.1 `src_next/` families

| Family | Current modules | Audit disposition |
|---|---|---|
| Source/config/common | `loader.bqn`, `util.bqn`, `config.bqn`, `date.bqn`, `json.bqn`, `unavailable.bqn`, `report_labels.bqn` | Keep boundaries except confirmed `loader` / `util` duplicate ownership; finite follow-up candidate below |
| Context/accounting pipeline | `context.bqn`, `account_key.bqn`, `exact_decimal.bqn`, `currency_registry.bqn`, `currency_setup.bqn`, `source_currency_admission.bqn`, `currency_arithmetic.bqn`, `currency_selection.bqn`, `projection.bqn`, `cube.bqn`, `tbds.bqn`, `cycle.bqn` | Keep; stages own materially different evidence, admission, arithmetic, projection, array, and period contracts |
| Report entry/metadata | `report.bqn`, `summary.bqn`, `main.bqn`, `report_sections.bqn`, `report_builder_order.bqn`, `report_section_metadata.bqn`, `format.bqn` | Keep current post-centralization ownership; `main.bqn` lifecycle is a routing concern, not a merge candidate |
| Report/view owners | `snapshot.bqn`, `issues.bqn`, `ytd_summary.bqn`, `balances.bqn`, `cycle_summary.bqn`, `trial_balance.bqn`, `envelope_computation.bqn`, `planned_payments.bqn`, `recent_journal.bqn`, `readiness_check.bqn`, `outlook.bqn`, `daily_trend.bqn`, `daily_flow.bqn`, `actual_comparison.bqn`, `expense_breakdown.bqn` | Keep section/view ownership; broad folding would recreate the former report monolith |
| Plan/household/temporal seams | `plan_rows.bqn`, `plan_status.bqn`, `plan_journal_overlap.bqn`, `household_metadata.bqn`, `household_policy.bqn`, `actual_snapshot.bqn`, `daily_capacity.bqn` | Keep; targeted overlaps are classified below, but no direct merge is recommended |
| Read-only event/export seams | `event_lens.bqn`, `event_lens_format.bqn` | Keep structured model and deterministic serializer separate |
| Travel lifecycle validators | `friend_travel_source_event.bqn`, `friend_travel_jpy_finalization.bqn`, `travel_exchange_event.bqn` | Keep; distinct source-event, finalization, and exchange contracts are reused by the editor path |
| Consultation calculator | `calc/envelope_calc.bqn`, `calc/main.bqn` | Keep pure/testable calculation surface separate from CLI orchestration; mixed formatting ownership is noted but not selected |

### 3.2 `src_edit/`

The 23 current files consist of shared render/validation/identity/integrity modules and command-specific modules for account, journal, plan, issue, budget-sync, and travel operations.

The command modules are not treated as over-fragmentation. `src_edit/` is the daily write path, and each command boundary limits accepted inputs, source reads, rendered edit protocol, and safe-write orchestration. Reducing file count by combining unrelated commands would enlarge write authority and make failure surfaces harder to isolate.

The small `journal_source_check.bqn` / `journal_source_integrity.bqn` pair is a positive boundary example: the former owns CLI argument, source loading, output, and exit behavior; the latter remains importable pure validation.

### 3.3 Supporting tool

`tools/bqn-dump.bqn` owns a standalone diagnostic/introspection contract and is used by its shell wrapper and tests. It has no repository source loading or report behavior and is not a consolidation candidate.

## 4. Confirmed duplicate ownership

### 4.1 `src_next/loader.bqn` and `src_next/util.bqn`

Both modules independently implement identical `Split` and `SplitKeepEmpty` functions.

They also overlap in line loading:

- `loader.bqn` owns `ResolvePath`, `ReadRaw`, `ReadLines`, and `ReadLinesOptional` using `•FChars` and `•file.Exists`;
- `util.bqn` retains migrated `LoadChars` / `LoadLines` using `•SH ⟨"cat", path⟩`;
- `config.bqn` still uses `util.LoadLines`;
- other consumers use `util` primarily for pure splitting or numeric text conversion.

The two implementations currently agree on CR removal, comment/empty-line filtering, and empty-field-preserving split behavior. That agreement is duplicated implementation, not a useful independent contract.

This creates four maintenance risks:

1. empty-field behavior can drift between canonical TSV loading and config/editor helpers;
2. path/error semantics differ between `•FChars`/`•file.Exists` and shell `cat`;
3. pure helper consumers import a module that also exposes legacy shell I/O;
4. future fixes must identify two text-splitting owners.

This is the only current-main finding that meets the audit threshold for a finite ownership-normalization candidate.

## 5. Small modules retained intentionally

### 5.1 `unavailable.bqn`

Although very small, it owns the canonical `unavailable/<reason>` vocabulary and detection helper used across view modules. Folding it into one consumer would duplicate semantic status knowledge elsewhere.

### 5.2 `plan_status.bqn`

It owns one pure, clock-free temporal classification:

```text
completed, plan_date, as_of -> future / due / overdue / completed
```

`plan_rows.bqn` is currently its only runtime consumer, but the seam has an independent test and was deliberately retained when the former `plan_evidence.bqn` boundary was folded into `plan_rows.bqn`. Consumer count alone is not sufficient reason to remove it.

### 5.3 `report_labels.bqn`

It is a small fail-closed import-time loader for the report presentation label registry. The completed descriptor centralization explicitly retains it as the configured-label owner. It is not reopened by this audit.

### 5.4 `exact_decimal.bqn`, `currency_registry.bqn`, and `currency_arithmetic.bqn`

These small currency modules correspond to different proof stages:

- lexical exact-decimal parsing;
- pure repository registry validation/policy lookup;
- snapshot arithmetic normalization over prepared row evidence.

Merging them would mix source grammar, registry policy, and arithmetic admission and would weaken current stage-specific tests and diagnostics.

### 5.5 `event_lens_format.bqn`

It owns deterministic column order, escaping, and TSV serialization, while `event_lens.bqn` owns structured event rows. This is a model/serialization boundary, not excess fragmentation.

### 5.6 `src_edit/txn_id.bqn`

It is a thin specialization over shared slug helpers, but transaction companion identity is distinct from plan identity. Keeping the semantic owner separate is lower risk than placing both identity lifecycles in `plan_id.bqn` merely to remove one file.

## 6. Examined pairs not recommended for merging

### 6.1 `household_metadata.bqn` and `household_policy.bqn`

Confirmed overlap:

- both inspect account roles and household metadata;
- both locally define small helpers such as `Sum0`, `StartsWith`, and `NonEmpty`;
- `main.bqn` and `summary.bqn` call them next to each other.

The overlap does not justify a direct merge:

- `household_metadata.Build` consumes only resolved account metadata and intentionally requires neither config nor posting rows;
- `household_policy.BuildSummary` loads policy config and consumes valid projection rows to calculate policy-group totals;
- their availability rules and output contracts differ;
- co-location would create a larger module combining readiness diagnostics, policy resolution, numeric aggregation, and two format surfaces.

Recommendation: keep both modules. Do not add a new generic household helper module solely to remove three trivial local helpers. Revisit only if a selected household-policy slice establishes a shared structured classification carrier used by both.

### 6.2 `actual_snapshot.bqn` and `snapshot.bqn`

`actual_snapshot.bqn` remains a direct journal/as-of observation seam used by Outlook-related paths and tests. `snapshot.bqn` now builds its report view from TBDS. Their overlap is part of temporal/numeric-owner alignment, not module granularity.

The completed report descriptor work explicitly did not select Outlook / `actual_snapshot`. This audit does not route around that decision.

### 6.3 `plan_status.bqn` and `plan_rows.bqn`

Folding the 24-line classifier into `plan_rows.bqn` would remove a file but erase a useful pure temporal oracle. The current arrangement is intentional and testable.

### 6.4 `journal_source_check.bqn` and `journal_source_integrity.bqn`

The CLI/core split isolates side effects and exit behavior from reusable validation. Keep.

### 6.5 `event_lens.bqn` and `event_lens_format.bqn`

The structured row builder and deterministic export contract have different consumers and failure surfaces. Keep.

### 6.6 Currency modules

`currency_setup.bqn` is relatively broad because it owns repository-registry I/O, default/explicit selection policy, and source currency metadata auditing. This is a responsibility-density observation, not an over-fragmentation finding. Merging neighboring currency modules into it would make the boundary worse. Splitting or renaming it is not selected by this audit.

### 6.7 Calculator modules

`calc/envelope_calc.bqn` describes itself as pure calculation primitives but also owns human and machine formatting, including output functions. This is mixed responsibility inside a module, not excess module count. The calculator track is not current enough to justify a speculative formatter reorganization.

## 7. Report and context boundaries not reopened

The completed report section descriptor centralization established final ownership across:

- `report_sections.bqn`;
- `report_builder_order.bqn`;
- `report.bqn`;
- `report_section_metadata.bqn`;
- `report_labels.bqn`.

No merge, serializer unification, metadata meaning change, or plugin redesign is recommended here.

`context.bqn` is broad orchestration, but splitting it was explicitly not selected by the completion record. A broad-file audit is not authority to begin that work.

## 8. Risk classification

| Area | Assessment | Reason |
|---|---|---|
| Broad BQN file count | Low | Most files map to stable semantic, report, pure-stage, CLI, or editor safety boundaries |
| `loader` / `util` duplicate text ownership | Medium maintenance risk | Identical implementations and parallel I/O paths can drift without adding an independent contract |
| Household module overlap | Low | Duplication is mostly trivial helpers; major responsibilities and inputs differ |
| Small one-consumer pure seams | Low | Independent tests/vocabularies provide useful oracles and constrain future migrations |
| `src_edit` command fragmentation | Low / protective | Separate command protocols reduce write-path authority and blast radius |
| `currency_setup.bqn` responsibility density | Medium observation, no selected action | Broad owner, but merging neighbors is harmful and splitting is a separate design problem |
| Calculator mixed calculation/formatting | Low current impact | Isolated consultation tool; no evidence that reorganization currently pays for its migration cost |

## 9. Options for the confirmed candidate

### A. Fold `util.bqn` into `loader.bqn` — not recommended

This removes one file but makes date, registry, travel validator, and editor helper consumers depend on an I/O-named module for pure text operations. It optimizes count rather than ownership.

### B. Fold loader I/O into `util.bqn` — not recommended

This turns the generic helper module into the file/path/error owner and preserves the least explicit name. It also risks retaining shell `cat` as a parallel canonical loader.

### C. Preserve two boundaries and normalize ownership — recommended future candidate

Target ownership:

```text
util.bqn
  pure Split / SplitKeepEmpty / ToNum only

loader.bqn
  path resolution and all repository file reads
  delegates or re-exports the pure split helpers

config.bqn
  uses loader-owned line I/O
  uses pure helper operations only where needed
```

The candidate should:

- eliminate one of the two `Split` / `SplitKeepEmpty` implementations;
- remove `LoadChars` / `LoadLines` shell I/O from `util.bqn` after all consumers migrate;
- preserve `loader.SplitTsvKeepEmpty` and existing public imports during the finite slice;
- preserve current comment, CR, empty-line, empty-column, missing-file, and read-failure behavior;
- add no new generic framework or dynamic loader;
- change no report, config value, source schema, editor protocol, or private data.

This candidate is ownership normalization, not a broad module merge campaign.

## 10. Recommendation

Do not start a repository-wide BQN consolidation.

The current module tree is numerous but not generally too fine. The majority of small files are contract-bearing seams. The one evidence-backed next finite candidate is:

```text
loader / util text-and-I/O ownership normalization
```

It should be separately characterized and selected before implementation. A preimplementation plan should enumerate exact current consumers and output/error equivalence checks, especially `config.bqn`, date parsing, currency registry/setup, travel validators, editor commands, broken-empty-column fixtures, and invalid-path behavior.

## 11. Non-authorization

This audit snapshot does not by itself authorize:

- BQN, shell, test, check, config, fixture, or source-data changes;
- a broad module merge or file-count target;
- merging `household_metadata.bqn` and `household_policy.bqn`;
- folding `plan_status.bqn` into `plan_rows.bqn`;
- combining `src_edit` command modules;
- changing report section ownership after descriptor centralization;
- splitting `context.bqn` or `currency_setup.bqn`;
- changing calculator output or structure;
- starting Outlook / `actual_snapshot`, Daily Capacity, or report-wide `as_of` work;
- accessing private production data.

Any implementation authority must come from a separately selected finite plan in current routing docs.

## 12. Verification boundary

This remote read-only audit inspected current repository files and call-site/search evidence through the GitHub repository interface. It did not execute BQN tests, shell checks, `tools/check.sh`, repository-index commands, or private production paths.

A future implementation slice must run the normal repository validation and focused equivalence checks before merge.
