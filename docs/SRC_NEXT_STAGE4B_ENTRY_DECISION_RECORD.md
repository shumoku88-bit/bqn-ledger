# src_next Stage 4b Entry Decision Record

Status: **Stage 4b started**
Date: 2026-06-25
Previous decision: defer Stage 4b
New decision: start Stage 4b daily-use trial

This document records the explicit decision to start `src_next` Stage 4b daily-use trial.

---

## 1. Decision

**Decision: Start Stage 4b daily-use trial.**

Stage 4b daily-use trial is explicitly opened.

---

## 2. Rationale

All P0 pretrial backlog items are satisfied:

| P0 | Condition | Status |
|:---|:---|:---|
| P0-1 | bug/src_next = 0 | ✅ confirmed in production comparison |
| P0-2 | unclassified = 0 | ✅ confirmed in production comparison |
| P0-3 | requires-contract = 0 | ✅ confirmed in production comparison |
| P0-4 | explicit start decision | ✅ this document |
| P0-5 | trial log location defined | ✅ `private/src-next-stage4b/daily-use-trial-log.md` |
| P0-6 | observation-only terms restated | ✅ below |
| P0-7 | src_next must not edit data/*.tsv | ✅ read-only maintained |
| P0-8 | unsupported/unavailable not for decisions | ✅ confirmed |
| P0-9 | production default remains current engine | ✅ `bqn main.bqn` unchanged |
| P0-10 | public-safe documentation only | ✅ no production amounts committed |

Gate A (production data comparison recorded) and Gate B (manual comparison executed) are satisfied.
See `private/src-next-validation/validation-log.md` for the full comparison record.

Production comparison result:
- match: 8 areas
- expected/current-engine-difference: 2 areas
- unsupported/src_next: 3 areas
- unavailable: 1 area
- bug/src_next: 0
- unclassified: 0
- requires-contract: 0

---

## 3. Observation-Only Terms (restated per P0-6)

- `src_next` output is **observation-only**.
- `src_next` output is **not production advice**.
- Household decisions use `bqn main.bqn` output, not `src_next` output.
- `src_next` envelope values remain `unavailable/src_next` in production route.
- Unsupported / unavailable fields must not be used for life decisions.
- `src_next` must not edit `data/*.tsv`.
- Production default remains `bqn main.bqn`.

---

## 4. Trial Scope

Per `docs/SRC_NEXT_STAGE4B_TRIAL_SCOPE.md`:

**Allowed observation areas:** cycle boundary, actual totals, account balances, unknown accounts, envelope production guard status, next income, plan totals baseline, plan totals export semantics, remaining days, actual comparison.

**Prohibited:** envelope advice, budget advice, daily_amount decisions, safe_remaining decisions, outlook advice, production replacement.

---

## 5. Trial Period

Target cycle: 2026-06-15 .. 2026-08-14 (current cycle)
Start date: 2026-06-25
Daily-use trial log: `private/src-next-stage4b/daily-use-trial-log.md`

---

## 6. Stop / Rollback Criteria

Per `docs/SRC_NEXT_STAGE4B_READINESS_GATE.md` §7. Any of the 7 stop conditions triggers immediate halt and return to `bqn main.bqn` for household decisions.

---

## 7. Related Documents

- `private/src-next-stage4b/daily-use-trial-log.md` — Stage 4b daily-use trial log
- `private/src-next-validation/validation-log.md` — Pre-trial production comparison record
- [SRC_NEXT_STAGE4B_READINESS_GATE.md](SRC_NEXT_STAGE4B_READINESS_GATE.md)
- [SRC_NEXT_STAGE4B_TRIAL_SCOPE.md](SRC_NEXT_STAGE4B_TRIAL_SCOPE.md)
- [SRC_NEXT_STAGE4B_PRETRIAL_BACKLOG.md](SRC_NEXT_STAGE4B_PRETRIAL_BACKLOG.md)
