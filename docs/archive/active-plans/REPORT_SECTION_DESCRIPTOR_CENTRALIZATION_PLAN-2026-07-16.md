# Report Section Descriptor Centralization Plan

Status: active plan
Owner: report
Canonical: no; evidence: docs/archive/audits/REPORT_SECTION_DESCRIPTOR_OWNERSHIP_AUDIT-2026-07-16.md
Exit: move to docs/archive/completed-plans/ after implementation, full verification, completion review, TODO cleanup, and active-plans inventory update

## 1. Decision

Select Option B as one finite maintenance slice:

> Create one pure static descriptor module and make report runtime metadata consumers derive static section identity from it, while preserving all current public behavior.

The expected module is `src_next/report_sections.bqn`. This plan authorizes only the bounded descriptor-centralization work selected in `TODO.md`. It does not authorize unrelated report development.

## 2. Problem statement

The problem is not the number of files by itself. The same report section identity is manually maintained across runtime builders, metadata rows, current docs, and checks. Current key/order parity is checked, but static ownership remains duplicated, and confirmed docs/check drift already exists.

The selected boundary separates:

- **static descriptor ownership**, which can be pure shared data; and
- **runtime builder ownership**, which remains executable report orchestration.

The goal is not to put every report concern into one file. Calculation, ViewModel construction, formatting, JSON dispatch, CLI behavior, and cache behavior remain with their current runtime owners.

## 3. Selected scope

The implementation slice includes only:

- add pure module `src_next/report_sections.bqn`;
- centralize canonical section key;
- centralize canonical section order;
- centralize metadata label spec;
- centralize category;
- centralize implementation owner path;
- centralize the current human output metadata value;
- centralize the current structured output metadata value without reinterpreting it;
- add descriptor uniqueness validation or a focused unit test;
- connect `report.bqn` key/order use to the descriptor;
- connect `report_section_metadata.bqn` static row projection to the descriptor;
- enforce descriptor-to-human-builder one-to-one correspondence with the smallest practical check;
- use `src_next/json.bqn` for metadata JSON serialization only if the public output is completely identical, including shape, field names, values, order, escaping, whitespace, and line layout;
- add missing `daily-flow` to the current section inventory in `docs/REPORT_CONTRACTS.md`;
- add `issues` and `daily-flow` to the explicit required-key coverage in `checks/check-ui-smoke.sh`;
- synchronize current report docs, code map, and focused checks;
- update the repo-index baseline after adding the BQN module and unit test.

This scope preserves all current semantics and public output. The confirmed drift repairs update inventory/check coverage to match existing runtime; they do not alter runtime behavior.

## 4. Explicit non-goals

This slice does not include:

- adding, removing, or reordering report sections;
- changing a section key;
- changing label wording;
- changing the metadata TSV header;
- changing metadata column count;
- changing metadata JSON shape;
- changing the meaning of `structured_output`;
- adding a section-specific JSON ViewModel;
- Outlook / `actual_snapshot` work;
- report-wide `as_of`;
- generic plugin architecture;
- dynamic module loading;
- storing builder functions in descriptors;
- splitting `context.bqn`;
- redesigning the UI;
- bulk correction of archive documents;
- private production data access;
- selecting the next Report Projection Alignment slice.

## 5. Descriptor contract

### Conceptual row shape

Each row represents exactly:

```text
key
label_spec
category
owner_path
human_output_value
structured_output_value
```

The concrete BQN shape must remain the smallest representation that supports these fields. Do not introduce a generic record framework, plugin protocol, dynamic dispatch framework, or config schema.

### Ordering and identity

- Descriptor row order is canonical section order.
- Keys are unique.
- The current row count is 15.
- `debug` is an ordinary descriptor row even though its implementation owner is `src_next/report.bqn`.
- `owner_path` is a repository-relative path and must exist.

### Purity constraints

`report_sections.bqn` must:

- contain no builder function;
- contain no formatter function;
- contain no context or source base path;
- read no config;
- read no source TSV;
- produce no output;
- read no `•args`;
- read no wall clock;
- have no import-time side effect;
- import no report implementation module;
- execute no CLI.

A symbolic `label_spec` may identify how `report_section_metadata.bqn` resolves the current label, but the pure descriptor must not load `config/report_labels.tsv` itself. Special existing forms such as composed Trial Balance text and the current Daily Flow literal must be represented minimally without changing output.

### Value preservation

