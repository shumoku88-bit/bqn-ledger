# src_next Stage 3 Entrypoint Contract

Status: **historical / superseded by `docs/SRC_NEXT_CURRENT.md`**

> Current daily operation uses `tools/bl`; non-interactive human reports use `tools/report` with `src_next/report.bqn`.
> `tools/report-next` remains only as a low-level diagnostic wrapper. This Stage 3 opt-in contract is migration history.
> See `docs/SRC_NEXT_CURRENT.md` and `docs/archive/audits/SRC_NEXT_DOCS_INVENTORY-2026-06-29.md`.

## 1. Purpose

Stage 3 introduced an explicit, opt-in way to run `src_next` while keeping `bqn main.bqn` as the trusted production default.

Currently `src_next` runs only as a direct prototype command (`bqn src_next/main.bqn data`). Stage 2 confirmed that all comparable fields match the current engine on production data. The next readiness step is to give users a stable, documented trial entrypoint that:

- Is explicitly opt-in.
- Cannot accidentally alter production output.
- Can eventually be used for Stage 4 daily-use trial without repeated direct-path invocation.

This document defines that contract. It **does not implement** the entrypoint.

## 2. Non-goals

- **Do not switch the production default.** `bqn main.bqn` remains the trusted path.
- **Do not change `bqn main.bqn` behavior.** No new flags, no argument handling changes.
- **Do not change TSV formats.**
- **Do not change production data.**
- **Do not remove the current engine.**
- **Do not wire `src_next` comparison helper into `tools/check.sh` yet.** Stage 3 entrypoint is a trial path, not a mandatory check.
- **Do not claim `src_next` is production-ready.**
- **Do not implement food/daily/safe/allocated remaining work in this PR.**

## 3. Entrypoint options considered

### Option A: `tools/report-next`

A standalone wrapper script that runs `src_next` explicitly.

**Pros:**

- Clear opt-in command.
- Does not change `bqn main.bqn`.
- Easy to delete or change later without affecting production.
- Fits the current migration stage well.

**Cons:**

- Adds another top-level helper file.
- Needs documentation so users know it is experimental.

### Option B: `bqn main.bqn --engine next`

Add an `--engine` flag to the production entrypoint.

**Pros:**

- One unified command shape.
- Could eventually become a clean engine selector at Stage 5.

**Cons:**

- Requires changing production entrypoint argument handling.
- Higher risk because `main.bqn` is the trusted production path.
- More likely to blur the boundary between current production and `src_next`.
- A bug in the flag parsing could break the production report.

### Option C: continue direct command only: `bqn src_next/main.bqn data`

No new entrypoint; keep using the prototype invocation directly.

**Pros:**

- No new files.
- Already works and is tested.

**Cons:**

- Not user-facing enough for Stage 3.
- Keeps the prototype path exposed as an internal command.
- Does not create a stable trial entrypoint for Stage 4 daily-use trial.

## 4. Recommended decision

**Recommend: `tools/report-next`**

Rationale:

- It is explicit and opt-in.
- It avoids changing `bqn main.bqn`.
- It keeps current production behavior untouched.
- It gives Stage 4 daily-use trial a stable command to run.
- It can internally call `bqn src_next/main.bqn data` at first.
- A simple wrapper is easy to understand, audit, and replace later.

**Important:** This PR only records the recommendation. It does **not** implement `tools/report-next`.

## 5. Contract for future implementation PR

When a future PR implements the Stage 3 entrypoint, it must obey these rules:

### Read-only

- `tools/report-next` must be read-only.
- It must not edit TSV files.
- It must not edit generated golden outputs.

### No production interference

- It must not replace `main.bqn`.
- It must not change `bqn main.bqn` behavior.
- It must not be called by `tools/check.sh` unless a later explicit decision is made.

### Explicit src_next path

- It must call the `src_next` path explicitly.
- It should fail closed on command errors.

### User-facing clarity

- It should print or preserve `src_next` output without pretending it is the current production report.
- It should be documented as experimental / shadow / opt-in.

### Minimal scope

- The initial implementation may simply wrap `bqn src_next/main.bqn <data-dir>`.
- No new exporters, report sections, or formatting are required.
- No food/daily/safe/allocated remaining work.

## 5a. Implementation note

`tools/report-next` was implemented as the Stage 3 opt-in wrapper on 2026-06-24.
It remains experimental and does not change `bqn main.bqn`.

## 6. Readiness checklist impact

After `tools/report-next` is implemented, Stage 3 in
`docs/SRC_NEXT_REPLACEMENT_READINESS.md` is complete.

This only means an explicit opt-in entrypoint exists.

It does not mean:
- `src_next` is production-ready.
- `bqn main.bqn` has changed.
- Stage 4 daily-use trial has started.
- Stage 5 default switch is allowed.

## 7. Verification

```sh
bash tools/check.sh
```

Expected: all checks pass. No new behavior, no new failures.

## 8. Related documents

- `docs/SRC_NEXT_REPLACEMENT_READINESS.md` — Stage gate checklist (this document feeds into Stage 3).
- `docs/SRC_NEXT_CURRENT_ENGINE_COMPARISON.md` — comparison notes and difference classification (Stage 2 prerequisite).
- `docs/CURRENT_STATE_REFERENCE.md` — current engine baseline and `src_next` baseline info.
