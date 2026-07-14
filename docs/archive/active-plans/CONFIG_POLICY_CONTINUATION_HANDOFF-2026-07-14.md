# Config policy continuation handoff — 2026-07-14

Status: active plan / continuation handoff
Owner: config / ledger policy
Canonical: no; current contracts and completed decisions are linked below
Exit: after the next jointly chosen policy decision is recorded, move this handoff to completed plans or replace it with a short historical pointer

## Purpose

Allow the next session to resume from the repository alone without reconstructing the 2026-07-14 conversation.

This handoff selects the next **discussion**, not a runtime implementation. `TODO.md` remains the finite-work selector.

## Completed sequence

The following slices are complete on `main`:

1. **PR #248 — personal/profile hardcode inventory**
   - classified literals as externalize-next, profile-bound, keep-fixed, quarantine, or fixture/example;
   - selected no runtime work by itself.
2. **PR #250 — Outlook presentation literal extraction**
   - moved remaining human-facing Outlook labels/separators into `config/report_labels.tsv`;
   - preserved existing human output and left calculation, ViewModel, machine output, JSON, and source data unchanged.
3. **PR #251 — explicit `POLICY_BUDGET_STYLE` decision**
   - envelope budgeting is optional and reversible;
   - new ledgers must explicitly choose `envelope` or `none`;
   - the current missing-key `envelope` fallback remains only as a temporary compatibility bridge;
   - switching to `none` must not delete or rewrite historical/source evidence.
4. **PR #252 — budget-style compatibility audit and enforcement**
   - scanned 78 public ledger-like roots;
   - final config classification is 19 explicit configs and 3 intentional missing/empty exceptions;
   - 56 legacy technical roots without local `config.tsv` were not mass-populated because adding a local config can change effective-resolution behavior;
   - the README Quick Start demo now explicitly chooses `envelope`;
   - full `tools/check.sh`, coverage, explicit-policy audit, and demo snapshot passed.

## Current budget-style contract

Read these as the current rationale and evidence:

- `docs/archive/completed-plans/POLICY_BUDGET_STYLE_EXPLICIT_CHOICE_DECISION-2026-07-14.md`
- `docs/archive/completed-plans/POLICY_BUDGET_STYLE_COMPATIBILITY_AUDIT-2026-07-14.md`
- `checks/audit-budget-style-explicit.sh`
- `docs/DATA_DIR_SETUP.md`

Current runtime compatibility remains:

```text
POLICY_BUDGET_STYLE missing
-> warning + envelope fallback
```

Target behavior is fail-closed, but the runtime migration is **not selected**. Do not remove the fallback automatically in the next session.

## Next session starting point

Continue with `POLICY_RISK_STYLE`, beginning with a joint meaning/ownership decision rather than code changes.

Current implementation in `src_next/config.bqn` accepts:

```text
POLICY_RISK_STYLE=conservative
POLICY_RISK_STYLE=simple
```

Current missing behavior is:

```text
missing -> warning + conservative fallback
```

The older profile-schema description says:

- `conservative`: reserve fixed expenses and `fixed_obligation` before calculating the daily amount;
- `simple`: divide liquid assets by remaining days without that fixed reserve.

Read first:

1. this handoff;
2. `src_next/config.bqn`, especially `PolicyRiskStyle`;
3. `config/default_config.tsv` and representative explicit profile configs;
4. `tests/test_src_next_config.bqn`;
5. `docs/archive/completed-plans/HOUSEHOLD_POLICY_PROFILE_SCHEMA.md`;
6. the two-style household proof/fixtures before assuming both names and semantics are still ideal.

## Questions to decide together

Do not answer these by inference alone:

1. Is risk style genuinely a ledger-owner choice, or an engine safety rule?
2. Is `conservative` a legitimate universal fallback, or does it silently choose a household-management philosophy?
3. Are the names `conservative` and `simple` accurate, or do they mix algorithm description with value judgment?
4. Should new ledgers explicitly choose a risk style, as with budget style?
5. If explicit choice becomes the target, what compatibility path preserves older ledgers and focused negative fixtures?
6. Does switching risk style affect only derived reports/diagnostics, with no source-data rewrite?
7. Are there enough current consumers and contrasting fixtures to justify keeping two styles unchanged?

## Recommended next finite slice

The first output of the next session should be a **docs-only decision record** for `POLICY_RISK_STYLE`.

That record should choose among at least these broad outcomes:

- keep the current conservative fallback as a justified engine default;
- make the policy eventually required-explicit through a compatibility transition;
- revise the names or semantic boundary before deciding missing behavior;
- park the question because current evidence is insufficient.

Only after that decision should a separate finite implementation or compatibility-audit slice be selected.

## Do not auto-start

- do not change `PolicyRiskStyle` runtime behavior;
- do not remove either policy value;
- do not rename config values or machine fields;
- do not edit private/live configuration;
- do not mass-add config files to legacy technical fixtures;
- do not remove the `POLICY_BUDGET_STYLE` fallback;
- do not resume Israel candidate 6, strict-source Steps 2–5, M4, the AI context-bundle route, or Observatory work merely because they remain listed elsewhere.

## Resume phrase

A future session can begin with:

```text
Read NEXT_SESSION.md and the linked config-policy handoff. Continue by helping me decide POLICY_RISK_STYLE. Do not implement it before we agree on the policy decision.
```