- Current metadata values must be copied exactly into the descriptor.
- The descriptor must not infer section-specific JSON support from `structured_output`.
- The current ambiguity must not be silently resolved in the descriptor.
- Any future value vocabulary or semantic change requires a separate contract decision.

## 6. Runtime ownership boundary

### `report_sections.bqn` owns

- static section identity;
- static section order;
- static metadata fields.

### `report.bqn` owns

- section implementation module imports;
- human builder functions;
- section execution;
- human rendering orchestration;
- section-specific JSON ViewModel dispatch;
- first-line marker generation;
- CLI behavior;
- cache behavior.

The human builder mapping remains executable code. It must correspond one-to-one with descriptor keys, but builder functions must not move into the descriptor.

### `report_section_metadata.bqn` owns

- metadata projection from descriptors;
- label resolution;
- TSV formatting;
- JSON formatting;
- metadata CLI behavior.

### `report_labels.bqn` owns

- configured label resolution;
- duplicate/missing label validation and current fail-closed behavior.

### `json.bqn` owns

- shared JSON serialization semantics.

Metadata may migrate to the shared serializer only when byte-for-byte public equivalence is demonstrated. If common serialization changes whitespace, line layout, escaping, shape, order, or values, leave serializer migration out of this slice.

## 7. Compatibility invariants

The implementation must preserve all of the following exactly:

- `tools/report --list-sections` keys;
- `tools/report --list-sections` order;
- `tools/report --section <key>` routing;
- full report section order;
- section cache filenames;
- section cache contents;
- human report body text;
- every first-line marker;
- metadata TSV header;
- metadata TSV six-column shape;
- metadata row order;
- all metadata field values;
- metadata JSON top-level array and row-object shape;
- metadata JSON field names;
- metadata JSON field order and values;
- human label wording;
- owner path strings;
- human output values;
- structured output values;
- metadata command source-TSV independence;
- metadata command success when `LEDGER_DATA_DIR` is missing or invalid;
- the current count of four section-specific JSON ViewModels;
- `report_labels.bqn` fail-closed behavior.

The slice must not claim output equivalence based only on successful parsing. Text and cache artifacts must also be compared.

## 8. Implementation phases

### Phase 0: docs-only selection

- Save the ownership audit snapshot.
- Create this active plan.
- Select this finite slice in `TODO.md`.
- Register this plan in the active-plans inventory.
- Do not change BQN, shell, tests, checks, fixtures, config, or repo-index baseline in this phase.

### Phase 1: descriptor introduction

- Add pure `src_next/report_sections.bqn`.
- Add `tests/test_src_next_report_sections.bqn`.
- Fix row count, six-field conceptual shape, key uniqueness, and exact order.
- Confirm every owner path exists.
- Consumers may remain temporarily unchanged while the descriptor test is established.
- If Phase 1 is committed separately, do not leave a long-lived state that presents the new descriptor as canonical while both consumers remain independent owners. Prefer one implementation commit for Phases 1–3 unless an intermediate commit is necessary and explicitly non-canonical.

### Phase 2: consumer migration

Connect:

- `src_next/report.bqn`; and
- `src_next/report_section_metadata.bqn`

to the descriptor.

Requirements:

- static key/order comes from descriptors;
- metadata static fields come from descriptors;
- human builders remain in `report.bqn`;
- a focused check proves descriptor keys and human builder keys are a bijection;
- JSON builder dispatch remains runtime-owned and unchanged;
- no circular import or implementation import from the descriptor is introduced.

### Phase 3: observed drift repair

- Add `daily-flow` to `docs/REPORT_CONTRACTS.md` at its current runtime position.
- Add `issues` and `daily-flow` to `checks/check-ui-smoke.sh::required_keys`.
- Update `docs/AI_CODEMAP.md` and the section checklist only as needed to describe the new static owner and registration rule.
- Unify metadata JSON serialization through `src_next/json.bqn` only if all captured public metadata JSON output remains byte-for-byte identical.
- Do not change metadata semantics or values.

### Phase 4: verification

- Compare all pre-implementation and post-implementation public artifacts.
- Run focused descriptor, metadata, UI, and report checks.
- Run repo-index diff after updating its baseline for the new BQN/test inventory.
- Run the full repository check.
- Inspect changed filenames, working-tree/staged diff, and intended base-to-HEAD diff for scope leakage before push/PR.

### Phase 5: completion

After implementation, full verification, and completion review:

