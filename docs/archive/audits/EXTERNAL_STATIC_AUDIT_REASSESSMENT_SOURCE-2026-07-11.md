# External Static Audit Reassessment Source

Status: audit snapshot
Owner: docs
Canonical: no; current work routing: `TODO.md`
Exit: retain as point-in-time review source; create a newer dated reassessment snapshot only when current-main evidence materially changes the classification

Date: 2026-07-11
Source: external static audit of a user-supplied `bqn-ledger` ZIP. The original long-form report was supplied out of repository and is not copied verbatim here.

## Purpose

Preserve the external audit as a periodic review lens without turning its recommendation order into an implementation queue.

```text
external audit finding
  != current-main fact
  != TODO authority
  != implementation authorization
```

This snapshot is intentionally compact. It keeps the findings that are useful for future reassessment while avoiding another large duplicated roadmap.

## Reassessment rule

When this source is revisited:

1. Re-check the finding against current `main`, not against the old ZIP alone.
2. Classify it as one of:
   - `confirmed-current`
   - `policy-choice`
   - `already-resolved`
   - `stale`
   - `unclear-needs-evidence`
3. Check whether there is concrete daily-use, maintenance, CI, review, or consumer evidence.
4. Do not preserve the audit's original priority order automatically.
5. Promote at most one small finite candidate into `TODO.md` at a time.
6. If source meaning, arithmetic, policy, or ownership is involved, prefer a docs-only decision slice before runtime changes.
7. Do not create a broad refactor, observability, i18n, security, or release campaign merely because the audit proposed one.

## Review triggers

Reassessment is useful when one of these occurs:

- a major finite campaign closes;
- a `TODO.md` hygiene pass is already being performed;
- repeated concrete friction appears;
- a broad refactor, CI, security/privacy, i18n, observability, or release initiative is being considered;
- moko explicitly requests a reassessment.

No calendar cadence is required. Do not create review work only to satisfy the existence of this snapshot.

## Preserved finding inventory

### F1. Prefix fallback documentation/runtime drift

External finding:

- roadmap wording says Prefix Fallback removal is complete;
- current runtime or diagnostics may still contain prefix-based compatibility behavior.

Initial current-main reassessment on 2026-07-11: `confirmed-current` as a semantic-drift candidate.

Observed evidence at review time:

- `docs/ENGINEERING_ROADMAP.md` describes Prefix Fallback removal as complete;
- `src_next/household_policy.bqn` still computes an `expenses:` prefix fallback and includes it in `expense_accounts`;
- `src_next/envelope_computation.bqn` still uses expense and budget prefix fallback in selection masks;
- `src_next/household_metadata.bqn` counts fallback observations while its actual expense selection uses explicit `role=expense`;
- `AGENTS.md` still describes a role-migration path that preserves an explicit-role / Prefix-fallback contract before real-data migration.

Interpretation:

- this is not proof that fallback should simply be deleted;
- current code appears to mix diagnostic observation, compatibility behavior, and product/accounting selection;
- a future finite review should classify each fallback site before any removal or preservation decision.

Do not auto-implement from this snapshot.

### F2. CBQN reproducibility and `master` tracking

External finding:

- CI follows CBQN `master` while README names a recommended baseline;
- pinning was proposed as urgent reproducibility work.

Initial current-main reassessment on 2026-07-11: `policy-choice`.

Observed evidence at review time:

- `.github/workflows/check.yml` intentionally uses `CBQN_REF: master` and logs the resolved commit;
- `docs/CBQN_REPRODUCIBILITY.md` explicitly documents this policy and defines failure handling, including temporary pinning when upstream drift breaks the repository.

Interpretation:

- upstream tracking is a real risk surface, but not an undocumented drift by itself;
- review again when an upstream break occurs, reproducible release artifacts become a goal, or repeatability requirements change;
- do not auto-pin merely because this audit proposed it.

### F3. `context.bqn` centralization

External finding:

- `context.bqn` is becoming a central dependency and may need decomposition.

Initial current-main reassessment on 2026-07-11: `unclear-needs-evidence`, with a concrete ownership question near Currency Stage 2 B2.

Interpretation:

- file size alone is not authorization for refactoring;
- before adding new pure snapshot arithmetic logic, re-check whether `context.bqn` should remain the owner or whether a dedicated pure arithmetic module is justified;
- do not begin broad `context.bqn` decomposition automatically.

### F4. `envelope_computation.bqn` centralization

External finding:

- selection, allocation, spend, status, temporal helpers, backing checks, and output concerns are concentrated.

