# AI Working Improvement Plan

Status: completed review / mitigated selected scope
Owner: workflow
Canonical: yes; canonical path: docs/archive/completed-plans/AI_WORKING_IMPROVEMENT_PLAN-2026-07-09.md
Exit: closed after the approved docs-only execution slice and Review / Learning assessment

## Target / purpose / current state

Target: reduce recurring BQN-specific AI debugging friction without adding a new tool or a duplicate guide.

Purpose: extend the existing canonical BQN pitfalls section in `docs/CONVENTIONS.md` so pit has one current, narrow place to check for the two remaining recurring traps.

Current state:
- `docs/CONVENTIONS.md` owns the current BQN pitfalls section.
- `docs/archive/active-plans/AI_WORKING_FEEDBACK_LOG.md` contains repeated friction records.
- `docs/archive/audits/AI_WORKING_FEEDBACK_CLASSIFICATION-2026-07-04.md` classifies the relevant BQN traps.
- A standalone `BQN_CONVENTIONS_FOR_AI.md` would duplicate current knowledge ownership.
- PR #135 implemented the selected two-gap docs-only slice and merged it into `main`.

## Selected classification items

- ID 10 — BQN Homogenization / shape contract
- A2 — BQN precedence / function role gotchas
- A3 — BQN `⎊` catch scope

Selection note:
- A2 was already mostly covered by the existing pitfalls section, so this plan did **not** create a broader BQN tutorial.
- The approved slice only covered the two open gaps: Merge / stable element boundaries, and catch-safe argument usage.

## Concrete evidence

- Repeated feedback records showed the same BQN-debugging friction reappearing.
- `docs/CONVENTIONS.md` already covered role inference, `? ;` scope, `⍟`, immediate evaluation, right-associative function application, and Double Subjects.
- Planning probes established concrete examples for the selected hazards.
- Execution review refined the causal explanation before merge:
  - ordinary `⟨...⟩` list notation does not automatically merge equal-shaped arrays; the relevant boundary is Merge `>`, `[]`, or another compatible-cell combination boundary;
  - the `⎊` failure was not a blanket prohibition on outer variables; the relevant hazard was accidentally creating an immediate block outside the intended catch boundary.

## Root-cause hypothesis

The recurring friction was not a lack of tooling.
It was a missing narrow current-doc contract for BQN-specific hazards that kept being rediscovered during AI debugging.

The hypothesis was partially confirmed and refined:

1. stable element boundaries need deliberate treatment at Merge / compatible-cell combination boundaries;
2. `⎊` only catches errors produced while its left function is evaluated, so an accidentally immediate block can fail before entering the intended catch boundary.

A further Review / Learning result is:

```text
behavior verification
!=
mechanism verification
```

A snippet can execute as observed while the prose explaining *why* it behaves that way is still wrong.

## Planning decision

A. Approve the existing-CONVENTIONS extension as the Execution slice.

## Selected execution slice

The approved slice was:

1. Extend the existing `## BQN 実装上のはまりどころ (BQN pitfalls)` section in `docs/CONVENTIONS.md`.
2. Add one concise, verified pitfall for Merge / shape boundary behavior.
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

## Files authorized during execution

- `docs/CONVENTIONS.md`
- this plan file only if needed for lifecycle state
- `docs/archive/active-plans/README.md` only if needed for discoverability

## Files excluded during execution

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
- The new text is short, current, and scoped to AI debugging friction.
- `docs/CONVENTIONS.md` remains the canonical owner; no duplicate BQN guide is created.
- The tree remains free of runtime, test, check, fixture, and TSV changes for this execution slice.

## Execution result

PR #135:

```text
docs: add BQN shape and catch pitfalls
```

Final changed file:

```text
docs/CONVENTIONS.md
```

The final current-doc additions cover:

- Merge boundaries and stable element boundaries;
- `⎊`, immediate blocks, and deferred left-function evaluation.

No standalone guide, lint, devtool, runtime change, test change, check change, fixture change, or TSV change was introduced.

## Review / Learning outcome

Review date: 2026-07-09

Final status:

```text
mitigated
```

Why `mitigated`, not `resolved`:

- the selected knowledge-placement and ownership problem was addressed;
- `docs/CONVENTIONS.md` remains the single current owner;
- no duplicate guide or second policy surface was created;
- no new tool or lint was added;
- however, there is not yet post-implementation evidence that future AI token use or debugging round trips have measurably decreased.

Review findings:

1. The ownership strategy was correct.
   - Existing `docs/CONVENTIONS.md` was the right home.
   - A standalone BQN-for-AI guide would have duplicated knowledge ownership.

2. The root-cause model needed refinement during review.
   - The first shape explanation overstated ordinary list notation and was corrected to the actual Merge / `[]` boundary.
   - The first catch explanation overstated outer-variable scope and was corrected to the immediate-block versus deferred-function boundary.

3. Executable examples alone were insufficient evidence for causal prose.
   - Future BQN-specific documentation should distinguish observed behavior from mechanism explanation.
   - This does not authorize a new tool, lint, or broad policy by momentum.

4. No new material friction was introduced by the final merged slice.
   - The final examples are narrow.
   - The canonical owner remains singular.
   - Runtime and source data are unaffected.

## Closure decision

```text
selected BQN pitfalls docs slice -> mitigated
plan lifecycle -> completed
broader BQN tutorial -> not authorized
new lint / devtool -> not authorized
future repeated friction -> re-enter Intake with concrete evidence
```

The selected slice is closed. Future evidence that the same traps still cause repeated token-heavy rediscovery should return through `docs/archive/active-plans/AI_WORKING_FEEDBACK_LOG.md` rather than reopening this plan by momentum.