- create a completion record when useful;
- move this plan to `docs/archive/completed-plans/`;
- update `docs/archive/active-plans/README.md` to remove or replace the active entry;
- remove the selected slice from Active work or route its completion out of `TODO.md` without leaving it active;
- remove any temporary `NEXT_SESSION.md` or equivalent route introduced during implementation;
- record that `structured_output` semantics remain a separate unselected decision;
- return to normal report routing;
- do not automatically select Outlook / `actual_snapshot`, projection alignment, or another report task.

## 9. Stop conditions

Stop implementation and re-evaluate this plan if any of the following becomes necessary:

- a metadata consumer must read source TSV;
- the descriptor must import a report builder or implementation module;
- a circular import is required;
- current metadata output values must change to complete the migration;
- section order changes;
- human report output changes;
- first-line markers change;
- deciding the meaning of `structured_output` becomes a prerequisite;
- a generic registry/plugin system is required;
- dynamic loading is required;
- an unrelated report rewrite is required;
- private production data is required.

A stop condition is not permission to widen scope. Report the evidence and select a new finite decision slice if needed.

## 10. Required focused tests

Implementation verification must cover:

- descriptor row count equals 15;
- descriptor keys are unique;
- descriptor key/order exactly matches the current 15-key sequence;
- every descriptor row has the selected shape;
- every owner path exists;
- descriptor keys and human builder keys correspond one-to-one;
- `--list-sections` exact output;
- full report section order;
- metadata TSV exact header;
- metadata TSV exact row shape, order, and values;
- metadata JSON parseability;
- metadata JSON shape and values;
- metadata command success with no source base argument;
- metadata command success with invalid `LEDGER_DATA_DIR`;
- every first-line marker is non-empty and unchanged;
- section cache filenames and contents are unchanged;
- structured UI boundary;
- UI smoke behavior;
- src_next report behavior;
- full repository check.

Expected commands, using current canonical fixture paths where required:

```sh
bqn tests/test_src_next_report_sections.bqn
bash checks/check-report-section-metadata.sh fixtures/src-next-golden
bash checks/check-structured-ui-boundary.sh
bash checks/check-ui-smoke.sh fixtures/src-next-golden
bash checks/check-src-next-report.sh fixtures/src-next-golden
tools/report fixtures/src-next-golden --list-sections --no-color
tools/report-section-metadata --format tsv
tools/report-section-metadata --format json
tools/repo-index --diff
rtk bash ./tools/check.sh
```

If command names change before implementation, current canonical commands take precedence and the plan must be updated narrowly.

## 11. Output equivalence evidence

Before implementation, capture outputs from repository fixture `fixtures/src-next-golden` into a temporary directory outside tracked files. Capture at least:

```sh
tools/report fixtures/src-next-golden --list-sections --no-color
tools/report-section-metadata --format tsv
tools/report-section-metadata --format json
tools/report fixtures/src-next-golden --no-color
tools/report fixtures/src-next-golden --section snapshot --no-color
tools/report fixtures/src-next-golden --section daily-flow --no-color
tools/report fixtures/src-next-golden --section debug --no-color
tools/report fixtures/src-next-golden --write-section-cache <temporary-directory> --no-color
```

After implementation:

- rerun the same commands with the same fixture;
- compare list, TSV, JSON, full report, representative sections, cache file inventory, and cache contents using exact diffs;
- require no differences except intentionally updated docs/check diagnostics outside public output;
- retain only privacy-safe structural results, not temporary report bodies, in public review notes.

Do not use private production data for equivalence evidence.

## 12. Rollback

The implementation must be revertible to the pre-descriptor implementation at one commit boundary. Prefer one implementation commit:

```text
refactor: centralize report section descriptors
```

The slice includes no:

- source TSV change;
- config schema change;
- user data migration;
- cache migration;
- metadata schema migration.

Rollback therefore consists of reverting the implementation commit and restoring the previous runtime/metadata static lists.

## 13. Separate future decision

The meaning of `structured_output` remains an unselected future contract decision after this refactor.

Candidate meanings are:

- availability of a structured representation of metadata rows; or
- availability of a section-specific structured ViewModel.

This plan does not choose between them. It does not change the column name, values, public shape, or consumer contract. Any future decision must separately inventory consumers, define vocabulary, preserve or intentionally version compatibility, and be selected in `TODO.md`.

## 14. Commit boundaries

This docs-only selection slice uses one commit:

```text
docs: plan report section descriptor centralization
```

The subsequent implementation candidate uses:

```text
refactor: centralize report section descriptors
```

A completion/retirement record may use a separate commit if moving this plan, updating inventory, and cleaning TODO would otherwise obscure the implementation diff.
