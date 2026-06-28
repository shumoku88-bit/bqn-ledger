# src_next Stage 4b Pretrial Backlog

Status: docs-only backlog / no Stage 4b start / no implementation change / no production replacement / no production advice
Branch: `docs-src-next-stage4b-pretrial-backlog`
Date: 2026-06-25

This document records the public-safe backlog that must be clarified, reduced, or explicitly accepted before `src_next` Stage 4b daily-use trial can be opened.

Important:

- This backlog does **not** start Stage 4b.
- This backlog does **not** change production default.
- Production default remains `bqn main.bqn`.
- `src_next` remains observation-only.
- This backlog does **not** introduce production advice.

---

## 1. Status

| Item | Status |
|:---|:---|
| Backlog type | docs-only backlog |
| Stage 4b | not started |
| Implementation change | none |
| Production replacement | none |
| Production advice | none |
| Production default | unchanged: `bqn main.bqn` |
| `src_next` role | observation-only |

---

## 2. Purpose

This backlog exists to:

- Record remaining pretrial work before Stage 4b can be explicitly opened.
- Separate blockers, caution items, accepted known differences, and out-of-scope areas.
- Avoid using unsupported or unavailable `src_next` output for life decisions.
- Keep public documentation free of production data amounts and private comparison logs.

---

## 3. Non-goals

This document does not:

- Start Stage 4b.
- Replace the current engine.
- Change `bqn main.bqn` as production default.
- Edit production data.
- Modify `data/*.tsv`.
- Implement missing fields.
- Implement `safe_remaining`, `daily_amount`, outlook, envelope advice, budget advice, or production advice.
- Modify BQN implementation.
- Modify fixtures.
- Modify check scripts.
- Commit private comparison logs.
- Create production advice.

---

## 4. Backlog categories

| Category | Meaning |
|:---|:---|
| P0: must resolve before Stage 4b can start | Blocking pretrial item. Stage 4b must not open until resolved or explicitly satisfied. |
| P1: should clarify before Stage 4b if possible | Caution item. Prefer to clarify before opening Stage 4b, but may be explicitly accepted as non-blocking. |
| P2: can remain out of scope during Stage 4b | Not required for Stage 4b daily-use observation. Must stay excluded and not be used for decisions. |
| Accepted known difference | Already classified difference that is not a blocker by itself while classification remains valid. |
| Guardrail | Rule that prevents misuse of `src_next` observation output. |

---

## 5. P0: must resolve before Stage 4b can start

| # | Item | Required state before Stage 4b |
|:---|:---|:---|
| P0-1 | No `bug/src_next` | Latest comparison record has `bug/src_next = 0`. |
| P0-2 | No `unclassified` differences | Latest comparison record has `unclassified = 0`. |
| P0-3 | No `requires-contract` differences | Latest comparison record has `requires-contract = 0`. |
| P0-4 | Entry decision must explicitly change from defer to start | `docs/SRC_NEXT_STAGE4B_ENTRY_DECISION_RECORD.md` or a later decision record must explicitly say Stage 4b starts. Current decision remains defer. |
| P0-5 | Trial log location must be defined | **Defined docs-only** in `docs/SRC_NEXT_STAGE4B_DAILY_USE_TRIAL_LOG_POLICY.md`: the future daily-use trial log path is `private/src-next-stage4b/daily-use-trial-log.md`; the daily log is private-only; public summaries are allowed only under the public-safe summary rule. This does not start Stage 4b. |
| P0-6 | Observation-only terms must be restated at trial start | The start decision must restate that `src_next` is observation-only and not production advice. |
| P0-7 | `src_next` must not edit `data/*.tsv` | Read-only behavior must remain a hard guardrail. |
| P0-8 | Unsupported / unavailable fields must not be used for life decisions | Any missing, unsupported, or unavailable output must stay excluded from household decisions. |
| P0-9 | Production default remains current engine | `bqn main.bqn` remains production default. |
| P0-10 | Public-safe documentation only | No production data amounts and no private comparison logs are committed. |

---

## 6. P1: should clarify before Stage 4b if possible

| # | Item | Clarification needed |
|:---|:---|:---|
| P1-1 | Unavailable-area handling | Clarify whether unavailable areas need observation substitutes or should remain excluded. |
| P1-2 | Additional dry runs | A third manual comparison dry run was completed privately and summarized publicly in `docs/SRC_NEXT_STAGE4B_THIRD_DRY_RUN_SUMMARY.md`; additional dry runs beyond that remain a separate decision. |
| P1-3 | Third dry run procedure | The third dry run procedure is defined by `docs/SRC_NEXT_STAGE4B_THIRD_DRY_RUN_PLAN.md` and uses the existing manual comparison procedure and record template. The completed third dry run summary preserves the 14-area structure. |
| P1-4 | Recurring expected differences | Clarify how to record recurring `expected/current-engine-difference` entries without creating log noise. |
| P1-5 | Daily log visibility | **Clarified** in `docs/SRC_NEXT_STAGE4B_DAILY_USE_TRIAL_LOG_POLICY.md`: the daily log is private-only; separate public summaries may include only status/classification/guardrail summaries with no production amounts, no private log contents, and no production advice. |

