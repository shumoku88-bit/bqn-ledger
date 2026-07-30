# Report route boundary status

Status: active continuation record

Date: 2026-07-30

Repository baseline: `cd332b5b9af07b1f18d6b076852e82d15d5caa80`

Related records:

- `docs/BQN_LANGUAGE_RESPONSIBILITY_BOUNDARY_AUDIT.md`
- `docs/REPORT_ROUTE_RESPONSIBILITY_DUPLICATION_AUDIT.md`
- `docs/ARCHITECTURE.md`
- `docs/BQN_REFACTORING_REVIEW_GUIDE.md`

## 1. Current decision

The repository should continue separating BQN-native accounting transformations from ordinary operational orchestration.

The target is not to remove procedural BQN merely because another language could express it. The target is:

```text
thin operational Shell or adapter
→ strict admitted Facts
→ visibly BQN-native accounting and projection kernels
→ thin publication boundary
```

A second implementation language remains a later option only after an effect boundary has a stable input, output, diagnostic, and failure contract.

## 2. Completed boundary slices

### Slice 1: pure report-route admission

Merged by PR #456 as `d988fcb9652d5bff80309ac94b1dd50db575be0d`.

`src/application/report_route.bqn` now admits one individual report route before source I/O or composition and returns:

- admitted key, surface, and coordinate texts;
- source argument indices;
- broad source kinds: `journal` or `tsv`;
- semantic source roles;
- fail-closed route diagnostics.

Key and surface admission still come from the static report catalog through `request.Validate`. `all` remains a manifest-level selection and is rejected by the individual-route owner.

### Slice 2: machine-readable route plan

Merged by PR #457 as `7422fedeb4a6bde52ae93416734bbb0c5e0054d7`.

`src/application/report_route_plan.bqn` converts route admission into a pure `exit_code` plus exact TSV lines. `src/application/report_route_plan_cli.bqn` is an effect-only printer and process-exit wrapper.

The output deliberately omits raw source names. Shell retains the original argv and can select source values by `argument_index`, so path, basename, suffix, readability, and process policy remain outside BQN.

### Later catalog growth

`daily-flow` was retained as the tenth report route in `300df5ba8bf226ea15a481cad867deb67a6813b3`.

The static catalog, pure route owner, machine-readable plan tests, Shell route table, destination composition, manifests, cache, metadata, and report checks were all extended. This was the first real catalog-growth test after the new route owner existed.

## 3. Current production path

The public path still contains both the old positional route tables and the new pure owner:

```text
CLI argv or request-manifest row
→ tools/report
→ request.Validate
→ Shell key-specific case and operational source checks
→ report_destination_cli.bqn key-specific branches
→ strict source admission and semantic composition
→ renderer
```

In parallel, the new unused production candidate is:

```text
key + surface + coordinate texts
→ report_route.Admit
→ report_route_plan.Run
→ ROUTE / SOURCE lines
```

Therefore the repository is currently in a safe transitional state, not the final ownership state. No old check has been removed before its replacement consumer exists.

## 4. Current quality assessment

### Strong properties

- Actual remains Native Journal only.
- Canonical Transaction and Posting Facts retain identity and provenance.
- Exact-decimal arithmetic remains exact.
- Invalid evidence fails closed without partial report publication.
- Report sections do not read files or the clock.
- Accounting capabilities do not import report sections or application composition.
- The report catalog owns retained key order and surface support.
- `all` obtains key order from the catalog and buffers publication until every row succeeds.
- Focused BQN tests, report integration checks, repository ownership checks, editor checks, Shell safety checks, and the module inventory run through `tools/check.sh` and `tools/coverage`.

### Known limitations

- `tools/report` still duplicates key-specific coordinate counts and source positions.
- `report_destination_cli.bqn` repeats raw coordinate admission before semantic composition.
- `report_route.bqn` uses a function array whose order must match catalog order.
- Route growth currently requires synchronized edits in several production and evidence files.
- Existing audit documents preserve their historical baselines and should not be read as the current runtime snapshot without this continuation record.
- `tools/coverage` is a module/test inventory, not measured line or branch coverage.

## 5. Catalog parity gate

Every retained individual catalog route must have exactly one ordered successful contract case in `tests/test_application_report_route.bqn`.

The test derives the catalog key vector from `catalog.Table` and compares it with the key vector of the successful route cases before running those cases.

This catches:

- a new catalog key without a route-contract success case;
- a removed key whose stale route case remains;
- a route order mismatch between the catalog and the dispatch function array;
- duplicate or reordered success cases.

Optional alternate shapes, such as `cycle-accounts` with an income-anchor Plan argument, remain additional cases outside the one-per-catalog parity vector.

## 6. Next finite slices

### Slice 3: Shell consumes the operational route plan

Replace the key-specific `tools/report` source table with the `ROUTE` and `SOURCE` output from `report_route_plan_cli.bqn`.

Shell must retain:

- caller working-directory handling;
- absolute base-path normalization;
- safe basename checks;
- `.journal` and `.tsv` suffix checks;
- file existence and readability;
- manifest file access;
- final process execution and exit behavior.

Do not change `report_destination_cli.bqn` in the same slice.

### Slice 4: destination composition consumes pure admission

After Slice 3 is independently merged, let `report_destination_cli.bqn` use `report_route.Admit` for key, surface, arity, and pre-I/O route diagnostics.

Keep route-specific semantic composition named and visible. Do not replace the branches with an opaque universal context or compressed train.

Only after this slice should duplicated raw route admission be removed completely.

### Reassessment

After Slices 3 and 4, reassess the remaining application boundary. At that point the repository can judge honestly whether the remaining effectful BQN adapter is thin enough to keep or has a stable protocol suitable for another language.

## 7. Slice discipline

Each continuation slice must:

1. verify current main and open PRs;
2. change one responsibility and one rollback point;
3. preserve diagnostics, stdout, exit codes, report bytes, source timing, and fail-closed publication unless separately characterized;
4. add focused evidence before deleting duplicate checks;
5. run full `tools/check.sh` and coverage;
6. review the final changed-file set before Ready and squash merge;
7. record the merged result in Issue #407.

Do not combine route-boundary wiring with accounting correctness, report semantics, editor behavior, or notation cleanup.
