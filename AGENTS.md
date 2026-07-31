# Working on bqn-ledger

This repository is a place to explore household accounting with plain-text data and BQN.

Read the code and the documents that help with the task at hand. Historical plans and decisions are available for context, but they do not limit present work.

## Development posture

You may:

- question existing designs and module boundaries;
- propose alternatives and explain your preference;
- change related files when that makes the result more coherent;
- build small experiments with public synthetic data;
- report discoveries that were not part of the original request;
- remove or replace structures that have outlived their purpose.

Prefer changes that are understandable, reviewable, and reversible. Use tests, fixtures, and checks where they make behavior clearer. Review the resulting diff and describe the important decisions.

Git preserves earlier versions. A reversible experiment is often more informative than a long permission process.

## BQN work

Before creating or changing any `.bqn` file:

1. read `docs/BQN_CAPABILITY_MAP.md` in full;
2. read `docs/BQN_SIMPLIFICATION.md`, the target owner, and focused evidence;
3. identify input and output shapes, semantic axes, fill and empty behavior, aligned evidence columns, and protected ordering;
4. consider every capability family in the map before selecting the expression that states the problem most directly;
5. consult the official BQN reference and run a small CBQN probe instead of guessing when a primitive, modifier, rank, depth, fill, grouping, or empty-array behavior is uncertain.

Dense classical array-language style is welcome. A compact BQN expression is not less readable merely because it does not resemble conventional procedural code. When axes and invariants are explicit, prefer a direct whole-array expression over loops, mutable append, temporary row namespaces, or a ladder of single-use staging names.

Purity is not a role. A pure accounting owner may be a capability boundary that admits request coordinates, checks cross-source compatibility, distinguishes success, unavailable, and error results, converts exact-arithmetic failures into public diagnostics, or assembles identity and provenance. Do not treat every pure function in `src/accounting/` as a whole-array kernel.

Separate a shallow capability boundary from the bounded whole-array kernel it protects. Ledger admission owns source-internal invariants; the capability boundary owns request-specific and cross-source contracts. Once those preconditions are established, the inner kernel should receive aligned arrays and expose the direct transformation rather than repeat source validation or hide it behind defensive predicate ladders. This prohibition concerns defensive control-flow nesting, not nested arrays or ragged evidence cells.

Do not expand a clear train, modifier composition, rank/cell expression, grouping pipeline, or structural transformation solely to make each mechanical step familiar to a non-array-language reader. Preserve names at accounting, admission, exact-arithmetic, diagnostic, provenance, publication, and effect boundaries. Inside a bounded whole-array kernel, local mechanical names are optional and may disappear when composition makes the complete transformation easier to see.

Use comments to state what the expression cannot state by itself:

- an axis legend and input/output shape;
- canonical ordering and contributor alignment;
- fill, empty-cell, and missing-coordinate behavior;
- accounting invariants and exactness requirements;
- why a dense composition preserves the public contract.

Do not narrate glyphs line by line. Tests should protect observable values, ordering, provenance, diagnostics, and edge shapes rather than force a verbose implementation form.

Explicit staging remains appropriate for genuine effect sequencing, fail-closed source or request admission, exact-arithmetic operations and conversion of their failures into public diagnostics, identity construction, provenance assembly, publication buffering, or write safety. Detect an exact failure at the operation that can produce it; do not pretend it can always be admitted earlier. When guards dominate a pure owner, split a shallow capability boundary from the successful whole-array kernel instead of deleting public contract checks or burying the kernel. Avoid code golf that hides semantic axes, but do not reject density, trains, tacit composition, or classical APL-style idioms on familiarity grounds.

Treat the capability map as a memory refresh, not a glyph quota. Do not add capability audits, primitive quotas, or checklist files.

## Local agent Git protocol

Before changing repository files:

1. confirm the working tree is clean;
2. fetch the latest remote `main` and record its SHA;
3. inspect open pull requests and branches that may overlap the intended slice;
4. read the current cursor in `TODO.md`; during the checked review queue, work on exactly that owner and its necessary focused evidence or consumers;
5. create a dedicated branch from the verified current `main`.

During the slice:

- keep correctness changes, ownership refactors, algorithm refactors, UI changes, and documentation-only queue movement separate;
- start with a Draft pull request;
- do not begin the next checked queue item;
- do not edit canonical household or private data, and do not add a separate private data repository to the workspace;
- do not run parallel agents against the same checkout or overlapping repository slice.

Before marking a pull request Ready:

- run focused evidence;
- run `tools/check.sh`;
- run `tools/coverage`;
- inspect the complete diff against current `main`;
- confirm the branch is not behind `main`;
- confirm there are no unresolved review threads;
- record the result in Issue #407 when the work belongs to the checked review queue.

Never merge a pull request, delete its branch, update a queue checkbox, or advance the current cursor without explicit human authorization for that transition. A checked queue item is complete only after its final decision is merged, the owner is reread on current `main`, and a separate queue update is merged.

## Finish the work

Documentation cleanup is part of completing every task.

Before finishing:

- update descriptions that became stale because of the change;
- remove or shorten completed plans, obsolete instructions, and finished TODO notes;
- repair nearby links and examples when the work changes their meaning;
- leave the repository easier to understand than it was at the start.

Prefer deleting or summarizing stale material over adding another process document. Git history retains the longer story.

## Household data

Canonical household data and private user data belong to the user. Work with them under explicit human direction and keep private details out of public commits, issues, fixtures, and reports.

Repository code, documentation, public fixtures, tests, tools, and architecture are open to revision.

## Useful entrances

- `README.md` for running the project
- `docs/ARCHITECTURE.md` for the current data flow
- `docs/BQN_CAPABILITY_MAP.md` for complete BQN language recall before BQN code work
- `docs/BQN_SIMPLIFICATION.md` for array-native simplification rules
- `docs/AI_CODEMAP.md` for a code map
- `TODO.md` for current notes and open directions
- `tools/check.sh` for the project checks

Follow the evidence in the repository, exercise judgment, and tell moko what you notice.
