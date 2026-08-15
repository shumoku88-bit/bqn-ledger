# Post-migration architecture observations — 2026-08-09

Status: observation record for discussion, not an accepted implementation plan

## Why this record exists

This document preserves the repository observations made after the Daily Flow work through PR #581 so that later design discussion does not require repeating the same broad audit.

The observations below are deliberately separated into:

- verified repository facts;
- structural inferences from the current call graph;
- hypotheses that still require measurement or semantic proof;
- negotiation questions that must be decided before implementation.

Do not treat an observation or hypothesis as an accepted roadmap item merely because it is written here.

## Audit baseline

The repository state inspected for these observations was:

- `main`: `1a20bbdea312db0041297be6cec97ff8051aeaf3`
- latest inspected main commit: `fix(report): focus daily flow on active accounts (#581)`
- PR #578: Draft, post-migration BQN/UI direction
- PR #550: separate Draft migration closeout work
- BQN review queue cursor on inspected main: `src/accounting/date_category_flow.bqn`

If later work needs to revisit these observations, first compare the relevant paths against this baseline. Re-run the broad audit only when ownership or the relevant call graph has materially changed.

## Preserved strengths

The following boundaries were found to be worth preserving rather than simplifying away.

### Read-side ownership

The documented production flow remains coherent:

```text
canonical Household root
  -> src/application
  -> src/ledger
  -> src/accounting
  -> src/sections
  -> src/report
  -> tool/UI delivery
```

Accounting capabilities are intended to remain pure and source-I/O-free. Sections do not own source reads. Application adapters own canonical source loading. This is a useful separation for both correctness and teaching.

### Writer authority and safe publication

The current editor architecture deliberately separates semantic edit intent from byte mutation:

```text
src_edit / src/editor
  -> validated machine-readable operation
  -> shell safe-write publication
```

The qualified Plan completion path uses source snapshots, stale checks, backup, candidate admission, post-write validation, and rollback/recovery behavior. These are safety properties, not incidental verbosity. Simplification work should not remove them merely to shorten the implementation.

### Existing pure/effect split worth using as a reference

`src/application/editor_actual.bqn` already separates effectful loading from a pure transformation:

- `LoadTransactionRows`
- `CompletionEvidenceFromRows`

This is a useful reference shape for later editor review: load/admit evidence at an effect boundary, then expose the domain transformation over already-admitted values.

## Observation A: current all-report execution discards shareable admitted evidence

### Verified facts

`tools/report-all` first invokes `src/application/current_report_profile_cli.bqn` to construct the current report request set. It then invokes `tools/report` separately for every selected report row.

For one human report, `tools/report` currently invokes these BQN entry points in sequence:

1. `src/application/report_request_cli.bqn`
2. `src/application/report_route_plan_cli.bqn`
3. `src/application/report_presentation_cli.bqn`
4. `src/application/report_destination_cli.bqn`

The retained catalog currently contains twelve human reports.

`src/application/current_report_profile_cli.bqn` itself already loads and admits reusable current-report context, including registry, canonical Actual facts, report policy, and Plan/Household context needed to construct the current request set.

`src/application/report_destination_cli.bqn` then loads the canonical evidence needed for each individual report again. Its single-report behavior is intentionally key-specific: Actual is loaded once inside a destination process and companion evidence is loaded only for report keys that need it.

### Structural inference

From that call graph, a full human `report-all` invocation has a static BQN process count of:

```text
1 current-report-profile process
+ 12 × 4 per-report processes
= 49 BQN process launches
```

A cold `tools/report-cache` generation has the same per-report structure plus its own report-selection process, giving a static count of 50 BQN process launches.

These numbers are call-graph counts, not wall-clock benchmark results.

The same architecture also implies repeated canonical source admission across report destinations. In particular, Actual facts are reconstructed for most report keys even though current-report request construction has already admitted Actual once.

### Important distinction

The problem, if measurement confirms it is significant, is not necessarily the internal single-report destination design. The single-report path benefits from key-specific I/O and should not automatically be replaced by an eager all-source loader.

The candidate architectural question is narrower:

> Should current all-report/cache execution have a batch owner that keeps one admitted Household observation alive while applying many pure report kernels?

