# Report route boundary status

Status: boundary implementation complete; post-boundary reassessment open

Date: 2026-07-30

Repository baseline: `bd88f19493085aa135b6a9331e22ca8bfdc57e59`

Related records:

- `docs/BQN_LANGUAGE_RESPONSIBILITY_BOUNDARY_AUDIT.md`
- `docs/REPORT_ROUTE_RESPONSIBILITY_DUPLICATION_AUDIT.md`
- `docs/ARCHITECTURE.md`
- `docs/BQN_REFACTORING_REVIEW_GUIDE.md`
- Issue #407

## 1. Decision

The repository separates BQN-native accounting transformations from ordinary operational orchestration without treating procedural BQN as automatically defective.

The retained shape is:

```text
thin operational Shell
→ pure admitted route description
→ strict BQN source/Facts admission
→ named BQN accounting and section composition
→ thin rendering/publication boundary
```

A second implementation language remains possible only after a boundary has a stable input, output, diagnostic, and failure contract. The completed route work creates such a contract but does not by itself prove that replacement would improve the system.

## 2. Completed boundary slices

### Slice 1: pure individual route admission

PR #456 merged as `d988fcb9652d5bff80309ac94b1dd50db575be0d`.

`src/application/report_route.bqn` owns pre-I/O individual-route admission and returns:

- admitted key, surface, and coordinate texts;
- source argument indices;
- broad source kinds: `journal` or `tsv`;
- semantic source roles;
- fail-closed route diagnostics.

Key and surface support remain catalog-backed through `request.Validate`. `all` remains a manifest-level selection rather than one individual route.

### Slice 2: machine-readable operational plan

PR #457 merged as `7422fedeb4a6bde52ae93416734bbb0c5e0054d7`.

`src/application/report_route_plan.bqn` converts route admission into a pure `exit_code` plus exact `ROUTE` and `SOURCE` TSV lines. `report_route_plan_cli.bqn` only prints those lines and exits.

Raw source names are not emitted. Shell retains original argv and selects source names by admitted `argument_index`, so path and filesystem policy do not move into BQN.

### Catalog parity gate

PR #458 merged as `e162020c34691da0c4e60a75a557c288d0ae1f22`.

`tests/test_application_report_route.bqn` compares the exact catalog key vector with one ordered successful route-contract case per retained key before running those cases.

The gate rejects:

- catalog growth without a route case;
- stale removed-key cases;
- duplicate or reordered cases;
- catalog and route-function dispatch order drift.

Optional alternate shapes remain additional cases outside the one-per-catalog parity vector.

### Slice 3: Shell consumes the plan

PR #459 merged as `b8f3d74dd63b3de30b76bfe60da2759518a7ff9f`.

`tools/report` no longer owns the key-specific table of coordinate counts, Journal/TSV argument positions, optional Plan positions, or explicit source enumeration. It consumes the admitted `ROUTE` and `SOURCE` lines and selects values from original argv.

Shell still owns:

- request-manifest reading and selection;
- caller working-directory and absolute base-path handling;
- safe basename checks;
- `.journal` and `.tsv` suffix checks;
- currency-registry and source operational readiness;
- source existence and readability;
- final process execution and exit behavior.

Full usage output, exit codes, route-aware basename wording, report bytes, and the established `recent` failure order remain protected by focused checks.

### Slice 4: destination composition consumes admission

PR #460 merged as `066474146cc91f13e34694297cbdd53668b3f9f7`.

`report_destination_cli.bqn` now consumes `report_route.Admit` after the existing global argv, request, `all`, and registry stages.

The destination CLI no longer owns:

- ten duplicate individual `usage_<route>` arity checks;
- a duplicate recent LIMIT-text predicate.

The named route branches remain because they own real semantic work:

- strict Account, Journal, Plan, Budget, Cycle, Daily Scope, and Issue admission;
- income-anchor Plan requirements;
- cycle-mode consistency;
- accounting/section composition;
- rendering and final publication.

## 3. Adjacent correctness repairs

Boundary characterization exposed two independent currency-registry defects. They were repaired separately rather than folded into ownership refactoring.

### Registry error publication

PR #461 merged as `50724297ed1a0aea6651ea6722091494c016a36a`.

