# AI Diff Self-review Pilot Plan

Status: active plan
Owner: workflow
Canonical: no; canonical process: docs/AI_WORKING_FEEDBACK_PROCESS.md
Exit: move to completed plans after the later Execution slice and one Review / Learning assessment, or mark superseded if current workflow policy already covers the exact rule before execution

## Target / purpose / current state

Target: classification ID 11, actual-diff-centered self-review.

Purpose: test one small workflow improvement without adding tooling or a measurement system.

Primary hypothesis:

```text
a short actual-diff self-review before first push / PR
may reduce later correction loops caused by scope mismatch
```

Current evidence:

- `docs/archive/audits/AI_WORKING_FEEDBACK_CLASSIFICATION-2026-07-04.md` records ID 11 as `git diff` Self-review, primarily workflow / information architecture.
- `AGENTS.md` already requires small, one-purpose changes and standardizes `rtk git status` / `rtk git diff` tool usage.
- The current rules do **not** yet mandate the exact structured final actual-diff review described below.
- PR #137 terminal review found one unrelated Daily Trend routing deletion and restored it before merge, which is concrete evidence that actual diff scope review can catch unrelated deletions.

## Planning decision

Approve only this selected improvement candidate for later Execution:

```text
short pre-push / pre-PR actual-diff self-review
```

Do not implement it in this Planning slice.

## Future rule owner

Chosen owner for the later rule: `AGENTS.md` work-completion / workflow rules.

Reason:

- The candidate is a pit workflow habit, not a runtime, test, report, or source-data contract.
- `AGENTS.md` already owns work-completion checks and command-wrapper usage.
- This plan must not create a second standing owner for AI workflow policy.

## Exact tiny Execution slice

Later Execution may edit only the workflow rule owner and lifecycle routing needed for this plan:

1. Add one short `AGENTS.md` completion rule requiring a pre-push / pre-PR actual-diff self-review.
2. Keep the review shape short:
   - intended scope;
   - actual changed filenames;
   - actual diff;
   - unrelated additions / deletions / restorations;
   - visible scope leakage or semantic side effects.

   `actual diff` means the full proposed change set against the intended base, including already-committed changes. The actual proposed change set is not only the current unstaged working-tree diff; the appropriate command may depend on state, such as working-tree diff, staged diff, or base...HEAD branch diff.
3. State that this is a human/pit self-review routine, not a new lint, parser, CI gate, permanent form, or metrics service.
4. After the observation window, record one Review / Learning result and retire this plan.

## Measurement definitions

Measurement is descriptive observation for this selected improvement only.

Primary observable: `post-first-push / post-PR scope-correction loop`.

Meaning: an extra correction commit or edit becomes necessary because the first pushed / proposed diff contained an unrelated change, accidental deletion, restoration loss, or other scope leakage that the selected self-review was intended to catch.

Secondary observable: `escaped unrelated-diff incident`.

Meaning: an unrelated changed file or unrelated changed hunk escapes the first self-review and is found later.

Positive learning signal: `pre-first-push / pre-PR intercepted scope-leak incident`.

Meaning: an unrelated changed file or hunk, accidental deletion, restoration loss, or other scope leakage is detected by the selected actual-diff self-review and corrected before the first push / PR. This is not a failure count; it is evidence that the selected review mechanism actually fired. Record it only when contemporaneous evidence exists, without retroactive guessing and without telemetry, a tracker, a database, or a permanent per-PR form.

Optional learning signal: `same-cause rediscovery`.

Meaning: the same diff-scope failure mode recurs after the improvement is introduced.

Exclusions:

- Do not count normal product-design changes as scope-correction loops.
- Do not count a reviewer changing the intended semantics as unrelated-diff failure.
- Do not use raw token count as the primary metric.
- Do not claim percentage token savings.
- Do not invent token estimates.
- Do not require token telemetry.

## Observation window

Observe the first 3 comparable finite AI-authored slices after later Execution.

Use descriptive notes only. Make no statistical claims. If 3 slices creates awkward lifecycle overhead, the later Review / Learning may close earlier with explicit rationale rather than adding infrastructure.

## Observation notes

### Comparable slice 1 of 3: Currency Stage 2 Slice B1 (PR #146)

- Comparable finite AI-authored slice: yes.
- PR creation: `2026-07-10T14:22:40Z`, after initial commit `f3207ed` and before correction commits `a4adf9c` and `e8287f0`.
- Primary descriptive signal: post-first-push / post-PR scope/safety correction loops occurred.
- Review finding 1: untagged invalid decimal/range row evidence could avoid the original proof disqualifiers; the final gate makes row error state independently disqualifying.
- Review finding 2: the first correction temporarily exported `BuildProjectionRowsForEvidence` and used it from a test without proof authorization; the final correction removed the export and restored the checked path.
- Green checks before the stronger review did not establish either stronger safety claim.
- No contemporaneous evidence records a pre-first-push / pre-PR intercepted scope-leak incident; both final corrections postdate PR creation.
- These are implementation/safety-boundary corrections, not unrelated changed-file incidents, so they are not classified as an `escaped unrelated-diff incident`.
- Causation: not established. Record only that post-PR actual-diff review exposed claim/evidence gaps.
- Window status: incomplete; do not perform final Review / Learning yet.
- Point-in-time evidence: `docs/archive/audits/CURRENCY_STAGE2_SLICE_B1_POST_IMPLEMENTATION_VERIFICATION-2026-07-10.md`.

### Comparable slice 2 of 3: Currency Stage 2 Slice B2 (PR #155)

- Comparable finite AI-authored slice: yes.
- PR #155 had one implementation commit: `395dd1fe69eddc6c8b7f644dc92e4c8d1fcf0050`.
- The PR recorded a pre-push full actual-diff self-review.
- No post-first-push correction commit is visible.
- No review thread or later scope correction is visible.
- No escaped unrelated changed file or hunk is visible.
- No contemporaneous evidence proves that a scope leak was intercepted before push.
- Do not claim causation, token savings, or statistical significance.
- Window status: **2 of 3 comparable slices observed; incomplete; no final Review / Learning assessment**.
- Point-in-time evidence: `docs/archive/audits/CURRENCY_STAGE2_SLICE_B2_POST_IMPLEMENTATION_VERIFICATION-2026-07-11.md`.

## Acceptance criteria

Planning slice acceptance:

- This active plan exists and selects only classification ID 11.
- The plan distinguishes existing `rtk git diff` usage and small-change rules from the proposed structured final actual-diff self-review.
- The future owner is `AGENTS.md`; no second workflow-policy owner is created.
- The future Execution slice is tiny and docs-only.
- Measurement definitions and exclusions are explicit.
- No workflow rule is executed or mandated by this Planning slice.

Later Execution acceptance:

- `AGENTS.md` gains one short pre-push / pre-PR actual-diff self-review rule.
- No runtime, BQN source, tests, checks, fixtures, source TSV, devtool, lint, CI, tracker, token telemetry, database, or global measurement framework is added.
- One later Review / Learning assessment records the descriptive outcome for the observation window.

## Non-goals

- New lint.
- New devtool.
- New diff parser.
- Guard registry.
- Global measurement framework.
- Token telemetry.
- Percentage token-saving claims.
- Permanent per-PR form.
- Autonomous improvement mandate.
- Runtime, report, currency, temporal, envelope, or source TSV work.
