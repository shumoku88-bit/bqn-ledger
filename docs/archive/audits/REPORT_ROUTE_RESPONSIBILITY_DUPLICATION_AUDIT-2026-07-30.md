# Report route responsibility duplication audit

Status: completed observation-only boundary audit

Date: 2026-07-30

Repository baseline: `2f0959968a3f26dfcb17e8d1dd6b127647225628`

Related records:

- `docs/BQN_LANGUAGE_RESPONSIBILITY_BOUNDARY_AUDIT.md`
- `docs/ARCHITECTURE.md`
- `docs/REPORT_PORTFOLIO_CONTRACT.md`
- `docs/BQN_REFACTORING_REVIEW_GUIDE.md`

Observed owners:

- `src/report/catalog.bqn`
- `src/report/request.bqn`
- `src/application/report_request_cli.bqn`
- `src/application/report_selection_cli.bqn`
- `src/application/report_destination_cli.bqn`
- `tools/report`
- `tools/report-all`
- explicit request-manifest rows

## 1. Question

This audit asks:

> Which report-route facts are owned once, which are repeated between Shell and BQN, and what pure admitted route plan would allow operational Shell checks and BQN semantic composition to meet without duplicating policy?

This is an observation-only audit. It does not authorize removal of current checks, movement of filesystem policy into accounting code, or a second implementation language.

## 2. Current route pipeline

For one report request, the public path is approximately:

```text
CLI argv or request-manifest row
→ tools/report
→ BQN request.Validate through report_request_cli
→ Shell key-specific arity and source-basename/readability checks
→ report_destination_cli.bqn
→ BQN key-specific arity, source admission, cycle resolution, and composition
→ renderer
```

For `all`, the path adds:

```text
catalog-selected keys
→ report_selection_cli
→ tools/report-all manifest count/order admission
→ one tools/report invocation per row
→ buffered publication after every row succeeds
```

This architecture already has two good properties:

1. key and surface validity are checked before household source reads;
2. `all` key selection and order are derived from the report catalog rather than a second hard-coded key list.

The duplication is narrower: key-specific coordinate and source contracts.

## 3. Existing owners and their proper responsibilities

### 3.1 Static report catalog

`src/report/catalog.bqn` owns:

- retained key order;
- labels and categories;
- semantic owner file;
- result shape name;
- human, compact, and JSON surface support.

This is appropriate pure report metadata. It does not own CLI coordinate names, source file types, filesystem checks, or cycle-specific optional arguments.

### 3.2 Pure request admission

`src/report/request.bqn` owns:

- known surfaces;
- known report keys;
- surface support for one key;
- `all` selection by supported surface;
- selected catalog indices and keys.

This is also appropriate. `report_request_cli.bqn` and `report_selection_cli.bqn` are thin process wrappers over this pure owner.

### 3.3 Operational Shell boundary

`tools/report` owns:

- caller working-directory preservation;
- absolute base-path normalization;
- safe basename checks;
- `.journal` and `.tsv` suffix checks;
- file existence and readability;
- manifest file reading;
- process exit and final `exec`.

These are proper Shell responsibilities.

It also owns a key-specific `case` containing:

- accepted argument counts;
- positions of Journal and TSV sources;
- optional Plan source positions;
- required-source enumeration.

Those are partly route-schema facts rather than purely operational facts.

### 3.4 BQN destination composition boundary

`src/application/report_destination_cli.bqn` owns:

- key-specific coordinate count checks;
- conversion of textual numeric coordinates;
- source reads through the source adapter;
- strict Account, Journal, Plan, Budget, Cycle, Scope, and Issue admission;
- income-anchor optional Plan semantics;
- cycle mode consistency;
- calls to the correct composition owner;
- structured diagnostic printing and process exit.

The semantic source admission and composition belong on the BQN side. The repeated raw coordinate counts and source positions overlap the Shell route table.

### 3.5 Request manifests

A manifest row owns concrete request values:

```text
key | surface | arguments...
```

It does not independently define the argument schema. The row is interpreted by `tools/report`, and the same values are interpreted again by `report_destination_cli.bqn`.

## 4. Per-route contract comparison

