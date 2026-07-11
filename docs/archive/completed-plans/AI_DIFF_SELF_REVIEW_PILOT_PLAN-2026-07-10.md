# AI Diff Self-review Pilot Plan

Status: completed Review / Learning
Owner: workflow
Canonical: no; canonical process remains `docs/AI_WORKING_FEEDBACK_PROCESS.md`, and the retained workflow rule remains in `AGENTS.md`
Completed: 2026-07-11
Exit result: retain the small pre-push / pre-PR actual-diff review rule; do not expand it into tooling or measurement infrastructure

## Target and purpose

Target: classification ID 11, actual-diff-centered self-review.

Primary hypothesis:

```text
a short actual-diff self-review before first push / PR
may reduce later correction loops caused by scope mismatch
```

The pilot tested one small workflow habit without adding lint, telemetry, a tracker, a parser, a permanent form, or a metrics service.

## Selected rule

The retained rule owner is `AGENTS.md`.

The review remains short and checks:

- intended scope;
- actual changed filenames;
- the complete proposed diff against the intended base;
- unrelated additions, deletions, or restorations;
- visible scope leakage or semantic side effects.

`actual diff` is not limited to the unstaged working tree. Depending on repository state, it may require working-tree, staged, and `base...HEAD` views.

## Descriptive observables

Primary observable: `post-first-push / post-PR scope-correction loop`.

Secondary observable: `escaped unrelated-diff incident`.

Positive learning signal: `pre-first-push / pre-PR intercepted scope-leak incident`, recorded only when contemporaneous evidence exists.

Exclusions:

- normal product-design changes are not scope-correction loops;
- reviewer-requested semantic changes are not automatically unrelated-diff failures;
- raw token count is not a primary metric;
- no percentage token-savings claim;
- no invented token estimate;
- no causation or statistical claim from three observations.

## Comparable slice 1 of 3: Currency Stage 2 Slice B1

Implementation: PR #146.

Observed:

- post-first-push / post-PR implementation and safety correction loops occurred;
- one correction made row error state independently disqualifying after untagged invalid decimal/range evidence could avoid the original predicates;
- another correction removed a temporarily exported unchecked posting helper and restored the checked path;
- green output assertions had not established the stronger safety claims;
- no contemporaneous evidence proves a pre-first-push intercepted scope leak;
- the corrections were semantic/safety-boundary corrections, not unrelated-file incidents.

Point-in-time evidence: `docs/archive/audits/CURRENCY_STAGE2_SLICE_B1_POST_IMPLEMENTATION_VERIFICATION-2026-07-10.md`.

## Comparable slice 2 of 3: Currency Stage 2 Slice B2

Implementation: PR #155, implementation commit `395dd1fe69eddc6c8b7f644dc92e4c8d1fcf0050`.

Observed:

- the PR recorded a pre-push full actual-diff self-review;
- no post-first-push correction commit is visible;
- no review thread or later scope correction is visible;
- no escaped unrelated changed file or hunk is visible;
- no contemporaneous evidence proves that a scope leak was intercepted before push;
- no causation, token-savings, or statistical claim is supported.

Point-in-time evidence: `docs/archive/audits/CURRENCY_STAGE2_SLICE_B2_POST_IMPLEMENTATION_VERIFICATION-2026-07-11.md`.

## Comparable slice 3 of 3: Currency Stage 2 Slice B3

Runtime lineage:

```text
b0097e2  initial B3 implementation
12a9f4e  correction pass
58514f1  final focused diff
```

Observed:

- the initial implementation was followed by a correction pass that removed stale proof constructors and a redundant failure gate;
- negative proof tests were rewritten so each case isolates the field it claims to test;
- a constant-only length assertion was replaced with runtime and structural guard evidence;
- full-context fixture assertions were strengthened through signed posting totals and TBDS movements;
- the final focus pass removed an unrelated feedback-log hunk from the runtime diff while preserving that feedback for a separate docs-only change;
- the final B3 diff contains exactly eight intended paths;
- no contemporaneous evidence proves the corrections happened before first push;
- no B3 PR exists, so no post-PR timing claim is possible;
- direct-main integration bypassed the intended PR review and PR-triggered CI lane.

Classification:

- correction loops occurred after the initial implementation commit;
- the feedback-log hunk is an escaped unrelated-diff incident within the initial runtime change and was corrected by the final focus pass;
- a pre-first-push intercepted signal is not established;
- the direct-main route is a separate workflow-process deviation.

Point-in-time evidence: `docs/archive/audits/CURRENCY_STAGE2_SLICE_B3_POST_IMPLEMENTATION_VERIFICATION-2026-07-11.md`.

## Final Review / Learning

Observation window:

```text
B1 -> semantic and safety-boundary correction loops
B2 -> no visible correction loop or escaped unrelated diff
B3 -> correction pass plus unrelated-doc removal; no PR boundary
```

Decision:

```text
selected small rule -> retain
finite pilot -> complete and retire
new lint / parser / tracker / telemetry / metrics service -> reject
statistical or token-efficiency conclusion -> not supported
```

Learning:

1. The short actual-diff review is useful for changed-file and hunk scope. B3 provides concrete evidence that it can separate valid feedback from a one-purpose runtime diff.
2. The review does not prove semantic correctness. B1 and B3 still required claim-to-evidence inspection of ownership, failure paths, authorization, and test meaning.
3. The rule should remain a compact human/pit habit in `AGENTS.md`, not become a new tool or permanent reporting system.
4. PR and CI discipline is independent. A focused final diff does not compensate for bypassing the review and PR-triggered check lane.

The pilot is closed as **completed; retain the existing small rule without expansion**.

## Non-goals retained

- new lint;
- new devtool;
- new diff parser;
- guard registry;
- global measurement framework;
- token telemetry;
- percentage token-saving claims;
- permanent per-PR form;
- autonomous improvement mandate;
- runtime, report, currency, temporal, envelope, or source TSV work.
