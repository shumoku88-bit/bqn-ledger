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

Do not expand a clear train, modifier composition, rank/cell expression, grouping pipeline, or structural transformation solely to make each mechanical step familiar to a non-array-language reader. Preserve names at accounting, admission, exact-arithmetic, diagnostic, provenance, publication, and effect boundaries. Inside a bounded pure kernel, local mechanical names are optional and may disappear when composition makes the complete transformation easier to see.

Use comments to state what the expression cannot state by itself:

- an axis legend and input/output shape;
- canonical ordering and contributor alignment;
- fill, empty-cell, and missing-coordinate behavior;
- accounting invariants and exactness requirements;
- why a dense composition preserves the public contract.

Do not narrate glyphs line by line. Tests should protect observable values, ordering, provenance, diagnostics, and edge shapes rather than force a verbose implementation form.

Explicit staging remains appropriate for genuine effect sequencing, fail-closed admission, dependent diagnostics, identity construction, provenance assembly, or write safety. It is not the default merely because a dense expression requires BQN fluency. Avoid code golf that hides semantic axes, but do not reject density, trains, tacit composition, or classical APL-style idioms on familiarity grounds.

Treat the capability map as a memory refresh, not a glyph quota. Do not add capability audits, primitive quotas, or checklist files.

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