Argument counts below exclude `BASE`, `KEY`, and `SURFACE`.

| Key | Catalog surfaces | Shell count | BQN count | Shell source positions and types | Additional BQN semantics |
|---|---|---:|---:|---|---|
| `envelopes` | human, compact, JSON | at least 8 | at least 8 | argument 5 Journal; 6 Plan TSV; 7 Budget TSV | funding account list nonempty through count; strict Actual/Plan/Budget admission; funding scope construction |
| `balances` | human, compact, JSON | exactly 3 | exactly 3 | argument 3 Journal | domain and observation composition |
| `recent` | human, compact | exactly 2 | exactly 2 | argument 2 Journal | argument 1 must contain decimal digits and becomes a natural limit |
| `planned` | human, compact, JSON | exactly 4 | exactly 4 | argument 2 Journal; 3 Plan TSV; 4 Cycle TSV | cycle admission and mode-aware resolution |
| `cycle-accounts` | human | 4 or 5 | 4 or 5 | argument 3 Journal; 4 Cycle TSV; optional 5 Plan TSV | Plan is required only for `incomeAnchor` and rejected for other modes |
| `cycle-comparison` | human | 7 or 8 | 7 or 8 | argument 5 Journal; 6 and 7 Cycle TSV; optional 8 Plan TSV | current/baseline modes must match; Plan required only for `incomeAnchor` |
| `monthly-accounts` | human | exactly 4 | exactly 4 | argument 4 Journal | month-coordinate composition |
| `daily-target` | human, compact | exactly 6 | exactly 6 | argument 4 Journal; 5 Plan TSV; 6 Daily Scope TSV | strict Plan and Daily Scope admission, then pure scope construction |
| `issues` | human | exactly 1 | exactly 1 | argument 1 Issues TSV | Issue-line composition |
| `all` | human, compact | exactly one manifest basename at public Shell entry | not accepted by destination CLI | manifest TSV; then each row follows its key contract | selected key order comes from catalog; all rows admitted before execution |

## 5. Exact duplication findings

### 5.1 Key-specific coordinate counts are duplicated

For every individual route, Shell checks the argument count and BQN checks it again.

This duplication is currently defensive, but there is no named pure owner for the count contract. A new key requires synchronized edits in at least:

- `src/report/catalog.bqn` for key/surface metadata;
- `tools/report` for argument count and source positions;
- `src/application/report_destination_cli.bqn` for argument count and interpretation;
- request-manifest fixtures and checks.

### 5.2 Source roles and positions are duplicated

Shell knows which argument must be a Journal or TSV basename. BQN knows the same argument position because it destructures coordinates and calls `sources.Actual`, `sources.Plan`, `sources.Companions`, `CycleLines`, `DailyScopeLines`, or `IssueLines`.

The two sides do different work:

- Shell validates basename shape and readability;
- BQN assigns semantic meaning and performs strict admission.

The position and broad source kind are nevertheless shared route facts without one explicit owner.

### 5.3 Optional Plan shape and optional Plan meaning are split

For `cycle-accounts` and `cycle-comparison`:

- Shell admits either the shorter or longer argv shape and validates the optional final value as TSV;
- BQN determines whether the optional Plan is required or forbidden from the admitted Cycle mode.

This split is sensible, but the relationship is implicit. Shell knows “optional Plan may exist”; BQN knows “Plan presence is conditional on incomeAnchor.”

### 5.4 Failure codes are intentionally different but should remain traceable

Shell failures describe operational admission:

- unsafe basename;
- unreadable source;
- manifest shape;
- public usage.

BQN failures describe semantic admission and composition:

- invalid limit text;
- unknown domain or layer;
- rejected Journal, Plan, Budget, Cycle, or Scope;
- missing or unexpected income-anchor Plan;
- cycle-mode mismatch.

These should not be collapsed into one generic failure. A future route plan should identify which checks are operational and which remain semantic.

### 5.5 Surface support is not materially duplicated

Surface support is admitted through `request.Validate`, derived from the catalog, before Shell's route-specific source checks. Shell usage text lists surfaces, but executable support decisions come from BQN request admission.

