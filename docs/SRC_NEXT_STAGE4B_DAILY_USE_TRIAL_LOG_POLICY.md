# src_next Stage 4b Daily-Use Trial Log Policy

Status: docs-only pretrial definition / no Stage 4b start / no implementation change / no production replacement / no production advice
Date: 2026-06-25

This document defines the private daily-use trial log location and public-safe summary rule for a future `src_next` Stage 4b daily-use trial.

Important:

- This document does **not** start Stage 4b.
- A separate explicit Stage 4b start decision is still required.
- This document does **not** change production default.
- Production default remains `bqn main.bqn`.
- `src_next` remains observation-only.
- This document does **not** create or commit any private log.

---

## 1. Private daily-use trial log path

If Stage 4b is explicitly started in the future, use this private log path for daily-use observation notes:

```text
private/src-next-stage4b/daily-use-trial-log.md
```

This path is defined as the Stage 4b daily-use trial log location for pretrial backlog item P0-5.

Requirements:

- The daily-use trial log is private-only.
- The log must not be committed.
- The log may contain production-specific observations only because it remains private.
- If the private log is accidentally staged, stop and unstage it before continuing.
- Defining this path does not create the file and does not start Stage 4b.

---

## 2. Public-safe summaries

Public summaries are allowed only as separate docs or PR text, not by publishing the private log.

A public-safe Stage 4b daily-use summary must follow all of these rules:

- no production amounts;
- no private log contents;
- no production advice;
- only status, classification, and guardrail summaries.

Allowed public-safe examples:

- Stage 4b started: yes/no, only if backed by a separate explicit start decision;
- production default: unchanged, `bqn main.bqn`;
- `src_next` role: observation-only;
- private log: exists/not staged/not committed;
- classification counts such as `bug/src_next = 0`, `unclassified = 0`, `requires-contract = 0`;
- guardrail status such as “no production data amounts included” or “unsupported fields were not used for decisions”.

Disallowed public content:

- actual household amounts;
- copied private daily notes;
- private comparison table contents;
- advice such as spending recommendations, envelope safety claims, or budget allocation recommendations;
- any statement that treats `src_next` as production default or production advice.

---

## 3. Relationship to Stage 4b start

This document is a docs-only pretrial clarification.

It satisfies only the location/visibility definition part of P0-5:

- daily-use trial log path: `private/src-next-stage4b/daily-use-trial-log.md`;
- daily-use trial log visibility: private-only;
- public summaries: allowed only under the public-safe summary rule above.

It does not satisfy the separate Stage 4b start decision requirement.

Before Stage 4b can start, a separate explicit start decision must still state that Stage 4b starts and must restate the observation-only terms required by `docs/SRC_NEXT_STAGE4B_PRETRIAL_BACKLOG.md`.

---

## 4. Related documents

- [SRC_NEXT_STAGE4B_PRETRIAL_BACKLOG.md](SRC_NEXT_STAGE4B_PRETRIAL_BACKLOG.md) — P0-5 backlog item that this document clarifies.
- [SRC_NEXT_STAGE4B_ENTRY_DECISION_RECORD.md](SRC_NEXT_STAGE4B_ENTRY_DECISION_RECORD.md) — current decision remains defer Stage 4b.
- [SRC_NEXT_STAGE4B_READINESS_GATE.md](SRC_NEXT_STAGE4B_READINESS_GATE.md) — Stage 4b readiness gate and operating rules.
- [SRC_NEXT_STAGE4B_TRIAL_SCOPE.md](SRC_NEXT_STAGE4B_TRIAL_SCOPE.md) — observation-only trial scope and prohibited advice usage.
- [SRC_NEXT_STAGE4_TRIAL_LOG.md](SRC_NEXT_STAGE4_TRIAL_LOG.md) — Stage 4 observation template and divergence log format.
- [SRC_NEXT_STAGE4B_THIRD_DRY_RUN_PLAN.md](SRC_NEXT_STAGE4B_THIRD_DRY_RUN_PLAN.md) — dry-run private log path, separate from this daily-use trial log.
- [SRC_NEXT_STAGE4B_THIRD_DRY_RUN_SUMMARY.md](SRC_NEXT_STAGE4B_THIRD_DRY_RUN_SUMMARY.md) — example of public-safe summary style.