Possible target shape:

```text
canonical Household root
  -> one admitted report observation
  -> shared Actual / Plan / Budget / policy evidence
  -> many purpose-specific report compositions
  -> many rendered results
```

### Not yet verified

No runtime conclusion was established from repository inspection alone. Before changing this boundary, measure at least:

- BQN cold-start cost;
- one simple report such as balances;
- one heavier report such as Daily Flow;
- `report-all`;
- cold report-cache generation;
- warm cache behavior;
- source read/admission counts where practical.

Do not label CBQN, a particular accounting kernel, or process startup as the dominant bottleneck before measurement.

## Observation B: `date_category_flow.bqn` carries two semantic grouped views

### Verified facts

After PR #579 and PR #581, `src/accounting/date_category_flow.bqn` supplies both:

- Date × dynamic expense-category grouped evidence;
- Date × Account grouped evidence used by the current Daily Flow matrix.

The file normalizes the selected Posting coefficients once, then performs separate `sparse.Build` operations for expense-category groups and account groups.

The review queue still names `src/accounting/date_category_flow.bqn` as the current unreviewed cursor on the inspected main.

### Focused follow-up result

A focused reread of `date_category_flow.bqn`, `sparse_group.bqn`, its direct consumers, tests, and `exact_scale.bqn` resolved the earlier semantic question.

The two grouped views are not interchangeable reductions. In particular, `exact_scale.Sum` is an ordered checked reduction, so Account-first reduction followed by Category regrouping can change intermediate exact-range failure behavior. It can also reorder contributor evidence by Account groups instead of original selected Posting order, and Account grouping intentionally includes non-expense evidence excluded from Category grouping.

The shared seam is therefore before semantic reduction: selected Posting evidence, scale normalization, and any coordinate work that can be shared without changing diagnostics, exact failure behavior, canonical order, contributor alignment, or empty behavior.

Decision D4 in `POST_MIGRATION_ARCHITECTURE_DECISIONS-2026-08-09.md` records the accepted result: Date × Account and Date × Category remain independent exact reductions. The presence of two `sparse.Build` calls is not by itself a defect.

### Cursor revalidation on 2026-08-10

Revalidated against `main` `01f7981921e0a051dab3cd67115d69d4548c9015` after the repository-resident continuation and complete production-BQN inventory work.

The direct consumer boundary remains meaningful rather than duplicated:

- `src/accounting/month_category_flow.bqn` consumes Date × Category evidence and performs the new semantic reduction onto a Month axis while retaining category policy, exact scale, and contributor Posting order;
- `src/sections/daily_flow.bqn` consumes Date × Account evidence, adds observation/period checks, filters presentation-visible active non-Budget Accounts, pivots the admitted groups, and owns labels/sign presentation rather than recomputing accounting classification.

The focused tests pin the contracts that matter for a rewrite: canonical axes, exact coefficients, mixed-scale normalization, contributor order/alignment, empty/fail-closed result shapes, Daily Flow visibility/presentation behavior, and Month × Category regrouping.

The current validation ladder also contains a more specific subtraction candidate. `date_category_flow.Build` requires admitted `budget.toml` and `household.toml` values but repeats several invariants already established by their admission owners:

- `budget_policy_admission.bqn` already guarantees unique Envelope ids, one-Envelope-per-Expense-Account assignment, admitted Expense Account role, and that published `expense_envelope_id` values arise from admitted Envelopes;
- `household_policy_admission.bqn` already guarantees unique Household Envelope ids, complete Budget/Household Envelope coordinate coverage for the Budget policy used at admission, and Budget role for allocation Accounts.

Not every flow-level guard is therefore redundant. The capability still receives independently admitted values and a query, so it must retain request-specific and cross-source compatibility checks. In particular:

- selected domain/layer and half-open period are request contracts;
- Facts/Household Account-axis compatibility is cross-source;
- Budget Envelope ids still need compatibility with the independently supplied Household coordinates rather than assuming both values came from the same admission call;
- allocation Account currency versus the selected domain is query-specific;
- the synthetic `other` category collision is a Date/Category capability concern unless a broader admission contract explicitly adopts that reservation.