Decision: keep catalog/request as the surface owner.

### 5.6 `all` key order is not materially duplicated

`tools/report-all` obtains selected keys from `report_selection_cli.bqn`, which delegates to `request.Validate` and the catalog. The manifest is checked against that order.

Decision: preserve this pattern. It is an example of Shell consuming a small BQN-owned pure decision rather than rebuilding it.

## 6. Why the current duplication exists

The duplication was not arbitrary. It supports a fail-closed sequence:

1. validate public key and surface;
2. reject unsafe or unreadable paths before launching full composition;
3. read and semantically admit only explicitly declared sources;
4. publish only a complete successful result.

The problem is therefore not duplicate checking by itself. The problem is the absence of a small admitted route description shared by both boundaries.

## 7. Candidate target boundary

The preferred future shape is:

```text
key + surface + coordinate texts
→ pure BQN route admission
→ admitted route plan
   ├─ operational source requirements for Shell
   └─ typed semantic coordinates for BQN composition
```

A route plan could contain only application-boundary facts such as:

- key and surface;
- coordinate count or admitted coordinate vector;
- named argument roles;
- source argument indices;
- broad source kinds: Journal or TSV;
- whether a Plan argument is absent, present, or conditionally interpretable;
- route-admission diagnostics.

It must not contain:

- household file contents;
- Account, Transaction, Posting, Plan, or Budget Facts;
- accounting results;
- filesystem existence or readability state;
- report rendering;
- cycle-mode decisions that require admitted Cycle evidence.

## 8. Candidate implementation sequence

### Slice 1: pure route contract owner

Create one pure application-boundary module that admits key-specific coordinate shape without reading files or exiting.

Required evidence:

- every retained individual key;
- too few and too many arguments;
- optional Plan shapes;
- numeric `recent` limit text;
- stable diagnostic codes and ordering;
- no source reads.

Do not modify `tools/report` yet.

### Slice 2: machine-readable route-plan CLI

Add a thin CLI that emits an admitted operational plan in a deliberately small stable format, likely TSV lines.

Required evidence:

- exact output bytes;
- no household reads;
- one output schema version or an explicitly versionless private contract;
- failure before any source access.

### Slice 3: Shell consumes operational plan

Replace the key-specific Shell `case` with interpretation of the admitted source requirements.

Shell retains:

- safe basename checks;
- suffix checks;
- existence and readability;
- caller path handling;
- process execution.

BQN retains semantic source admission and composition.

### Slice 4: destination CLI consumes the same pure admission

Replace repeated raw arity checks and positional destructuring preconditions with the pure admitted route result, while keeping route-specific semantic composition named and visible.

Only after this slice should the old duplicated route table be removed completely.

## 9. Rejected shortcuts

Do not:

- move safe-path or readability checks into accounting or report modules;
- make `catalog.bqn` own filesystem source policy merely because it owns report metadata;
- replace the BQN destination CLI with a second language before the route protocol exists;
- encode route schema only in documentation or fixtures;
- remove duplicate checks before a replacement owner and focused tests exist;
- combine route-boundary thinning with accounting or report correctness changes;
- compress route composition into opaque trains or modifier-heavy dispatch.

## 10. First finite implementation candidate

The first candidate is Class B boundary thinning:

> Add a pure `report_route` admission owner that validates individual-route coordinate shapes and identifies operational source arguments without reading files, running composition, or exiting.

This candidate is valuable even if the final operational boundary remains Shell plus BQN. It converts implicit duplicated positional knowledge into one inspectable value.

Before implementation, the exact output namespace and diagnostics should be fixed in a Draft PR body and focused test. The initial slice should not modify `tools/report`, `report_destination_cli.bqn`, catalog, manifests, or output bytes.

## 11. Conclusion

The report boundary does not currently prove that BQN should be removed. It shows a more precise problem:

> Shell and BQN perform different responsibilities over the same unowned positional route schema.

The right next move is not language replacement. It is to create a pure admitted route plan, let Shell keep operational safety, and let BQN keep strict semantic admission and composition. After that thinning, the remaining BQN CLI will be small enough to judge honestly.