P1 items should be resolved if practical. If not resolved, the Stage 4b start decision must explicitly accept them as non-blocking.

---

## 7. P2 / out-of-scope during Stage 4b

The following areas can remain out of scope during Stage 4b and must not be used as daily-use decision inputs:

| Area | Stage 4b handling |
|:---|:---|
| budget totals | out of scope |
| skipped rows | out of scope |
| valid row count | out of scope |
| `actual_comparison` | out of scope |
| `net_worth` | out of scope |
| `daily_remaining` | out of scope |
| envelopes | out of scope |
| `daily_amount` | out of scope / not implemented |
| `safe_remaining` | out of scope / not implemented |
| outlook | out of scope / not implemented |
| envelope advice | prohibited |
| budget advice | prohibited |
| production advice | prohibited |

These exclusions are not permission to fill missing values by assumption.

---

## 8. Accepted known differences

The following differences are not blockers by themselves **only if** they remain classified as `expected/current-engine-difference`:

| Difference | Accepted condition |
|:---|:---|
| `as_of` difference | Remains classified as `expected/current-engine-difference`. |
| `remaining_days` difference derived from `as_of` | Remains classified as `expected/current-engine-difference`. |
| plan boundary / export semantics difference | Remains classified as `expected/current-engine-difference`. |
| `cycle_end_exclusive` plan rows excluded from `src_next` current cycle by half-open interval semantics | Remains classified as `expected/current-engine-difference`. |

If any of these become unexplained, inconsistent, or no longer fit the existing classification, progress pauses until reclassified.

---

## 9. Guardrails

- Current engine remains the production reference.
- Household decisions use current engine output, not `src_next` observation output.
- `src_next` output must not be treated as advice.
- Unsupported / unavailable output must not be filled in by assumption.
- Private comparison logs remain private.
- Public docs must not include production data amounts.
- Any new unexplained mismatch pauses progress.
- `src_next` must not edit `data/*.tsv`.
- Production default remains `bqn main.bqn`.
- Stage 4b cannot start without a separate explicit start decision.

---

## 10. Exit criteria for this backlog

This pretrial backlog is ready when:

- P0 items are resolved or explicitly satisfied.
- P1 items are either resolved or explicitly accepted as non-blocking.
- P2 items are explicitly excluded from Stage 4b scope.
- Accepted known differences remain classified as `expected/current-engine-difference`.
- Public docs contain no production data amounts.
- Private comparison logs are not committed.
- A separate Stage 4b start decision record is created if and only if Stage 4b is actually opened.

---

## 11. Current decision

Current decision: **Stage 4b started (2026-06-25)**.

Entry decision record: `docs/SRC_NEXT_STAGE4B_ENTRY_DECISION_RECORD.md`.
Stage 4b daily-use trial is active. Production default remains `bqn main.bqn`. `src_next` remains observation-only.

---

## 12. Related documents

- [SRC_NEXT_STAGE4B_DAILY_USE_TRIAL_LOG_POLICY.md](SRC_NEXT_STAGE4B_DAILY_USE_TRIAL_LOG_POLICY.md)
- [SRC_NEXT_STAGE4B_ENTRY_DECISION_RECORD.md](SRC_NEXT_STAGE4B_ENTRY_DECISION_RECORD.md)
- [SRC_NEXT_STAGE4B_THIRD_DRY_RUN_PLAN.md](SRC_NEXT_STAGE4B_THIRD_DRY_RUN_PLAN.md)
- [SRC_NEXT_STAGE4B_THIRD_DRY_RUN_SUMMARY.md](SRC_NEXT_STAGE4B_THIRD_DRY_RUN_SUMMARY.md)
- [SRC_NEXT_STAGE4B_TRIAL_SCOPE.md](SRC_NEXT_STAGE4B_TRIAL_SCOPE.md)
- [SRC_NEXT_STAGE4B_READINESS_GATE.md](SRC_NEXT_STAGE4B_READINESS_GATE.md)
- [SRC_NEXT_SNAPSHOT_EQUIVALENCE_CRITERIA.md](SRC_NEXT_SNAPSHOT_EQUIVALENCE_CRITERIA.md)
- [SRC_NEXT_MANUAL_COMPARISON_PROCEDURE.md](SRC_NEXT_MANUAL_COMPARISON_PROCEDURE.md)
- [SRC_NEXT_COMPARISON_RECORD_TEMPLATE.md](SRC_NEXT_COMPARISON_RECORD_TEMPLATE.md)
