# Post-migration architecture decisions — 2026-08-09

Status: negotiated decisions associated with `POST_MIGRATION_ARCHITECTURE_OBSERVATIONS-2026-08-09.md`

This file records decisions only. Structural observations, measurements, and unresolved questions remain in their own records.

## D1. Review cursor is a default sequence, not an absolute prohibition

Accepted 2026-08-09.

The review cursor remains the normal way to remember where architectural review should resume. It prevents arbitrary cherry-picking of easier work, but it does not define the permitted size or owner span of a change.

It is **not** an absolute rule that blocks a justified cross-cutting change outside the current cursor.

An out-of-order change is allowed when all of the following hold:

- the reason is concrete rather than aesthetic convenience;
- a user-facing defect, measured performance problem, correctness risk, or clearly demonstrated cross-owner architectural defect justifies the interruption;
- the change has one clear reason-to-change and an explicit completion condition;
- unrelated work is excluded, but every owner/layer needed to reach the coherent end-state may move together;
- exact arithmetic, diagnostics, identity, provenance, canonical order, source authority, and writer safety remain protected;
- the reason for leaving the cursor is recorded in the PR or measurement/design record;
- after the exception closes, the normal queue resumes unless a new explicit decision changes the order.

Examples that may justify an exception after evidence exists include measured all-report startup/admission overhead or a reproducible daily UI defect. A later file merely looking easier is not sufficient reason.

This resolves negotiation point N1 in the observation record. N4–N6 remain open; N2 is resolved by D5 and N3 by D4 below.

## D2. Coherence, not smallness, defines change boundaries

Accepted 2026-08-09.

Change size is **not** a quality target. The repository must not force architectural work into one-file, one-owner, one-layer, low-line-count, or otherwise artificially small PRs merely to make each step look safer.

The preferred unit of change is one coherent architectural argument with a stable end-state.

A coherent change may therefore include, when required by the same reason-to-change:

- multiple production owners;
- callers and consumers;
- ledger/accounting/section/application/editor/tool boundaries;
- shell and BQN adapters;
- tests, checks, fixtures, and documentation;
- removal of obsolete paths made unnecessary by the new end-state.

Do not introduce temporary adapters, duplicate implementations, compatibility shims, forwarding layers, or intermediate abstractions solely to keep a PR small. If such machinery is required for a real compatibility or safety contract, record that contract explicitly instead of treating small PR size as the justification.

Reviewability comes from conceptual unity, explicit invariants, evidence, and a clear completion condition, not from an arbitrary file or line limit. A PR should be explainable as one reason-to-change; it need not be explainable as one file-to-change.

Commits inside a PR may be arranged to make the reasoning reviewable, but the merged architectural end-state is the unit that must be coherent. There is no requirement to preserve temporary internal architecture between commits when no external contract requires it.

Protected invariants remain non-negotiable: exact arithmetic, diagnostics, identity, provenance, canonical ordering, fail-closed admission, source authority, safe effects, stale rejection, and qualified writer publication must survive the complete change.

This decision intentionally removes process language that would otherwise bias the project toward tiny slices. The cursor remains a navigation aid; it is not a PR-size policy.

## D3. Git history is the archive; stale archive documents do not remain in the current tree

Accepted 2026-08-09.

Completed plans, old audits, historical handoffs, retired TODO snapshots, and superseded policy notes do not need a second persistent home under `docs/archive/` merely to preserve history. Git already preserves the repository history in which those documents existed.

The current tree should preferentially contain current architecture, current operational documentation, live design evidence, and active decisions. Historical documents may be recovered from Git history when needed.

Therefore `docs/archive/` is to be removed from the current repository tree together with active documentation, indexes, and checks whose only purpose is to expose or validate that archive.

Removal must be coherent rather than a bare directory deletion:

- remove the archived documents from the current tree;
- remove active links and navigation entries that point into `docs/archive/`;
- remove repository-index/check assumptions that treat `docs/archive/` as a live documentation surface;
- preserve any still-live semantic, safety, compatibility, or writer contract by moving its current statement into an active owner before deleting the historical copy;
- verify that no required current workflow depends on an archived path.

This does not rewrite history. Deleted documents remain available through Git commits and tags. The purpose is to reduce present-day cognitive load and prevent stale plans from being mistaken for current process authority.

## D4. Date × Account and Date × Category remain independent exact reductions

Accepted 2026-08-09 after rereading `date_category_flow.bqn`, `sparse_group.bqn`, its direct consumers, and `exact_scale.bqn` on main `1a20bbdea312db0041297be6cec97ff8051aeaf3`.

`date_category_flow.bqn` intentionally publishes two different grouped views over the same selected and normalized Posting evidence:

- Date × Account over every selected Posting in admitted Account order;
- Date × dynamic expense Category over selected Expense Postings in admitted category order.

These views may share selection, scale normalization, and other pre-group evidence. They must not be implemented by reducing one grouped result first and then deriving the other grouped result from those already-reduced cells.

The reason is semantic, not merely performance-related:

- `exact_scale.Sum` is a checked ordered reduction whose intermediate failure behavior is part of the result contract;
- reducing by Account first and then by Category can change intermediate sums and therefore change exact-range failure behavior even when an unbounded mathematical total would match;
- contributor arrays retain source-relative evidence order inside each semantic group;
- regrouping already-reduced Account cells by Category would reorder contributors by Account groups rather than by the original selected Posting order;
- Account grouping includes non-expense evidence that Category grouping intentionally excludes.