After a compatible Account axis is established, rechecking the allocation Account's Budget role is a candidate duplicate because Household admission already established that role against that axis. Rechecking Budget-internal Envelope uniqueness, Expense assignment uniqueness, and Expense-to-Envelope reference membership is likewise a candidate duplicate of source admission rather than a capability contract.

The successful transformation underneath those guards is comparatively direct:

```text
admitted Account / Category coordinates
  -> selected period Posting axis
  -> one exact common-scale normalization
  -> Date × Income checked reduction
  -> independent Date × Category and Date × Account sparse checked reductions
  -> Date expense total and exact net
  -> semantic result publication
```

One local array-visibility hotspot remains before that kernel: `accountCategory` currently iterates every Account and performs nested role/assignment/category lookup control flow even after assignment uniqueness has been established. This is a candidate for a classify-once aligned mapping, but no rewrite is accepted yet. The replacement must be shown to make the Account → Category relation clearer while preserving canonical Account order, unmatched-Expense → `other`, non-Expense exclusion, diagnostics, and contributor behavior.

Current classification: **OBSERVE / RESTRUCTURE candidate**, not SUBTRACT and not yet reviewed-complete. The likely reason-to-change is narrower than the file size: remove repeated source admission and expose the existing bounded array kernel without moving accounting meaning into sections or deriving one semantic reduction from the other.

## Observation C: validation density is not itself the problem

Ordered diagnostics and fail-closed validation appear broadly across ledger, accounting, section, and editor owners. The repeated visual shape of helpers such as `AddIf` is not sufficient evidence that validation should be centralized into one generic validation framework.

Diagnostic stage, ordering, and rejection semantics are part of owner contracts.

The more useful review criterion is whether the successful mathematical/data transformation remains visible inside each owner.

Preferred review shape where semantics permit:

```text
boundary validation / guards
  -> admitted transformation kernel
  -> publication of the owner-specific result
```

This is a separation-of-concerns goal, not a rule to erase local diagnostics.

## Observation D: editor simplification should target orchestration, not publication safety

### Verified facts

`src_edit/plan_finish_cmd.bqn` currently combines several concerns in one command owner:

- command input validation;
- canonical Plan loading;
- Actual completion-evidence loading;
- open/closed selection;
- Plan selection;
- amount override validation;
- Posting reconstruction;
- machine-readable intent publication.

The retired Plan Budget-sync path had combined canonical Account/Plan/Budget/Household/Actual loading with cross-source semantic matching, Budget-envelope mapping, idempotence checking, and candidate preparation. Plan completion now stops at Actual evidence; historical PlanId routing owns Fulfillment.

The surrounding shell writers hold important publication authority and stale/rollback safety.

### Candidate review question

Where useful, expose pure kernels whose inputs are already-admitted evidence, for example conceptually:

```text
admitted Plan + completion evidence + selection
  -> Plan completion intent
```

Names and exact boundaries must follow the domain, not these placeholder signatures. Plan completion now ends at the Actual append; historical PlanId routing owns Fulfillment rather than producing a Budget execution intent.

The goal is to make the semantic transformation independently readable and testable while preserving one qualified writer path.

## Observation E: editor shell remains a deliberate migration structure

`tools/edit` currently acts as a small public dispatcher that sends the qualified Budget Add writer to its dedicated owner and otherwise delegates to `tools/edit-bqn`. Plan completion has no Budget publication branch.

`tools/edit-bqn` is still large, but the repository already documents an extraction rule: move one coherent command group without creating a second write authority.

Therefore this area should be treated as unfinished strangler-style migration, not as evidence that a new editor architecture should be invented wholesale.

Desired cleanup criterion:

- keep `tools/edit` stable;
- keep one publication authority per mutation;
- continue shrinking dispatch/orchestration by coherent command group when review reaches the owner;
- do not re-centralize ledger semantics in shell.

## Observation F: selector behavior is duplicated across UI shells

Current selector/input delivery logic exists independently in multiple shell owners, including:

- `tools/bl`
- `tools/main-ui.sh`
- `tools/add-ui.sh`

Each contains variants of fzf/gum/plain selection and cancellation/fallback behavior.

This is a change-locality concern: changing terminal selector behavior can require coordinated changes across several files.

