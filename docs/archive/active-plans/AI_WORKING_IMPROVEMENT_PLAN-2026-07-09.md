# AI Working Improvement Plan

Status: active plan / docs-only
Owner: workflow
Canonical: yes; canonical path: docs/archive/active-plans/AI_WORKING_IMPROVEMENT_PLAN-2026-07-09.md
Exit: hand off to Execution only after the smallest docs-only slice is approved; archive or supersede after the later implementation/review loop finishes

## Target / purpose / current state

Target: reduce recurring BQN-specific AI debugging friction without adding a new tool or a duplicate guide.

Purpose: extend the existing canonical BQN pitfalls section in `docs/CONVENTIONS.md` so pit has one current, narrow place to check for the two remaining recurring traps.

Current state:
- `docs/CONVENTIONS.md` already owns the current BQN pitfalls section.
- `docs/archive/active-plans/AI_WORKING_FEEDBACK_LOG.md` contains repeated friction records.
- `docs/archive/audits/AI_WORKING_FEEDBACK_CLASSIFICATION-2026-07-04.md` already classifies the relevant BQN traps.
- A standalone `BQN_CONVENTIONS_FOR_AI.md` would duplicate current knowledge ownership.

## Selected classification items

- ID 10 — BQN Homogenization / shape contract
- A2 — BQN precedence / function role gotchas
- A3 — BQN `⎊` catch scope

Selection note:
- A2 is already mostly covered by the existing pitfalls section, so this plan does **not** create a broader BQN tutorial.
- This plan only authorizes the smallest extension needed for the two still-open gaps: homogenization / stable boundaries, and catch-safe argument usage.

## Concrete evidence

- Repeated feedback records show the same BQN-debugging friction reappearing.
- `docs/CONVENTIONS.md` already covers role inference, `? ;` scope, `⍟`, immediate evaluation, right-associative function application, and Double Subjects.
- Current-tree probes verified the safe idioms we want to keep:
  - `outer←⟨⟩ ⋄ •Out •Fmt ({1⊑𝕩}⎊{0}) outer` returns `0`.
  - `outer←⟨⟩ ⋄ •Out •Fmt ({1⊑outer}⎊{0}) 123` escapes the intended catch boundary and errors.
  - `bqn-dump '⟨<"OK", <"WARN"⟩'` reports a boxed list with stable element boundaries.
  - `bqn-dump '⟨<"OK", <"OK"⟩'` shows the same stable boxed-list shape.
  - `•Out •Fmt >0⊏⟨<"OK", <"WARN"⟩` prints `"OK"`.

## Root-cause hypothesis

The recurring friction is not a lack of tooling.
It is a missing narrow current-doc contract for two BQN-specific hazards that keep being rediscovered during AI debugging:

1. stable element boundaries are easy to lose unless boxed explicitly when collection shape may vary;
2. `⎊` only helps when the left operand is a real function of `𝕩`, not when the body silently depends on outer lexical state or gets evaluated too early.

## Planning decision

A. Approve the existing-CONVENTIONS extension as the next Execution slice.

## Selected smallest execution slice

Authorize only this next slice:

1. Extend the existing `## BQN 実装上のはまりどころ (BQN pitfalls)` section in `docs/CONVENTIONS.md`.
2. Add one concise, verified pitfall for homogenization / shape instability.
3. Add one concise, verified pitfall for `⎊` catch-safe argument usage.
4. Use minimal bad/good examples.
5. Prefer safe idioms over broad language tutorial text.
6. Keep `docs/CONVENTIONS.md` as the single current owner; do not create a new standalone BQN guide.
7. Do not introduce a new lint rule or devtool.
8. Do not change runtime code, tests, checks, or TSV data.

## Non-goals

- No implementation of new BQN runtime behavior.
- No check script changes.
- No fixture changes.
- No source TSV changes.
- No new devtool.
- No broad BQN language tutorial.
- No AGENTS.md rewrite.
- No TODO.md routing rewrite for this slice.
- No new standalone `BQN_CONVENTIONS_FOR_AI.md`.

## Files that may be touched

- `docs/CONVENTIONS.md`
- `docs/archive/active-plans/AI_WORKING_IMPROVEMENT_PLAN-2026-07-09.md`
- `docs/archive/active-plans/README.md` (only if the inventory is updated for discoverability)

## Files that must not be touched

- `AGENTS.md`
- `TODO.md`
- `docs/AI_WORKING_FEEDBACK_PROCESS.md`
- `docs/archive/active-plans/AI_WORKING_FEEDBACK_LOG.md`
- `docs/archive/audits/AI_WORKING_FEEDBACK_CLASSIFICATION-2026-07-04.md`
- `docs/archive/completed-plans/DECISION_AI_DEVELOPMENT_EFFICIENCY_PROPOSALS.md`
- any `src_next/` code
- any `tests/` file
- any `checks/` file
- any source TSV (`journal.tsv`, `plan.tsv`, `budget_alloc.tsv`, `accounts.tsv`)

## Acceptance criteria

- `docs/CONVENTIONS.md` gains exactly the two narrow BQN pitfall additions.
- The new text is short, current, and clearly scoped to AI debugging friction.
- The document keeps `docs/CONVENTIONS.md` as the canonical owner; no duplicate BQN guide is created.
- Any optional inventory change stays docs-only.
- The tree remains free of runtime, test, and TSV changes.

## Recommended checks

- `rtk bash ./tools/check.sh`
- `rtk git diff`
- `rtk git status --short --branch`

## Handoff draft for later Execution stage

Read this plan, then make the smallest docs-only change set:

- open `docs/CONVENTIONS.md`
- add one short pitfall note for homogenization / stable boundaries with Enclose/Disclose
- add one short pitfall note for `⎊` catch-safe `𝕩` usage
- keep examples tiny and verified
- do not add a new guide, tool, test, or check
- if the inventory file is updated, keep it to a single line entry
- finish by running `rtk bash ./tools/check.sh` and checking `rtk git diff`
