# Docs Lifecycle Contract

Status: current docs policy / docs-only
Owner: docs
Canonical: yes
Exit: keep current while `docs/README.md` is the docs router; revise when the docs directory layout or archive policy changes

This document defines how documentation is created, routed, completed, and retired in `bqn-ledger`.

The goal is not to reduce the number of documents for its own sake. The goal is to prevent repeated docs cleanup by making every document's role, owner, and exit path explicit at creation time.

```text
Do not just write a document.
Decide where it lives, what it is canonical for, and how it retires.
```

## Non-goals

- Do not rewrite all existing docs in one pass.
- Do not build a broad natural-language docs/code synchronizer.
- Do not require every historical note to be perfectly normalized before useful work continues.
- Do not duplicate existing process docs. AI workflow feedback remains governed by `docs/AI_WORKING_FEEDBACK_PROCESS.md`.
- Do not turn archive notes into current specs.

## Required lifecycle header

New docs, and materially revised docs, should carry a short lifecycle header near the top.

Minimum form:

```md
Status: current spec / current contract / current policy / current operational guide / active plan / active backlog / parked / historical / completed / superseded / audit snapshot
Owner: report / editor / safety / docs / workflow / config / envelope / release / other
Canonical: yes | no; canonical path: docs/...
Exit: condition for archive, completion, replacement, or review
```

Existing docs do not need a mechanical backfill. Adopt the header when a doc is created, promoted, retired, or substantially edited.

## Status meanings

| Status | Meaning | Normal location | How to read it |
|---|---|---|---|
| `current spec` | Current behavior or user-facing specification | `docs/` | May be used as present truth. |
| `current contract` | Interface, data shape, invariant, or tool contract | `docs/` | May be used as present truth; code/check changes should keep it in sync. |
| `current policy` | Standing decision rule or quality boundary | `docs/` | Use for judgment and review. |
| `current operational guide` | How to run or operate current tooling safely | `docs/` | Use for day-to-day operation. |
| `active plan` | Approved or selected work plan | `docs/archive/active-plans/` or rarely `docs/` | May authorize work only within its stated scope. |
| `active backlog` | Curated candidates, not automatic implementation authority | `docs/` or `docs/archive/active-plans/` | Select a small slice before implementation. |
| `parked` | Idea/sketch with no current authorization | `docs/archive/active-plans/` | Do not implement directly. Promote through TODO/plan first. |
| `historical` | Background, old design, stale handoff, or superseded note | `docs/archive/` | Do not use as current spec. |
| `completed` | Implemented plan or decision record | `docs/archive/completed-plans/` | Read for rationale, not as a next-step instruction. |
| `superseded` | Replaced by another current path | `docs/archive/` or short status stub | Follow the current path. |
| `audit snapshot` | Point-in-time investigation or classification | `docs/archive/audits/` | Evidence only; not an implementation backlog. |

## Canonical and auxiliary docs

For each topic, prefer one canonical current path.

- Canonical docs own the current meaning.
- Auxiliary docs may explain examples, plans, or implementation notes, but must link to the canonical path.
- Historical docs should point back to the current path when one exists.
- If two current docs appear to own the same meaning, fix ownership first rather than updating both forever.

Examples:

| Topic | Canonical path |
|---|---|
| Overall docs routing | `docs/README.md` |
| Code/data flow map for pit | `docs/AI_CODEMAP.md` |
| Quality boundary | `docs/QUALITY_BAR.md` |
| Source TSV and metadata conventions | `docs/CONVENTIONS.md`, `docs/JOURNAL_META.md` |
| Current report engine | `docs/SRC_NEXT_CURRENT.md`, `docs/ARCHITECTURE.md` |
| Docs lifecycle | `docs/DOCS_LIFECYCLE_CONTRACT.md` |

## Location rules

### `docs/`

Use for current specs, current contracts, current policies, current operational guides, and small active backlogs that are intentionally part of the current reading path.

### `docs/archive/active-plans/`

Use for active plans, parked sketches, and temporary planning notes. This directory is not automatically current. Its `README.md` inventory decides whether a file is active, parked, or historical.

### `docs/archive/completed-plans/`

Use for implemented plans, decision records, and historical design notes that remain valuable but should not guide current work directly.

### `docs/archive/audits/`

Use for point-in-time audits, classifications, drift tables, and investigation worksheets.

## Creation workflow

When adding a doc:

1. Choose `Status`, `Owner`, `Canonical`, and `Exit` before writing the body.
2. Decide whether it belongs in `docs/`, `docs/archive/active-plans/`, or an archive subdirectory.
3. If it is canonical, add or update the route in `docs/README.md`.
4. If it is auxiliary, link to the canonical doc instead of repeating the whole spec.
5. If it supersedes another doc, add a status note or archive move plan for the old doc.
6. Keep the first slice docs-only unless implementation is separately authorized.

## Retirement workflow

When a plan completes or a current doc becomes stale:

1. Do not silently leave it in the current path as if it were still active.
2. Choose one:
   - move to `docs/archive/completed-plans/`,
   - replace with a short historical stub,
   - add a status note pointing to the current path,
   - or keep as current after revising the header and routing.
3. Update `docs/README.md` and any active inventory that routed readers to the old path.
4. Prefer small moves and explicit stubs over large rewrites.

Archive/historical stub template:

```md
# Title

Status: historical / superseded / completed
Owner: docs
Canonical: no; current path: docs/...
Exit: archived; do not use as current spec

This document is kept for background. Use `docs/...` for the current contract.
```

## Automation policy

Checks should target high-value, low-ambiguity failures. Do not try to infer all semantic drift from prose.

Good first checks:

- new or touched Markdown has a lifecycle `Status:` when it is intended to be current or active;
- archive docs do not claim `Status: current ...`;
- archive stubs that say `current path:` point to an existing file;
- `docs/README.md` links to canonical docs that exist;
- stale tool names and removed guards are caught by narrow allowlist/denylist checks.

Avoid broad checks that create a second source of truth or require constant allowlist churn.

## Adoption plan

Adopt this contract gradually:

1. Use this file as the current docs lifecycle policy.
2. Add routing from `docs/README.md` and `README.md`.
3. Apply lifecycle headers to new docs and docs touched for substantive changes.
4. Only after repeated friction, add a narrow check for the smallest observed drift.
5. Periodically move completed plans in small batches, updating routes before or with the move.

## Acceptance criteria for future docs hygiene slices

A docs hygiene slice is good when:

- it reduces the number of places that claim current authority;
- it improves `docs/README.md` routing;
- it leaves historical rationale reachable but clearly non-current;
- it does not rewrite unrelated docs for style alone;
- it does not create a new process that requires more upkeep than the drift it prevents.