The likely long-term direction is a neutral selector/input adapter consuming key/label or other machine-readable candidate records, while domain meaning remains in BQN/editor/report owners.

Do not move Account, Plan, report, accounting, or writer semantics into a shared shell helper in the name of UI reuse.

## Observation G: terminal color policy has a semantic/presentation boundary worth deciding explicitly

Current policy is split between:

- canonical `report.toml`, which admits negative style and negative color;
- terminal-local theme state such as `BL_THEME`;
- `tools/lib/color-filter`, which maps some configured colors through theme semantic colors and some directly to fixed ANSI colors.

This is not recorded as a correctness bug.

It is an ownership question for later UI/presentation work:

> Should canonical Household report policy select a literal terminal color, or should it select a semantic presentation role whose concrete color belongs entirely to the terminal theme?

Do not change this until the desired ownership is agreed.

## Cross-cutting quality axes discovered by this audit

The owner-by-owner BQN review remains useful, but the audit found cross-cutting properties that a purely local cursor can miss.

For each reviewed area, consider these questions in addition to glyph/array form:

1. **Concern separation** — are admission, pure transformation, publication, and presentation distinguishable where they represent different responsibilities?
2. **Change locality** — does one semantic or UI change require touching unrelated owners?
3. **Duplicate work** — is already-admitted or already-classified evidence reconstructed unnecessarily?
4. **Effect lifetime** — is useful admitted evidence discarded merely because of a process/adapter boundary?
5. **Array visibility** — can the central relationship between semantic axes be seen directly in the BQN kernel?
6. **Protected invariants** — are exactness, diagnostics, identity, provenance, canonical order, stale rejection, and writer authority still explicit?

These are review lenses, not automatic refactoring mandates.

## Negotiation points before implementation

Some points below are resolved and retained here so the original audit questions remain traceable; unresolved points remain explicitly open.

### N1. Cursor navigation versus demonstrated cross-cutting defect

Resolved by decision D1 in `POST_MIGRATION_ARCHITECTURE_DECISIONS-2026-08-09.md`: the cursor is navigation, not an absolute prohibition or PR-size rule. Evidence-backed architectural work may cross owners/layers when one reason-to-change requires it.

### N2. Batch report owner

If measurement confirms repeated startup/admission is expensive, decide whether to:

- add a dedicated batch/current-report composition owner while preserving the single-report path;
- redesign the existing destination API to accept an admitted observation;
- accept the current process isolation because its simplicity/reliability outweighs the cost.

### N3. Dense reuse versus independent semantic projections

Resolved by decision D4. Date × Account and Date × Category remain independent exact reductions over shared selected/normalized Posting evidence; neither is derived from an already-reduced form of the other.

### N4. Editor pure kernels

Decide how far to separate pure edit decisions from command adapters. A distinct pure kernel may improve teaching and tests, but excessive micro-modules can hide the end-to-end edit story.

### N5. UI consolidation timing

Selector duplication is real, but consolidating it too early could create a generic shell framework before the terminal UI direction is settled. Decide whether to defer until the relevant architecture is understood or consolidate when a concrete UI/ownership change requires it.

### N6. Canonical versus terminal-local color choice

Decide whether literal color names are Household policy or whether the Household should express only semantic negative presentation while the local theme owns concrete color.

## Suggested measurement record format

When performance observation begins, append measured results to a separate dated record rather than rewriting these structural observations. Record:

- repository SHA;
- canonical test fixture or synthetic fixture identity;
- command;
- cold/warm condition;
- wall/user/sys timing where available;
- BQN process count;
- source/admission count where instrumented;
- output equivalence evidence.

This keeps structural facts, measurements, and later decisions independently auditable.

## Revalidation rule

Future discussion should not begin by repeating this entire audit.

Instead:

1. compare current main against baseline `1a20bbdea312db0041297be6cec97ff8051aeaf3`;
2. identify whether the files/owners relevant to the question changed;
3. re-read only changed relevant owners and their direct contracts;
4. preserve still-valid observations from this document;
5. explicitly mark an observation superseded when evidence changes.

Broad re-audit is reserved for a material ownership/topology change, not routine continuation.