Initial current-main reassessment on 2026-07-11: `unclear-needs-evidence`.

Interpretation:

- complexity is observable;
- no broad split is authorized without concrete change friction, repeated multi-site edits, test-isolation problems, or a selected ownership decision;
- temporal semantics recently completed a major campaign, so structural cleanup must not casually reopen closed meaning questions.

### F5. `tools/coverage` truthfulness

External finding:

- the visible coverage inventory may lag actual tests/checks.

Initial current-main reassessment on 2026-07-11: `confirmed-current` as a small review candidate, not as proof of missing runtime tests.

Observed evidence at review time:

- `tools/coverage` is a hand-maintained module inventory and direct editor-check map;
- unmatched modules are printed as `untested`;
- mappings should be compared with actual current checks before the output is treated as evidence.

Possible future finite slice:

- compare current mappings with actual tests/checks;
- clarify naming and semantics if the tool overstates what it measures;
- do not build a broad coverage framework automatically.

### F6. Structured operation logs / OpenTelemetry

External finding:

- add JSONL operation logs and potentially align naming with OpenTelemetry conventions.

Initial current-main reassessment on 2026-07-11: `hold`.

Interpretation:

- this is a proposal, not a demonstrated defect;
- the project is a local CLI/workbench rather than a hosted distributed service;
- operation logs can create a new private evidence surface, including local paths and financial context;
- revisit only with a concrete troubleshooting or operational consumer.

### F7. Privacy, redaction, and backup handling

External finding:

- public-development procedures for screenshots, paths, backups, and fixture conversion could be stronger.

Initial current-main reassessment on 2026-07-11: `unclear-needs-evidence`, with narrow value.

Observed current baseline at review time:

- real data is kept outside the public repository via `LEDGER_DATA_DIR`;
- `SECURITY.md` forbids private household data, identifying local paths, screenshots with private financial details, tokens, and similar material in public reports;
- fixture-based reproduction is preferred.

Interpretation:

- do not start a broad privacy program automatically;
- reconsider a narrow public-evidence/redaction procedure if screenshot sharing, fixture extraction, backup retention, or external collaboration creates concrete friction.

### F8. i18n / locale / UTF-8 contract

External finding:

- label externalization exists, but locale selection and broader i18n contracts are incomplete.

Initial current-main reassessment on 2026-07-11: `hold`.

Interpretation:

- this may matter for a real multi-language consumer or distribution goal;
- do not create locale architecture only because the audit proposed it.

### F9. CI matrix, artifacts, OIDC, attestation, release packaging

External finding:

- expand CI/CD and supply-chain controls.

Initial current-main reassessment on 2026-07-11: `hold`.

Interpretation:

- distinguish CI reliability from release/distribution needs;
- matrix testing, release tarballs, OIDC, and attestation require concrete support or release goals;
- do not turn a local personal ledger into a release-engineering project without a consumer.

### F10. Currency / exact-decimal transition

External finding:

- integer-JPY behavior and exact-decimal / currency preparations coexist and can be misread as completed multi-currency support.

Initial current-main reassessment on 2026-07-11: `confirmed-current`, but already governed by a current staged plan.

Current authority remains:

- `docs/CURRENCY_STAGE2_SLICE_B_SPLIT_DECISION.md`;
- `TODO.md` finite routing.

Interpretation:

- do not create a second currency backlog from the audit;
- use the audit only to question ownership, drift, or misleading claims against the current staged contract.

### F11. Documentation volume and lifecycle drift

External finding:

- documentation is unusually large and can become a second source of confusion.

Initial current-main reassessment on 2026-07-11: `confirmed-current` as a standing risk already addressed by current policy.

Current authority remains:

- `docs/DOCS_LIFECYCLE_CONTRACT.md`;
- `docs/README.md` routing;
- `TODO.md` documentation currency/lifecycle maintenance lane.

Interpretation:

- do not start a broad docs rewrite from this audit;
- use small lifecycle corrections when concrete drift is found.

## Initial routing conclusion

At the 2026-07-11 reassessment:

- the Prefix Fallback finding is the strongest confirmed semantic-drift candidate;
- B2 remains current work and is not demoted merely because the audit proposed other work first;
- B2 ownership deserves a focused re-check before adding more pure arithmetic logic to a central module;
- CBQN pinning is a policy question, not an automatic defect fix;
- coverage inventory truthfulness is a small future candidate;
- broad decomposition, observability, i18n, release, and supply-chain initiatives remain unapproved.

This conclusion is point-in-time evidence only. Re-check current `main` before using it for future routing.