Therefore the two reductions remain independently derived from the shared normalized Posting axis. A future simplification may share coordinate resolution or another pre-reduction step only when it preserves diagnostics, exact failure behavior, canonical order, contributor order/alignment, empty behavior, and both public grouped result shapes.

This resolves negotiation point N3 in the observation record. The presence of two `sparse.Build` calls is not, by itself, architectural duplication that must be removed.

## D5. Multi-report execution gets a shared application lifetime; single-report execution stays narrow

Accepted 2026-08-09 after the measured baseline in PR #583 and the byte-equivalent shared-lifetime prototype in PR #584.

The retained multi-report path has a demonstrated architectural cost from repeatedly ending BQN process/admission lifetime. The baseline measured 49 BQN launches for `report-all` and 50 for cache generation. The disposable prototype kept current request construction unchanged, executed all twelve human destinations inside one shared destination lifetime, reproduced the complete `report-all` bytes exactly on the proof context, and reduced the measured all-report path from 49 BQN launches to 2 with roughly a ninefold wall-time improvement across two GitHub-hosted runners.

This evidence is strong enough to choose the production direction, but not to promote the prototype itself.

The production architecture shall preserve these responsibilities:

- **current request-set ownership remains semantic and separate**: the current report profile/request owner continues to determine retained keys, surface, coordinates, cycle-relative requests, and catalog order;
- **single-report execution remains a narrow path**: one requested report may continue to load only the evidence it needs and must preserve its existing request/registry/route admission order and diagnostics;
- **multi-report execution may retain one admitted Household/report observation** across the current request set instead of re-reading/re-admitting the same canonical evidence per report;
- **one shared destination dispatch owns key-to-composition behavior**: production must not keep separate single and batch copies of the key → `compose.*` → render mapping;
- **existing pure semantic owners remain authoritative**: `compose.*` and `render.Render` remain the report semantics/presentation owners rather than being copied into the batch adapter;
- **batch transport is machine framing, not report semantics**: a batch adapter may frame rendered report bodies with explicit metadata needed by shell consumers, but the framing must not alter report bytes;
- **cache staging and atomic publication remain shell responsibilities**: BQN must not gain canonical/cache publication authority merely to obtain a longer compute lifetime;
- **no universal application context is introduced by default**: the shared admitted evidence must be named for this current-report capability rather than becoming a generic bag passed throughout the repository;
- **no accounting micro-optimization is justified by this result**: the measured improvement came from evidence/process lifetime alone, so accounting exactness, diagnostics, provenance, and existing kernels are not performance targets for this issue.

The likely coherent production slice spans the shared application destination dispatcher, a current multi-report batch adapter, `tools/report-all`, `tools/report-cache`, and their qualification checks. That cross-layer scope is justified by D2 because all of those owners are required to remove one demonstrated repeated-lifetime defect without leaving duplicate dispatch or a second publication authority.

Qualification must include:

- byte-equivalent retained human report bodies against the current path;
- preservation of direct single-report route/registry failure contracts;
- canonical report order and complete key coverage;
- cache stage/lock/atomic publication behavior;
- fail-closed handling of invalid batch request rows or source admission;
- measured confirmation that the production multi-report path actually retains the process/admission reduction rather than merely moving work elsewhere.

This resolves negotiation point N2 in the observation record.

## D6. Architecture guards protect laws, not implementation topology

Accepted 2026-08-09 after PR #585 established the shared multi-report lifetime in production.

Regression protection should preserve the reason an architecture exists without turning the current implementation into a permanent template. A check is a guardrail, not a requirement that future code keep the same file names, helper names, import graph, process count, or internal arrangement.

For the current-report lifetime, the durable laws are:

- batch output remains semantically and byte compatible with the independent single-report path for supported aggregate surfaces;
- reusable admitted evidence is retained across the multi-report lifetime rather than re-read or re-admitted once per report;
- orchestration cost must not grow in proportion to the number of selected reports;
- invalid request rows and source admission still fail closed;
- cache staging and publication safety remain preserved.

The measured `report-all = 2` and `report-cache = 3` BQN process counts are evidence about the current implementation, not permanent architecture API. A future implementation may reduce or otherwise rearrange those fixed costs without changing this decision.

Prefer behavioral qualification that varies the workload or makes a prohibited lifetime observable. For example, compare different report-set sizes and verify that orchestration process count does not scale with them, or provide one-shot source evidence that cannot be re-read successfully. Such tests protect the lifetime property while leaving internal ownership free to improve.

Avoid permanent checks whose only purpose is to require an exact import statement, helper function, source filename, or concrete dispatch placement when the same semantic/lifetime law can be observed from outside. Static ownership checks remain appropriate when the ownership itself is the protected contract, such as canonical writer authority or forbidden I/O in a pure owner.

Wall-clock measurements remain evidence and diagnostics rather than hard CI thresholds unless a future explicit service-level contract requires otherwise. Runner speed is not architecture.

When implementation topology changes, guards may be rewritten so long as the same law remains demonstrably protected. The test should make the bad architecture difficult to reintroduce, not make the good architecture difficult to evolve.

## Process-authority precedence

Current active documentation and this decision record define present repository process. Historical documents remain useful as evidence only through Git history after D3 is applied.

Safety, semantic, compatibility, or writer constraints remain relevant when they describe a still-live contract. A constraint that is still live must have a current active owner rather than relying on an archived document for authority.