The registry builder returns `state`, `code`, `message`, and `registry`, not a diagnostics vector. The report destination now converts that admitted error shape into one normal report diagnostic instead of leaking a missing-field error.

### Short registry rows

PR #462 merged as `bd88f19493085aa135b6a9331e22ca8bfdc57e59`.

One- and two-field registry rows previously evaluated absent field picks before row-shape rejection. `ParseLine` now safely pads and destructures three values while preserving the original `field_count` as the exact admission gate.

Non-three-field rows return the existing `currency_registry_row_invalid` result; valid three-field Policy semantics are unchanged.

## 4. Current production path

The public individual-report path is now:

```text
CLI argv or selected request-manifest row
→ catalog-backed request admission
→ pure route admission
→ machine-readable operational plan
→ Shell basename/suffix/readability checks
→ destination registry and route admission
→ strict source/Facts admission
→ named semantic composition
→ renderer
```

The positional route schema has one pure BQN owner consumed by both operational Shell and destination composition. The previous Shell and destination arity/source-position tables are no longer parallel owners.

`all` remains:

```text
catalog-selected keys
→ complete manifest admission
→ one individual route per row
→ buffered publication only after every row succeeds
```

## 5. Current quality assessment

### Strong properties

- Actual remains Native Journal only.
- Canonical Transaction and Posting Facts retain identity and provenance.
- Exact-decimal arithmetic remains exact.
- Invalid admitted evidence fails closed without partial report publication.
- Report sections do not read files or the clock.
- Accounting capabilities do not import sections or application composition.
- The static catalog owns retained key order and surface support.
- Route shape and operational source coordinates have one pure owner.
- Shell retains filesystem and process policy rather than leaking it into accounting code.
- Destination route branches retain named semantic meaning instead of becoming an opaque universal context.
- Focused BQN tests, report integration checks, ownership checks, editor checks, Shell safety checks, and the module inventory run through `tools/check.sh` and `tools/coverage`.

### Remaining limitations

- `report_destination_cli.bqn` remains a long effectful orchestration module, although its branches now contain semantic source/composition responsibilities rather than duplicate raw admission.
- `tools/report` retains route/role-specific public basename wording for compatibility; this is message policy, not positional route ownership.
- Adding a report still requires coordinated semantic work in catalog, route owner, composition, section, renderer, manifests, fixtures, and checks. The parity gate catches route-contract drift but does not make report addition automatic.
- `report_route.bqn` uses a function array aligned with catalog order; the catalog parity test is the executable guard for that alignment.
- `tools/coverage` is a module/test inventory, not measured line or branch coverage.
- Historical audits retain their original baselines and should be read as evidence records, not current runtime snapshots.

## 6. Reassessment result

The report boundary no longer provides a strong reason to move the destination adapter to another language immediately.

After thinning, the remaining BQN destination work is mostly:

- strict domain admission into BQN Facts;
- cycle and Plan semantics;
- calls to BQN accounting capabilities;
- section and renderer publication.

Moving this now would introduce a serialization and diagnostic protocol around data already native to BQN without clearly reducing the difficult semantic work.

Current decision:

> Keep the thinned destination boundary in BQN while it remains close to strict Facts and named accounting composition. Keep Shell for filesystem and process policy. Reassess only when a concrete operational requirement, safety property, or alternate client makes a second-language boundary materially useful.

This is not a permanent prohibition. It is the evidence-based result after completing the boundary experiment.

## 7. Next-step rule

There is no automatic continuation from the report-route boundary stream.

Before another change:

1. verify current main and open PRs;
2. select one observed retained owner or one separately characterized correctness defect;
3. compare at least two finite candidates when choosing a BQN-native refactor;
4. preserve diagnostics, provenance, exact arithmetic, ordering, stdout, exit behavior, and report bytes unless the slice explicitly characterizes a correctness change;
5. keep one responsibility and one rollback point;
6. run full `tools/check.sh` and coverage;
7. review the final changed-file set before Ready and squash merge;
8. record the result in Issue #407.

Do not continue changing the report boundary merely to make it smaller. Future work should be selected from current evidence rather than from a predetermined cleanup queue.
